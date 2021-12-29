# hazard.sh

Skrypt pozwala wdrożyć ustawę hazardową w sieci ISP - to jest blokowanie domen w oparciu o rejestr http://hazard.mf.gov.pl/

Napisany został dla programu Bind, przetestowany na dystrybucji Linux Centos 7 oraz Debian 9,11, Ubuntu 20.04 LTS

## Instalacja

Jako administrator:

tworzymy katalog 

```
mkdir /opt/hazard
```

Pobieramy skrypt ze strony

```
curl -sS https://raw.githubusercontent.com/darton/hazard.sh/master/hazard.sh | tee /opt/hazard/hazard.sh
```

Ustawiamy prawo do uruchamiania skryptu

```
chmod u+x /opt/hazard/hazard.sh
```

Na końcu pliku /etc/named.conf (Centos) lub /etc/bind/named.conf (Debian,Ubuntu) dopisujemy linię:

dla Centos:

```
include "/etc/named/hazard.conf"; 
```

dla Debian

```
include "/etc/bind/hazard.conf"; 
```

oraz w sekcji "options {}"  dodajemy

```
response-policy { zone "rpz"; };
```

Dla Ubuntu 20.04 LTS ustawienia sekcji options znajdują się w osobnym pliku named.conf.options 


## Uruchomienie
Skrypt należy zainicjować:

```
/opt/hazard/hazard.sh initialize
```

Wtedy skrypt utworzy odpowiednie pliki konfiguracyjne dla programu bind i na własne potrzeby oraz pobierze wykaz domen ze strony www Ministerstwa Finansów.
Skrypt nie zmienia niczego w plikach których sam nie tworzy. 

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


## Deinstalacja

Usuwamy lub komentujemy na końcu pliku /etc/named.conf (Centos) lub /etc/bind/named.conf (Debian,Ubuntu) dopisujemy linię:

dla Centos:

```
//include "/etc/named/hazard.conf"; 
```

dla Debian

```
//include "/etc/bind/hazard.conf"; 
```

oraz w sekcji "options {}" usuwamy lub komentujemy linię

```
//response-policy { zone "rpz"; };
```

Dla Ubuntu 20.04 LTS ustawienia sekcji options znajdują się w osobnym pliku named.conf.options 

Wykonujemy komendę:

```
/opt/hazard/hazard.sh stop
```


