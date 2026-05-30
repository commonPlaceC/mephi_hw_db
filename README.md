# mephi_db

[Сессионное задание] Итоговый проект. База данных
4 Базы данных:
* транспортные средства
* автомобильные гонки
* бронирование отелей
* структура организации

## Структура проекта

```
mephi_db/
├── docker-compose.yml          # PostgreSQL + Flyway
├── docker/
│   ├── init-databases.sql      # создание 4 БД при старте
│   └── migrate-all.sh          # проведение миграции во все БД
├── db1_vehicle/                # БД 1 — транспорт
│   ├── migrations/V1__init.sql # схема и тестовые данные
│   ├── solutions/task01.sql
│   └── solutions/task02.sql
├── db2_racing/                 # БД 2 — гонки
├── db3_hotel/                  # БД 3 — отели
├── db4_employees/              # БД 4 — сотрудники
└── scripts/
    ├── verify-solutions.sh     # проверка всех решений
    └── expected/               # эталонные ответы для скрипта
```

В `migrations/` — то, что применяет Flyway.</br>В `solutions/` — запросы к задачам, НЕ запускаются автоматически

## Требования

- Docker и `docker-compose` (или `docker compose`)

## Запуск базы данных

Выполнить из корня проекта:

```bash
docker-compose up -d
```

Будут подняты контейнер PostgreSQL, созданы четыре базы и применены миграции Flyway

Параметры подключения:

| Параметр     | Значение    |
|--------------|-------------|
| Хост         | `localhost` |
| Порт         | `5432`      |
| Пользователь | `mephi`     |
| Пароль       | `mephi`     |

Остановка:

```bash
docker-compose down
```

Полный сброс данных (пересоздать БД с нуля):

```bash
docker-compose down -v
docker-compose up -d
```

## Проверка решений

Автоматическая проверка всех 13 задач (вывод результата + сравнение с эталоном):

```bash
chmod +x scripts/verify-solutions.sh
./scripts/verify-solutions.sh
```

При успехе в конце: **«ВСЕ ОК: все 13 решений выполнены корректно»**.

## Ручной запуск одного решения

Пример для базы `vehicle` и задачи `task01`:

```bash
docker-compose exec -T postgres psql -U mephi -d vehicle -f - < db1_vehicle/solutions/task01.sql
```

Для других задач заменить название БД и номер задачи
