#!/usr/bin/env perl
package typing_score;
use strict;


sub get_score_line_by_line {
  my ($this, @files) = @_;
  local @ARGV = @files;
  local $_;
  while (<>) {
    chomp;
    print "<<$_>>\n";
  }
}

sub get_score_paragraph {
  my ($this, @files) = @_;
  local @ARGV = @files;
  local $_;
  local $/ = ""; # パラグラフモード. コマンド行だと perl -00
  while (<>) {
    chomp;
    my ($day, $unpro, $wpm)
      = m{
	   \=\= \s+ (\d+\/\d+\/\d+ \n)
	   \w+ \s+ \w+ \n
	   \w+ \s+ \w+ \s+ \d+ \s+ \n
	   \w+ \s+ \w+ \s+ \d+ \s+ \n
	   \d+ \s+ \w+ \s+ \w+ \n
	   \W+ \s+ \d+ \s+ \w+ \s+ \w+ \n
	   \W+ \s+ \d+ \s+ \w+ \s+ \w+ \s+ \w+ \s+ \w+ \n
	   \W+ \s+ \d+ \s+ \w+ \n
	   (unproductive \s+ \w+ \s+ \w+ \s+ \d+\% \s+ \n)
	   \d+ \s+ \w+ \s+ \w+ \s+ \— \s+ \d+ \s+ \w+ \s+ \w+ \n
	   \d+ \s+ \w+ \s+ \w+ \n
	   \w+ \s+ \w+ \s+ \d+:\d+ \s+ \n
	   (wpm \s+ \d+ \s+ \n)
	   # (\w+ \s+ \w+)
	   # unproductive \s+ \w+ \s+ \w+ \s+ (\d+\%)
	   # wpm \s+ (\w+)
       }x
	 or do {print "NOT MATCHED: $_"; next};
    print "==ここから==\n";
    print "$day";
    print "$unpro";
    print "$wpm";
    print "==ここまで==\n";
  }
}


sub get_score{
  my ($this, @files) = @_;
  local @ARGV = @files;
  local $_;
  my @data;;
  my $file = "@files"; # XXX: これは何？？
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
