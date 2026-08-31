#!/bin/bash
#
# status.sh — panorama da migracao iCloud -> Google Drive.
#
# Uso:  ./status.sh          (rapido, sem consultar o Drive)
#       ./status.sh --drive  (inclui o total ja' recebido pelo Drive; demora)

ICLOUD_DIR="${ICLOUD_ROOT:-$HOME/Library/Mobile Documents/com~apple~CloudDocs}/${ICLOUD_SUBDIR:-Arte}"
STATE_DIR="${STATE_DIR:-$HOME/.icloud-migration/$(basename "$ICLOUD_DIR")}"
SAIDA="${SAIDA:-$HOME/Desktop/migracao.txt}"
DEST="${GDRIVE_REMOTE:-gdrive}:${GDRIVE_DEST:-Meus Arquivos/Arte}"

B=$'\033[1m'; V=$'\033[0;32m'; A=$'\033[0;33m'; R=$'\033[0;31m'; N=$'\033[0m'

gb() { awk -v b="$1" 'BEGIN {printf "%.1f GB", b/1073741824}'; }

# --- esta' rodando? ---
# Uma execucao saudavel aparece como TRES processos — caffeinate, o laco
# `while true` e o script — porque os tres carregam o texto do comando no argv.
# Para saber quantas copias existem de fato, conta os caffeinate: um por
# lancamento. (pgrep -c nao existe no macOS, e `ps -o command=` corta a linha na
# largura do terminal; por isso pgrep -f + wc.)
vivo=$(pgrep -f "icloud-to-gdrive.sh" 2>/dev/null | wc -l | tr -d ' ')
copias=$(pgrep -f "caffeinate -ims bash" 2>/dev/null | wc -l | tr -d ' ')
: "${vivo:=0}"; : "${copias:=0}"

if (( vivo == 0 )); then
    printf '%sestado:%s %sparado%s\n' "$B" "$N" "$R" "$N"
elif (( copias > 1 )); then
    printf '%sestado:%s %s%d copias rodando — elas se atrapalham, deixe so uma%s\n' \
        "$B" "$N" "$R" "$copias" "$N"
else
    printf '%sestado:%s %srodando%s\n' "$B" "$N" "$V" "$N"
fi

# --- progresso ---
linhas() { cat "$1" 2>/dev/null | wc -l | tr -d ' '; }
feitos=$(sort -u "$STATE_DIR/concluidos.txt" 2>/dev/null | wc -l | tr -d ' ')
total=$(linhas "$STATE_DIR/.todos.txt")
: "${total:=0}"
fila="$STATE_DIR/.fila.txt"
[[ -s "$fila" ]] || fila="$STATE_DIR/.pendentes.txt"
restam=$(linhas "$fila")
: "${restam:=0}"

printf '%sarquivos:%s %s enviados' "$B" "$N" "$feitos"
(( total > 0 )) && printf ' — %d na fila (%d%% feito)' "$restam" $(( feitos * 100 / (feitos + restam > 0 ? feitos + restam : 1) ))
printf '\n'

# --- quanto falta em bytes ---
if [[ -s "$fila" ]]; then
    bytes=$(awk -v d="$ICLOUD_DIR" '{print d"/"$0}' "$fila" | tr '\n' '\0' \
            | xargs -0 stat -f%z 2>/dev/null | awk '{s+=$1} END {print s+0}')
    printf '%sfalta:%s   %s\n' "$B" "$N" "$(gb "$bytes")"
fi

# --- falhas ---
falhas=$(linhas "$STATE_DIR/falhas.txt")
: "${falhas:=0}"
if (( falhas > 0 )); then
    printf '%sfalhas:%s  %s%d%s (rode o script de novo para tentar outra vez)\n' \
        "$B" "$N" "$A" "$falhas" "$N"
fi

# --- disco ---
livre=$(df -k / | awk 'NR==2 {print $4 * 1024}')
if (( livre < 4294967296 )); then
    printf '%sdisco:%s   %s%s livre — apertado%s\n' "$B" "$N" "$A" "$(gb "$livre")" "$N"
else
    printf '%sdisco:%s   %s livre\n' "$B" "$N" "$(gb "$livre")"
fi

# --- ultimo lote ---
if [[ -f "$SAIDA" ]]; then
    ultimo=$(grep -a "^\[lote" "$SAIDA" | tail -1)
    tempo=$(grep -a "tempo:" "$SAIDA" | tail -1 | sed 's/^ *//')
    [[ -n "$ultimo" ]] && printf '\n%sultimo lote:%s %s\n' "$B" "$N" "$ultimo"
    [[ -n "$tempo" ]] && printf '  %s\n' "$tempo"
fi

# --- Drive (opcional: demora) ---
if [[ "${1:-}" == "--drive" ]]; then
    printf '\n%sno Drive:%s ' "$B" "$N"
    rclone size "$DEST" 2>/dev/null | tr '\n' ' '; printf '\n'
fi
