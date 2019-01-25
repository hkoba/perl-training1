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
		  _prev_epoch/];

use Time::Piece;
use Time::Local;


#========================================

sub after_new {
  (my MY $self) = @_;
  $self->SUPER::after_new;
  $self->{year} //= localtime->year;
}

#========================================

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
