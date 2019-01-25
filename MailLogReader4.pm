#!/usr/bin/env perl
package MailLogReader4;
use strict;
use utf8;

# BEGIN {
#   unshift @INC, "......./training1/";
# }
use File::AddInc;

use MOP4Import::Base::CLI_JSON -as_base
  , [fields => ['year' => doc => "年度を指定"],
	       qw/foo
		  bar
		  _queueid_dict
		  _email_dict
		  _prev_epoch/];
use MOP4Import::Types
  (QItem => [[fields => qw(queueid from to uid message-id client other first_epoch)]],
   From => [[fields => qw(from nrcpt size comment)]],
   To => [[fields => qw(status to delays comment delay dsn relay)]],
   );

use Time::Piece;
use Time::Local;


#========================================

sub after_new {
  (my MY $self) = @_;
  $self->SUPER::after_new;
  $self->{year} //= localtime->year;
}

#========================================

#
# cmd_... で始まる名前のメソッドは、この実行可能モジュールの正式な(CLI用の)コマンドとして扱われる
# 正式なCLI用コマンドは、
#   - 自分で入出力を管理する(特に出力処理)
#   - help のコマンド一覧に名前が出る

# sub safe_print {
#   print @_ or die;
# }

sub cmd_emit_sql_insert0 : Doc("SQL の INSERT文として出力") {
  (my MY $self, my @files) = @_;
  print "BEGIN;\n";
  $self->do_group_by_queueid(as_sql => @files);
  print "END;\n";
}

sub as_sql {
  (my MY $self, my QItem $queue) = @_;

  # テーブルqueueのインサート
  # my $queueid_sql; $queueid_expr; ...
  my $queueid_sql = $self->escape_or_null($queue->{'queueid'});
  print qq{INSERT INTO queueid(queue_id) values($queueid_sql);\n}
    if not $self->{_queueid_dict}{$queue->{'queueid'}}++;
  {
    # テーブルmaillogのインサート
    my $VALUES = join(",", $self->escape_or_null(
      $queue->{first_epoch}, $queue->{uid}, $queue->{client}, $queue->{'message-id'}));
    print qq{INSERT INTO maillog(qid, first_epoch, uid, client, "message-id" )
VALUES((SELECT qid FROM queueid WHERE queue_id = $queueid_sql),$VALUES);\n};
  }

  {
    # テーブルtoのインサート
    my $to_data = $queue->{to};
    foreach my To $i (@$to_data) {
      my $VALUES = join(",", $self->escape_or_null(
	$i->{status}, $i->{delays}, $i->{comment}, $i->{delay}, $i->{dsn}, $i->{relay}));
      my $escape_email = $self->escape_or_null($i->{to});
      print qq{INSERT INTO email(email) values($escape_email);\n}
	if not $self->{_email_dict}{$escape_email}++;
      print qq{insert into "to"(qid, email_id, status, delays, comment, delay, dsn, relay)
VALUES((SELECT qid FROM queueid WHERE queue_id = $queueid_sql), (SELECT email_id FROM email WHERE email = $escape_email), $VALUES);\n};
    }
  }

  {
    # テーブルfromのインサート
    my $from_data = $queue->{from};
    foreach my From $f (@$from_data) {
      my $VALUES = join(",", $self->escape_or_null(
	$f->{nrcpt}, $f->{size}, $f->{comment}
      ));
      my $escape_email = $self->escape_or_null($f->{from});
      print qq{INSERT INTO email(email) values($escape_email);\n}
	if not $self->{_email_dict}{$escape_email}++;
      print qq{insert into "from"(qid, email_id, nrcpt, size, comment)
values((SELECT qid FROM queueid WHERE queue_id = $queueid_sql), (SELECT email_id FROM email WHERE email = $escape_email), $VALUES);\n};
    }
  }

}

sub escape_or_null {
  my ($self, @args) = @_;
  my @result = map {
    if (defined $_) {
      $_ =~ s/'/''/g; # substitute
      "'$_'"
    } else {
      "NULL";
    }
  } @args;
  wantarray ? @result : $result[0];
}

#========================================

sub do_something {
  (my MY $self, my @args) = @_;
  my %summary;
  foreach my $dict (@args) {
    foreach my $key (keys %$dict) {
      $summary{$key} += $dict->{$key};
    }
  }
  \%summary;
}

sub cli_apply {
  (my MY $self, my ($subSpec, @args)) = @_;
  if (not defined $subSpec
	or (not ref $subSpec)) {
    my $method = $subSpec || 'cli_output';
    $self->$method(@args);
  }
  elsif (ref $subSpec eq 'CODE') {
    $subSpec->(@args);
  }
  elsif (ref $subSpec eq 'ARRAY') {
    my ($method, @prefix) = @$subSpec;
    $self->$method(@prefix, @args);
  }
  else {
    Carp::croak "Invalid subSpec: $subSpec";
  }
}

sub do_group_by_queueid {
  (my MY $self, my ($sub, @files)) = @_;
  local @ARGV = @files;
  local $_;

  my %queue;
  while (<>) {
    chomp;
    my ($dateTime, $monthName, $day, $H, $M, $S, $host, $prog, $pid, $queueid, $text)
      = m{^
	  ((\w+) \s+ (\d+)\s+
	    (\d+):(\d+):(\d+))\s+
	  ([-\.\w]+)\s+
          postfix/(\w+)\[(\d+)\]:\s+
	  ([\dA-F]+):\s+
          (.*)
       }x
	 or next;

    my $epoch = $self->epoch_from_localtime(
      $S, $M, $H, $day, $monthName
    );

    my $queue = $queue{$queueid} //= +{
      queueid => $queueid,
      first_datetime => $dateTime,
      first_datetime_epoch => $epoch,
    }; #記号部分と$queue{$queueid}がよくわからない
    
    if (my ($key) = $text =~ m{^(from|to)=}) {
      
      $text =~ s/\s+(\(.*\))$//; # *がわからない,スペース,().$
      my $comment = $1; # $1はどこから・・・
      
      my @elems = split /\s*,\s*/, $text;
      my $kv = +{map {split /=/, $_, 2} @elems}; #$_,2何者なのかがわからない
      $kv->{comment} = $comment; #'status' => 'bounced',の構造を作っている？＄１が何者なのかわからなかったのでここも理解できていなかった。
      $kv->{datetime} = $dateTime;
      $kv->{first_epoch} = $epoch;
      $kv->{$key} =~ s/^<|>$//g;

      push @{$queue->{$key}}, $kv; # ifでつくった$key(to|from)に$kvを入れている？
      
    } elsif (($key, my $rest) = $text =~ m{^(uid|message-id|client)=(.*)}) { #=(.*)のぶぶんがどんな処理なのかわからない
      $queue->{$key} = $rest;
    } elsif ($text eq 'removed') {
      $self->cli_apply($sub, $queue); # subを呼び出すというのがどういった処理になるのかがわからない
      delete $queue{$queueid};
      # print Dumper($queue), "\n";
    } else {
      push @{$queue->{other}}, $text;
    }
  }

  foreach my $queueid (keys %queue) {
    my $queue = delete $queue{$queueid};
    $self->cli_apply($sub, $queue)
  }
}

our %MONTH = qw(Jan 1 Feb 2 Mar 3 Apr 4 May 5 Jun 6 Jul 7 Aug 8 Sep 9 Oct 10 Nov 11 Dec 12);

sub epoch_from_localtime {
  (my MY $self, my ($S, $M, $H, $day, $monthName, $year)) = @_;
  my $yearRef = defined $year ? \$year : \$self->{year};
  my $epoch = timelocal($S, $M, $H, $day, $MONTH{$monthName} - 1
			, $$yearRef);
  if ($self->{_prev_epoch} and ($self->{_prev_epoch} - $epoch) > (3600*24)) {
    $$yearRef++;
    $epoch = timelocal($S, $M, $H, $day, $MONTH{$monthName} - 1
			 , $$yearRef);
  }
  $self->{_prev_epoch} = $epoch;
  $epoch;
}

#========================================

MY->run(\@ARGV) unless caller;

1;
