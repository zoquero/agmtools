#!/usr/bin/perl

#
# Merge CSV files line by line
#
# zoquero@gmail.com 20160125
#

use strict;
use warnings;

sub usage () {
  print "Concat files line by line\n";
  print "$0 separator file1 file2 ...\n";
  exit 1;
}

if($#ARGV < 2) {
  print "Missing arguments\n";
  usage();
}

my $separator = $ARGV[0];
if ( -z $separator ) {
  print "Error: Missing separator\n";
  usage();
}

my @files = @ARGV;
shift @files;
my @fileHandlers;
my @fieldsPerFile;
for(my $i=0; $i <= $#files; $i++) {
  my $oneLine;
  my $aFile = $files[$i];
  die "Error: The file $aFile is not a readable file\n" if ( ! -r $aFile );
  
  open($fileHandlers[$i], '<:encoding(UTF-8)', $aFile)
    or die "Could not open file '$aFile': $!";

  $oneLine = readline($fileHandlers[$i]);
  chomp $oneLine;
  my @firstFields = split $separator, $oneLine;
  $fieldsPerFile[$i] = $#firstFields + 1;

  # Let's reset file handler to the beginning of the file
  seek $fileHandlers[$i], 0, 0;
}

#
# Let's read and concat the files, line by line
#
for(;;) {
  my @linesArray;
  my $oneLine;
  my $nonEmptyLines = 0;
  for(my $i=0; $i <= $#files; $i++) {
    $oneLine = readline($fileHandlers[$i]);
    if (defined $oneLine) {
      chomp $oneLine;
      push @linesArray, $oneLine;
      $nonEmptyLines++;
    }
    else {
      for(my $j=0; $j < $fieldsPerFile[$i]; $j++) {
        push @linesArray, "";
      }
    }
  }
  last if $nonEmptyLines == 0;
  print join $separator, @linesArray;
  print "\n";
}

for(my $i=0; $i <= $#files; $i++) {
  my $aFile = $files[$i];
  close($fileHandlers[$i])
    or die "Could not close file '$aFile': $!";
}
