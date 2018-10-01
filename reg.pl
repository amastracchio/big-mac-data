#!usr/bin/perl




use strict;
use warnings;
use Data::Dumper;
use Statistics::LineFit;
use CGI; # not cgi but for use correct tags
use GD::Graph;
use List::Util qw(min max);
use Chart::Gnuplot;


# For make graph only
my %slopes; 
my %intercepts;

my $lineFit = Statistics::LineFit->new();

my @basecurrencies = ('USD', 'EUR', 'GBP', 'JPY', 'CNY');

# reg_countries chardcodeados?
my @reg_countries = ('ARG', 'AUS', 'BRA', 'GBR', 'CAN', 'CHL', 'CHN', 'CZE', 'DNK', 'EGY', 'EUZ', 'HKG', 'HUN', 'IDN', 'ISR', 'JPN', 'MYS', 'MEX', 'NZL', 'NOR', 'PER', 'PHL', 'POL', 'RUS', 'SAU', 'SGP', 'ZAF', 'KOR', 'SWE', 'CHE', 'TWN', 'THA', 'TUR', 'USA', 'COL', 'PAK', 'IND', 'AUT', 'BEL', 'NLD', 'FIN', 'FRA', 'DEU', 'IRL', 'ITA', 'PRT', 'ESP', 'GRC', 'EST');


       

# OJO BASE CURRENCIAES HAY QUE TOMAR EL PRECIO AJUSTADO??


my %paisgdp;
my %base_currencies;
my %base_currencies_adj;


my $q = CGI->new;

# Solo para mostrar en html
my $tmp_file_currencies = "/tmp/currencies.tmp";;
open (FILEGDP,"/root/big-mac-data/big-mac-data/source-data/big-mac-source-data.csv") or die($!);
open (HTML,">/root/3p/ht/htdocs/big-mac-index.html");
open (TMP,">$tmp_file_currencies");
print TMP "<table border=1 summary=\"The table show  the currency tables copyng from source data\"><tr><th>date</th><th>currency_code</th><th>dollar_price</th></tr>\n";
print HTML "<HTML>";

# primera linea la evitamos
<FILEGDP>;


print HTML $q->start_html( -title=>"Calculate big max indec from source and currencies data<",
	                                -bgcolor=>"#ffffff");

print HTML "<h1>Source data</h1>\n";
print HTML "<strong>dollar_ex</strong> = price of the dollar in local currency. Precio de 1 dolar en moneda local<p>\n";
print HTML "<strong>gdp</strong> = In dollars can be informed or not. Puede no estar informado<p>\n";
print HTML "<strong>dollar_price</strong> = Price of big mac in dollars (local_price/dollar_ex). Calculated.<p>\n";

while( <FILEGDP>){
	# name,iso_a3,currency_code,local_price,dollar_ex,GDP_dollar,date
	my @campos =  split(',');

	my %gdp_dollarppais;
	my $iso_a3 = $campos[1];
	my $currency_code = $campos[2];
	my $local_price = $campos[3];  # cuando cuesta la big mac en moneda local
	my $dollar_ex = $campos[4];    # precio de la moneda respecot moneda local
	my $gdp = $campos[5];
	my $date = $campos[6];

	my $dollar_price;
	chomp($date);

	if ($dollar_ex) {

		$dollar_price = $local_price /$dollar_ex;
		$dollar_price = sprintf("%.6f",$dollar_price);
	}

	if ($gdp) {
		$paisgdp{$date}{$iso_a3}{gdp} = $gdp;

		# Calculamos el precio de la big mac en en dolares
		$paisgdp{$date}{$iso_a3}{dollar_price} = $dollar_price;

		print $iso_a3 ."->"."dollar_price =$dollar_price\n";
	}

	$paisgdp{$date}{$iso_a3}{currency_code} = $currency_code;
	$paisgdp{$date}{$iso_a3}{local_price} = $local_price;
	$paisgdp{$date}{$iso_a3}{dollar_ex} = $dollar_ex;

	if ($currency_code ~~ @basecurrencies) {

		$base_currencies{$date}{$currency_code} = $dollar_price;
		print TMP "<tr><td>$date</td><td>$currency_code</td><td>$dollar_price</td></tr>\n";
	}
	
}

close FILEGDP;
print HTML "<h1>Currencies table:</h1>\n";
print HTML "<p>The currencies table is calculated (copied) from the source data below. Is the dollar price of big mac for each currencie. Not magic here.</b>";

print TMP "</table>\n";
close TMP;

my $all;
{
	open (TMP, "<$tmp_file_currencies");
	local $/ = undef;
	$all = <TMP>;	
	close TMP;
}

# Dump de las tablas de currencies bases
print HTML $all;




foreach  my $fecha (keys %paisgdp){

#	if ($fecha eq "2018-07-01"){

		my @xvalues;
	        my @yvalues;
	        my @isos_a3;

	        print "Precio dollar x pais / base_currencies\n";
		foreach my $iso_a3 (keys %{ $paisgdp{$fecha} }){
				
				print $fecha." ".$iso_a3 ."\t";
#				print $paisgdp{$fecha}{$iso_a3}{gdp} ."\t";
#				print $paisgdp{$fecha}{$iso_a3}{dollar_price} ." ";

				
				my $index;
				# raw index
				# Calculating the index is as simple as dividing the local price by the price in the base currency. 

				foreach my $cur (@basecurrencies) {


					if (defined $base_currencies{$fecha}{$cur}) {


						# indice crudo raw
						$index = $paisgdp{$fecha}{$iso_a3}{dollar_price} /$base_currencies{$fecha}{$cur} -1 ;
						$index = sprintf("%.3f",$index);
						# print   " ARI ($cur) index raw= $index ";

						# guardamos el indice x currencie en hash
						my $indexkey = $cur ."_raw";
						$paisgdp{$fecha}{$iso_a3}{$indexkey}  = $index ;
					}
				}


				#the use of 1.0 in the includes allows
				##for the computation of a y intercept
				#

				# Cargamos lo array agrupados por fecha
				if ( grep( /^$iso_a3$/, @reg_countries ) ) {

				     if ((defined $paisgdp{$fecha}{$iso_a3}{gdp}) && (defined $paisgdp{$fecha}{$iso_a3}{dollar_price})){

					# solo para poder grabar los valores
					push(@isos_a3, $iso_a3);

					push(@xvalues, $paisgdp{$fecha}{$iso_a3}{gdp});
					push(@yvalues, $paisgdp{$fecha}{$iso_a3}{dollar_price});
				     }

				}
				#
				print "\n";
			# print HTML "<tr><td>$fecha</td><td>$iso_a3</td><td>".$paisgdp{$fecha}{$iso_a3}{currency_code}."</td><td>".$paisgdp{$fecha}{$iso_a3}{local_price}."</td><td>".$paisgdp{$fecha}{$iso_a3}{dollar_ex}."</td><td>".$paisgdp{$fecha}{$iso_a3}{dollar_price}."</td><td>".$paisgdp{$fecha}{$iso_a3}{gdp}."</th></tr>\n";


		}

		# Para esta fecha alimentamos la funcion lineal regrecion


		next unless ( @xvalues &&  @yvalues);

		print "xvalues = ";
		print @xvalues;
		print "yvalues = ";
		print @yvalues;


		$lineFit->setData (\@xvalues, \@yvalues) or die "Invalid data";
		my ($intercept, $slope) = $lineFit->coefficients();
		defined $intercept or die "Can't fit line if x values are all equal";
		print "f(x) = $slope * x + $intercept\n";

		# Lo guardamos para graficar nada mas..
		$slopes{$fecha}{slope} = $slope;
		$intercepts{$fecha}{intercept} = $intercept;

	        
		my @predictedYs = $lineFit->predictedYs();
		my @residuals   = $lineFit->residuals();
		for ( my $i = 0 ; $i <= $#xvalues ; $i++ ) {
			    printf "X: %2s Y: %4s Y pred: %-16s Residual: %s\n", $xvalues[$i],
		          $yvalues[$i], $predictedYs[$i], $residuals[$i];

			  # dollar adjusted price
			  $paisgdp{$fecha}{$isos_a3[$i]}{adj_price} = sprintf("%.6f",$predictedYs[$i]);
			  print "por definir ".$isos_a3[$i] ."\n";

#			foreach my $cur (@basecurrencies) {

#					# indice crudo raw
#					my $index = $paisgdp{$fecha}{$isos_a3[$i]}{adj_price} /$base_currencies{$fecha}{$cur} -1 ;
#					$index = sprintf("%.3f",$index);
#					print "($cur) index adjusted= $index ";
#
#					# guardamos el indice x currencie en hash
#					my $indexkey = $cur ."_adjusted";
#					$paisgdp{$fecha}{$isos_a3[$i]}{$indexkey}  = $index ;
#			}
		}


		# if }
}


print HTML "<table border=1 summary=\"The table shot the source input data currency code , local price, dollar exchange etc\"><tr><th>date</th><th>iso_a3</th><th>currency_code</th><th>local_price</th><th>dollar_ex</th><th>dollar_price (calculated)</th><th>gdp</th>";

foreach my $cur (@basecurrencies) {
	print HTML "<th> index ".$cur."_adjusted (calculated)</th>";
	print HTML "<th> index ".$cur."_raw (calculated)</th>";
}


print HTML "</tr>";

# Tenemos que calcular los indices ajustados por moneda. Recorrer de nuevo el hash

# Hay que sacar las base_currencies pero ajustadas guardadas en una tabla para luego utilizar
foreach  my $fecha (keys %paisgdp){

		foreach my $iso_a3 (keys %{ $paisgdp{$fecha} }){

			print "fecha = $fecha , iso_a3 = $iso_a3\n";
			my $adj_price = $paisgdp{$fecha}{$iso_a3}{adj_price};

			my $currency_code = $paisgdp{$fecha}{$iso_a3}{currency_code};

			print "fecha =$fecha currencies=$currency_code!!\n";

		        if ($currency_code ~~ @basecurrencies) {

				$base_currencies_adj{$fecha}{$currency_code} = $adj_price;
		        }


		} # foreach my iso_a3

} # foreach my feha





# calculamos los adj_price segun las tablas de currencies
foreach  my $fecha (keys %paisgdp){

		# For make graph
		my @xdata ;
		my @ydata ;
		my @ydata_adjusted ;

		my $chart = Chart::Gnuplot->new(
		       output  => "/root/3p/ht/htdocs/$fecha.png",
		       xlabel => "GDP_dollar",
		       title => "$fecha",
		       ylabel => "Dollar_price"
	         );



		foreach my $iso_a3 (keys %{ $paisgdp{$fecha} }){

			print HTML "<tr><td>$fecha</td><td>$iso_a3</td><td>".$paisgdp{$fecha}{$iso_a3}{currency_code}."</td><td>".$paisgdp{$fecha}{$iso_a3}{local_price}."</td><td>".$paisgdp{$fecha}{$iso_a3}{dollar_ex}."</td><td>".$paisgdp{$fecha}{$iso_a3}{dollar_price}."</td><td>".$paisgdp{$fecha}{$iso_a3}{gdp}."</td>";

			if ( (defined $paisgdp{$fecha}{$iso_a3}{dollar_price}) and (defined $paisgdp{$fecha}{$iso_a3}{gdp}) ) {
				push(@ydata,$paisgdp{$fecha}{$iso_a3}{dollar_price});
				push(@xdata,$paisgdp{$fecha}{$iso_a3}{gdp});
				push(@ydata_adjusted,$paisgdp{$fecha}{$iso_a3}{adj_price});
		        }


			foreach my $cur (@basecurrencies) {


				print HTML "<td>";

			        if ((defined $base_currencies_adj{$fecha}{$cur}) && (defined $paisgdp{$fecha}{$iso_a3}{adj_price})  ){

					# indice crudo raw
					my $index = $paisgdp{$fecha}{$iso_a3}{adj_price} /$base_currencies_adj{$fecha}{$cur} -1 ;
					$index = sprintf("%.3f",$index);
					# print "($cur) index adjusted= $index ";

					# guardamos el indice x currencie en hash
					my $indexkey = $cur ."_adjusted";
					$paisgdp{$fecha}{$iso_a3}{$indexkey}  = $index ;
					print HTML $index;

				 }
				print HTML "</td>";
				print HTML "<td>";
				# ARI
				if ((defined $base_currencies{$fecha}{$cur}) && (defined $paisgdp{$fecha}{$iso_a3}{dollar_price}) ) {
					my $indexkey = $cur ."_raw";
					my $index = $paisgdp{$fecha}{$iso_a3}{$indexkey};
					print HTML $index;
				}
				print HTML "</td>";
			}
			print HTML "</tr>";

		} #foreach pais

		my $dataSet;
		my $dataSetadj;
		if (scalar @xdata> 0 ){

		   $dataSet = Chart::Gnuplot::DataSet->new(
			        xdata => [@xdata],
			        ydata => [@ydata],
		 		style => "points",
				title => "raw price"
	           );

		   $dataSetadj = Chart::Gnuplot::DataSet->new(
			        xdata => [@xdata],
			        ydata => [@ydata_adjusted],
				title => "adjusted price",
			        style => "linespoints"
	           );


		   $chart->plot2d($dataSet,$dataSetadj);
		}

}


print HTML "</HTML>";
die Dumper \%paisgdp;


