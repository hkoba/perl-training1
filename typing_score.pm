#!/usr/bin/env perl
package typing_score;
use strict;
use Data::Dumper;

sub MY () {__PACKAGE__}
use fields qw/output_format/;


use Getopt::Long;

sub new {
  my ($class) = @_;
  fields::new($class);
}

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
  my %typing_scores;
  while (<>) {
    chomp;
    my ($Y, $M, $D, $unpro, $wpm)
      = m{
	   == \s+ (\d+)\/(\d+)\/(\d+) \n
	   [\s\S]*?
	   unproductive \s+ \w+ \s+ \w+ \s+ (\d+\%) \s+ \n
	   [\s\S]*?
	   wpm \s+ (\d+) \s+ \n
	   # (\w+ \s+ \w+)
	   # unproductive \s+ \w+ \s+ \w+ \s+ (\d+\%)
	   # wpm \s+ (\w+)
       }x
	 or do {print "NOT MATCHED: $_"; next};
    my $typing_score = $typing_scores{"$Y-$M-$D"} = +{
      day => "$Y-$M-$D",
      unproductive => $unpro,
      wpm => $wpm,
    };

    if ($this->{output_format}) {
      my $sub = $this->can("output_as_$this->{output_format}")
	or die "Unknown output format: $this->{output_format}";
      $sub->($this, $typing_score);
    } else {
      print Dumper($typing_score), "\n"; # "$typing_score->{day} $typing_score->{wpm}\n";
    }

    # print "==ここから==\n";
    # print "$day";
    # print "$unpro";
    # print "$wpm";
    # print "==ここまで==\n";
  }
}

sub output_as_gnuplot {
  (my MY $self, my $scoreRec) = @_;
  print "$scoreRec->{day}\t$scoreRec->{wpm}\n";
}

sub output_as_html {
  (my MY $self, my $scoreRec) =@_;
  print "HTML: $scoreRec->{wpm}\n";
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

  my MY $obj = MY->new;

  GetOptions("output_format=s", \ $obj->{output_format})
    or die "Unknown option";

  my $method = $ARGV[0];
  $obj->$method(@ARGV[1..$#ARGV]);
  print "\n";
}

1;
