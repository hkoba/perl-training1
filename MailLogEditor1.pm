#!/usr/bin/env perl
package MailLogEditor1;
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

# unless (caller) {
#   print foo(), "\n";
# }

# unless (caller) {
#   print "ARGV is: ", @ARGV, "\n";
# }

unless (caller) {
  my $method = $ARGV[0];
  print MailLogEditor1->$method(@ARGV[1..$#ARGV]), "\n";
}

1;
