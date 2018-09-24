#!usr/bin/perl



use strict;
use warnings;
use Data::Dumper;
use Statistics::LineFit;

my $lineFit = Statistics::LineFit->new();

my @basecurrencies = ('USD', 'EUR', 'GBP', 'JPY', 'CNY');

# reg_countries chardcodeados?
my @reg_countries = ('ARG', 'AUS', 'BRA', 'GBR', 'CAN', 'CHL', 'CHN', 'CZE', 'DNK', 'EGY', 'EUZ', 'HKG', 'HUN', 'IDN', 'ISR', 'JPN', 'MYS', 'MEX', 'NZL', 'NOR', 'PER', 'PHL', 'POL', 'RUS', 'SAU', 'SGP', 'ZAF', 'KOR', 'SWE', 'CHE', 'TWN', 'THA', 'TUR', 'USA', 'COL', 'PAK', 'IND', 'AUT', 'BEL', 'NLD', 'FIN', 'FRA', 'DEU', 'IRL', 'ITA', 'PRT', 'ESP', 'GRC', 'EST');


       

# OJO BASE CURRENCIAES HAY QUE TOMAR EL PRECIO AJUSTADO??


my %paisgdp;
my %base_currencies;
my %base_currencies_adj;

open (FILEGDP,"/root/bigmac/big-mac-data/source-data/big-mac-source-data.csv");

# primera linea la evitamos
<FILEGDP>;
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

	if ($currency_code ~~ @basecurrencies) {

		$base_currencies{$date}{$currency_code} = $dollar_price;
	}
	
}

print "Precios de big mac en 'base_currencies'\n";

close FILEGDP;


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

					if (defined $base_currencies{fecha}{$cur}) {

						# indice crudo raw
						$index = $paisgdp{$fecha}{$iso_a3}{dollar_price} /$base_currencies{$fecha}{$cur} -1 ;
						$index = sprintf("%.3f",$index);
						# print "($cur) index raw= $index ";

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




# Tenemos que calcular los indices ajustados por moneda. Recorrer de nuevo el hash

# Hay que sacar las base_currencies pero ajustadas guardadas en una tabla para luego utilizar
foreach  my $fecha (keys %paisgdp){

		foreach my $iso_a3 (keys %{ $paisgdp{$fecha} }){

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
		foreach my $iso_a3 (keys %{ $paisgdp{$fecha} }){

			foreach my $cur (@basecurrencies) {


				  if ((defined $base_currencies_adj{$fecha}{$cur}) && (defined $paisgdp{$fecha}{$iso_a3}{adj_price})  ){

					# indice crudo raw
					my $index = $paisgdp{$fecha}{$iso_a3}{adj_price} /$base_currencies_adj{$fecha}{$cur} -1 ;
					$index = sprintf("%.3f",$index);
					# print "($cur) index adjusted= $index ";

					# guardamos el indice x currencie en hash
					my $indexkey = $cur ."_adjusted";
					$paisgdp{$fecha}{$iso_a3}{$indexkey}  = $index ;

				 }
			}
		}
}

die Dumper \%paisgdp;
