#!/usr/bin/env perl
package typing_score;
use strict;

sub get_score{
  my ($this, @files) = @_;
  local @ARGV = @files;
  local $_;
  my @data;;
  my $file = "@files";
  my $output = "../score.txt";
  my $count;
  open(OUT, ">$output") or die "$!";
  while (<>) {
    chomp;
    my ($wpm)
      = m{
	   #\=\= \s+ (\d+\/\d+\/\d+)
	   # unproductive \s+ \w+ \s+ \w+ \s+ (\d+\%)
	   wpm \s+ (\w+)
       }x
	 or next;
    $count += 1;
    print OUT "$count\t$wpm\n";
  }
}



sub test{
  my ($this, @files) = @_;
  local @ARGV = @files;
  local $_;
  my $file = "@files";
  open(IN, $file) or die "$!";
  while (<IN>) {
    chomp;
    my ($wpm)
      = m{^
	  wpm \s+ (\w+)
       }x
	 or next;
	 print $wpm, "\n";
  }
  close(IN);
}
unless (caller) {
  my $method = $ARGV[0];
  typing_score->$method(@ARGV[1..$#ARGV]);
  print "\n";
}

1;
