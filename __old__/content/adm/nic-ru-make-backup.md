---
title: "Создание бэкапа на nic.ru"
aliases:
  - /adm/nic-ru-make-backup.html
date: 2014-04-24T12:10:00Z
featured_image: /images/posts/backup-wide.jpg
tags:
- backup
- bash
- dump
- hosting
- linux
- mysql
- nic.ru
- ssh
- tar
---

Хреновенький, не очень удобный, но работающий скрипт для создания бэкапа всех сайтов + БД на хостинге, имя которому - nic.ru. Хосинг ущербный, и использовать что-то более и менее адекватное на нем - проблематично. Перейдем к телу:

<!--more-->

```bash
#!/bin/bash
## @project   Nic.ru backup script
## @copyright 2014 <https://github.com/tarampampam>
## @github    [https://github.com/tarampampam/nic.ru-bascup-script/](https://github.com/tarampampam/nic.ru-bascup-script/)
## @version   0.1.3
##
## @depends   mysqldump, tar

# *****************************************************************************
# ***                               Config                                   **
# *****************************************************************************

## nic.ru hosting id, look in 'cd ~ && pwd', ex.:
## \[%YourID%@web2006 ~\]$ cd ~ && pwd
## /home/%YourID%
HostingID=YourID
## Path to home dir, not need in change
PathToHomeDir=/home/$HostingID
## Path to directory, where backups will stored
PathToBackupsDir=$PathToHomeDir/backups
## Path to directory, where store DataBase dumps (add to backup file, and
##   remove from file system), not need in change
PathToDatabaseDumps=$PathToHomeDir/database-backup
##
## !!! IMPORTANT !!!
## Add your login, password and db_name to 'mysqldump' (line ~84)
## !!! IMPORTANT !!!
##
## Days count for backup files store, not need in change
StoreBackupsDaysCount=20
# Path to link file, set empty value ("") for disable this
linkfile=$PathToHomeDir/yoursite.com/docs/dir-with-password/backup-latest.tar.bz2

# *****************************************************************************
# ***                            END Config                                  **
# *****************************************************************************

## Found here - [http://goo.gl/4Oi5ZK](http://goo.gl/4Oi5ZK)
cRed='e\[1;31m'; cGreen='e\[0;32m'; cNone='e\[0m'; cYel='e\[1;33m';
cBlue='e\[1;34m'; cGray='e\[1;30m'; cWhite='e\[1;37m';

## Helpers Functions ##########################################################

logmessage() {
  ## $1 = (not required) '-n' flag for echo output
  ## $2 = message to output

  flag=''; outtext='';
  if \[ "$1" == "-n" \]; then
    flag="-n "; outtext=$2;
  else
    outtext=$1;
  fi

  echo -e $flag\[$(date +%H:%M:%S)\] "$outtext";
}

## Begin work #################################################################

# Create directory for backups (if not exists)
if \[ ! -d $PathToBackupsDir \]; then
  logmessage -n "Create $PathToBackupsDir.. ";
  mkdir -p $PathToBackupsDir;
  if \[ -d $PathToBackupsDir \]; then
    echo -e "${cGreen}Ok${cNone}";
  else
    echo -e "${cRed}Error${cNone}";
    exit 1;
  fi
fi

# Clean temp dumps $PathToDatabaseDumps + create it (ex: broken last run)
logmessage -n "Clean and prepare $PathToDatabaseDumps.. ";
rm -R -f $PathToDatabaseDumps;
mkdir -p $PathToDatabaseDumps;
if \[ -d $PathToBackupsDir \]; then
  echo -e "${cGreen}Ok${cNone}";
else
  echo -e "${cRed}Error${cNone}";
fi

logmessage -n "Backup DataBase(s) to $PathToDatabaseDumps.. "
mysqldump --force --opt --add-locks --user=UserName1 -pPassword1 --databases DatabaseName1 \> $PathToDatabaseDumps/DatabaseName1.sql
mysqldump --force --opt --add-locks --user=UserName2 -pPassword2 --databases DatabaseName2 \> $PathToDatabaseDumps/DatabaseName2.sql
# Write here all files to check exists
if \[ -f $PathToDatabaseDumps/DatabaseName1.sql \] && \[ -f $PathToDatabaseDumps/DatabaseName2.sql \]; then
  echo -e "${cGreen}Complete${cNone}";
else
  echo -e "${cRed}Error${cNone}";
fi


cd $PathToBackupsDir
thisBackupFileName=backup-$(date +%y-%m-%d--%H-%M)-$HostingID.tar.bz2

logmessage -n "Pack files to $PathToBackupsDir/${cYel}$thisBackupFileName${cNone}.. "
tar -cpPjf $PathToBackupsDir/$thisBackupFileName
    --exclude=$PathToBackupsDir*
    --exclude=$PathToHomeDir/dir1/\*
    --exclude=$PathToHomeDir/dir2/\*
    --exclude=$PathToHomeDir/tmp/*
    --exclude=*httpd.core
    --exclude=$linkfile
    $PathToHomeDir;
echo -e "${cGreen}Complete${cNone}";

# Make some clean
logmessage -n "Make some clean.. ";
rm -R -f $PathToDatabaseDumps;
echo -e "${cGreen}Complete${cNone}";

# Make link to latest PathToBackupsDir file
if \[ ! "linkfile" == "" \]; then
  logmessage -n "Make link $PathToBackupsDir/$thisBackupFileName ${cYel}<===>${cNone} $linkfile.. ";
  rm -f $linkfile;
  ln $PathToBackupsDir/$thisBackupFileName $linkfile;
  echo -e "${cGreen}Complete${cNone}";
fi

sleep 2s;

## Finish work ################################################################

logmessage -n "Deleting old backups from $PathToBackupsDir.. "
find $PathToBackupsDir -type f -mtime +$StoreBackupsDaysCount -exec rm '{}' ;
for FILE in $(find $PathToBackupsDir -mtime +$StoreBackupsDaysCount -type f); do
  logmessage "${cRed}Deliting${cNone} $FILE as Old";
  rm -f $FILE;
done
echo -e "${cGreen}Complete${cNone}";
```

И небольшие комментарии к скрипту:

- Всё, что тебе необходимо подправить под себя \- я подчеркнул
- Формат даты подсмотри [хоть тут](http://www.cyberciti.biz/faq/linux-unix-formatting-dates-for-display/)
- `PathToBackupsDir` \- это та папка, куда бэкапы будут складываться;
- Вызовы `mysqldump` \- создание дампов баз (по одному дампу за вызов);
- Те пути и типы файлов, которые необходимо **исключить** из бэкапа \- прописаны в строках, начинающихся со слова `--exclude=`

### Ссылки

- **[Скачать](https://raw.githubusercontent.com/tarampampam/scripts/master/nix/nic.ru-backup-script/make-backup.sh)**
- **[GitHub](https://github.com/tarampampam/scripts/tree/master/nix/nic.ru-backup-script)**
