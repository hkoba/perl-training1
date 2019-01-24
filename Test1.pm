#!/usr/bin/env perl
package Test1;
use strict;
use File::AddInc;
sub MY () {__PACKAGE__}

use base 'MailLogReader3';
use Time::Piece;

sub dummy {
  print qq{2018-12-19 03:18:55	3
2018-12-23 03:50:19	5
2018-12-29 04:00:09	6
};
  "";
}

sub new {
  my ($class) = @_;
  my MY $self = $class->SUPER::new;
  $self->{year} = localtime->year;
  $self;
}

unless (caller) {

  my MY $obj = MY->new;

  my $method = $ARGV[0];
  print $obj->$method(@ARGV[1..$#ARGV]), "\n";
  print "\n";
}


1;
