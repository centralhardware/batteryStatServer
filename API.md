# Battery Health Tracker API Documentation

Base URL: `http://localhost:8080`

## Endpoints

### 1. Health Check

Проверка работоспособности сервера.

**Endpoint:** `GET /api/battery/healthcheck`

**Response:**

```json
{
  "status": "ok"
}
```

**Status Codes:**
- `200 OK` - Сервер работает нормально

**Example:**

```bash
curl http://localhost:8080/api/battery/healthcheck
```

---

### 2. Submit Battery Health Data

Отправка данных о здоровье батареи.

**Endpoint:** `POST /api/battery/health`

**Headers:**
- `Content-Type: application/json`

**Request Body:**

```json
{
  "deviceId": "ABC123...",     // Обязательно: уникальный ID устройства
  "cycleCount": 123,           // Обязательно: количество циклов зарядки
  "healthPercent": 94          // Обязательно: процент здоровья батареи (из системы)
}
```

**Field Descriptions:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `deviceId` | String | Yes | Уникальный идентификатор устройства (Hardware UUID) |
| `cycleCount` | Integer | Yes | Количество полных циклов зарядки батареи |
| `healthPercent` | Integer | Yes | Процент здоровья батареи (из System Information) |

**Response:**

```json
{
  "status": "success"
}
```

**Status Codes:**
- `201 Created` - Данные успешно сохранены
- `400 Bad Request` - Неверный формат данных
- `500 Internal Server Error` - Ошибка сервера

**Examples:**

```bash
curl -X POST http://localhost:8080/api/battery/health \
  -H "Content-Type: application/json" \
  -d '{
    "deviceId": "ABC123-DEF456-GHI789",
    "cycleCount": 123,
    "healthPercent": 94
  }'
```

#### Using jq for formatting:

```bash
echo '{
  "deviceId": "test-device",
  "cycleCount": 789,
  "healthPercent": 88
}' | curl -X POST http://localhost:8080/api/battery/health \
  -H "Content-Type: application/json" \
  -d @-
```

---

## Health Percentage

Процент здоровья батареи берется из System Information (system_profiler SPPowerDataType) и представляет официальное значение, рассчитанное macOS.

## Error Responses

### 400 Bad Request

```json
{
  "error": "Invalid request format",
  "message": "Missing required field: cycleCount"
}
```

### 500 Internal Server Error

```json
{
  "error": "Database error",
  "message": "Failed to save battery health data"
}
```

## Rate Limiting

В текущей версии rate limiting не реализован. Рекомендуется отправлять данные с интервалом не чаще чем раз в 5 минут.

## Authentication

В текущей версии аутентификация не требуется. Для production рекомендуется добавить API ключи или другой метод аутентификации.

## Data Retention

Данные хранятся в ClickHouse бессрочно. Для настройки автоматического удаления старых данных можно использовать TTL в ClickHouse:

```sql
ALTER TABLE battery_health MODIFY TTL date_time + INTERVAL 365 DAY;
```

Это удалит данные старше 1 года.

## Testing

Используйте предоставленный скрипт для тестирования API:

```bash
./scripts/test_api.sh
```

Или используйте curl для ручного тестирования:

```bash
# Health check
curl -v http://localhost:8080/api/battery/healthcheck

# Submit data
curl -v -X POST http://localhost:8080/api/battery/health \
  -H "Content-Type: application/json" \
  -d '{"deviceId":"test-device","cycleCount":100,"healthPercent":95}'
```
