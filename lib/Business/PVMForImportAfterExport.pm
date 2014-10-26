package Business::PVMForImportAfterExport;

use warnings;
use strict;
use String::StringLight qw( trim );

our $VERSION = '0.03';

BEGIN {
	use Exporter;
	our @ISA         = qw( Exporter );
	our @EXPORT      = qw( );
	our %EXPORT_TAGS = ( );
	our @EXPORT_OK   = qw( &PvmDateiErstellen &AdresslisteDazu );
}

sub PvmDateiErstellen {

	my ($dateiEin, $dateiPvm, $aufbau, $idStelle, $idLaenge, $lkzStelle, $lkzLaenge, $plzStelle, $plzLaenge, $buendelung) = @_;

	open(my $fhEin, "<", $dateiEin) or die $!;
	open(my $fhPvm, ">", $dateiPvm) or die $!;

	print $fhPvm join(";", "PLZ", "ID")."\n";

	while(my $zeile = <$fhEin>) {

		chomp $zeile;

		my ($lkz, $plz, $pvmSatz) = ("", "", "");
		if ($aufbau =~ m/^D/) {
			my @satz = ();
			@satz    = split(substr($aufbau,1), $zeile);
			$lkz     = trim($satz[$lkzStelle - 1]);
			$plz     = trim($satz[$plzStelle - 1]);
			$pvmSatz = join(";", $plz, trim($satz[$idStelle - 1]))."\n" if $buendelung eq "J";
			$pvmSatz = join(";", $plz, $.)."\n"                         if $buendelung eq "N";
		} # if
		else {
			$lkz     = trim(substr($zeile,$lkzStelle - 1,$lkzLaenge));
			$plz     = trim(substr($zeile,$plzStelle - 1,$plzLaenge));
			$pvmSatz = join(";", $plz, trim(substr($zeile,$idStelle - 1,$idLaenge)))."\n" if $buendelung eq "J";
			$pvmSatz = join(";", $plz, $.)."\n"                                           if $buendelung eq "N";
		} # else

		print $fhPvm $pvmSatz if $lkz eq "A";

	} # while

	close($fhEin) or die $!;
	close($fhPvm) or die $!;

} # PvmDateiErstellen

sub AdresslisteDazu {

	my ($dateiAdrListe, $dateiEin, $dateiAus, $idStelle, $idLaenge, $aufbau) = @_;

	open(my $fhAdrListe, "<", $dateiAdrListe) or die $!;
	my %pnr;
	while(my $zeile = <$fhAdrListe>) {
		chomp $zeile;
		my @satz = ();
		@satz    = split(/;/, $zeile);
		defined $satz[8] or $satz[8] = "";
		defined $satz[9] or $satz[9] = "";
		if ($aufbau =~ m/^D/) {
			$pnr{$satz[2]} = join(substr($aufbau,1), $satz[0], @satz[3..9]);
		} # if
		else {
			$pnr{$satz[2]} = sprintf("%-11s", $satz[0]).sprintf("%-3s", $satz[3]).sprintf("%-3s", $satz[4]).sprintf("%-3s", $satz[5]).
			                 sprintf("%-1s", $satz[6]).sprintf("%-2s", $satz[7]).sprintf("%-1s", $satz[8]).sprintf("%-1s", $satz[9]);
		} # else
	} # while
	close($fhAdrListe) or die $!;

	open(my $fhEin, "<", $dateiEin) or die $!;
	open(my $fhAus, ">", $dateiAus) or die $!;
	while(my $zeile = <$fhEin>) {
		chomp $zeile;
		if ($aufbau =~ m/^D/) {
			my @satz = ();
			@satz    = split(substr($aufbau,1), $zeile);
			# bei delimitedAusgabe nicht so "dramatisch", wenn auch die zuvor eingef�gte ID ausgegegen wird, darum @satz...
			print $fhAus join(substr($aufbau,1), @satz, $pnr{trim($satz[$idStelle - 1])})."\n";
		} # if
		else {
			print $fhAus substr($zeile,0,$idStelle - 1).$pnr{trim(substr($zeile,$idStelle - 1,$idLaenge))}."\n";
		} # else
	} # while
	close($fhEin) or die $!;
	close($fhAus) or die $!;

} # AdresslisteDazu

1;
__END__

=pod

=head1 NAME

PVMForImportAfterExport - a module for Postversandmanager in Austria

=head1 SYNOPSIS

  use warnings;
  use strict;
  use PVMForImportAfterExport qw( PvmDateiErstellen AdresslisteDazu );

  my $dateiEin      = "Datei.txt";       # Eingabedatei
  my $dateiPvm      = "DateiPVM.csv";    # Datei f�r den Import in den Postversandmanager
  my $aufbau        = "D\t";             # Aufbau der Eingabedatei F = fixe Satzl�nge, D = delimited, \t oder ; oder ... = Trennzeichen
  my $idStelle      = 3;                 # Stelle/Feld der eindeutigen ID
  my $idLaenge      = 0;                 # L�nge der eindeutigen ID (nur bei fixer Satzl�nge auszuf�llen, ansonsten 0)
  my $lkzStelle     = 1;                 # Stelle/Feld des LKZ
  my $lkzLaenge     = 0;                 # L�nge des LKZ (nur bei fixer Satzl�nge auszuf�llen, ansonsten 0)
  my $plzStelle     = 2;                 # Stelle/Feld der PLZ
  my $plzLaenge     = 0;                 # L�nge der PLZ (nur bei fixer Satzl�nge auszuf�llen, ansonsten 0)
  my $buendelung    = "J";               # J = mit B�ndelung, N = keine B�ndelung
  my $dateiAdrListe = "Adressliste.csv"; # Name der Adressliste die vom Postversandmanager kommt
  my $dateiAus      = "Datei.fertig";    # Ausgabedatei

  # forwards Import
  PvmDateiErstellen($dateiEin, $dateiPvm, $aufbau, $idStelle, $idLaenge, $lkzStelle, $lkzLaenge, $plzStelle, $plzLaenge, $buendelung);
  # ... Postversandmanager works
  # after Export
  AdresslisteDazu($dateiAdrListe, $dateiEin, $dateiAus, $idStelle, $idLaenge, $aufbau);

=head1 DESCRIPTION

...

=head1 AUTHOR AND LICENSE

copyright 2009 (c)
Gernot Havranek

=cut
