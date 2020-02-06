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

scriptdir=/opt/hazard
urlHAZARDXML=https://hazard.mf.gov.pl/api/Register
HazardDomainFile=/opt/hazard/hazard.domains
HazardDomainZone=/var/named/hazard.redirect
HazardBindConf=/etc/named/named.conf.hazard-redirect

#Adres ip serwera Ministerstwa Finansów na którym jest winietka informacyjna
MFIPADDR=145.237.235.240

[[ -d $scriptdir ]] || mkdir $scriptdir

# Deklaracja funkcji

function make_conf_file {

    touch $HazardDomainFile
    touch $HazardDomainZone
    chown root.named $HazardDomainZone
    touch $HazardBindConf
    chown root.named $HazardBindConf
}

function make_zone_file {
echo'$TTL 3600
    @   IN  SOA     localhost. root.localhost. (
              2017070101  ;Serial
              3600        ;Refresh
              1800        ;Retry
              604800      ;Expire
              86400       ;Minimum TTL
              )
              NS      localhost.
              A       $MFIPADDR' > $HazardDomainZone
}

function make_bind_conf {
    yes | cp -f /dev/null $HazardBindConf
    while read domainname ; do
    echo "zone \"$domainname\" in { type master; file \"hazard.redirect\"; allow-update { none; }; }; ">> $HazardBindConf
    done < $HazardDomainFile
}

function get_rejestr_domen_gier_hazardowych {
    cd $scriptdir
    mv $HazardDomainFile $HazardDomainFile.old
    echo Pobieram dane ze strony  $urlHAZARDXML
    curl -s -G -L $urlHAZARDXML | awk -F"[<>]" '/AdresDomeny/ {print $3}' | sort | uniq > $HazardDomainFile
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
    
     'stop')
        stop
    ;;
    
     'start')
        start
    ;;
    
        *)
        echo -e "\nUsage: hazard.sh init|reload|stop|start"
    ;;

esac
