#! /bin/bash
# Odczytaj sensory; wynik wyświetl na ekranie
#
BIN_TP=/home/tomek/bin
LOG_DIR=$HOME/logs/Digitemp
## Opcja -i powoduje inicjalizacje (zapis pliku .digitemprc)
##/usr/bin/digitemp_DS9097U -r 4500 -i -a -s/dev/ttyUSB0
/usr/bin/digitemp_DS9097U -c /home/tomek/.digitemprc -r 2200 -a -s/dev/ttyUSB0
#
