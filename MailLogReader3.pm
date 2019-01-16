#!/usr/bin/env perl
package MailLogReader3;
use strict;

use Data::Dumper;

sub group_by_queueid{
  my ($this, @files) = @_;
  local @ARGV = @files;
  local $_;

  my %queue;
  while (<>) {
    chomp;
    my ($month, $day, $H, $M, $S, $host, $prog, $pid, $queueid, $text)
      = m{^
	  (\w+) \s+ (\d+)\s+
          (\d+):(\d+):(\d+)\s+
	  ([-\.\w]+)\s+
          postfix/(\w+)\[(\d+)\]:\s+
	  ([\dA-F]+):\s+
          (.*)
       }x
	 or next;
    
    my $queue = $queue{$queueid} //= +{queueid => $queueid}; #記号部分と$queue{$queueid}がよくわからない
    
    if (my ($key) = $text =~ m{^(from|to)=}) {
      
      $text =~ s/\s+(\(.*\))$//; # *がわからない,スペース,().$
      my $comment = $1; # $1はどこから・・・
      
      my @elems = split /,/, $text;
      my $kv = +{map {split /=/, $_, 2} @elems}; #$_,2なんの関数なのかがわからない
      $kv->{comment} = $comment;
      
      push @{$queue->{$key}}, $kv;
      
    } elsif (($key, my $rest) = $text =~ m{^(uid|message-id|client)=(.*)}) { #=(.*)のぶぶんがどんな処理なのかわからない
      $queue->{$key} = $rest;
    } elsif ($text eq 'removed') { #eqの処理内容がわからない
      print Dumper($queue), "\n";# subを呼び出すというのがどういった処理になるのかがわからない
    } else {
      push @{$queue->{other}}, $text;
    }
  }
}

1;
