---
title: Дружим Kali Linux с VMware
date: 2015-08-13T07:17:03+00:00
aliases:
  - /etc/kali-linux-and-vmware.html
featured_image: /images/posts/kali-linux-wide.jpg
tags:
  - kali linux
  - linux
  - vmware
---

Для комфортной работы в Kali linux запущенной в VMware Workstation потребуется выполнить несколько простых манипуляций:

<!--more-->

- Установка VMware tools:

```bash
# В окне VMware Workstation нажимаем "VM -> Install Vmware Tools"
$ mkdir ~/vmware && cd ~/vmware
$ cp /media/cdrom/* ./
$ apt-get install gcc make linux-headers-$(uname -r)
$ tar -xvf VMwareTools-*.tar.gz vmware-tools-distrib/
$ ./vmware-tools-distrib/vmware-install.pl
# На все запросы нажимаем Enter
$ service gdm3 restart
```

- Отключаем запрос логина/пароля при входе в иксы:

```bash
$ nano /etc/gdm3/daemon.conf
# Раскомментируем строки "AutomaticLoginEnable = true" и "AutomaticLogin = root"
```

- Отключаем блокировку экрана и отключение его при бездействии:

  - Нажимаем "Show Applications": ![screenshot](https://habrastorage.org/files/783/78a/acc/78378aacca724c8ebe273a6be9753b0f)
  - В поле поиска вводим "Settings": ![screenshot](https://habrastorage.org/files/682/a9b/d53/682a9bd530f84067abbbd349c63509dd)
  - Заходим в управление питанием ("Power"): ![screenshot](https://habrastorage.org/files/d57/5ec/145/d575ec14555f4b6eb5702ea78c4bdf34)
  - Ставим "Blank screen" в "Never": ![screenshot](https://habrastorage.org/files/c10/c9f/b9a/c10c9fb9a7c94fc6af20022ec006fb3b)

- Добавляем нормальную поддержку VPN:

```bash
$ aptitude -r install network-manager-openvpn-gnome network-manager-pptp network-manager-pptp-gnome network-manager-strongswan network-manager-vpnc network-manager-vpnc-gnome
```

Теперь пользоваться будет чуть-чуть удобнее :)
