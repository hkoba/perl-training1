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

#========================================

sub after_new {
  (my MY $self) = @_;
  $self->SUPER::after_new;
  $self->{year} //= localtime->year;
}

MY->run(\@ARGV) unless caller;

1;
