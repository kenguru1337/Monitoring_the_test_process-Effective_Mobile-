#!/bin/bash
set -euo pipefail

LOG_FILE="/var/log/monitoring.log"
STATE_FILE="/var/run/test_monitor.pid"
PROCESS_NAME="test"
MONITOR_URL="https://test.com/monitoring/test/api"

timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

# Создаём файлы при отсутствии и задаём права
touch "$LOG_FILE" "$STATE_FILE"
chown root:root "$LOG_FILE" "$STATE_FILE"
chmod 644 "$LOG_FILE"
chmod 644 "$STATE_FILE"

# Используем flock для защиты от параллельных запусков
exec 200>"$STATE_FILE.lock"
flock -n 200 || exit 0

PID=$(pgrep -x "$PROCESS_NAME" || true)

if [[ -n "$PID" ]]; then
    # Проверка доступности сервера мониторинга
    if ! curl -fsS --max-time 5 "$MONITOR_URL" >/dev/null 2>&1; then
        echo "$(timestamp) - Ошибка: Сервер мониторинга недоступен" >> "$LOG_FILE"
    fi

    # Проверка на перезапуск процесса
    if [[ -s "$STATE_FILE" ]]; then
        LAST_PID=$(cat "$STATE_FILE")
        if [[ "$PID" != "$LAST_PID" ]]; then
            echo "$(timestamp) - Процесс '$PROCESS_NAME' был перезапущен (PID: $PID)" >> "$LOG_FILE"
        fi
    fi

    echo "$PID" > "$STATE_FILE"
else
    echo "$(timestamp) - Процесс '$PROCESS_NAME' не запущен" >> "$LOG_FILE"
fi
