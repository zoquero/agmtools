#!/usr/bin/perl

#
# Extract headernames of CSV file
#
# zoquero@gmail.com 20160123
#

use strict;
use warnings;

sub usage () {
  print "$0 csvFile separator\n";
  exit 1;
}

my $csvFile=$ARGV[0];
my $separator=$ARGV[1];
my $fh;
my $aField;
my @fields;
my $fileHead;

if($#ARGV < 1) {
  print "Error: Missing arguments\n";
  usage();
}

if ( ! -r $csvFile ) {
  print "Error: The $csvFile is not a readable file\n";
  usage();
}
if ( -z $separator ) {
  print "Error: Missing separator\n";
  usage();
}

open($fh, '<:encoding(UTF-8)', $csvFile)
  or die "Could not open file '$csvFile' $!";

$fileHead = <$fh>;
chomp($fileHead);
@fields = split $separator, $fileHead;
die "There are no fields. Wrong separator?" if(! @fields);

foreach $aField (@fields) {
  print "$aField\n";
}

close($fh)
  or die "Could not close file '$csvFile' $!";
