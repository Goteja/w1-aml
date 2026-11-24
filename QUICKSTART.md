# Как включить Wi-Fi и Bluetooth на Tanix W2

Эта инструкция для **Tanix W2 с чипом W155S1 (CDW-47W3155)**, где уже стоит Debian 13 от devmfc с ядром `6.18.64-meson64`. Если на приставке ещё Android, сначала загрузите Debian с флешки по инструкции devmfc. В `boot.config` выберите `box=tanixw2`. [Образ Debian](https://github.com/devmfc/debian-on-amlogic/releases/tag/v6.18.64) · [Инструкция devmfc](https://github.com/devmfc/debian-on-amlogic#install).

Вводите команды по порядку. Если команда заканчивается ошибкой, остановитесь на этом шаге.

## 1. Скопируйте архив на приставку

Подключите приставку сетевым кабелем к роутеру. В списке подключённых устройств роутера найдите `tvbox` и посмотрите его IP-адрес. Сохраните `tanix-w2-wireless-kit.tar.gz` на компьютере и откройте терминал или PowerShell в папке с архивом. В обеих командах замените `192.168.1.50` на IP своей приставки.

```sh
scp tanix-w2-wireless-kit.tar.gz root@192.168.1.50:/root/
ssh root@192.168.1.50
```

Если появится вопрос `Are you sure you want to continue connecting?`, введите `yes`. Затем введите пароль от Debian на приставке. Символы пароля в терминале не отображаются. Дальше команды вводите уже в SSH.

## 2. Проверьте приставку и установите всё нужное

```sh
cd /root
tar -xzf tanix-w2-wireless-kit.tar.gz
cd tanix-w2-wireless
uname -r
```

Последняя команда должна показать `6.18.64-meson64`. Если версия другая, на этом остановитесь и загрузитесь с нужным ядром.

```sh
apt update
apt install build-essential bc bison flex libssl-dev libelf-dev perl git curl ca-certificates python3 device-tree-compiler kmod iw network-manager wpasupplicant bluez
./scripts/tanix-wireless check
```

Если `apt` спрашивает, продолжать ли установку, введите `y`. Проверка должна закончиться сообщением `Target verified`. Затем скачайте заголовки ядра и соберите драйверы. [Пакет заголовков в релизе devmfc](https://github.com/devmfc/debian-on-amlogic/releases/expanded_assets/v6.18.64).

```sh
curl -fLO https://github.com/devmfc/debian-on-amlogic/releases/download/v6.18.64/linux-headers-6.18.64-meson64_20261122_arm64.deb
apt install ./linux-headers-6.18.64-meson64_20261122_arm64.deb
JOBS=2 ./scripts/tanix-wireless build
./scripts/tanix-wireless verify
./scripts/tanix-wireless install
reboot
```

Сборка займёт несколько минут. После `reboot` SSH отключится. Дождитесь загрузки и снова выполните команду `ssh` из шага 1.

## 3. Подключите Wi-Fi

```sh
cd /root/tanix-w2-wireless
./scripts/tanix-wireless status
nmcli device wifi list ifname wlan0
```

Выберите из списка свою сеть 2,4 ГГц. Для обычной домашней сети с паролем WPA2 замените `ИМЯ_СЕТИ` на её имя, оставьте кавычки и введите команды. Пароль введите, когда его попросит `nmcli`.

```sh
nmcli connection add type wifi ifname wlan0 con-name tanix-wifi ssid 'ИМЯ_СЕТИ' 802-11-wireless.band bg wifi-sec.key-mgmt wpa-psk ipv4.route-metric 700 ipv6.route-metric 700
nmcli --ask connection up tanix-wifi ifname wlan0
ip -br -4 addr show wlan0
```

В последней строке должен появиться IP-адрес Wi-Fi. Если профиль `tanix-wifi` уже создавали, начните с команды `nmcli --ask connection up`.

## 4. Проверьте Bluetooth в Home Assistant

```sh
bluetoothctl list
```

В списке должен появиться контроллер. Если подключён USB-адаптер, контроллеров будет два. В выводе `./scripts/tanix-wireless status` встроенный контроллер виден по пути с `fe078000.serial`.

Откройте Home Assistant в браузере. Перейдите в **Настройки → Устройства и службы**. Если там уже есть карточка **Bluetooth**, откройте её. Если карточки нет, нажмите **Добавить интеграцию**, найдите **Bluetooth** и завершите настройку. Если Home Assistant в Docker не видит адаптер, проверьте подключение системной шины D-Bus к контейнеру. [Документация Home Assistant](https://www.home-assistant.io/integrations/bluetooth/#additional-details-for-container).
