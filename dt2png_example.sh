#! /bin/bash
# generuje wykresy dla 30 dniowej śr. ruchomej
#
BIN_TP=/home/tomek/bin
LOG_DIR=$HOME/Logs/Digitemp
WWW_DIR=/var/www/stats
PNGFILE="digitemp30.png"

while test $# -gt 0; do
  case "$1" in
    -30)  PNGFILE="digitemp30.png" ;;
    -45)  PNGFILE="digitemp`date +"%y_%m"`.png" ;;
  esac
  shift
done


cat  $LOG_DIR/{digitemp.log.1,digitemp.log} 2>/dev/null | $BIN_TP/dt2ht.pl -days=30 -frame=1 -chartname="$WWW_DIR/$PNGFILE" -width=990 -height=660 -ma=6 -xskip=72 > /dev/null

## end
