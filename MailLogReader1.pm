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

use Data::Dumper;

sub test1 {
  my ($this, @files) = @_;
  local @ARGV = @files;
  local $_; # 他所の関数から呼ばれたときのため

  my %queue;
  while (<>) {
    # $_ に、一行分、読み込まれる
    chomp;
    print "[$_]\n";
  }
}

sub emit_sql_insert0 {
  my ($this, @files) = @_;
  print "BEGIN;\n";
  $this->do_group_by_queueid(
    sub {
      my ($queue) = @_;
      print qq{insert into maillog(queue_id,message_id,uid,client) values(}
	, join(", ", map {
	  defined $_ ? "'$_'" : "NULL";
	} $queue->{queueid}, $queue->{'message-id'}, $queue->{uid}
	  , $queue->{client})
	, qq{);\n};
    },
    @files
  );
  print "END;\n";
  "";
}

sub group_by_queueid {
  my ($this, @files) = @_;
  $this->do_group_by_queueid(
    sub {
      my ($queue) = @_;
      print Dumper($queue), "\n";
    },
    @files
  );
}

sub do_group_by_queueid {
  my ($this, $sub, @files) = @_;
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


    my $queue = $queue{$queueid} //= +{queueid => $queueid};

    if (my ($key) = $text =~ m{^(from|to)=}) {
      # ', ' で区切られているケース.

      # 末尾の (...) を捨てる (s/パターン/置換文字列/ は置換)
      $text =~ s/\s+(\(.*\))$//;
      my $comment = $1;

      my @elems = split /, /, $text;
      my $kv = +{map {split /=/, $_, 2} @elems};
      $kv->{comment} = $comment;

      push @{$queue->{$key}}, $kv;

    } elsif (($key, my $rest) = $text =~ m{^(uid|message-id|client)=(.*)}) {
      $queue->{$key} = $rest;
      # ' '
    } elsif ($text eq 'removed') {

      # レコードが完結したら、 $sub を呼び出す。
      $sub->($queue);

    } else {
      push @{$queue->{other}}, $text;
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
