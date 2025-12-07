# Battery Health Tracker Server

REST API сервер для отслеживания состояния здоровья батареи MacBook с сохранением данных в ClickHouse.

## Документация

- [README.md](README.md) - Основная документация (этот файл)
- [API.md](API.md) - Документация API
- [sql/queries.sql](sql/queries.sql) - Полезные SQL запросы для ClickHouse

## Возможности

- Отслеживание ключевых метрик здоровья батареи:
  - Уникальный ID устройства (Device ID)
  - Количество циклов зарядки (Cycle Count)
  - Процент здоровья батареи (Health Percent)
  - Дата производства (опционально)
- Поддержка множества устройств (различие по Device ID)
- Автоматическая миграция БД через Flyway
- REST API для приема данных (Ktor)
- Скрипт для автоматической отправки данных с macOS (совместим с bash 3.2)
- Сборка Docker образов через Jib

## Требования

- Java 24+
- ClickHouse
- macOS (для скрипта сбора данных)

## Структура проекта

```
batteryStatServer/
├── src/main/kotlin/me/centralhardware/
│   ├── Application.kt              # Точка входа приложения
│   ├── model/
│   │   └── BatteryStatus.kt        # Модели данных
│   ├── repository/
│   │   └── BatteryRepository.kt    # Работа с ClickHouse
│   └── routes/
│       └── BatteryRoutes.kt        # API endpoints
├── scripts/
│   └── report_battery_health.sh    # Скрипт для macOS
└── build.gradle.kts
```

## Настройка

### 1. Настройка ClickHouse

Установите ClickHouse (если еще не установлен):

```bash
brew install clickhouse
brew services start clickhouse
```

Таблица создается автоматически при первом запуске сервера.

### 2. Настройка переменных окружения

```bash
# URL подключения к ClickHouse (включая учетные данные)
# ВАЖНО: используйте протокол jdbc:clickhouse:// (НЕ jdbc:ch:http://)
export CLICKHOUSE_URL="jdbc:clickhouse://localhost:8123/default?user=default&password="

# Порт сервера (по умолчанию 8080)
export PORT=8080
```

### 3. Сборка и запуск сервера

Запуск напрямую:

```bash
./gradlew run
```

Сборка Docker образа через Jib:

```bash
./gradlew jibDockerBuild
```

Или публикация в registry:

```bash
./gradlew jib
```

## API Endpoints

### POST /api/battery/health

Отправка данных о здоровье батареи.

**Request Body:**

```json
{
  "deviceId": "ABC123-DEF456-GHI789",
  "cycleCount": 123,
  "healthPercent": 94,
  "manufactureDate": "2022-01-15"
}
```

**Response:**

```json
{
  "status": "success"
}
```

### GET /api/battery/healthcheck

Проверка работоспособности сервера.

**Response:**

```json
{
  "status": "ok"
}
```

## Настройка автоматической отправки данных (macOS)

### 1. Настройка скрипта

```bash
# Установите URL вашего сервера
export BATTERY_SERVER_URL="http://localhost:8080"
```

### 2. Тестирование скрипта

```bash
./scripts/report_battery_health.sh
```

### 3. Настройка автоматического запуска через cron

Откройте crontab:

```bash
crontab -e
```

Добавьте строку для запуска каждый час:

```cron
0 * * * * export BATTERY_SERVER_URL="http://localhost:8080" && /path/to/batteryStatServer/scripts/report_battery_health.sh >> /tmp/battery_health.log 2>&1
```

Или каждые 30 минут:

```cron
*/30 * * * * export BATTERY_SERVER_URL="http://localhost:8080" && /path/to/batteryStatServer/scripts/report_battery_health.sh >> /tmp/battery_health.log 2>&1
```

### 4. Альтернатива: использование launchd (рекомендуется для macOS)

Создайте файл `~/Library/LaunchAgents/com.centralhardware.battery-health.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.centralhardware.battery-health</string>
    <key>ProgramArguments</key>
    <array>
        <string>/path/to/batteryStatServer/scripts/report_battery_health.sh</string>
    </array>
    <key>EnvironmentVariables</key>
    <dict>
        <key>BATTERY_SERVER_URL</key>
        <string>http://localhost:8080</string>
    </dict>
    <key>StartInterval</key>
    <integer>3600</integer>
    <key>RunAtLoad</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/tmp/battery_health.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/battery_health_error.log</string>
</dict>
</plist>
```

Загрузите задачу:

```bash
launchctl load ~/Library/LaunchAgents/com.centralhardware.battery-health.plist
```

Запустите немедленно:

```bash
launchctl start com.centralhardware.battery-health
```

## Просмотр данных в ClickHouse

Подключитесь к ClickHouse:

```bash
clickhouse-client
```

Примеры запросов:

```sql
-- Последние записи
SELECT * FROM battery_health ORDER BY date_time DESC LIMIT 10;

-- Динамика здоровья батареи
SELECT
    date_time,
    cycle_count,
    health_percent
FROM battery_health
ORDER BY date_time DESC
LIMIT 30;

-- Средние показатели за последнюю неделю
SELECT
    toDate(date_time) as date,
    avg(cycle_count) as avg_cycles,
    avg(health_percent) as avg_health_percent
FROM battery_health
WHERE date_time >= now() - INTERVAL 7 DAY
GROUP BY date
ORDER BY date;
```

## Схема таблицы ClickHouse

```sql
CREATE TABLE battery_health (
    date_time DateTime,
    device_id String,
    cycle_count UInt32,
    health_percent UInt8,
    manufacture_date Nullable(String)
) ENGINE = MergeTree()
ORDER BY (device_id, date_time);
```

## Логирование

Логи приложения выводятся в консоль. Для записи в файл:

```bash
./gradlew run > application.log 2>&1
```

Логи скрипта:
- При использовании cron: `/tmp/battery_health.log`
- При использовании launchd: `/tmp/battery_health.log` и `/tmp/battery_health_error.log`

## Troubleshooting

### Скрипт не может отправить данные

1. Проверьте, что сервер запущен:
   ```bash
   curl http://localhost:8080/api/battery/healthcheck
   ```

2. Проверьте права на выполнение скрипта:
   ```bash
   chmod +x scripts/report_battery_health.sh
   ```

3. Запустите скрипт вручную для отладки:
   ```bash
   bash -x scripts/report_battery_health.sh
   ```

### Ошибки подключения к ClickHouse

1. Проверьте, что ClickHouse запущен:
   ```bash
   brew services list | grep clickhouse
   ```

2. Проверьте подключение:
   ```bash
   clickhouse-client --query "SELECT 1"
   ```

3. Проверьте переменную окружения CLICKHOUSE_URL

## Технологии

- **Kotlin** - язык программирования
- **Ktor** - веб-фреймворк
- **ClickHouse** - база данных
- **Flyway** - миграции БД
- **kotliquery** - SQL query DSL
- **Jib** - сборка Docker образов

## License

MIT
