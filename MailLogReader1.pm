#!/usr/bin/env perl
package MailLogReader1;
use strict;

sub foo {"BARRR"}
sub hoehoe {"hoehoe"}

sub sum {
  my ($this, @num) = @_;
  my $sum = shift @num;
  foreach my $val (@num) {
    $sum += $val;
  }
  $sum;
}

sub group_by_queueid {
  my ($this, @files) = @_;
  local @ARGV = @files;
  local $_; # 他所の関数から呼ばれたときのため

  my %queue;
  while (<>) {
    # $_ に、一行分、読み込まれる
    chomp; # chomp($_);
    my ($month, $day, $H, $M, $S, $host, $prog, $pid, $queueid, $text)
      = m{^
	  (\w+) \s+ (\d+)\s+         # Jan 06
	  (\d+):(\d+):(\d+)\s+       # 03:31:12
	  ([-\.\w]+)\s+              # newera
	  postfix/(\w+)\[(\d+)\]:\s+ # postfix/pickup[4249]:
	  ([\dA-F]+):\s+             # 5DB5042448:
	  (.*)
       }x
	 or next;

    # print join("\t", ($month, $day, $H, $M, $S, $host, $prog, $pid, $queueid)), "\n";


    # my $queue = $queue{$queueid} //= +{};

    if ($text =~ m{^(from|to)=}) {
      # ', ' で区切られているケース.

      # 末尾の (...) を捨てる (s/パターン/置換文字列/ は置換)
      $text =~ s/\s+(\(.*\))$//;
      my $comment = $1;

      my @elems = split /, /, $text;
      my @kv = map {split /=/, $_, 2} @elems;
      print @kv, "\n";

    } elsif ($text =~ m{^(uid|message-id|client)=}) {
      # ' '
    } elsif ($text =~ m{^host }) {
    } elsif ($text eq 'removed') {
    } else {
    }

    # print join("\t", $queueid, $text), "\n";

  }
}

sub show_ip_warnings {
  my ($this, @files) = @_;
  local @ARGV = @files;
  local $_; # 他所の関数から呼ばれたときのため

  my %stat;
  while (<>) {
    # $_ に、一行分、読み込まれる
    chomp; # chomp($_);
    # 正規表現のメタ文字
    # [ ]  character class (括弧内の文字、どれでもマッチ)
    # [^ ] negative? (括弧内の文字以外、どれでもマッチ)
    # \   メタ文字の意味を殺す、メタ文字
    # ( ) マッチを変数 $1, $2, ... に保存する
    if (my ($pid, $ip) = /\[([^\]]+)\]: warning: unknown\[([^\]]+)\]/) {
      # $_ =~ /warning: unknown/ の省略形
      
      $stat{$ip}++
    }

    # (?<名前> ...) でマッチしたものは $+{名前} に保存される
    # $+{}
    # if (/\[(?<pid>[^\]]+)\]: warning: unknown\[(?<ip>[^\]]+)\]/) {
    #   # $_ =~ /warning: unknown/ の省略形

    #   print "[$+{ip}]\n";
    #   # my %match = %+;
    # }
  }

  foreach my $ip (sort keys %stat) {
    print "$ip\t$stat{$ip}\n";
  }
}

# unless (caller) {
#   print foo(), "\n";
# }

# unless (caller) {
#   print "ARGV is: ", @ARGV, "\n";
# }

unless (caller) {
  my $method = $ARGV[0];
  print MailLogReader1->$method(@ARGV[1..$#ARGV]), "\n";
  print "\n";
}

1;
