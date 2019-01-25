#!/usr/bin/env perl
package MailLogDB1;
use strict;
use MOP4Import::Base::CLI_JSON -as_base
  , [fields =>
       qw/dbname
	  _DBH
	 /
   ];

use DBI;

#========================================


sub fetchall_hashref {
  (my MY $self, my ($sql, @bind)) = @_;
  my $sth = $self->DB->prepare($sql);
  $sth->execute(@bind);
  my @res;
  while (my $row = $sth->fetchrow_hashref) {
    push @res, $row;
  }
  @res;
}

sub DB {
  (my MY $self) = @_;

  $self->{_DBH} //= do {
    # 初回の DB() の呼び出し時に SQLite への接続を作る
    DBI->connect("dbi:SQLite:dbname=$self->{dbname}", '', '',
		 {PrintError => 0, RaiseError => 1, AutoCommit => 1});
  };
}

MY->run(\@ARGV) unless caller;

1;
