#!/bin/bash
#
# comparar.sh — compara origem (iCloud) e destino (Drive) pasta a pasta.
#
# Para cada pasta de primeiro nivel dentro de Arte, mostra quantos arquivos e
# quantos bytes existem de cada lado, e marca as que divergem.
#
# Uso:  ./comparar.sh            # so' as pastas com diferenca
#       ./comparar.sh --todas    # todas as pastas

set -uo pipefail

BASE="${ICLOUD_ROOT:-$HOME/Library/Mobile Documents/com~apple~CloudDocs}/${ICLOUD_SUBDIR:-Arte}"
DEST="${GDRIVE_REMOTE:-gdrive}:${GDRIVE_DEST:-Meus Arquivos/Arte}"
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT

TODAS=false
[[ "${1:-}" == "--todas" ]] && TODAS=true

# Agrega uma listagem "tamanho caminho/relativo" por pasta de primeiro nivel.
agrega() {
    awk '{
        sz = $1; $1 = ""; sub(/^[ \t]+/, "")
        n = index($0, "/")
        top = (n ? substr($0, 1, n-1) : "(raiz)")
        cnt[top]++; sum[top] += sz
    }
    END { for (t in cnt) printf "%s\t%d\t%d\n", t, cnt[t], sum[t] }'
}

printf 'Lendo a origem (iCloud)...\n' >&2
find "$BASE" -type f ! -name '.DS_Store' ! -name '.localized' ! -name '*.icloud' \
     ! -path '*/.Trash/*' -exec stat -f '%z %N' {} + 2>/dev/null \
  | sed "s| ${BASE}/| |" | agrega | LC_ALL=C sort > "$TMP/origem"

printf 'Lendo o destino (Drive)...\n' >&2
rclone ls "$DEST" 2>/dev/null | agrega | LC_ALL=C sort > "$TMP/destino"

printf '\n%-38s %8s %10s   %8s %10s   %s\n' \
    "PASTA" "arq(o)" "GiB(o)" "arq(d)" "GiB(d)" ""
printf '%s\n' "$(printf '%.0s-' {1..92})"

LC_ALL=C join -a1 -a2 -t$'\t' -e 0 -o '0,1.2,1.3,2.2,2.3' "$TMP/origem" "$TMP/destino" \
  | TODAS=$TODAS awk -F'\t' '
    {
        pasta = $1; co = $2; so = $3; cd = $4; sd = $5
        difc = cd - co; difs = sd - so
        if (difc == 0 && difs == 0)      marca = "ok"
        else if (difc < 0 || difs < 0)   { marca = sprintf("FALTA %d arq, %.2f GiB", -difc, -difs/1073741824); falhou = 1 }
        else                              marca = sprintf("+%d arq no destino", difc)
        if (ENVIRON["TODAS"] == "true" || marca != "ok")
            printf "%-38s %8d %10.2f   %8d %10.2f   %s\n", pasta, co, so/1073741824, cd, sd/1073741824, marca
        tco += co; tso += so; tcd += cd; tsd += sd
    }
    END {
        sep = ""; for (i = 0; i < 92; i++) sep = sep "-"
        printf "%s\n", sep
        printf "%-38s %8d %10.2f   %8d %10.2f\n", "TOTAL", tco, tso/1073741824, tcd, tsd/1073741824
    }'
