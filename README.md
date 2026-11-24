# Wi-Fi и Bluetooth W155S1 на Tanix W2 с Debian

Это воспроизводимая настройка встроенного модуля **CDTECH CDW-47W3155 на Amlogic W155S1**. Она проверена на **Tanix W2 (S905W2)** с Debian 13 из проекта devmfc и ядром **6.18.64-meson64, arm64**. Службы поднимают Wi-Fi и Bluetooth после загрузки, а Home Assistant получает их через NetworkManager и BlueZ. Модули рассчитаны на эту версию ядра. Под названием Tanix W2 продаются разные ревизии, поэтому перед установкой проверьте маркировку радио.

## Из чего собрано решение

| Источник | Что использовано |
| --- | --- |
| [devmfc/debian-on-amlogic, v6.18.64](https://github.com/devmfc/debian-on-amlogic/releases/tag/v6.18.64) | Linux, заголовки для сборки модулей и базовый DTB `meson-s4-tanixw2.dtb`. |
| [Паспорт CDTECH CDW-47W3155](https://fccid.io/m/b9402acc8a628633d2fc1d39c7b01f2c64e596c45a3cbf726fb57ad49e888139.pdf) | Модель чипа, Wi-Fi по SDIO 3.0, Bluetooth по UART/PCM, опорная частота 32,768 кГц и назначение выводов. |
| [Рецепт CoreELEC 22](https://github.com/CoreELEC/CoreELEC/blob/coreelec-22/projects/Amlogic-ce/packages/linux-drivers/amlogic/w1-aml/package.mk) и [w1-aml на fc5417f](https://github.com/CoreELEC/w1-aml/tree/fc5417f19706f85bccb125c1f951c787cf9362f5) | Основа Wi-Fi, модули `aml_sdio` и `vlsicomm`, таблица SDIO ID и заводские файлы радиокалибровки. На этой плате определился ID `8888:8888` и код калибровки `0631`. |
| [Порт Goteja, b8836e1](https://github.com/Goteja/w1-aml/tree/b8836e19feba8b90be05ebe9ecc473a15a97907c) | Справочник по старым правкам cfg80211 и операциям питания, GPIO и IRQ из BSP Amlogic. Основа сборки осталась на свежей ревизии CoreELEC. |
| [Moxnatiy/tvbox-wifi-fix](https://github.com/Moxnatiy/tvbox-wifi-fix) | Измерения проблемы с PWM_E на другой Tanix W2 с W155S1. Его [референсный Android DTS](https://github.com/Moxnatiy/tvbox-wifi-fix/blob/master/dtb/stock_s905w2_2g.dts) помог найти UART_A и его пины. Тактирование и UART проверены на этой плате. |
| [thanhnhu/aml_bt на eba38ec](https://github.com/thanhnhu/aml_bt/tree/eba38ecbcf0e8ce33e8b424d92c07938293e44c2) | Основа Bluetooth: `sdio_bt`, UART-загрузчик, прошивка и радиоконфигурация W155S1. Патчи связывают Bluetooth с нашим `aml_sdio` и требуют явно указать встроенный UART. |

## Почему модули не работали

1. **SDIO видел контроллер, но не видел карту.** `CMD5` на 400 кГц завершался тайм-аутом. Дополнительные 100 мс после снятия сброса ничего не изменили. Linux поднимал вход PWM_E до **1,476 ГГц**. При ограничении входа PWM до **24 МГц** и удержании ссылки на опорный тактовый сигнал **32,768 кГц** карта отвечала и регистрировала семь функций SDIO. Это сработало и без дополнительной задержки. Питанием и GPIO продолжает управлять штатный `mmc-pwrseq-simple`.
2. **Драйвер CoreELEC требовал адаптации к Linux 6.18.** Патчи в [patches/](patches/) исправляют Kbuild, cfg80211, таймеры и конфликты имён. Для этой конфигурации включены прерывания по SDIO без вызовов платформенного ядра Amlogic. При повторной сборке из списка исходников нужно исключать `*.mod.c`, иначе `vlsicomm` повторно экспортирует символы `aml_sdio` и ядро отклоняет модуль.
3. **Обнаружение карты не гарантировало загрузку Wi-Fi-прошивки.** При первой попытке на некоторых загрузках возникала ошибка записи ICCM. Служба ждёт привязки семи SDIO-функций и пробует загрузить `vlsicomm` до трёх раз. На проверочной загрузке восстановилась со второй попытки.
4. **Bluetooth нужен и SDIO, и UART.** Через SDIO включается Bluetooth-часть чипа. Прошивка и HCI идут по UART_A `fe078000`, которого не было в активном DTB Debian. Временный overlay добавляет порт в памяти. Служба выбирает его по физическому пути и сохраняет Bluetooth-адрес. Встроенный контроллер и USB Realtek видны в BlueZ одновременно.
5. **Сетевые службы дублировали настройки.** NetworkManager и systemd-networkd выдавали `wlan0` два адреса по DHCP. Теперь Wi-Fi управляет NetworkManager. Для `p2p0` управление отключено, а старый отдельный `wpa_supplicant@wlan0` с отсутствующим конфигом маскируется при установке, если обнаружена битая ссылка. Общая служба supplicant остаётся доступна NetworkManager.

## Сборка на приставке

Подключите Ethernet и сохраните доступ по SSH. Убедитесь, что приставка загрузилась на нужном ядре с DTB для `box=tanixw2`. Установите **заголовки именно 6.18.64-meson64** из [релиза devmfc](https://github.com/devmfc/debian-on-amlogic/releases/tag/v6.18.64). Стандартные заголовки Debian другого ядра для этой сборки не подходят.

Установите инструменты из Debian. Если вы уже вошли как root, запускайте команды без `sudo`.

```sh
sudo apt install build-essential bc bison flex libssl-dev libelf-dev perl \
  git curl ca-certificates python3 device-tree-compiler kmod iw \
  network-manager wpasupplicant bluez
```

Запустите из корня распакованного комплекта. Сборка создаёт локальный комплект и не устанавливает модули или службы.

```sh
./scripts/tanix-wireless check
./scripts/tanix-wireless build
./scripts/tanix-wireless verify
```

Утилита сверяет архитектуру, версию ядра, идентификатор платы и ссылки тактирования в DTB. Она скачивает исходники по зафиксированным коммитам, накладывает оба набора патчей, собирает модули и проверяет их метаданные. Обычный результат — каталог `tanix-wireless-build/` с модулями, загрузчиком, радиофайлами, `SOURCES` и `SHA256SUMS`. Для другого каталога передайте его вторым аргументом в `build` и `install`. Для приставки с малым объёмом ОЗУ можно указать `JOBS=2` перед командой сборки.

## Установка и подключение

Устанавливайте только комплект, собранный вами из изученных исходников. Скрипт проверяет контрольные суммы, сохраняет копии заменяемых файлов в `/var/backups/tanix-wireless.*`, устанавливает модули и включает службы. Он не меняет загрузочный DTB, не перезагружает приставку и не настраивает учётные данные сети. Будут использоваться обычные службы NetworkManager и BlueZ.

```sh
sudo ./scripts/tanix-wireless install
sudo reboot
```

После перезагрузки проверьте, что появился `wlan0`, и выберите свою сеть. Пример проверенного режима 2,4 ГГц для WPA-Personal. При активации `nmcli` запросит пароль интерактивно.

```sh
./scripts/tanix-wireless status
nmcli device wifi list ifname wlan0

sudo nmcli connection add type wifi ifname wlan0 con-name tanix-wifi ssid 'ВАШ_SSID' \
  802-11-wireless.band bg wifi-sec.key-mgmt wpa-psk \
  ipv4.method auto ipv4.route-metric 700 ipv6.method auto ipv6.route-metric 700
sudo nmcli --ask connection up tanix-wifi ifname wlan0
```

Если профиль уже существует, активируйте его вместо создания второго. Метрика 700 оставляет Wi-Fi резервным, если метрика Ethernet ниже. Для других типов защиты используйте подходящий профиль NetworkManager. Ethernet стоит оставить подключённым до проверки связи по Wi-Fi.

После перезагрузки обе службы должны быть активны. В sysfs встроенный Bluetooth определяется по пути через `fe078000.serial`, внешний — по пути через USB. Индексы `hci0` и `hci1` могут меняться.

```sh
./scripts/tanix-wireless status
journalctl -b -u tanix-wifi.service -u tanix-bluetooth.service
ip -br -4 addr show wlan0
ping -I wlan0 -c 3 1.1.1.1
```

Для Home Assistant Supervised проверьте `ha network info` и откройте `http://<адрес-wlan0>:8123/` с другого устройства. Если список сетевых интерфейсов в Supervisor устарел, выполните `ha network reload`. Для Bluetooth контейнеру нужен доступ к системной шине D-Bus хоста, где работает BlueZ. Проверка этого проекта подтвердила доступ к двум контроллерам из контейнера и BLE-сканирование через встроенный адаптер одновременно с трафиком Wi-Fi.

## База радиочастот и откат

Если в журнале ядра есть `regulatory.db is malformed or signature is missing/invalid`, проверьте, какой ключ загружает ядро. В проверенной сборке devmfc доверенным оказался `wens`, которым подписана upstream-альтернатива Debian. Если на вашей системе есть такая же пара файлов и доверенный ключ, проверьте подпись и выберите её. Страну вручную эта настройка не меняет.

```sh
journalctl -k -b | grep -Ei 'wens:|regulatory\.db'
openssl cms -verify -noverify -binary -inform DER \
  -in /lib/firmware/regulatory.db.p7s-upstream \
  -content /lib/firmware/regulatory.db-upstream -out /dev/null
sudo update-alternatives --set regulatory.db /lib/firmware/regulatory.db-upstream
```

Выбор вступит в силу после перезагрузки; вернуть выбор пакета можно командой `sudo update-alternatives --auto regulatory.db`.

Отключение автозапуска: `sudo systemctl disable tanix-bluetooth.service tanix-wifi.service`, затем перезагрузка. Не выгружайте вручную общий `aml_sdio` на работающей системе. Для полного отката используйте каталог резервной копии, напечатанный установщиком. В `created-paths` перечислены добавленные файлы, в `units-before.txt` — прежние состояния служб, а заменённые файлы лежат в копии исходного пути внутри каталога. Удалите добавленные файлы, верните заменённые и снимите маску с `wpa_supplicant@wlan0.service` только если её создал установщик и её не было раньше. Затем выполните `sudo depmod -a` и `sudo systemctl daemon-reload`. При переходе на новое ядро сначала проверьте DTB, затем пересоберите модули под его заголовки.
