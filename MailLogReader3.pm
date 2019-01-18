#!/usr/bin/env perl
package MailLogReader3;
use strict;

use Data::Dumper;

sub emit_sql_insert0 {
  my ($this, @files) = @_;
  print "BEGIN;\n";
  $this->do_group_by_queueid(
    sub {
      my ($queue) = @_;
      my $VALUES = join(",", map {
	defined $_ ? "'$_'" :"NULL";
      } $queue->{queueid}, $queue->{'message-id'}, $queue->{uid}, $queue->{client});
      print qq{insert into maillog(queue_id, message_id, uid, client) values($VALUES);\n};
      my $to_data = $queue->{to};
      foreach my $i (@$to_data) {
	my $VALUES_2 = join(",", map {
	  if (defined $_) {
	    s/'/''/g; # substitute
	    "'$_'"
	  } else {
	    "NULL";
	  }
	} $queue->{queueid}, $i->{status}, $i->{to}, $i->{delays}, $i->{comment}, $i->{delay}, $i->{dsn}, $i->{relay});
	print qq{insert into to_data(queue_id, status, to_address, delays, comment, delay, dsn, relay) values($VALUES_2);\n};
      }
      my $from_data = $queue->{from};
      foreach my $f (@$from_data) {
	my $VALUES_3 = join(",", map {
	  if (defined $_) {
	    s/'/''/g; # substitute
	    "'$_'"
	  } else {
	    "NULL";
	  }
	} $queue->{queueid}, $f->{'from'}, $f->{nrcpt}, $f->{size}, $f->{comment});
	print qq{insert into from_data(queue_id, from_address, nrcpt, size, comment) values($VALUES_3);\n};
      }
    },
    @files
  );
  print "END;\n";
  "";
}



# 構造確認用の関数という認識であってますよね？
sub group_by_queueid {
  my ($this, @files) = @_;
  $this->do_group_by_queueid( # ここもわからなかった...do_group_by_queueidに@filesを入れている?
    sub {
      my ($queue) = @_;
      # print $queue->{queueid};
      print Dumper($queue), "\n";
      # ここから編集
      # my $to_data = $queue->{to};
      # foreach my $i (@$to_data) {
      # 	print "BEGIN;\n";
      # 	print "$queue->{queueid}, $i->{status}, $i->{to}, $i->{delays}, $i->{comment}, $i->{delay}, $i->{dsn}, $i->{relay}, $i->{text} \n";
      # 	foreach my $key (keys %$i){
      # 	  my $value = $i->{$key};
      # 	  print "$key => $value\n";
      # 	}
      # }
      print "END;\n";
      # foreach my $i (@$to_data) {
      # 	my $VALUES_2 = join(",", map {
      # 	  defined $_ ? "'$_'" :"NOT NULL"; #ここがよくわからない
      # 	} $queue->{queueid}, $i->{status}, $i->{to_address}, $i->{delays}, $i->{comment}, $i->{delay}, $i->{dsn}, $i->{relay}, $i->{text});
      # 	print qq{insert into to_data(queue_id, status, to_address, delays, comment, delay, dsn, relay, text_data) values($VALUES_2);\n};
      # }
    },
    @files
  );
}

sub do_group_by_queueid{
  my ($this, $sub, @files) = @_;
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
      
      my @elems = split /\s*,\s*/, $text;
      my $kv = +{map {split /=/, $_, 2} @elems}; #$_,2何者なのかがわからない
      $kv->{comment} = $comment; #'status' => 'bounced',の構造を作っている？＄１が何者なのかわからなかったのでここも理解できていなかった。
      
      push @{$queue->{$key}}, $kv; # ifでつくった$key(to|from)に$kvを入れている？
      
    } elsif (($key, my $rest) = $text =~ m{^(uid|message-id|client)=(.*)}) { #=(.*)のぶぶんがどんな処理なのかわからない
      $queue->{$key} = $rest;
    } elsif ($text eq 'removed') {
      $sub->($queue); # subを呼び出すというのがどういった処理になるのかがわからない
      # print Dumper($queue), "\n";
    } else {
      push @{$queue->{other}}, $text;
    }
  }
}

unless (caller) {
  my $method = $ARGV[0];
  print MailLogReader3->$method(@ARGV[1..$#ARGV]), "\n";
  print "\n";
}

1;
