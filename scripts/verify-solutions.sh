#!/usr/bin/env bash
# Проверка всех SQL-решений по 4 базам данных.
# Запуск из корня проекта: ./scripts/verify-solutions.sh
# Требуется: docker-compose up (PostgreSQL + миграции Flyway уже применены)

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

readonly PSQL_USER="${POSTGRES_USER:-mephi}"
readonly PSQL_PASS="${POSTGRES_PASSWORD:-mephi}"
readonly EXPECTED_DIR="$ROOT/scripts/expected"

PASS=0
FAIL=0
TOTAL=0

if [[ -t 1 ]]; then
  C_GREEN='\033[1;32m'
  C_RED='\033[1;31m'
  C_YELLOW='\033[1;33m'
  C_CYAN='\033[1;36m'
  C_BOLD='\033[1m'
  C_RESET='\033[0m'
else
  C_GREEN='' C_RED='' C_YELLOW='' C_CYAN='' C_BOLD='' C_RESET=''
fi

print_banner() {
  echo ""
  echo -e "${C_CYAN}╔══════════════════════════════════════════════════════════════════════╗${C_RESET}"
  echo -e "${C_CYAN}║${C_RESET}  ${C_BOLD}mephi_db — проверка решений SQL-задач${C_RESET}                              ${C_CYAN}║${C_RESET}"
  echo -e "${C_CYAN}╚══════════════════════════════════════════════════════════════════════╝${C_RESET}"
  echo ""
}

log_info()  { echo -e "${C_CYAN}[i]${C_RESET} $*"; }
log_ok()    { echo -e "${C_GREEN}[✓]${C_RESET} $*"; }
log_err()   { echo -e "${C_RED}[✗]${C_RESET} $*"; }
log_warn()  { echo -e "${C_YELLOW}[!]${C_RESET} $*"; }

docker_compose() {
  if command -v docker-compose >/dev/null 2>&1; then
    docker-compose "$@"
  elif docker compose version >/dev/null 2>&1; then
    docker compose "$@"
  else
    log_err "Не найден docker-compose / docker compose"
    exit 1
  fi
}

check_environment() {
  log_info "Проверка окружения..."

  if ! docker_compose ps --status running 2>/dev/null | grep -q postgres; then
    log_err "Контейнер PostgreSQL не запущен."
    echo "    Запустите стек: docker-compose up -d"
    echo "    (или: docker compose up -d)"
    exit 1
  fi

  if ! docker_compose exec -T postgres pg_isready -U "$PSQL_USER" >/dev/null 2>&1; then
    log_err "PostgreSQL не готов принимать подключения."
    exit 1
  fi

  for db in vehicle racing hotel employees; do
    if ! docker_compose exec -T postgres psql -U "$PSQL_USER" -d "$db" -tAc \
        "SELECT 1 FROM flyway_schema_history WHERE success = true LIMIT 1;" 2>/dev/null | grep -q 1; then
      log_err "База «${db}»: миграции Flyway не найдены."
      echo "    Выполните: docker-compose up"
      exit 1
    fi
  done

  log_ok "PostgreSQL запущен, 4 базы с миграциями на месте."
}

run_query_pretty() {
  local db=$1 sql_file=$2
  docker_compose exec -T postgres psql -U "$PSQL_USER" -d "$db" \
    -v ON_ERROR_STOP=1 -P pager=off -f - < "$sql_file" 2>&1 || true
}

run_query_tsv() {
  local db=$1 sql_file=$2
  docker_compose exec -T postgres psql -U "$PSQL_USER" -d "$db" \
    -v ON_ERROR_STOP=1 -t -A -F $'\t' -f - < "$sql_file" 2>/dev/null | sed '/^$/d'
}

# key|db|folder|task|title|description
TASKS=(
  "db1_vehicle_task01|vehicle|db1_vehicle|01|БД 1 — Задача 1|Спортивные мотоциклы: мощность > 150, цена < 20000, тип Sport"
  "db1_vehicle_task02|vehicle|db1_vehicle|02|БД 1 — Задача 2|Объединённая выборка автомобилей, мотоциклов и велосипедов по критериям"
  "db2_racing_task01|racing|db2_racing|01|БД 2 — Задача 1|Лучший автомобиль в каждом классе по средней позиции в гонках"
  "db2_racing_task02|racing|db2_racing|02|БД 2 — Задача 2|Автомобиль с наименьшей средней позицией среди всех"
  "db2_racing_task03|racing|db2_racing|03|БД 2 — Задача 3|Классы с наилучшей средней позицией — все автомобили этих классов"
  "db2_racing_task04|racing|db2_racing|04|БД 2 — Задача 4|Автомобили лучше среднего по классу (класс ≥ 2 машин)"
  "db2_racing_task05|racing|db2_racing|05|БД 2 — Задача 5|Автомобили с плохой средней позицией (> 3) в классах-лидерах"
  "db3_hotel_task01|hotel|db3_hotel|01|БД 3 — Задача 1|Клиенты с > 2 бронированиями в разных отелях"
  "db3_hotel_task02|hotel|db3_hotel|02|БД 3 — Задача 2|Клиенты: мульти-отель + траты > 500 USD"
  "db3_hotel_task03|hotel|db3_hotel|03|БД 3 — Задача 3|Предпочитаемый тип отеля по категории цен"
  "db4_employees_task01|employees|db4_employees|01|БД 4 — Задача 1|Иерархия подчинённых Ивана Иванова (RECURSIVE)"
  "db4_employees_task02|employees|db4_employees|02|БД 4 — Задача 2|Иерархия + задачи и прямые подчинённые"
  "db4_employees_task03|employees|db4_employees|03|БД 4 — Задача 3|Менеджеры с подчинёнными (RECURSIVE, все потомки)"
)

run_task() {
  local key=$1 db=$2 folder=$3 task=$4 title=$5 description=$6
  local sql_file="$ROOT/${folder}/solutions/task${task}.sql"
  local expected_file="$EXPECTED_DIR/${key}.tsv"
  local actual_file
  actual_file="$(mktemp)"

  TOTAL=$((TOTAL + 1))

  echo ""
  echo -e "${C_BOLD}────────────────────────────────────────────────────────────────────────${C_RESET}"
  echo -e "${C_BOLD}  ${title}${C_RESET}"
  echo -e "${C_BOLD}────────────────────────────────────────────────────────────────────────${C_RESET}"
  echo "  Условие:    ${description}"
  echo "  База:       ${db}"
  echo "  SQL-файл:   ${folder}/solutions/task${task}.sql"
  echo ""

  if [[ ! -f "$sql_file" ]]; then
    log_err "Файл решения не найден: ${sql_file}"
    FAIL=$((FAIL + 1))
    return
  fi

  if [[ ! -f "$expected_file" ]]; then
    log_err "Эталон не найден: ${expected_file}"
    FAIL=$((FAIL + 1))
    return
  fi

  echo "  ┌─ Результат запроса ─────────────────────────────────────────────────┐"
  echo ""
  if ! run_query_pretty "$db" "$sql_file"; then
    echo ""
    log_err "Ошибка при выполнении SQL."
    FAIL=$((FAIL + 1))
    rm -f "$actual_file"
    return
  fi
  echo ""
  echo "  └──────────────────────────────────────────────────────────────────────┘"
  echo ""

  if ! run_query_tsv "$db" "$sql_file" > "$actual_file"; then
    log_err "Не удалось получить результат для сравнения."
    FAIL=$((FAIL + 1))
    rm -f "$actual_file"
    return
  fi

  local exp_rows act_rows
  exp_rows=$(wc -l < "$expected_file" | tr -d ' ')
  act_rows=$(wc -l < "$actual_file" | tr -d ' ')

  echo "  Сравнение с эталоном: ${exp_rows} строк(и) ожидается, получено ${act_rows}."

  if diff -u "$expected_file" "$actual_file" > /dev/null 2>&1; then
    log_ok "Задача ${key}: результат совпадает с эталоном."
    PASS=$((PASS + 1))
  else
    log_err "Задача ${key}: результат НЕ совпадает с эталоном."
    echo ""
    echo "  ┌─ Отличия (ожидалось → получено) ─────────────────────────────────────┐"
    diff -u "$expected_file" "$actual_file" | sed 's/^/  │ /' || true
    echo "  └──────────────────────────────────────────────────────────────────────┘"
    FAIL=$((FAIL + 1))
  fi

  rm -f "$actual_file"
}

print_summary() {
  echo ""
  echo -e "${C_CYAN}╔══════════════════════════════════════════════════════════════════════╗${C_RESET}"
  echo -e "${C_CYAN}║${C_RESET}  ${C_BOLD}ИТОГ${C_RESET}                                                                  ${C_CYAN}║${C_RESET}"
  echo -e "${C_CYAN}╠══════════════════════════════════════════════════════════════════════╣${C_RESET}"
  printf "${C_CYAN}║${C_RESET}  Всего задач:     %-3s                                              ${C_CYAN}║${C_RESET}\n" "$TOTAL"
  printf "${C_CYAN}║${C_RESET}  Успешно:         ${C_GREEN}%-3s${C_RESET}                                              ${C_CYAN}║${C_RESET}\n" "$PASS"
  printf "${C_CYAN}║${C_RESET}  С ошибками:      %-3s                                              ${C_CYAN}║${C_RESET}\n" "$FAIL"
  echo -e "${C_CYAN}╚══════════════════════════════════════════════════════════════════════╝${C_RESET}"
  echo ""

  if [[ "$FAIL" -eq 0 ]]; then
    echo -e "${C_GREEN}${C_BOLD}  ✓ ВСЕ ОК: все ${PASS} решений выполнены корректно, данные и запросы в порядке.${C_RESET}"
    echo ""
    return 0
  fi

  echo -e "${C_RED}${C_BOLD}  ✗ Есть расхождения: исправьте запросы или перезапустите docker-compose up.${C_RESET}"
  echo ""
  return 1
}

main() {
  print_banner
  check_environment
  log_info "Запуск ${#TASKS[@]} SQL-решений..."
  echo ""

  for entry in "${TASKS[@]}"; do
    IFS='|' read -r key db folder task title description <<< "$entry"
    run_task "$key" "$db" "$folder" "$task" "$title" "$description"
  done

  print_summary
}

main "$@"
