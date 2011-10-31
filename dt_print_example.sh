#! /bin/bash
# Sformatuj loga programu Digitemp (za pomocą dt2ht.pl) bez odczytu sensorów
#
BIN_TP=/home/tomek/bin
LOG_DIR=$HOME/Logs/Digitemp
WWW_DIR=/var/www/stats
###
cd $LOG_DIR && cat {digitemp.log.1,digitemp.log} 2>/dev/null | \
	$BIN_TP/dt2ht.pl -width=990 -height=660 -frame=1 > $LOG_DIR/digitemp.html && \
	cp digitemp.html digitemp.png digitemp_r.png $WWW_DIR
