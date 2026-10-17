#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

main=(curl --noproxy '*' --silent --show-error --insecure --resolve lab.localhost:443:127.0.0.1)

echo 'Контейнеры:'
docker compose ps

echo 'Пользователь хорошего образа:'
user="$(docker compose exec -T backend-a whoami | tr -d '\r')"
echo "$user"
[[ "$user" == node ]]

echo 'Проверяем сохранение записи после пересоздания MongoDB:'
text="persist-$(date +%s)"
old_mongo="$(docker compose ps -q mongo)"
"${main[@]}" -H 'Content-Type: application/json' -d "{\"text\":\"$text\"}" https://lab.localhost/api/notes/add
echo
docker compose stop mongo
docker compose rm -f mongo
docker compose up -d mongo
new_mongo="$(docker compose ps -q mongo)"
[[ -n "$old_mongo" && -n "$new_mongo" && "$old_mongo" != "$new_mongo" ]]
echo "Контейнер MongoDB заменён: ${old_mongo:0:12} → ${new_mongo:0:12}"
for _ in {1..30}; do
  if "${main[@]}" https://lab.localhost/api/notes | grep -q "$text"; then
    echo "После пересоздания MongoDB запись $text найдена."
    break
  fi
  sleep 2
done
"${main[@]}" https://lab.localhost/api/notes | grep -q "$text"

echo 'Сетевая изоляция frontend → mongo:'
docker compose exec -T frontend sh -c 'command -v nc >/dev/null'
if docker compose exec -T frontend sh -c 'nc -z -w 2 mongo 27017'; then
  echo 'Ошибка: фронтенд видит БД напрямую.' >&2
  exit 1
else
  echo 'Соединение отклонено: у frontend нет доступа к сети data.'
fi

echo 'Проверки лабы 2 прошли.'
