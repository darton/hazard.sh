#!/bin/bash
#
# hazard.sh version 0.99
#
#  (C) Copyright 2017 Dariusz Kowalczyk
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

scriptdir=/opt/hazard
urlHAZARDXML=https://hazard.mf.gov.pl/api/Register
HazardDomainFile=/opt/hazard/hazard.domains
HazardDomainZone=/var/named/hazard.redirect
HazardBindConf=/etc/named/named.conf.hazard-redirect

#Adres ip serwera Ministerstwa Finansów na którym jest winietka informacyjna
MFIPADDR=145.237.235.240


# Deklaracja funkcji

function make_conf_file {

    touch $HazardDomainFile
    touch $HazardDomainZone
    chown root.named $HazardDomainZone
    touch $HazardBindConf
    chown root.named $HazardBindConf
}

function get_rejestr_domen_gier_hazardowych {
    cd $scriptdir
    mv $HazardDomainFile $HazardDomainFile.old
    echo Pobieram dane ze strony  $urlHAZARDXML
    curl -s -G -L $urlHAZARDXML | grep AdresDomeny | awk -F"[<>]" '{print $3}' | sort | uniq > $HazardDomainFile
}

function make_zone_file {
    echo '$TTL 3600' > $HazardDomainZone
    echo '@   IN  SOA     localhost. root.localhost. (' >> $HazardDomainZone
    echo '          2017070101  ;Serial' >> $HazardDomainZone
    echo '          3600        ;Refresh' >> $HazardDomainZone
    echo '          1800        ;Retry' >> $HazardDomainZone
    echo '          604800      ;Expire' >> $HazardDomainZone
    echo '          86400       ;Minimum TTL' >> $HazardDomainZone
    echo '          )' >> $HazardDomainZone
    echo '          NS      localhost.' >> $HazardDomainZone
    echo "          A       $MFIPADDR" >> $HazardDomainZone
}

function make_bind_conf {
    yes | cp -f /dev/null $HazardBindConf
    while read domainname ; do
    echo "zone \"$domainname\" in { type master; file \"hazard.redirect\"; allow-update { none; }; }; ">> $HazardBindConf
    done < $HazardDomainFile
}

function compare_config {
    diff -q $HazardDomainFile $HazardDomainFile.old > /tmp/hazard.diff
}

function init_script {
    echo "Tworzę pliki konfiguracyjne dla programu Bind"
    echo ""
    make_conf_file
    make_zone_file
    get_rejestr_domen_gier_hazardowych
    make_bind_conf
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

    stop ()
    {
         hazard_cron stop
    }

    start ()
    {
         hazard_cron start
    }

    reload ()
    {
        get_rejestr_domen_gier_hazardowych
        compare_config
    if [ -s "/tmp/hazard.diff" ]
    then
        echo Pliki sie róznią przełądowuję konfigurację
        make_bind_conf
        systemctl restart named.service
    else
        echo Nowa konfiguracja jest identyczna nic nie robię
    fi
    }


    init ()
    {
         init_script
    }

# Program główny

case "$1" in

    'init')
        init
    echo 'Dodaj do pliku /etc/named/conf linię: include "/etc/named/named.conf.hazard-redirect";'
    ;;

    'reload')
        reload
    ;;
        *)
        echo -e "\nUsage: hazard.sh init|reload|stop|start"
    ;;

esac
