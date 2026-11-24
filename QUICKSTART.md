# Как включить Wi-Fi и Bluetooth на Tanix W2

Эта инструкция для **Tanix W2 с чипом W155S1 (CDW-47W3155)**, где уже стоит Debian 13 от devmfc с ядром `6.18.64-meson64`. Если на приставке ещё Android, сначала загрузите Debian с флешки по инструкции devmfc. В `boot.config` выберите `box=tanixw2`. [Образ Debian](https://github.com/devmfc/debian-on-amlogic/releases/tag/v6.18.64) · [Инструкция devmfc](https://github.com/devmfc/debian-on-amlogic#install).

Копируйте каждый блок целиком. Если появилась ошибка, остановитесь на этом шаге.

## 1. Откройте терминал приставки

Подключите приставку сетевым кабелем к роутеру и оставьте кабель до конца настройки. Если к приставке подключены экран и клавиатура, войдите в Debian как `root` и переходите к шагу 2.

Чтобы зайти с компьютера, откройте страницу роутера, найдите `tvbox` в списке подключённых устройств и запишите его IP-адрес. Вставьте один из блоков ниже и введите этот адрес, когда появится запрос.

**Windows, PowerShell**

```powershell
$tanixIp = Read-Host 'IP приставки'
ssh "root@$tanixIp"
```

**macOS или Linux, Терминал**

```sh
printf 'IP приставки: '
IFS= read -r tanix_ip && ssh "root@$tanix_ip"
```

При первом подключении SSH может спросить `Are you sure you want to continue connecting?`. Введите `yes`, затем пароль `root` от Debian на приставке. Символы пароля в терминале не отображаются.

## 2. Скачайте и установите драйверы

```sh
uname -r
```

Эта команда должна показать `6.18.64-meson64`. Если версия совпадает, вставьте блок ниже **в терминал приставки**. Он скачает комплект с GitHub, соберёт и установит драйверы, затем перезагрузит приставку. Сборка займёт несколько минут.

```sh
cd /root &&
apt-get update &&
apt-get install -y build-essential bc bison flex libssl-dev libelf-dev perl git curl ca-certificates python3 device-tree-compiler kmod iw network-manager wpasupplicant bluez &&
curl -fL https://raw.githubusercontent.com/Goteja/w1-aml/Main/tanix-w2-wireless-kit.tar.gz -o tanix-w2-wireless-kit.tar.gz &&
tar -xzf tanix-w2-wireless-kit.tar.gz &&
cd tanix-w2-wireless &&
./scripts/tanix-wireless check &&
curl -fLO https://github.com/devmfc/debian-on-amlogic/releases/download/v6.18.64/linux-headers-6.18.64-meson64_20261122_arm64.deb &&
apt-get install -y ./linux-headers-6.18.64-meson64_20261122_arm64.deb &&
JOBS=2 ./scripts/tanix-wireless build &&
./scripts/tanix-wireless verify &&
./scripts/tanix-wireless install &&
reboot
```

Когда SSH отключится при перезагрузке, дождитесь загрузки и повторите подключение из шага 1.

## 3. Подключите Wi-Fi

Вставьте блок. Появится список сетей. Введите имя своей сети Wi-Fi 2,4 ГГц, затем её пароль, когда приставка его попросит.

```sh
nmcli device wifi list ifname wlan0 &&
printf 'Имя Wi-Fi сети: ' &&
IFS= read -r wifi_ssid &&
nmcli --ask device wifi connect "$wifi_ssid" ifname wlan0 &&
ip -br -4 addr show wlan0
```

В последней строке должен появиться IP-адрес Wi-Fi рядом с `wlan0`.

## 4. Проверьте Bluetooth

```sh
bluetoothctl list
```

В списке должна появиться строка `Controller`. Если подключён USB-адаптер, таких строк будет две.
