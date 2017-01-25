#!/usr/bin/perl

#
# Resize a CSV file interpolating.
#
# zoquero@gmail.com 20160124
#

use strict;
use warnings;
use POSIX qw(ceil);
use POSIX qw(floor);

sub usage () {
  print "Script to resize a CSV file interpolating as needed " .
  print "Usage:\n";
  print "$0 csvFile separator numberOfRows\n";
  exit 1;
}


sub getMappedPosition($$$) {
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
  if ( /^#/ ) {
    print "$_\n";
    next;
  }
  @fields = split $separator;
  die "There are no fields. Wrong separator?" if(! @fields);

  $nc = 0;
  foreach $aField (@fields) {
    ## Regexp from http://perldoc.perl.org/perlfaq4.html#How-do-I-determine-whether-a-scalar-is-a-number%2fwhole%2finteger%2ffloat%3f
    if ( $aField !~ /^-?(?:\d+\.?|\.\d)\d*\z/ &&
         $aField !~ /^[+-]?(?=\.?\d)\d*\.?\d*(?:e[+-]?\d+)?\z/i) {
      die "It doesn't look like a number: [$aField]. Check separator, locale and format";
    }
    $contents[$nr][$nc] = $aField;
    $nc++;
  }
  $nr++;
}

$originalNumberOfRows = $nr + 1;

close($fh)
  or die "Could not close file '$csvFile' $!";


if ($desiredNumberOfRows > $originalNumberOfRows) {
  die "oversamping on next version";
}

my(@results) = ();
my($mapped) = (0);
my($hmp) = (ceil($originalNumberOfRows/$desiredNumberOfRows));
for (my $i=0; $i < $desiredNumberOfRows; $i++) {
  for (my $j=0; $j < $nc; $j++) {
    $mapped = getMappedPosition($originalNumberOfRows, $desiredNumberOfRows, $i);
    my($c) = (0);
    for(my $k = floor($mapped - $hmp + 1); $k <= floor($mapped + $hmp); $k++) {
      next if $k < 0;
      next if $k >= $originalNumberOfRows - 1;
      $c++;
      $results[$i][$j] += $contents[$k][$j];
    }
    $results[$i][$j] /= $c;   # average, not splines
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
