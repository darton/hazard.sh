Skrypt napisany dla programu Bind na dystrybucji Centos 7

#Instalacja
Zapisujemy skrypt pod dowolna nazwą np hazard.sh w katalogu np /opt/hazard (który okreslimy w skrypcie pod zmienną $scriptdir)

Do pliku /etc/named.conf dopisujemy linię:

include "/etc/named/named.conf.hazard-redirect";

Skrypt należy zainicjować:

/opt/hazard/hazard.sh init

Wtedy skrypt utworzy odpowiednie pliki konfiguracyjne dla programu bind i na własne potrzeby oraz pobierze wykaz domen ze strony www Ministerstwa Finansów.

Skrypt powinno się uruchamiać w cron np. co dwie godziny z parametrem "reload":
0 */2 * * * root bash /opt/hazard/hazard.sh reload

Skrypt pobierze wtedy nową listę domen i porówna z tą, którą już posiada. jeśli nie będzie różnic skrypt zakończy działanie.
W przeciwnym przypadku stworzy nowy plik z wykazem domen dla programu bind oraz wykona jego restart.

