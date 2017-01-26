#!/usr/bin/perl

#
# Resize a CSV file with linear interpolation.
#
# zoquero@gmail.com 20160124
#

use strict;
use warnings;
use POSIX qw(ceil);
use POSIX qw(floor);
use POSIX qw(round);

sub usage () {
  print "Script to resize a CSV file with linear interpolatation.\n" .
  print "Usage:\n";
  print "$0 csvFile separator numberOfRows (-d)\n";
  print "  csvFile:      Path to the CSV file to resize\n";
  print "  separator:    String used as separador\n";
  print "  numberOfRows: Number of rows of the resulting CSV\n";
  print "  (-d):         (optional) Show debug messages\n";
  exit 1;
}


sub getMappedPos($$$) {
  my $originalNumberOfRows = $_[0];
  my $desiredNumberOfRows  = $_[1];
  my $n                    = $_[2];
  return $originalNumberOfRows / ($desiredNumberOfRows - 1) * $n;
}


if($#ARGV < 2) {
  print "Missing arguments\n";
  usage();
}

my $csvFile=$ARGV[0];
my $separator=$ARGV[1];
my $desiredNumberOfRows=$ARGV[2];
my $debug = 0;
if($#ARGV >= 3 && $ARGV[3] eq "-d") {
  $debug = 1;
}
my $fh;
my $aField;
my @fields;

if ( ! -r $csvFile ) {
  print "Error: The file $csvFile is not a readable file\n";
  usage();
}
if ( -z $separator ) {
  print "Error: Missing separator\n";
  usage();
}

open($fh, '<:encoding(UTF-8)', $csvFile)
  or die "Could not open file '$csvFile' $!";

#
# First let's load the whole file
# (not stream oriented, memory hungry script)
#
my ($nr, $nc, @contents, $originalNumberOfRows) = (0, 0, ());
while(<$fh>) {
  chomp;
  # print comments
  next if ( /^$/ );
  if ( /^#/ ) {
    print "$_\n";
    next;
  }
  @fields = split $separator;
  die "There are no fields. Wrong separator?" if(! @fields);

  $nc = 0;
  foreach $aField (@fields) {
    ## Regexp from http://perldoc.perl.org/perlfaq4.html#How-do-I-determine-whether-a-scalar-is-a-number%2fwhole%2finteger%2ffloat%3f
    $aField = 0 if ( $aField eq "" );
    if ( $aField !~ /^-?(?:\d+\.?|\.\d)\d*\z/ &&
         $aField !~ /^[+-]?(?=\.?\d)\d*\.?\d*(?:e[+-]?\d+)?\z/i) {
      die "It doesn't look like a number: [$aField]. Check separator, locale and format";
    }
    $contents[$nr][$nc] = $aField;
    $nc++;
  }
  $nr++;
}

$originalNumberOfRows = $nr;

close($fh)
  or die "Could not close file '$csvFile' $!";

my($oversampling);
if ($desiredNumberOfRows > $originalNumberOfRows) {
  # Oversamping   => We will interpolate
  $oversampling = 1;
}
else {
  # Undersampling => We will average
  $oversampling = 0;
}

my(@results) = ();
my($mapped)  = (0);
print "originalNumberOfRows=$originalNumberOfRows\n"                if($debug);
print "desiredNumberOfRows=$desiredNumberOfRows\n"                  if($debug);

for (my $i=0; $i < $desiredNumberOfRows; $i++) {
  print "Row [$i]\n" if($debug);
  for (my $j=0; $j < $nc; $j++) {
    $mapped = getMappedPos($originalNumberOfRows, $desiredNumberOfRows, $i);

    if($oversampling) {
      die "Oversamping still not implemented";
    }
    else {
      # We'll average at least two near points
      my($hmp)     = round($originalNumberOfRows/$desiredNumberOfRows);
      $hmp = $hmp < 2 ? 2 : $hmp;
      print "hmp=$hmp (how many points to average per resulting point)\n" if($debug);
      my($c) = (0);
      my $first = floor($mapped - $hmp/2);
      my $last  = $first + $hmp - 1;
      print "  Col [$j], mapped [$mapped]. first=$first , last=$last\n" if($debug);
      for(my $k = $first; $k <= $last ; $k++) {
        next if $k < 0;
        last if $k >= $originalNumberOfRows;
        $results[$i][$j] += $contents[$k][$j];
        $c++;
        print "    Concatenating row [$k] (". $contents[$k][$j] .")\n" if($debug);
      }
      $results[$i][$j] /= $c;   # average, not splines
    }
    print "  Result for [$i][$j] = " . $results[$i][$j] . "\n" if($debug);
  }
}

for (my $i=0; $i < $desiredNumberOfRows; $i++) {
  my(@r) = ();
  for (my $j=0; $j < $nc; $j++) {
    push @r, $results[$i][$j];
  }
  print join $separator, @r;
  print "\n";
}
