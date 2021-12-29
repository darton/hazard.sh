# hazard.sh

Skrypt pozwala wdrożyć ustawę hazardową w sieci ISP - to jest blokowanie domen w oparciu o rejestr http://hazard.mf.gov.pl/

Napisany został dla programu Bind, przetestowany na dystrybucji Linux Centos 7 oraz Debian 9,11

## Instalacja

Zapisujemy skrypt pod dowolna nazwą np hazard.sh w katalogu np /opt/hazard,  który określimy w skrypcie pod zmienną $scriptdir

```
curl -sS https://raw.githubusercontent.com/darton/hazard.sh/master/hazard.sh > /opt/hazard/hazard.sh
```

Na końcu pliku /etc/named.conf (Centos) lub /etc/bind/named.conf (Debian) dopisujemy linię:

include "/etc/named/hazard.conf"; (Centos)

include "/etc/bind/hazard.conf"; (Debian)

oraz w sekcji "options {}"  dodajemy

```
response-policy { zone "rpz"; };
```

## Uruchomienie
Skrypt należy zainicjować:

```
/opt/hazard/hazard.sh initialize
```

Wtedy skrypt utworzy odpowiednie pliki konfiguracyjne dla programu bind i na własne potrzeby oraz pobierze wykaz domen ze strony www Ministerstwa Finansów.

A następnie uruchomić poleceniem:

```
/opt/hazard/hazard.sh start
```

Które doda do cron zadanie uruchamiania cyklicznie skryptu z parametrem reload. Domyślnie skrypt bedzie uruchamiał to zadanie w cron co 8 godzin.

Aby usunąć zadanie z cron należy wydać polecenie:

```
/opt/hazard/hazard.sh stop
```

Aby ręcznie aktualizować plik strefy należy wykonać polecenie:

```
/opt/hazard/hazard.sh reload
```

Skrypt  pobierze wtedy nową listę domen i porówna z tą, którą już posiada. Jeśli nie będzie różnic, skrypt zakończy działanie.
W przeciwnym przypadku stworzy nowy plik z aktualnym wykazem domen dla programu bind oraz wykona jego restart.
