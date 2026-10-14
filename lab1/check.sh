#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

http=(curl --noproxy '*' --silent --show-error --resolve lab.localhost:80:127.0.0.1)
main=(curl --noproxy '*' --silent --show-error --insecure --resolve lab.localhost:443:127.0.0.1)
other=(curl --noproxy '*' --silent --show-error --insecure --resolve other.localhost:443:127.0.0.1)

echo '1. HTTP → HTTPS'
redirect="$("${http[@]}" -I http://lab.localhost/ | tr -d '\r')"
echo "$redirect" | head -n 5
[[ "$redirect" == *'301'* && "$redirect" == *'https://lab.localhost/'* ]]

echo '2. Оба экземпляра API'
seen=''
for _ in 1 2 3 4 5 6; do
  instance="$("${main[@]}" -D - -o /dev/null https://lab.localhost/api/notes | tr -d '\r' | awk -F ': ' 'tolower($1)=="x-backend-instance" {print $2}')"
  printf 'X-Backend-Instance: %s\n' "$instance"
  seen="$seen $instance"
  sleep 0.25
done
[[ "$seen" == *backend-a* && "$seen" == *backend-b* ]]

echo '3. alias /docs/'
"${main[@]}" https://lab.localhost/docs/ | grep -q 'директиву alias'
echo '/docs/: OK'

echo '4. Виртуальные хосты'
"${other[@]}" https://other.localhost/ | grep -q 'Второй проект'
other_headers="$("${other[@]}" -I https://other.localhost/ | tr -d '\r')"
echo "$other_headers" | grep -i 'X-Site: other'
foreign_status="$(curl --noproxy '*' --silent --insecure -o /dev/null -w '%{http_code}' --resolve stranger.localhost:443:127.0.0.1 https://stranger.localhost/)"
echo "Чужой Host: $foreign_status"
[[ "$foreign_status" == 421 ]]

echo '5. /admin без пароля'
admin_status="$("${main[@]}" -o /dev/null -w '%{http_code}' https://lab.localhost/admin)"
echo "/admin: $admin_status"
[[ "$admin_status" == 401 ]]

echo '6. Своя 404'
not_found="$("${main[@]}" -o /dev/null -w '%{http_code}' https://lab.localhost/missing-page)"
"${main[@]}" https://lab.localhost/missing-page | grep -q 'Такой страницы нет'
echo "/missing-page: $not_found, своя страница"
[[ "$not_found" == 404 ]]

echo '7. limit_req → 429'
flood=''
for _ in {1..30}; do
  code="$("${main[@]}" -o /dev/null -w '%{http_code}' https://lab.localhost/api/ping)"
  flood="$flood $code"
done
echo "Коды ответов:$flood"
[[ "$flood" == *429* ]]

echo '8. Останавливаем backend-a, API остаётся доступен'
docker compose stop backend-a
trap 'docker compose start backend-a >/dev/null' EXIT
sleep 2
for _ in 1 2 3; do
  code="$("${main[@]}" -o /dev/null -w '%{http_code}' https://lab.localhost/api/ping)"
  echo "При выключенном backend-a: $code"
  [[ "$code" == 200 ]]
  sleep 0.3
done

echo 'Все проверки лабы 1 прошли.'
