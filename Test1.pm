#!/usr/bin/env perl
package Test1;
use strict;
use File::AddInc;
sub MY () {__PACKAGE__}

use base 'MailLogReader3';
use Time::Piece;

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
