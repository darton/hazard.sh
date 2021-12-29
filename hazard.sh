#!/bin/bash

#
# hazard.sh version 1.0
#
#  Author : Dariusz Kowalczyk
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License Version 2 as
#  published by the Free Software Foundation.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.

PATH=/sbin:/usr/sbin/:/bin:/usr/sbin:$PATH

OSRelease=$(awk -F\= '/^ID=/ {print $2}' /etc/os-release)

scriptdir=/opt/hazard
HazardDomainFile=/opt/hazard/hazard.domains

#URL serwera www Ministerstwa Finansów na którym jest plik z domenami
urlHAZARDXML=https://hazard.mf.gov.pl/api/Register

#Adres IP serwera Ministerstwa Finansów na którym jest winietka informacyjna
MFIPADDR=145.237.235.240

if [ $OSRelease = "debian" ] || [ $OSRelease = "ubuntu" ]; then
    HazardDomainZone=/etc/bind/hazard_rpz.db
    HazardZoneFile=/etc/bind/hazard.conf
fi

if [ $OSRelease = "\"centos\"" ]; then
    HazardDomainZone=/var/named/hazard_rpz.db
    HazardZoneFile=/etc/named/hazard.conf
fi

[[ -d $scriptdir ]] || mkdir $scriptdir



# Deklaracja funkcji

function make_conf_file {
    touch $HazardZoneFile
    touch $HazardDomainZone
    touch $HazardDomainFile
    touch $HazardDomainFile.old
    chmod 640 $HazardDomainZone
    chmod 640 $HazardZoneFile

    if [ $OSRelease = "\"centos\"" ]; then
        chown root.named $HazardZoneFile
        chown root.named $HazardDomainZone
    fi
    if [ $OSRelease = "debian" ] || [ $OSRelease = "ubuntu" ]; then
        chown root.bind $HazardZoneFile
        chown root.bind $HazardDomainZone
    fi
    echo 'zone "rpz" { type master; file "hazard_rpz.db"; };' > $HazardZoneFile
}


function make_zone_file {
    Serial=$(date '+%s')
    yes | cp -f /dev/null $HazardDomainZone
echo "\$TTL 2H
@   IN  SOA localhost. root.localhost. (
              $Serial   ;Serial
              604800    ;Refresh
              86400     ;Retry
              2419200   ;Expire
              604800 )  ;Minimum TTL
@   IN  NS  localhost.
@   IN  A   $MFIPADDR" > $HazardDomainZone

    while read domainname ; do
    echo "$domainname CNAME rpz." >> $HazardDomainZone
    done < $HazardDomainFile
}


function get_rejestr_domen_gier_hazardowych {
    cd $scriptdir
    mv $HazardDomainFile $HazardDomainFile.old
    echo "Pobieram dane ze strony  $urlHAZARDXML"
    curl -s -G -L $urlHAZARDXML | awk -F"[<>]" '/AdresDomeny/ {print $3}' | sort -u > $HazardDomainFile
}


function compare_config {
    diff -q $HazardDomainFile $HazardDomainFile.old > /tmp/hazard.diff
}


function initialize {
    echo
    echo "Tworzę pliki konfiguracyjne dla programu BIND"
    echo
    make_conf_file
    get_rejestr_domen_gier_hazardowych
    make_zone_file

    if [ $OSRelease = "\"debian\"" ]; then
        echo 'Aby zainstalować wykonaj czynności:'
        echo ' Dodaj na końcu pliku /etc/bind/named.conf:'
        echo '  include "/etc/bind/hazard.conf";'
        echo ' Dodaj do pliku /etc/bind/named.conf w sekcji Options:'
        echo '  response-policy { zone "rpz"; };'
    fi

    if [ $OSRelease = "\"centos\"" ]; then
        echo 'Aby zainstalować wykonaj czynności:'
        echo ' Dodaj na końcu pliku /etc/named.conf:'
        echo '  include "/etc/named/hazard.conf";'
        echo ' Dodaj do pliku /etc/named.conf w sekcji Options:'
        echo '  response-policy { zone "rpz"; };'
    fi
}


function hazard_cron {
    if [ "$1" = "start" ]
    then
echo '# Run the fw.sh cron jobs
SHELL=/bin/bash
PATH=/sbin:/bin:/usr/sbin:/usr/bin
MAILTO=""
* */8 * * * root /opt/hazard/hazard.sh reload 2>&1
' > /etc/cron.d/hazard
    fi

    if [ "$1" = "stop" ]
    then
        rm /etc/cron.d/hazard
    fi
}


function stop {
         hazard_cron stop
}


function start {
         hazard_cron start
}


function reload {
        get_rejestr_domen_gier_hazardowych
        compare_config
    if [ -s "/tmp/hazard.diff" ]; then
        echo "Pliki sie róznią przełądowuję konfigurację"
        make_zone_file
        if [ $OSRelease = "\"centos\"" ]; then
            systemctl restart named.service
        fi
        if [ $OSRelease = "debian" ] || [ $OSRelease = "ubuntu" ]; then
            systemctl restart bind9.service
        fi
    else
        echo "Nowa konfiguracja jest identyczna nic nie robię"
    fi
}

# Program główny
case "$1" in

    'initialize')
        initialize
    ;;

    'reload')
        reload
    ;;

     'stop')
        stop
    ;;

     'start')
        start
    ;;

        *)
        echo -e "\nUsage: hazard.sh initialize|reload|start|stop\n"
        echo -e " hazard.sh initialize - tworzy pliki konfiguracyjne, pobiera plik z domenami oraz wyświetla czynności konieczne do zakończenia procesu instalacji"
        echo -e " hazard.sh reload - pobiera plik z domenami ze strony MF, tworzy plik strefy RPZ oraz restartuje program Bind"
        echo -e " hazard.sh start - dodaje do Cron zadanie cykliczne wykonywania skryptu hazard.sh z opcją reload"
        echo -e " hazard.sh stop - usuwa z Cron zadanie cyklicznego wykonywania skryptu hazard.sh"
    ;;

esac
