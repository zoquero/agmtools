#!/usr/bin/perl

#
# Extract statistics from a CSV file
#
# zoquero@gmail.com 20160124
#

use strict;
use warnings;

sub usage () {
  print "Script to calculate the average and standard " .
        "deviation of each column of a CSV file\n";
  print "Usage:\n";
  print "$0 csvFile separator\n";
  exit 1;
}

if($#ARGV < 1) {
  print "Missing arguments\n";
  usage();
}

my $csvFile=$ARGV[0];
my $separator=$ARGV[1];
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
# First let's calculate the average for each column
#
my @acc;
my ($nr) = (0);
while(<$fh>) {
  chomp;
  next if /^#/;  # discard comments
  @fields = split $separator;
  die "There are no fields. Wrong separator?" if(! @fields);

  my($i) = (0);
  foreach $aField (@fields) {
    $aField = 0 if ( $aField eq "" );
    ## Regexp from http://perldoc.perl.org/perlfaq4.html#How-do-I-determine-whether-a-scalar-is-a-number%2fwhole%2finteger%2ffloat%3f
    if ( $aField !~ /^-?(?:\d+\.?|\.\d)\d*\z/ &&
         $aField !~ /^[+-]?(?=\.?\d)\d*\.?\d*(?:e[+-]?\d+)?\z/i) {
      warn "For nr=$nr it doesn't look like a number: [$aField]. Check separator, locale and format";
      $i++;
      next;
    }
    $acc[$i] += $aField;
    $i++;
  }
  $nr++;
}

close($fh)
  or die "Could not close file '$csvFile' $!";

my(@averages);
for(my $i = 0; $i <= $#acc; $i++) {
  $averages[$i] = $acc[$i]/$nr;
}

#
# We have calculated the average for each column.
# Now let's look for the standard deviation
#
# Let's read the file again.
# For huge files is better to re-read in front of a full load on memory
#

open($fh, '<:encoding(UTF-8)', $csvFile)
  or die "Could not open file '$csvFile' $!";

my @standardDeviations;
my @maxs;
my @mins;
my @qacc;
while(<$fh>) {
  chomp;
  next if /^#/;  # discard comments
  @fields = split $separator;
  die "There are no fields. Wrong separator?" if(! @fields);

  my($i) = (0);
  foreach $aField (@fields) {
    $aField = 0 if ( $aField eq "" );
    ## Regexp from http://perldoc.perl.org/perlfaq4.html#How-do-I-determine-whether-a-scalar-is-a-number%2fwhole%2finteger%2ffloat%3f
    if ( $aField !~ /^-?(?:\d+\.?|\.\d)\d*\z/ &&
         $aField !~ /^[+-]?(?=\.?\d)\d*\.?\d*(?:e[+-]?\d+)?\z/i) {
      die "It doesn't look like a number: [$aField]. Check separator, locale and format";
    }
    $qacc[$i] += ($averages[$i] - $aField) ** 2; # difference to the 2nd power
    $maxs[$i] = $aField if(!exists($maxs[$i]) || $maxs[$i] < $aField);
    $mins[$i] = $aField if(!exists($mins[$i]) || $mins[$i] > $aField);
    $i++;
  }
}

close($fh)
  or die "Could not close file '$csvFile' $!";

for(my $i = 0; $i <= $#qacc; $i++) {
  $standardDeviations[$i] = $qacc[$i] ** 0.5;
}

#
# Now let's print the results
#
print "Tuples;$nr\n";
print "Average"        . $separator . (join $separator, @averages) . "\n";
print "Std. deviation" . $separator . (join $separator, @standardDeviations) . "\n";
print "Maximum"        . $separator . (join $separator, @maxs) . "\n";
print "Minimum"        . $separator . (join $separator, @mins) . "\n";
