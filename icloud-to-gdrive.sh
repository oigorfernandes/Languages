#!/bin/bash
#
# icloud-to-gdrive.sh — migra iCloud Drive -> Google Drive, em LOTES.
#
# Estrategia:
#   Junta arquivos ate' fechar um lote (por bytes ou por quantidade), materializa
#   o lote inteiro de uma vez, sobe numa unica chamada do rclone com varios
#   uploads em paralelo, confere, e so' entao despeja as copias locais.
#
#   Uma chamada de rclone por LOTE em vez de uma por arquivo: e' isso que faz a
#   diferenca entre dias e horas quando ha' dezenas de milhares de arquivos
#   pequenos, onde o custo fixo de abrir conexao dominava o tempo total.
#
#   O pico de disco continua limitado: um lote nunca e' maior que BATCH_BYTES,
#   e nunca e' iniciado se nao couber na folga livre.
#
# A arvore de pastas e' preservada identica, incluindo pastas vazias. Pacotes do
# macOS (.pages, .key, .app) sobem como a pasta que sao, com o conteudo no lugar.
#
# Uso:
#   ./icloud-to-gdrive.sh --dry-run     # so' planeja os lotes, nao transfere
#   ./icloud-to-gdrive.sh               # pra valer
#
# Pode interromper com Ctrl+C e rodar de novo: retoma pelo arquivo de estado.

set -uo pipefail

# ----------------------------------------------------------------------------
# CONFIGURACAO — todos aceitam sobrescrita por variavel de ambiente
# ----------------------------------------------------------------------------

ICLOUD_ROOT="${ICLOUD_ROOT:-$HOME/Library/Mobile Documents/com~apple~CloudDocs}"
ICLOUD_SUBDIR="${ICLOUD_SUBDIR:-Arte}"            # vazio = iCloud Drive inteiro
GDRIVE_REMOTE="${GDRIVE_REMOTE:-gdrive}"
GDRIVE_DEST="${GDRIVE_DEST:-Meus Arquivos/Arte}"
SEAGATE_DIR="${SEAGATE_DIR:-/Volumes/SEAGATE/iCloudGrandes}"

if [[ -n "$ICLOUD_SUBDIR" ]]; then
    ICLOUD_DIR="$ICLOUD_ROOT/$ICLOUD_SUBDIR"
else
    ICLOUD_DIR="$ICLOUD_ROOT"
fi

BATCH_BYTES="${BATCH_BYTES:-$((2 * 1024 * 1024 * 1024))}"        # ~2GB por lote
BATCH_MAX_FILES="${BATCH_MAX_FILES:-400}"                        # teto de itens
TRANSFERS="${TRANSFERS:-8}"                                      # uploads simultaneos
CHECKERS="${CHECKERS:-16}"
MAX_SIZE_BYTES="${MAX_SIZE_BYTES:-$((8 * 1024 * 1024 * 1024))}"  # acima disso, Seagate
MIN_FREE_BYTES="${MIN_FREE_BYTES:-$((4 * 1024 * 1024 * 1024))}"  # margem de disco
DOWNLOAD_TIMEOUT="${DOWNLOAD_TIMEOUT:-3600}"                     # espera por lote

JOB_SLUG=$(basename "$ICLOUD_DIR" | sed 's/[^A-Za-z0-9_-]/_/g')
STATE_DIR="${STATE_DIR:-$HOME/.icloud-migration/$JOB_SLUG}"
DONE_FILE="$STATE_DIR/concluidos.txt"
FAIL_FILE="$STATE_DIR/falhas.txt"
LOG_FILE="$STATE_DIR/migracao.log"

EVICT_AFTER_UPLOAD="${EVICT_AFTER_UPLOAD:-true}"

# ----------------------------------------------------------------------------

DRY_RUN=false
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=true

mkdir -p "$STATE_DIR"
touch "$DONE_FILE" "$FAIL_FILE"

RED=$'\033[0;31m'; GREEN=$'\033[0;32m'; YELLOW=$'\033[0;33m'
BLUE=$'\033[0;34m'; BOLD=$'\033[1m'; NC=$'\033[0m'

log() {
    printf '%s\n' "$1"
    printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" \
        "$(printf '%s' "$1" | sed $'s/\033\\[[0-9;]*m//g')" >> "$LOG_FILE"
}

human() {
    local b=$1
    if   (( b >= 1073741824 )); then printf '%.2f GB' "$(bc -l <<< "$b/1073741824")"
    elif (( b >= 1048576 ));    then printf '%.1f MB' "$(bc -l <<< "$b/1048576")"
    elif (( b >= 1024 ));       then printf '%.0f KB' "$(bc -l <<< "$b/1024")"
    else                             printf '%d B' "$b"
    fi
}

free_bytes() { df -k / | awk 'NR==2 {print $4 * 1024}'; }

# --- verificacoes -----------------------------------------------------------

command -v rclone >/dev/null || { log "${RED}rclone nao instalado.${NC}"; exit 1; }
command -v brctl  >/dev/null || { log "${RED}brctl nao encontrado (precisa ser macOS).${NC}"; exit 1; }
[[ -d "$ICLOUD_DIR" ]] || { log "${RED}Pasta nao encontrada: $ICLOUD_DIR${NC}"; exit 1; }

if ! $DRY_RUN && ! rclone lsd "${GDRIVE_REMOTE}:" >/dev/null 2>&1; then
    log "${RED}Remote '${GDRIVE_REMOTE}' nao responde. Rode: rclone config${NC}"
    exit 1
fi

DEST_ROOT="${GDRIVE_REMOTE}:${GDRIVE_DEST}"

log "${BOLD}Origem :${NC} $ICLOUD_DIR"
log "${BOLD}Destino:${NC} $DEST_ROOT"
log "${BOLD}Lote   :${NC} ate' $(human "$BATCH_BYTES") ou ${BATCH_MAX_FILES} arquivos, ${TRANSFERS} em paralelo"
echo

# --- lista o que falta ------------------------------------------------------
#
# Subtrai os concluidos da lista completa com `comm`, que compara duas listas
# ordenadas de uma vez — em vez de um `grep` por arquivo, que com 31 mil itens
# viraria dezenas de milhoes de comparacoes.

log "${BOLD}Varrendo...${NC}"

ALL_FILE="$STATE_DIR/.todos.txt"
PENDING="$STATE_DIR/.pendentes.txt"

find "$ICLOUD_DIR" -type f \
     ! -name '.DS_Store' ! -name '.localized' ! -name '*.icloud' \
     ! -path '*/.Trash/*' -print 2>/dev/null \
    | sed "s|^${ICLOUD_DIR}/||" | LC_ALL=C sort > "$ALL_FILE"

TOTAL=$(wc -l < "$ALL_FILE" | tr -d ' ')
LC_ALL=C sort -u "$DONE_FILE" > "$STATE_DIR/.feitos.txt"
LC_ALL=C comm -23 "$ALL_FILE" "$STATE_DIR/.feitos.txt" > "$PENDING"
FALTAM=$(wc -l < "$PENDING" | tr -d ' ')

log "Total: ${BOLD}${TOTAL}${NC} arquivos — ja' feitos: $((TOTAL - FALTAM)) — faltam: ${BOLD}${FALTAM}${NC}"
log "Disco livre: ${BOLD}$(human "$(free_bytes)")${NC}"
$DRY_RUN && log "${YELLOW}${BOLD}DRY-RUN — nada sera transferido.${NC}"
echo

(( FALTAM == 0 )) && { log "${GREEN}Nada a fazer.${NC}"; exit 0; }

# --- estado do loop ---------------------------------------------------------

BATCH_LIST="$STATE_DIR/.lote.txt"
COMBINED="$STATE_DIR/.combined.txt"
: > "$BATCH_LIST"
lote_n=0; lote_bytes=0; lote_arqs=0
enviados=0; falhados=0; grandes=0; bytes_ok=0
INICIO=$(date +%s)

# Envia o lote acumulado: materializa -> sobe -> confere -> despeja.
flush_lote() {
    (( lote_arqs == 0 )) && return 0
    lote_n=$((lote_n + 1))

    # Locais de verdade: sem isso os `read -r rel` daqui sobrescreveriam o `rel`
    # do laco principal, que continua valendo depois que esta funcao retorna.
    local rel marca linha f lg al

    local restam=$((FALTAM - enviados - falhados))
    printf '%s[lote %d]%s %d arquivos, %s  (restam %d)\n' \
        "$BLUE" "$lote_n" "$NC" "$lote_arqs" "$(human "$lote_bytes")" "$restam"

    if $DRY_RUN; then
        enviados=$((enviados + lote_arqs))
        : > "$BATCH_LIST"; lote_bytes=0; lote_arqs=0
        return 0
    fi

    # ---- 1. materializa o lote ----
    # Dispara todos os downloads e depois espera: o iCloud busca varios em
    # paralelo, entao pedir tudo de uma vez e' bem mais rapido que um a um.
    local t0 t1 t_baixa t_sobe t_confere
    t0=$(date +%s)
    printf '  baixando...'
    while IFS= read -r rel; do
        brctl download "$ICLOUD_DIR/$rel" 2>/dev/null
    done < "$BATCH_LIST"

    local esperou=0 faltando=0
    while (( esperou < DOWNLOAD_TIMEOUT )); do
        faltando=0
        while IFS= read -r rel; do
            local f="$ICLOUD_DIR/$rel"
            local lg al
            lg=$(stat -f%z "$f" 2>/dev/null || echo 0)
            al=$(( $(stat -f%b "$f" 2>/dev/null || echo 0) * 512 ))
            (( al < lg )) && faltando=$((faltando + 1))
        done < "$BATCH_LIST"
        (( faltando == 0 )) && break
        sleep 3; esperou=$((esperou + 3))
        (( esperou % 30 == 0 )) && printf '.'
    done

    t1=$(date +%s); t_baixa=$((t1 - t0)); t0=$t1
    if (( faltando > 0 )); then
        printf ' %s%d nao baixaram%s (%ds)\n' "$YELLOW" "$faltando" "$NC" "$t_baixa"
    else
        printf ' ok (%ds)\n' "$t_baixa"
    fi

    # ---- 2. sobe o lote inteiro numa chamada ----
    # --files-from limita a copia aos arquivos do lote; --no-traverse evita
    # listar o destino inteiro a cada lote, que ficaria caro conforme ele cresce.
    printf '  enviando (%d em paralelo)...' "$TRANSFERS"
    rclone copy "$ICLOUD_DIR" "$DEST_ROOT" \
        --files-from "$BATCH_LIST" \
        --transfers "$TRANSFERS" --checkers "$CHECKERS" \
        --drive-chunk-size 32M --retries 3 --low-level-retries 10 \
        --no-traverse --stats 0 >>"$LOG_FILE" 2>&1
    t1=$(date +%s); t_sobe=$((t1 - t0)); t0=$t1
    if (( t_sobe > 0 )); then
        printf ' ok (%ds, %.0f Mbps)\n' "$t_sobe" \
            "$(bc -l <<< "$lote_bytes * 8 / 1000000 / $t_sobe")"
    else
        printf ' ok (%ds)\n' "$t_sobe"
    fi

    # ---- 3. confere o lote ----
    # --combined marca cada arquivo: '=' igual, o resto e' problema. Assim um
    # arquivo com defeito nao condena o lote todo — so' ele volta pra fila.
    printf '  verificando...'
    rclone check "$ICLOUD_DIR" "$DEST_ROOT" \
        --files-from "$BATCH_LIST" --size-only \
        --combined "$COMBINED" >>"$LOG_FILE" 2>&1

    local ok_n=0 bad_n=0
    if [[ -s "$COMBINED" ]]; then
        while IFS= read -r linha; do
            local marca="${linha:0:1}" rel="${linha:2}"
            if [[ "$marca" == "=" ]]; then
                printf '%s\n' "$rel" >> "$DONE_FILE"
                ok_n=$((ok_n + 1))
                $EVICT_AFTER_UPLOAD && brctl evict "$ICLOUD_DIR/$rel" >/dev/null 2>&1
            else
                printf '%s\tdivergente (%s)\n' "$rel" "$marca" >> "$FAIL_FILE"
                bad_n=$((bad_n + 1))
            fi
        done < "$COMBINED"
    else
        # sem saida do check: nao da' pra afirmar que chegou, entao nao despeja
        while IFS= read -r rel; do
            printf '%s\tverificacao sem resultado\n' "$rel" >> "$FAIL_FILE"
            bad_n=$((bad_n + 1))
        done < "$BATCH_LIST"
    fi

    t1=$(date +%s); t_confere=$((t1 - t0))
    if (( bad_n == 0 )); then
        printf ' %sok (%d)%s (%ds)\n' "$GREEN" "$ok_n" "$NC" "$t_confere"
    else
        printf ' %s%d ok, %d com problema%s (%ds)\n' "$YELLOW" "$ok_n" "$bad_n" "$NC" "$t_confere"
    fi
    printf '  %stempo: baixar %ds | subir %ds | conferir %ds%s\n' \
        "$BOLD" "$t_baixa" "$t_sobe" "$t_confere" "$NC" 

    enviados=$((enviados + ok_n))
    falhados=$((falhados + bad_n))
    bytes_ok=$((bytes_ok + lote_bytes))

    # ---- ritmo e previsao ----
    local agora decorrido taxa restantes eta
    agora=$(date +%s); decorrido=$((agora - INICIO))
    if (( enviados > 0 && decorrido > 0 )); then
        taxa=$(( enviados * 3600 / decorrido ))
        restantes=$((FALTAM - enviados - falhados))
        if (( taxa > 0 )); then
            eta=$(( restantes / taxa ))
            printf '  %s%d arq/h — faltam ~%dh%s  (livre: %s)\n\n' \
                "$BOLD" "$taxa" "$eta" "$NC" "$(human "$(free_bytes)")"
        fi
    fi

    : > "$BATCH_LIST"; lote_bytes=0; lote_arqs=0
}

# --- monta e despacha os lotes ----------------------------------------------

while IFS= read -r rel; do
    arquivo="$ICLOUD_DIR/$rel"
    tam=$(stat -f%z "$arquivo" 2>/dev/null || echo 0)

    # arquivo gigante: vai sozinho pro HD externo
    if (( tam > MAX_SIZE_BYTES )); then
        flush_lote
        if [[ -d "$SEAGATE_DIR" ]]; then
            printf '%s[grande]%s %s (%s) -> Seagate\n' "$YELLOW" "$NC" "$rel" "$(human "$tam")"
            if ! $DRY_RUN; then
                mkdir -p "$(dirname "$SEAGATE_DIR/$rel")"
                brctl download "$arquivo" 2>/dev/null
                if rclone copyto "$arquivo" "$SEAGATE_DIR/$rel" --retries 3 \
                     --stats 0 >>"$LOG_FILE" 2>&1; then
                    printf '%s\n' "$rel" >> "$DONE_FILE"
                    $EVICT_AFTER_UPLOAD && brctl evict "$arquivo" >/dev/null 2>&1
                else
                    printf '%s\tcopia pro HD falhou\n' "$rel" >> "$FAIL_FILE"
                fi
            fi
        else
            printf '%s[grande]%s %s (%s) — HD ausente, pulando\n' \
                "$YELLOW" "$NC" "$rel" "$(human "$tam")"
            printf '%s\tgrande, HD ausente\n' "$rel" >> "$FAIL_FILE"
        fi
        grandes=$((grandes + 1))
        continue
    fi

    # o lote nao pode passar do limite de bytes nem estourar o disco
    livre=$(free_bytes)
    teto=$(( livre - MIN_FREE_BYTES ))
    (( teto > BATCH_BYTES )) && teto=$BATCH_BYTES

    if (( lote_arqs > 0 )) && \
       { (( lote_bytes + tam > teto )) || (( lote_arqs >= BATCH_MAX_FILES )); }; then
        flush_lote
        livre=$(free_bytes)
    fi

    if (( tam > livre - MIN_FREE_BYTES )); then
        log "${RED}ABORTANDO: sem espaco para $rel ($(human "$tam")).${NC}"
        log "${RED}Libere disco e rode de novo — ele retoma daqui.${NC}"
        break
    fi

    printf '%s\n' "$rel" >> "$BATCH_LIST"
    lote_bytes=$((lote_bytes + tam))
    lote_arqs=$((lote_arqs + 1))
done < "$PENDING"

flush_lote

# --- pastas vazias ----------------------------------------------------------

if ! $DRY_RUN; then
    printf '%sRecriando pastas vazias...%s\n' "$BOLD" "$NC"
    vazias=0
    while IFS= read -r dir; do
        reldir="${dir#"$ICLOUD_DIR"/}"
        [[ "$reldir" == "$dir" ]] && continue
        rclone mkdir "$DEST_ROOT/$reldir" >>"$LOG_FILE" 2>&1 && vazias=$((vazias + 1))
    done < <(find "$ICLOUD_DIR" -type d -empty -not -path '*/.Trash/*' 2>/dev/null)
    printf '  %d pasta(s) recriada(s)\n' "$vazias"
fi

# --- resumo -----------------------------------------------------------------

DECORRIDO=$(( $(date +%s) - INICIO ))
echo
log "${BOLD}=== RESUMO ===${NC}"
log "  lotes        : ${lote_n}"
log "  transferidos : ${GREEN}${enviados}${NC}"
log "  no Seagate   : ${YELLOW}${grandes}${NC}"
log "  com problema : ${RED}${falhados}${NC}"
log "  tempo        : $((DECORRIDO / 3600))h $(((DECORRIDO % 3600) / 60))min"
log "  disco livre  : $(human "$(free_bytes)")"
echo
log "  estado : $DONE_FILE"
log "  falhas : $FAIL_FILE"
log "  log    : $LOG_FILE"

if (( falhados > 0 )); then
    echo
    log "${YELLOW}Rode de novo para tentar os que ficaram (os prontos sao pulados).${NC}"
fi
