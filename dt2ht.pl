#!/usr/bin/perl 
# digitemp 2 HTML conversion
# (c) t.przechlewski luty 2011 ; wersja 0.1 [licencja GPL]
#
# Wykorzystanie:
# --------------
# perl dt2ht.pl [parametry]  > digitemp.html
#
# parametry:
#  -days=liczba    okre¶la liczbê wy¶wietlanych pe³nych dni w tabeli/na wykresie [domy¶lnie 14];
#  -chartname=nazwa-pliku    nazwa pliku, do którego generowany jest wykres [domy¶lnie digitemp.png];
#  -frame=liczba   je¿eli liczba=1, to drukuje d³ugie linie podzia³ki w polu wykresu [domy¶lnie drukuje krótkie];
#  -ma=okres       na wykresie bêdzie drukowana ¶rednia ruchoma o okresie równym _okres_;
#  -width=szeroko¶æ,-height=wysoko¶æ   szeroko¶æ/wysoko¶æ wykresu [domy¶lnie 820/500];
#  -xskip=n        drukuj co n-t± etykietê na osi X.
#
# Zak³adany jest nastêpuj±cy format LOGa generowanego przez digitemp [plik .digitemprc]:
#   LOG_FORMAT "%Y-%m-%d %H:%M:%S S# %s C: %.2C F: %.2F [%R]"
# co daje w rezultacie co¶ podobnego do wiersza poni¿ej:
#   2011-02-10 01:00:16 S# 5 C: 15.75 F: 60.35 [10173F0102080078]
#
# Uwaga: skrypt wymaga dopasowania do lokalnej instalacji [patrz sekcja `Parametry skryptu' poni¿ej]
# -----
#
use GD::Graph::lines;
use POSIX; # floor
use Getopt::Long;
#

my $max_days = 14; ## Liczba wy¶wietlanych obserwacji w tabeli/na wykresie
my $chart__name = "digitemp.png" ; ## nazwa pliku z obrazkiem
my $chart__name2 = "digitemp_r.png" ; ## nazwa pliku z obrazkiem dla wybranych szczegó³owych temperatur

my $chart_width = 820;
my $chart_height = 500 ;
my $long_ticks = 0 ;
my $xskip = 24 ;
my $mov_avg_pts = 0;

GetOptions( "days=i" => \$max_days, "chartname=s" => \$chart__name, "frame=i" => \$long_ticks,
 "ma=i" => \$mov_avg_pts, "width=i" => \$chart_width, "height=i" => \$chart_height, "xskip=i" => \$xskip, );

undef $/;

($sec,$min,$hour,$mday,$mon,$year,$wday, $yday,$isdst)=localtime(time);

## ### ### ### ### ## ### ## ## ## ## ## ## ##
## Parametry skryptu:

# ## Weranda jest dwa razy z uwagi na awarie: ## #
my %SensorsHex = (
 '105C1C990108005A' => '0', ## pokój#1
 '1029400102080084' => '1', ## kaloryfer#1
 '282B6E25030000F6' => '2', ## pokój#2 (ma³y)
 '10D3200102080028' => '3', ## kaloryfer#2
 '10E8EF98010800E6' => '4', ## pokój#3 (¶redni)
 '10173F0102080078' => '5', ## piwnica
 '28EA6D2503000010' => '6', ## kaloryfer#piwnica
 ##'10E8EF98010800E6' => '7', ##### weranda ma Hex identyczny jak pokój #3 ##### dzia³a³o przez przypadek
 '1065259901080056' => '7', ## ditto
 '1087130102080010' => '8', ## ogród
);

# ## Okre¶lamy numery sensorów: ## #
my %Sensors = (
  '0' => 'Pokój#1',
  '1' => 'Kaloryfer#1',
  '2' => 'Pokój#2',
  '3' => 'Kaloryfer#2',
  '4' => 'Pokój#3',
  '5' => 'Piwnica',
  '6' => 'Kaloryfer#P',
  '7' => 'Weranda',
  '8' => 'Zewnêtrzna',
);

### Zdjecia z ogrodu sa wariantowe lato/zima ### $mon+1 jest prawid³owym numerem miesiaca
## Ustaw warto¶æ zmiennej $D_Ogrod_Photo w zale¿nosci od numeru bie¿ m-ca:

my $SensorPicturesURI = 'http://www.flickr.com/photos/tprzechlewski';

if ( $mon < 11 && $mon > 1 ) { $D_Ogrod_Photo = "<a href='$SensorPicturesURI/4472712919/'>Zewnêtrzna</a>" ; } 
else { $D_Ogrod_Photo = "<a href='$SensorPicturesURI/5263366810/'>Zewnêtrzna</a>" ; }

## Napisy, które zostan± umieszczone w nag³ówku tabeli z wynikami temp.:
my %SensorsDsc = (
 '0' => "<a href='$SensorPicturesURI/4324798366/'>Pokój#1</a>",
 '1' => "<a href='$SensorPicturesURI/4324798968/'>Grzejnik#1</a>",
 '2' => "<a href='$SensorPicturesURI/5841775884/'>Pokój#2</a>",      ## --by³ 3 -- 31/10/2011 ##
 '3' => "<a href='$SensorPicturesURI/4324798968/'>Grzejnik#2</a>",
 '4' => "<a href='$SensorPicturesURI/5468313508/'>Pokój#3</a>",

 '5' => "<a href='$SensorPicturesURI/4545002993/'>Piwnica</a>",
 '6' => "<a href='$SensorPicturesURI/4545002993/'>Grzejnik#P</a>",

 '7' => "<a href='$SensorPicturesURI/4324064385/'>Weranda</a>",
 '8' => $D_Ogrod_Photo,
);


## HTML:
my $chartname30 = "digitemp30.png" ; ## nazwa pliku z obrazkiem dla danych 30-dniowych

## Wykres, kolory linii (je¿eli za ma³o do³o¿yæ):
my @Kolory = ( 'green', '#FF8C00', 'red', 'blue', '#5CB3FF', '#9208F3' );

## Kolor/styl linii oznaczajacej zero
my $BaselineKolor = 'black';
my $BaseLineStyle = 3; # linia kropkowana

## Styl linii wykreslaj±cej warto¶æ temperatury:
my $NormalLineStyle = 1;

## Styl wy¶wietlania tabeli (HTML):
my $tb_f_spec = 'border="1" cellpadding="2" bordercolor="#6CA0DB" bgcolor="WHITE" width="100%"';

## Nag³ówek HTMLa (style i metadane):
my $html_head_text = '<meta name="DC.creator" content="Tomasz Przechlewski" />
 <meta name="DC.rights" content="(c) Tomasz Przechlewski"/>
 <link rel="stylesheet" type="text/css" href="/style/tp-base.css" title="ES"/>
 <link rel="alternate stylesheet" type="text/css" href="/style/tp-bw.css" title="NS"/>
 <link rel="alternate stylesheet" type="text/css" href="/style/tp-big.css" title="BS"/>
 <script type="text/javascript" src="/script/tp.js"></script>
 <style type="text/css"> td { padding: 3px 9px 3px 9px ; text-align: right ; }
         table { font-family : sans-serif ; border: 1px dotted; }</style>
<title xml:lang="pl">Pomiar temperatury/stacja meteorologiczna</title>
<meta name="DC.title" content="Pomiar temperatury/stacja meteorologiczna" />';

## Tekst miêdzy tytu³em a tabel±:
my $html_after_body = "<h3>Temperatura: ostatnie $max_days dni, w st. C [<a href=\"./$chart__name\">wykres</a>][<a href=\"./$chart__name2\">wykres2</a>][<a href=\"./$chartname30\">wykres30</a>]</h3>\n
<p>Wspó³rzêdne geograficzne punktu pomiaru:\n"
 . "<a href='http://pinkaccordions.homelinux.org/staff/tp/Geo/show_point.html?lat=54.43966270&amp;lon=18.55015754'>54.43966270/18.55015754</a>.\n"
 . "Do rejestrowania wykorzystywany jest uk³ad <a href='http://www.flickr.com/photos/tprzechlewski/4306010587/'>FT232RL + DS2480B</a>,"
 . "czujniki DS18B20 oraz program <a href='http://www.digitemp.com/'>DigiTemp</a>.</p>\n";

## ### ### ### ### ## ### ## ## ## ## ## ## ##
## koniec parametryzacji
##

$mon += 1 ; $year += 1900;

my @tmp__ = keys %Sensors ;  $SensorTNo = $#tmp__ + 1;

## @LineStyles to array zawieraj±cy $#SensorTNo jedynek :
my @LineStyles = ((1) x $SensorTNo);

my $baza = <STDIN> ;

my %Max; ##
my %Min; ##

@baza = split /\n/, $baza;

my $current_date = '';
my $day_no = 0;
my @Daty ;
my $sensor_hex ;

### ### ### ### ### ### ### ### ### ### ### ### ###
### Czytanie pliku LOG
for $l (reverse  @baza)  {

  ## HexNumer sensora jest wewn±trz [ ... ]
  $l =~ /\[([0123456789ABCDEF]+)\]/; $sensor_hex = $1;
  ###print STDERR "==> $sensor_hex\n";

  ($date, $time, $sensor, $sensor_current_no, $celsius, $temp) =  split / /, $l;
  ($hr, $mn) =  split /:/, $time;

  ## `bezwzgledny' numer sensora (oparty na hex-numerze):
  $sensor_no = $SensorsHex{$sensor_hex};

  push (@Daty, $date);

  ## rejestracja zaczyna sie o kazdej pelnej godzine
  ## poniewaz czasami pobranie danych trwa dluzej niz 1 min dajemy zabezpiecznie:
  $mn = "00" ;

  push (@DatyCzasy, "$date/$hr:$mn");

  if ($date ne $current_date) { $day_no++; $current_date =  $date; }
  if ($day_no > $max_days) { last }

  $Temp{"$date $hr:$mn"}{"$sensor_no"} = $temp;

  ## inicjalizacja (redundantna) ale...
  $Max{$sensor_no} = -999;  $Min{$sensor_no} = 999; 

}

### ### ### ### ### ### ### ### ### ### ### ### ###
### Generowanie HTMLa (wszystkie sensory)
### [Wymaga dostosowania do konkretnej strony]
###
print '<?xml version="1.0" encoding="iso-8859-2" ?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN"
   "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head><meta http-equiv="content-type" content="text/html; charset=iso-8859-2" />';
print "\n<meta name=\"DC.date\" content=\"$year-$mon-${mday}T${hour}:${min}:${sec}CET\"/>\n";

print $html_head_text ;

print '</head><body xml:lang="pl">';

my $lst_day = $DatyCzasy[$#DatyCzasy];
my $fst_day = $DatyCzasy[0];

print $html_after_body;

print "<table class='tr.comment'>\n";
print "<tr class='main'><td>Data / Godzina</td>";
for $s (sort keys %Sensors ) { ## ### print STDERR "$s => $Sensors{$s}\n";
   print "<td>$SensorsDsc{$s}</td>"; }
print "</tr>\n";

## ##
## ## foreach $_ (sort keys %Sensors ) { print STDERR "$_ => $Sensors{$_} \n"; }

$current_date = '';
my $day_no = 0;

for $d (reverse sort keys %Temp ) {
  $d_txt = $d; 
  $d_txt =~ s/[ \t]+/\//g;
  $d_txt =~ s/^[0-9]+\-(.*)\/([0-9][0-9]?):[0-9][0-9]?$/$1:$2/; # usun rok i minuty 

  push(@TempDates, $d_txt); ## daty **

  ($date, $time) =  split / /, $d;

  ##print STDERR "$date $current_date $day_no\n";

  if ($date ne $current_date) { $day_no++; $current_date =  $date; }

  if ( ($day_no % 2)  == 0 ) {  $row_spec = 'class="odd-r"' }
  else { $row_spec = 'class="even-r"'  }

   ($year, $mon, $day) =  split /\-/, $date;
   print "<tr $row_spec><td>$mon-$day / $time</td>";

   my %previous_t ;
   ### s is sensor ###
   ###for $s (sort keys %{ $Temp{ $d }} ) {
   for $s (sort keys %Sensors ) {## wszystkie sensory (je¿eli jest b³±d bêdzie undef)

     ## mo¿e nie istnieæ jezeli jest problem z odczytem ##
     if ( exists ( $Temp{$d}{$s} ) ) {
        if ($Max{$s} < $Temp{$d}{$s}  ) { $Max{$s} = $Temp{$d}{$s}  }
        if ($Min{$s} > $Temp{$d}{$s}  ) { $Min{$s} = $Temp{$d}{$s}  }

        print "<td> $Temp{$d}{$s} </td>";

        ## hash of arrays (for printing picture): 

        $previous_t{$s}=$Temp{$d}{$s}; ## poprzedni wpis ** na wypadek b³êdu w odczycie **

        push(@{$STemp{$s}}, $Temp{$d}{$s});
     } else {
        ## wstaw pust± rubrykê do tabeli
        print "<td> x </td>";

        ## ponizsze jest na potrzeby wykresu (inaczej linie sa przestawione)
        push(@{$STemp{$s}}, $previous_t{$s} ); ##jezeli blad wstaw poprzedni zarejstrowany wpis
     }
   }

   print "</tr>\n";

}

## Druk warto¶ci min/max
print "<tr class='main'><td>Temp. minimalna </td>";
for $s (sort keys %Min ) { print "<td> $Min{$s} </td>"; }
print "</tr>\n";

print "<tr class='main'><td>Temp. maksymalna </td>";
for $s (sort keys %Max ) { print "<td> $Max{$s} </td>"; }
print "</tr>\n";


print "</table>\n";
print "<p>£±cznie: $day_no dni [<a href='./all-logs'>wszystkie logi w formacie txt</a>]";
print "[<a href='./'>wykresy miesiêczne</a>]</p>\n";
print "</body></html>\n";


### ### ### ### ### ### ### ### ### ### ### ### ###
### Generowanie rysunków (wybrane sensory)

## Dzia³amy na uchwytach (handle)
## http://docstore.mik.ua/orelly/perl3/prog/ch09_02.htm

@TempDates = reverse(@TempDates); ##

my @data = \@TempDates; ##
my @data_Pokoje = \@TempDates; ## 

for $s (sort keys %STemp ) {
  ## na potrzeby rysunku trzeba zrobiæ reverse:
  ## print STDERR ">>> $STemp{$s}\n";
  @{$STemp{$s}} = reverse @{$STemp{$s}};

  ## Pseudo-srednia ruchoma (pseudo po pozostawiamy bez zmian pierwsze/ostatnie obserwacje)
  if (  $mov_avg_pts > 0 ) {  $STemp{$s} = moving_avg ($STemp{$s}, $mov_avg_pts) ; } 

  ## print STDERR "<<< @{$STemp{$s}}\n";
  unless ($Sensors{$s} =~/Pokój#2|Kaloryfer#2|Kaloryfer#P/ ) { push (@data, $STemp{$s} ); }
  if ($Sensors{$s} =~ /Pokój/) { push (@data_Pokoje, $STemp{$s} );  } ## !! tylko pokoje !!
  ##print STDERR "==>$Sensors{$s}\n";
 }

## Legenda musi byæ posortowana
my @legend_All_Sensors = () ;   
my @legend_Pokoje=();

foreach (sort keys %Sensors)  { 
  ##print STDERR "=+=>$Sensors{$_}\n";
  unless ($Sensors{$_} =~ /Pokój#2|Kaloryfer#2|Kaloryfer#P/) { push (@legend_All_Sensors, $Sensors{$_} ) ; }
  if ($Sensors{$_} =~ /Pokój/) { push (@legend_Pokoje, $Sensors{$_}) };
} ;

## \@data = reference to data ;
draw_temperature_chart(\@data,  \@legend_All_Sensors, 55, -25, 16, $chart__name );

## dopasowaæ legendê:
draw_temperature_chart(\@data_Pokoje, \@legend_Pokoje, 35, 15, 10, $chart__name2 );

### ### ## ### ### ###

sub draw_temperature_chart {
  my $data_ref = shift ; ## wska¼nik do danych
  my $legend_ref = shift ; ## wska¼nik do legendy

  my $y_max_value = shift ;
  my $y_min_value = shift ;
  my $y_tick_number = shift ;

  my $chartname = shift;

  my @data = @$data_ref; ## dereferencing ref to local @data ; 
  my @legend_txt = @$legend_ref; ## ditto

  ## @sens = sort keys %STemp ; print STDERR "@TempDates\n"@sens\n@data\n";
  ## dodaæ liniê zera:
  for ($i=0; $i<=$#TempDates; $i++) { push (@Zeros, 0) }
  push (@data, \@Zeros );

  my $mygraph = GD::Graph::lines->new($chart_width,  $chart_height);

  #  If the option "x_tick_number" is set to a defined value, GD::Graph will attempt to
  #  treat the X data as numerical.
  #  If set to 'auto', GD::Graph will attempt to format the X axis in a nice way, 
  #  based on the actual X values. 
  #  If set to a number, that's the number of ticks you will get. [[but treated as numbers, tp.]]
  #  If set to undef, GD::Graph will treat X data as labels. Default: undef.
  #  [[Auto is of no use as well, tp.]
  #
  #  x_label_skip, y_label_skip
  #  Print every x_label_skipth number under the tick on the x axis, and every 
  #  y_label_skipth number next to the
  #  tick on the y axis.  Default: 1 for both.
  #

  ## skip some dates to avoid label overlapping on X-axis:
  ## my $x_factor = floor (($#Dates + 1) / 10 ) + 2;
  ## print "$#Dates observations. X-axis labels printed evey ${x_factor}th one!\n";

  push @LineStyles, $BaseLineStyle ;
  @Kolory = @Kolory[0..$SensorTNo-1]; push @Kolory, $BaselineKolor;
  ##print STDERR ">>@LineStyles\n"; print STDERR ">>@Kolory\n";
  my $chart_type = $mov_avg_pts> 0? " [¶r.ruchoma,n=$mov_avg_pts]" : "";

  $mygraph->set_text_clr('black');
  $mygraph->set(
    x_label     => 'Czas',
    y_label     => 'Temp [C]',
    title       => "Temperatura$chart_type: $lst_day--$fst_day",
    long_ticks  => $long_ticks,  ### 1 or 0
    #
    # Draw datasets in 'solid', 'dashed' and 'dotted-dashed' lines
    # Style poszczególnych linii: [ostatnia jest kropkowana]:
    line_types  => \@LineStyles,
    # Set the thickness of line
    line_width  => 2,
    # ** Kolory poszczególnych linii: ***
    dclrs  => \@Kolory,
    # Opcja x_tick_number  generuje b³êdy:
    # Illegal division by zero at /usr/share/perl5/GD/Graph/axestype.pm line 1289, <> chunk 1.
    #x_tick_number => 16,
    #x_tick_number => 'auto',
    ##x_tick_offset => 144,
    ## Drukuje co _$xskip_ etykietê:
    x_label_skip => $xskip,
    ##y_label_skip => 5,
    ## ## ##
    y_tick_number => $y_tick_number,
    y_max_value => $y_max_value,
    y_min_value => $y_min_value,
    ## ## ##
    transparent => 0, ## non-transparent
    bgclr => 'white',
    fgclr => 'black',
    borderclrs => 'black',
    boxclr => '#ede7e7',
    labelclr => 'black',
    #axislabelclr,
    legendclr => 'black',
  ) or warn $mygraph->error;

  $mygraph->set_legend_font(GD::gdMediumBoldFont);
  
  $mygraph->set_legend( @legend_txt ) ; 

  my $myimage = $mygraph->plot(\@data) or die $mygraph->error;

  ## for cgi script uncomment:
  ##print "Content-type: image/png\n\n";

  open ( IMG, ">$chartname") or die " *** Problems opening: $chartname ***" ;

  print IMG $myimage->png;

  close (IMG);

  return ;
}

## ## ## ## ## ## ###
# Policzenie sredniej ruchomej:

sub moving_avg {## ##
  my $sens_temp = shift;
  my $mov_avg_pts = shift;

  my $i; my $total ;

  my @sens_new_temp_array = @{$sens_temp};

  for ($i=0; $i < $mov_avg_pts; $i++) {  $total += ${$sens_temp}[$i] ; }

  # w oryginale by³o $i < $#{$sens_temp} ; ale to jest zle/czy poprawka jest OK to inna sprawa
  for ($i=$mov_avg_pts; $i <= $#{$sens_temp} + 1; $i++) {
    ##print STDERR $i, " ", "$total $mov_avg_pts", "\n";
    $sens_new_temp_array[$i] = $total / $mov_avg_pts ;
    $total += ${$sens_temp}[$i] - ${$sens_temp}[$i - $mov_avg_pts];
   }
    
  return \@sens_new_temp_array; ## zwróæ wska¼nik do listy z u¶redn. warto¶ciami 
}
## koniec ##
