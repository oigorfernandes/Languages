#!/bin/bash
#
# icloud-to-gdrive.sh — migra iCloud Drive -> Google Drive, um item por vez.
#
# Como funciona:
#   Para CADA item, na ordem: baixa (materializa) -> sobe -> confere -> despeja.
#   O pico de uso de disco e' o tamanho do MAIOR item, nao o da biblioteca toda.
#
# A arvore de pastas e' preservada identica no destino, incluindo pastas vazias.
# Pacotes do macOS (.pages, .key, .app, .rtfd...) sao tratados como UMA unidade,
# nunca abertos e espalhados.
#
# Itens acima de MAX_SIZE_BYTES vao para o HD externo, para upload manual depois.
#
# Uso:
#   ./icloud-to-gdrive.sh --dry-run     # simula, nao move nada (COMECE POR AQUI)
#   ./icloud-to-gdrive.sh               # pra valer
#
# Pode interromper com Ctrl+C a qualquer momento e rodar de novo: ele retoma
# de onde parou lendo o arquivo de estado.

set -uo pipefail

# ----------------------------------------------------------------------------
# CONFIGURACAO — ajuste estes valores
# ----------------------------------------------------------------------------

# Todos aceitam ser sobrescritos por variavel de ambiente, entao da' pra rodar
# pastas diferentes sem editar o script. Ex:
#   ICLOUD_SUBDIR="ARTE" GDRIVE_DEST="Meus Arquivos/ARTE" ./icloud-to-gdrive.sh

ICLOUD_ROOT="${ICLOUD_ROOT:-$HOME/Library/Mobile Documents/com~apple~CloudDocs}"
ICLOUD_SUBDIR="${ICLOUD_SUBDIR:-Arte}"      # vazio = migrar o iCloud Drive inteiro
GDRIVE_REMOTE="${GDRIVE_REMOTE:-gdrive}"    # nome do remote do `rclone config`
GDRIVE_DEST="${GDRIVE_DEST:-Meus Arquivos/Arte}"  # pasta de destino dentro do Drive
SEAGATE_DIR="${SEAGATE_DIR:-/Volumes/SEAGATE/iCloudGrandes}"

if [[ -n "$ICLOUD_SUBDIR" ]]; then
    ICLOUD_DIR="$ICLOUD_ROOT/$ICLOUD_SUBDIR"
else
    ICLOUD_DIR="$ICLOUD_ROOT"
fi

MAX_SIZE_BYTES="${MAX_SIZE_BYTES:-$((8 * 1024 * 1024 * 1024))}"  # acima disso, Seagate
MIN_FREE_BYTES="${MIN_FREE_BYTES:-$((4 * 1024 * 1024 * 1024))}"  # margem de disco livre
DOWNLOAD_TIMEOUT="${DOWNLOAD_TIMEOUT:-1800}"                     # espera maxima por item

JOB_SLUG=$(basename "$ICLOUD_DIR" | sed 's/[^A-Za-z0-9_-]/_/g')
STATE_DIR="${STATE_DIR:-$HOME/.icloud-migration/$JOB_SLUG}"
DONE_FILE="$STATE_DIR/concluidos.txt"
FAIL_FILE="$STATE_DIR/falhas.txt"
LOG_FILE="$STATE_DIR/migracao.log"

# Despejar a copia local depois de subir? (false = util pra testar)
EVICT_AFTER_UPLOAD=true

# Extensoes que o macOS trata como PACOTE: sao pastas por baixo, mas precisam
# viajar inteiras. Abrir uma dessas e copiar o conteudo solto QUEBRA o arquivo.
BUNDLE_EXTS=(app rtfd pages numbers key photoslibrary musiclibrary tvlibrary
             band logicx fcpbundle scriv sparsebundle framework bundle pkg
             mpkg qlgenerator prefpane workflow download aplibrary)

# ----------------------------------------------------------------------------

DRY_RUN=false
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=true

mkdir -p "$STATE_DIR"
touch "$DONE_FILE" "$FAIL_FILE"

RED=$'\033[0;31m'; GREEN=$'\033[0;32m'; YELLOW=$'\033[0;33m'
BLUE=$'\033[0;34m'; BOLD=$'\033[1m'; NC=$'\033[0m'

log() {
    local msg="$1"
    printf '%s\n' "$msg"
    printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" \
        "$(printf '%s' "$msg" | sed $'s/\033\\[[0-9;]*m//g')" >> "$LOG_FILE"
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

# Tamanho LOGICO de um item: para um placeholder do iCloud, `stat -f%z` ja
# devolve o tamanho real que o arquivo tera' depois de baixado — entao da' pra
# decidir o destino ANTES de baixar. Para um pacote, soma os arquivos internos.
logical_size() {
    local path="$1"
    if [[ -d "$path" ]]; then
        find "$path" -type f -exec stat -f%z {} + 2>/dev/null \
            | awk '{s+=$1} END {print s+0}'
    else
        stat -f%z "$path" 2>/dev/null || echo 0
    fi
}

# Quantos bytes do item ja' estao de fato materializados em disco.
materialized_size() {
    local path="$1"
    if [[ -d "$path" ]]; then
        find "$path" -type f -exec stat -f%b {} + 2>/dev/null \
            | awk '{s+=$1} END {print (s+0)*512}'
    else
        echo $(( $(stat -f%b "$path" 2>/dev/null || echo 0) * 512 ))
    fi
}

# --- verificacoes iniciais --------------------------------------------------

command -v rclone >/dev/null || { log "${RED}rclone nao instalado. Rode: brew install rclone${NC}"; exit 1; }
command -v brctl  >/dev/null || { log "${RED}brctl nao encontrado (precisa ser macOS).${NC}"; exit 1; }
[[ -d "$ICLOUD_DIR" ]] || { log "${RED}Pasta do iCloud nao encontrada: $ICLOUD_DIR${NC}"; exit 1; }

if ! rclone lsd "${GDRIVE_REMOTE}:" >/dev/null 2>&1; then
    log "${RED}Remote '${GDRIVE_REMOTE}' nao responde. Rode: rclone config${NC}"
    exit 1
fi

if [[ ! -d "$SEAGATE_DIR" ]]; then
    log "${YELLOW}Aviso: $SEAGATE_DIR nao existe.${NC}"
    log "${YELLOW}Itens acima de $(human $MAX_SIZE_BYTES) serao PULADOS.${NC}"
    log "${YELLOW}Conecte o HD (ou ajuste SEAGATE_DIR no script) para trata-los.${NC}"
    echo
fi

# --- monta a lista de itens -------------------------------------------------
#
# Um "item" e' um arquivo comum OU um pacote inteiro. O -prune faz o find parar
# na borda do pacote: ele reporta o pacote e nao desce dentro dele.

log "${BOLD}Origem :${NC} $ICLOUD_DIR"
log "${BOLD}Destino:${NC} ${GDRIVE_REMOTE}:${GDRIVE_DEST}"
echo
log "${BOLD}Varrendo...${NC}"

bundle_pred=()
for ext in "${BUNDLE_EXTS[@]}"; do
    bundle_pred+=(-o -iname "*.${ext}")
done
bundle_pred=("${bundle_pred[@]:1}")   # descarta o -o inicial

FILE_LIST="$STATE_DIR/lista.txt"
find "$ICLOUD_DIR" \
     \( -type d \( "${bundle_pred[@]}" \) -prune -print0 \) -o \
     \( -type f ! -name '.DS_Store' ! -name '.localized' \
        ! -name '*.icloud' ! -path '*/.Trash/*' -print0 \) \
     > "$FILE_LIST" 2>/dev/null

TOTAL=$(tr -dc '\0' < "$FILE_LIST" | wc -c | tr -d ' ')
log "Encontrados ${BOLD}${TOTAL}${NC} itens (arquivos + pacotes)."
log "Espaco livre agora: ${BOLD}$(human "$(free_bytes)")${NC}"
$DRY_RUN && log "${YELLOW}${BOLD}MODO DRY-RUN — nada sera transferido.${NC}"
echo

n=0; ok=0; skip=0; big=0; fail=0; bundles=0
bytes_enviados=0

# --- loop principal ---------------------------------------------------------

while IFS= read -r -d '' item; do
    n=$((n + 1))

    rel="${item#"$ICLOUD_DIR"/}"          # caminho relativo — preserva a arvore

    if grep -qxF "$rel" "$DONE_FILE" 2>/dev/null; then
        skip=$((skip + 1)); continue
    fi

    if [[ -d "$item" ]]; then
        eh_pacote=true;  rotulo=" ${BLUE}[pacote]${NC}"
    else
        eh_pacote=false; rotulo=""
    fi

    printf '%s[%d/%d]%s %s%s\n' "$BLUE" "$n" "$TOTAL" "$NC" "$rel" "$rotulo"

    size=$(logical_size "$item")
    if (( size == 0 )) && ! $eh_pacote; then
        log "  ${RED}nao consegui ler o tamanho — pulando${NC}"
        printf '%s\tstat falhou\n' "$rel" >> "$FAIL_FILE"
        fail=$((fail + 1)); continue
    fi
    printf '  tamanho: %s\n' "$(human "$size")"

    livre=$(free_bytes)
    if (( livre - size < MIN_FREE_BYTES )); then
        log "  ${RED}ABORTANDO: livre $(human "$livre"), preciso de $(human "$size") + margem.${NC}"
        log "  ${RED}Libere espaco e rode de novo — ele retoma daqui.${NC}"
        break
    fi

    if (( size > MAX_SIZE_BYTES )); then
        if [[ ! -d "$SEAGATE_DIR" ]]; then
            printf '  %sgrande demais e HD ausente — pulando%s\n' "$YELLOW" "$NC"
            printf '%s\tgrande, HD ausente\n' "$rel" >> "$FAIL_FILE"
            big=$((big + 1)); continue
        fi
        destino="$SEAGATE_DIR/$rel"
        printf '  %s-> Seagate (acima de %s)%s\n' "$YELLOW" "$(human $MAX_SIZE_BYTES)" "$NC"
        $DRY_RUN && { big=$((big + 1)); continue; }
        mkdir -p "$(dirname "$destino")"
        modo="seagate"
    else
        modo="gdrive"
    fi

    $DRY_RUN && { printf '  %s(dry-run)%s\n' "$YELLOW" "$NC"; ok=$((ok + 1)); continue; }

    # ---- 1. materializa (baixa do iCloud) ----
    printf '  baixando...'
    brctl download "$item" 2>/dev/null

    esperou=0
    while (( esperou < DOWNLOAD_TIMEOUT )); do
        (( $(materialized_size "$item") >= size )) && break
        sleep 2; esperou=$((esperou + 2))
        (( esperou % 30 == 0 )) && printf '.'
    done

    if (( $(materialized_size "$item") < size )); then
        printf ' %sTIMEOUT%s\n' "$RED" "$NC"
        printf '%s\tdownload timeout\n' "$rel" >> "$FAIL_FILE"
        fail=$((fail + 1)); continue
    fi
    printf ' ok\n'

    # ---- 2. envia ----
    # copyto para arquivo (destino = caminho final), copy para pacote
    # (destino = a pasta do pacote, conteudo espelhado dentro dela).
    if [[ "$modo" == "gdrive" ]]; then
        alvo="${GDRIVE_REMOTE}:${GDRIVE_DEST}/${rel}"
        printf '  enviando pro Drive...'
    else
        alvo="$destino"
        printf '  copiando pro Seagate...'
    fi

    if $eh_pacote; then
        rclone_cmd=(rclone copy "$item" "$alvo")
    else
        rclone_cmd=(rclone copyto "$item" "$alvo")
    fi

    if "${rclone_cmd[@]}" --drive-chunk-size 32M --retries 3 \
         --low-level-retries 10 --stats-one-line --stats 0 >>"$LOG_FILE" 2>&1
    then
        printf ' ok\n'
    else
        printf ' %sFALHOU%s\n' "$RED" "$NC"
        printf '%s\tenvio falhou\n' "$rel" >> "$FAIL_FILE"
        fail=$((fail + 1)); continue
    fi

    # ---- 3. confere ----
    # Compara o total de bytes no destino com o tamanho logico local.
    # `rclone size` aceita tanto arquivo quanto pasta, entao a mesma checagem
    # serve para itens comuns e para pacotes — ao contrario do `rclone check`,
    # que espera diretorios e da' falso negativo quando recebe um arquivo.
    printf '  verificando...'
    remoto=$(rclone size --json "$alvo" 2>>"$LOG_FILE" \
             | sed -n 's/.*"bytes":[[:space:]]*\([0-9-]*\).*/\1/p')
    : "${remoto:=-1}"

    if [[ "$remoto" == "$size" ]]; then
        printf ' ok\n'
    else
        printf ' %sNAO CONFERE%s (local %s, remoto %s)\n' "$RED" "$NC" \
            "$(human "$size")" "$( (( remoto >= 0 )) && human "$remoto" || echo '?' )"
        printf '%s\tverificacao falhou: local=%s remoto=%s\n' "$rel" "$size" "$remoto" >> "$FAIL_FILE"
        fail=$((fail + 1)); continue
    fi

    # ---- 4. despeja (libera disco; o item continua no iCloud) ----
    $EVICT_AFTER_UPLOAD && brctl evict "$item" 2>/dev/null || true

    printf '%s\n' "$rel" >> "$DONE_FILE"
    ok=$((ok + 1))
    bytes_enviados=$((bytes_enviados + size))
    $eh_pacote && bundles=$((bundles + 1))
    [[ "$modo" == "seagate" ]] && big=$((big + 1))

    printf '  %sconcluido%s  (livre: %s)\n\n' "$GREEN" "$NC" "$(human "$(free_bytes)")"

done < "$FILE_LIST"

# --- pastas vazias ----------------------------------------------------------
#
# O find acima so' lista arquivos e pacotes, entao uma pasta sem nada dentro
# nunca apareceria no destino. Recria essas pastas para a arvore ficar identica.

if ! $DRY_RUN; then
    printf '%sRecriando pastas vazias...%s\n' "$BOLD" "$NC"
    vazias=0
    while IFS= read -r -d '' dir; do
        reldir="${dir#"$ICLOUD_DIR"/}"
        [[ "$reldir" == "$dir" ]] && continue          # e' a raiz, ignora
        rclone mkdir "${GDRIVE_REMOTE}:${GDRIVE_DEST}/${reldir}" >>"$LOG_FILE" 2>&1 \
            && vazias=$((vazias + 1))
    done < <(find "$ICLOUD_DIR" -type d -empty -not -path '*/.Trash/*' -print0 2>/dev/null)
    printf '  %d pasta(s) vazia(s) recriada(s)\n' "$vazias"
fi

# --- resumo -----------------------------------------------------------------

echo
log "${BOLD}=== RESUMO ===${NC}"
log "  transferidos : ${GREEN}${ok}${NC}"
log "  ja feitos    : ${skip}"
log "  pacotes      : ${bundles} (enviados inteiros)"
log "  no Seagate   : ${YELLOW}${big}${NC}"
log "  falhas       : ${RED}${fail}${NC}"
log "  volume       : ${BOLD}$(human "$bytes_enviados")${NC}"
echo
log "  estado : $DONE_FILE"
log "  falhas : $FAIL_FILE"
log "  log    : $LOG_FILE"

if (( fail > 0 )); then
    echo
    log "${YELLOW}Rode o script de novo para tentar as falhas outra vez${NC}"
    log "${YELLOW}(os concluidos sao pulados automaticamente).${NC}"
fi
