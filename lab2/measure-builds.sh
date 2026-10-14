#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
git archive HEAD | tar -x -C "$tmp"

echo 'Первоначальная сборка обоих образов:'
docker build -f "$tmp/lab2/Dockerfile.bad" -t lab2-bad:local "$tmp"
docker build -f "$tmp/Dockerfile" -t lab2-good:local "$tmp"

echo '// Изменена одна строка для измерения кеша' >> "$tmp/modules/api/methods/ping/index.js"
echo 'Повторная сборка после изменения одной строки:'
echo 'Плохой образ:'
time docker build -f "$tmp/lab2/Dockerfile.bad" -t lab2-bad:local "$tmp"
echo 'Хороший образ:'
time docker build -f "$tmp/Dockerfile" -t lab2-good:local "$tmp"

echo 'Размеры в байтах:'
docker image inspect lab2-bad:local --format 'bad={{.Size}}'
docker image inspect lab2-good:local --format 'good={{.Size}}'
