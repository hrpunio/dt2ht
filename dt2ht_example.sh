#! /bin/bash
#
# Uruchom dt2ht.pl, zamień log programu Digitemp na HTML/wykres PNG
#
LOG_DIR=$HOME/Logs/Digitemp
DT_BIN=/usr/bin/digitemp_DS9097U

$DT_BIN -c/home/tomek/.digitemprc -l$LOG_DIR/digitemp.log -r 2200 -a -s /dev/ttyUSB0

# Jako by-product jest generowany digitemp.png
# Log programu digitemp podlega rotacji w taki sposób, że 
# zawartość plików digitemp.log oraz digitemp.log.1 wystarczy do utworzenia pliku HTML/wykresu PNG
#
cd $LOG_DIR && cat {digitemp.log.1,digitemp.log} 2>/dev/null | dt2ht.pl -width=990 -height=660 -frame=1 > $LOG_DIR/digitemp.html

