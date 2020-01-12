Skrypt pozwala wdrożyć ustawę hazardową z 15.12.2016 to jest blokowanie domen w sieci ISP według rejestru blokowanych domen sporządzanaego przez MF od dnia 01.07.2017.


Napisany został dla programu Bind, przetestowany na dystrybucji Linux Centos 7

Instalacja

Zapisujemy skrypt pod dowolna nazwą np hazard.sh w katalogu np /opt/hazard,  który określimy w skrypcie pod zmienną $scriptdir

curl -sS https://raw.githubusercontent.com/darton/hazard.sh/master/hazard.sh > /opt/hazard/hazard.sh

Do pliku /etc/named.conf dopisujemy linię:

include "/etc/named/named.conf.hazard-redirect";

Skrypt należy zainicjować:

/opt/hazard/hazard.sh init

Wtedy skrypt utworzy odpowiednie pliki konfiguracyjne dla programu bind i na własne potrzeby oraz pobierze wykaz domen ze strony www Ministerstwa Finansów.

A następnie uruchomić poleceniem:

/opt/hazard/hazard.sh start

Które doda do cron zadanie uruchamiania cyklicznie skryptu z parametrem reload. Domyślnie skrypt bedzie uruchamiał to zadanie w cron co 8 godzin.

Skrypt  pobierze wtedy nową listę domen i porówna z tą, którą już posiada. Jeśli nie będzie różnic, skrypt zakończy działanie.
W przeciwnym przypadku stworzy nowy plik z aktualnym wykazem domen dla programu bind oraz wykona jego restart.

Aby usunąć zadanie z cron należy wydać polecenie:

/opt/hazard/hazard.sh stop

