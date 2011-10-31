#!/usr/bin/perl
use CGI qw(:standard);

## który sensor odczytać?:
my $sensor2read = param('sensor');

# Odczyt temperatury przez dt_try.sh z formatowaniem `w locie' do HTML

$SENSORS_CNF = "/home/tomek/.digitemp_sensor_names.rc";
$DT_BIN = "/usr/bin/digitemp_DS9097U -c /home/tomek/.digitemprc -r 2200 -a -s/dev/ttyUSB0" ;
$DT_BIN_ONE = "/usr/bin/digitemp_DS9097U -c /home/tomek/.digitemprc -r 2200 -t $sensor2read -s/dev/ttyUSB0" ;

open SENSORS, $SENSORS_CNF || die "Cannot open ";

while (<SENSORS>) { chomp($_); 
my ($sensor_no, $sensor_dsc, $sensor_hex) = split /[ \t]+/, $_ ; $Sensors{$sensor_hex} = $sensor_dsc ;  }

## each line has the following syntax
## 2011-01-01 10:11:54 S# 0 C: 20.00 F: 68.00 [105C1C990108005A]
if ($sensor2read) { @temps = `$DT_BIN_ONE` ; }
else { @temps = `$DT_BIN`; }

my ($sec,$min,$hour,$mday,$mon,$year,$wday, $yday,$isdst)=localtime(time); $mon += 1 ; $year += 1900;

## header
print "Content-type: text/html; charset=iso-8859-2\n\n";

print '<?xml version="1.0" encoding="iso-8859-2" ?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head><meta http-equiv="content-type" content="text/html; charset=iso-8859-2" />
 <meta name="DC.creator" content="Tomasz Przechlewski" />';

print "\n<meta name=\"DC.date\" content=\"$year-$mon-${mday}T${hour}:${min}:${sec}CET\"/>\n";

print '<meta name="DC.rights" content="(c) Tomasz Przechlewski"/>
 <link rel="stylesheet" type="text/css" href="/style/tp-base.css" title="ES"/>
 <link rel="alternate stylesheet" type="text/css" href="/style/tp-bw.css" title="NS"/>
 <link rel="alternate stylesheet" type="text/css" href="/style/tp-big.css" title="BS"/>
 <script type="text/javascript" src="/script/tp.js"></script>
 <style type="text/css"> td { padding: 3px 18px 3px 18px ; text-align: right ; }
         table { font-family : sans-serif ; border: 1px dotted; }</style>
<title xml:lang="pl">Pomiar temperatury/stacja meteorologiczna</title>
<meta name="DC.title" content="Pomiar temperatury/stacja meteorologiczna" />
</head><body xml:lang="pl">';

print "<table><tr><td>Czas</td><td>Miejsce</td><td>Temperatura C</td></tr>";

foreach $line (@temps) {
   ## *** Cf syntax of the DT log file: ***
   if ($line =~ /(\d\d:\d\d:\d\d) S# (\d+) C: ([-+]?\d+\.\d+).*\[([\dA-F]+)\]/) {
        print "<tr><td> $1 </td><td>$Sensors{$4}</td><td>$3</td></tr>" ;   } }

print "</table>";
print "<p><a href='/stats/digitemp.html'><img longdesc='[[back.png' src='./icons/back.png' alt='Powrót'/>Powrót</a></p>";
print "</body></html>\n";

##
