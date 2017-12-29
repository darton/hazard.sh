Skrypt napisany dla programu Bind na dystrybucji Centos 7

Zapisujemy skrypt pod dowolna nazwą np hazard.sh w katalogu np /opt/hazard,  który określimy w skrypcie pod zmienną $scriptdir)

Do pliku /etc/named.conf dopisujemy linię:

include "/etc/named/named.conf.hazard-redirect";

Skrypt należy zainicjować:

/opt/hazard/hazard.sh init

Wtedy skrypt utworzy odpowiednie pliki konfiguracyjne dla programu bind i na własne potrzeby oraz pobierze wykaz domen ze strony www Ministerstwa Finansów.

A następnie uruchomić poleceniem:

/opt/hazard/hazard.sh start

Które doda do cron zadanie uruchamiania cyklicznie skryptu z parametrem reload. Domyślnie zrobi to co 8 godzin.

Skrypt  pobierze wtedy nową listę domen i porówna z tą, którą już posiada. Jeśli nie będzie różnic, skrypt zakończy działanie.
W przeciwnym przypadku stworzy nowy plik z aktualnym wykazem domen dla programu bind oraz wykona jego restart.

Aby usunąć zadanie z cron należy wydać polecenie:

/opt/hazard/hazard.sh stop

