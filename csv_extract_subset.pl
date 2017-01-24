#!/usr/bin/perl

#
# Extract subset of CSV file
#
# zoquero@gmail.com 20160123
#

use strict;
use warnings;

sub usage () {
  print "$0 csvFile separator fieldNumbersFile\n";
  exit 1;
}

if($#ARGV < 2) {
  print "Missing arguments\n";
  usage();
}

my $csvFile=$ARGV[0];
my $separator=$ARGV[1];
my $fieldNumbersFile=$ARGV[2];
my $fh;
my @fieldNumbers;
my $aField;
my @fields;

if ( ! -r $csvFile ) {
  print "Error: The file $csvFile is not a readable file\n";
  usage();
}
if ( ! -r $fieldNumbersFile ) {
  print "Error: The file $fieldNumbersFile is not a readable file\n";
  usage();
}
if ( -z $separator ) {
  print "Error: Missing separator\n";
  usage();
}

open($fh, '<:encoding(UTF-8)', $fieldNumbersFile)
  or die "Could not open file '$fieldNumbersFile' $!";

while(<$fh>) {
  chomp;
  if (! /^\d+$/) {
    die "The line $_ doesn't contain a number\n"
  }
  push @fieldNumbers, $_;
}

close($fh)
  or die "Could not close file '$fieldNumbersFile' $!";

open($fh, '<:encoding(UTF-8)', $csvFile)
  or die "Could not open file '$csvFile' $!";

my @extractedFields;
my $s;
while(<$fh>) {
  chomp;
  my $i = 1;
  @fields = split $separator;
  die "There are no fields. Wrong separator?" if(! @fields);
  @extractedFields = ();
  foreach $aField (@fields) {
    if ( grep( /^$i$/, @fieldNumbers ) ) {
      push @extractedFields, $aField;
    }
    $i++;
  }
  $s = join $separator, @extractedFields;
  print "$s\n";
}

close($fh)
  or die "Could not close file '$csvFile' $!";

