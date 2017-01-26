#!/usr/bin/perl

#
# Script to extract histogram of fields from a CSV file
#
# zoquero@gmail.com 20160126
#

use strict;
use warnings;

sub usage () {
  print "Script to calculate the histogram of fields from a CSV file.";
  print "Usage:\n";
  print "$0 csvFile separator list_of_fields min max intervals (-d)\n";
  print "  csvFile:        path to CSV file\n";
  print "  separator:      CSV separator\n";
  print "  list_of_fields: Comma separated list of fields to work on (0..N-1)\n";
  print "  min:            Low  value for the first interval\n";
  print "  max:            High value for the last interval\n";
  print "  intervals:      Number of intervals\n";
  print "                  (will add before the first a greater than min\n";
  print "                  and after the last a greater than max field)\n";
  print "  (-d):           (optional) Enable debug\n";
  exit 1;
}

if($#ARGV < 5) {
  print "Missing arguments\n";
  usage();
}

my $csvFile     = $ARGV[0];
my $separator   = $ARGV[1];
my $listOfFields= $ARGV[2];
my $min         = $ARGV[3];
my $max         = $ARGV[4];
my $intervals   = $ARGV[5];
my $debug       = 0;
my $fh;
my $aField;

$debug = 1 if($#ARGV >= 6 and $ARGV[6] eq "-d");

###########################
## Let's check the input ##
###########################
if ( ! -r $csvFile ) {
  print "Error: The file $csvFile is not a readable file\n";
  usage();
}
if ( -z $separator || -z $listOfFields || -z $min || -z $max || -z $intervals ) {
  print "Error: Missing arguments.\n";
  usage();
}

my @fieldNumbers=split ",", $listOfFields;
my $maxFieldNumber = 0;
die "Can't parse list_of_fields" if ($#fieldNumbers < 0);
foreach my $f (@fieldNumbers) {
  if ( $f !~ /^\d+$/ || $f < 0) {
    die "The field number [$f] doesn't look like a positive integer (0..N-1)";
  }
  $maxFieldNumber = $f if($maxFieldNumber < $f);
}

if ( $min !~ /^-?(?:\d+\.?|\.\d)\d*\z/ &&
     $min !~ /^[+-]?(?=\.?\d)\d*\.?\d*(?:e[+-]?\d+)?\z/i) {
  die "\"min\" [$min] value doesn't look like a number. Check locale and format";
}
if ( $max !~ /^-?(?:\d+\.?|\.\d)\d*\z/ &&
     $max !~ /^[+-]?(?=\.?\d)\d*\.?\d*(?:e[+-]?\d+)?\z/i) {
  die "\"max\" [$max] value doesn't look like a number. Check locale and format";
}
if ( $intervals !~ /^\d+$/ || $intervals < 0) {
  die "\"intervals\" [$intervals] value doesn't look like a positive integer. Check locale and format";
}

if($debug) {
  print "Using csvFile=$csvFile, separator=$separator, listOfFields=$listOfFields, maxFieldNumber=$maxFieldNumber, min=$min, max=$max, intervals=$intervals\n";
}

open($fh, '<:encoding(UTF-8)', $csvFile)
  or die "Could not open file '$csvFile' $!";

############################
# Let's read the CSV file ##
############################
my ($nr) = (0);
my (@histograms); # [colIndex_O..N][histInterval] . Intervals are "[)"
                  # histInterval #0    : less than min
                  # histInterval #1..N : 1 for each interval
                  # histInterval #N+1  : greater or equal than max

my (@histLimits); # ( min, min+1*(max-min)/intervals, min+2*(max-min)/intervals, ... max )

# Let's initialize @histograms and histLimit:
for (my $i = 0; $i <= $#fieldNumbers; $i++) {
  for (my $j = 0; $j < $intervals+2; $j++) {
    $histograms[$i][$j] = 0;
  }
}

# Let's set histLimit:
for (my $i = 0; $i < $intervals+1; $i++) {
  $histLimits[$i] = $min + $i * ($max-$min)/$intervals;
}

while(<$fh>) {
  chomp;
  next if /^#/;  # discard comments
  my @fields = split $separator;
  die "There are no fields. Wrong separator?" if(! @fields);
  die "Just $#fields read on line [$_] and $listOfFields demanded" if($#fields < $maxFieldNumber);

  ## Let's validate the values
  foreach $aField (@fields) {
    ## Regexp from http://perldoc.perl.org/perlfaq4.html#How-do-I-determine-whether-a-scalar-is-a-number%2fwhole%2finteger%2ffloat%3f
    $aField = 0 if ( $aField eq "" );
    if ( $aField !~ /^-?(?:\d+\.?|\.\d)\d*\z/ &&
         $aField !~ /^[+-]?(?=\.?\d)\d*\.?\d*(?:e[+-]?\d+)?\z/i) {
      die "It doesn't look like a number: [$aField]. Check separator, locale and format. Row #$nr (0..N-1)";
    }
  }

  ## Let's check the values and add them to the histogram:
  for (my $i = 0; $i <= $#fieldNumbers; $i++) {
    # Intervals are [) : include low, don't include high

    # Less than min:
    print "Checking [$fields[$fieldNumbers[$i]]]:" if ($debug);
    if($fields[$fieldNumbers[$i]] < $histLimits[0]) {
      $histograms[$i][0]++;
      print "    less than min\n" if ($debug);
    }
    # greater than max:
    elsif($fields[$fieldNumbers[$i]] >= $histLimits[$intervals]) {
      $histograms[$i][$intervals + 1]++;
      print "    greater or equal than max\n" if ($debug);
    }
    # intervals
    else {
      my $found = 0;
      for(my $z = 1; $z <= $intervals; $z++) {
        # iterate from $z=1 because $z=0 is already checked with "min"
        if($fields[$fieldNumbers[$i]] < $histLimits[$z]) {
          $histograms[$i][$z]++;
          print "    belongs to interval #" . $z . "\n" if ($debug);
          $found = 1;
          last;
        }
      }
      die "BUG: Couldn't set [$fields[$fieldNumbers[$i]]] on any interval" if !$found;
    }
  }
  $nr++;
}

close($fh)
  or die "Could not close file '$csvFile' $!";

# Let's print output:
for (my $i = 0; $i < $intervals+2; $i++) {
  my @rl;
  if($i != $intervals+1) {
    push @rl, "Interval <  $histLimits[$i]";
  }
  else {
    push @rl, "Interval >= $histLimits[$i - 1]";
  }

  for (my $j = 0; $j <= $#fieldNumbers; $j++) {
    if($i != $intervals+1) {
      push @rl, $histograms[$j][$i];
    }
    else {
      push @rl, $histograms[$j][$i];
    }
  }
  print join $separator, @rl;
  print "\n";
}

