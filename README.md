# Monitoring_the_test_process-Effective_Mobile-

Выполненное тестовое задание на позицию DevOps-инженера в компанию Effective Mobile

## Задание

Написать скрипт на bash для мониторинга процесса test в среде linux.\
Скрипт должен отвечать следующим требованиям:
1. Запускаться при запуске системы (предпочтительно написать юнит systemd в дополнение к скрипту)
2. Отрабатывать каждую минуту
3. Если процесс запущен, то стучаться (по `https`) на <https://test.com/monitoring/test/api>
4. Если процесс был перезапущен, писать в лог `/var/log/monitoring.log` (если процесс не запущен, то ничего не делать)
5. Если сервер мониторинга не доступен, так же писать в лог.

## Реализация
Этот проект реализует мониторинг процесса test в Linux (Ubuntu) с помощью bash-скрипта, запускаемого через `systemd timer`.\
Решение полностью соответствует требованиям ТЗ.

### Что делает скрипт
1. Каждую минуту запускается `systemd timer`.
2. Скрипт проверяет, запущен ли процесс `test`.
3. Если процесс работает:
* проверяет доступность сервера мониторинга <https://test.com/monitoring/test/api>;
* фиксирует перезапуск процесса (по изменению `PID`);
* сохраняет актуальный `PID`.
4. Если процесс не запущен → пишет в лог об этом.
5. Все события пишутся в `/var/log/monitoring.log`.
6. Лог-файл ротируется при достижении 50MB, хранится до 70 архивов `(.gz)`.

### Состав проекта
* `/usr/local/bin/test_monitor.sh` — основной bash-скрипт мониторинга.
* `/etc/systemd/system/test_monitor.service` — unit-файл для запуска скрипта.
* `/etc/systemd/system/test_monitor.timer` — таймер для запуска сервиса раз в минуту.
* `/etc/logrotate.d/test_monitor` — конфиг ротации логов.

### Установка
1. Переместить скрипт в `/usr/local/bin/` и сделать его исполняемым:
```console
sudo mv test_monitor.sh /usr/local/bin/test_monitor.sh
sudo chmod +x /usr/local/bin/test_monitor.sh
```
2. Переместить systemd unit и timer:
```console
sudo mv test_monitor.service /etc/systemd/system/
sudo mv test_monitor.timer /etc/systemd/system/
```
3. Активировать таймер:
```console
sudo systemctl daemon-reload
sudo systemctl enable --now test_monitor.timer
```
4. Переместить конфиг logrotate:
```console
sudo mv test_monitor /etc/logrotate.d/test_monitor
```
### Запуск и проверка работоспособности:

1. Ручной запуск скрипта с проверкой логов
```console
sudo /usr/local/bin/test_monitor.sh
cat /var/log/monitoring.log
```
В логе должна появиться запись: либо «Процесс test не запущен», либо информация о PID/перезапуске.

2. Проверка активности таймера
```console
systemctl list-timers | grep test_monitor
```
Вывод должен содержать строчку с `test_monitor.timer` и временем следующего запуска.
Посмотреть логи выполнения юнита:
```console
journalctl -u test_monitor.service -f
```
Там будут отображаться запуски сервиса каждую минуту.

3. Проверка ротации логов

Имитация ротации:
```console
sudo logrotate -d /etc/logrotate.d/test_monitor
```
(`-d` = dry-run, покажет что сделает logrotate, но без выполнения).

Запуск ротации принудительно (флаг `-f`):
```console
sudo logrotate -f /etc/logrotate.d/test_monitor
```
4. Проверка поведения скрипта

   1) Процесс test отсутствует
