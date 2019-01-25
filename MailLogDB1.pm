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

sub maillog_of_email {
  (my MY $self, my $email) = @_;

  $self->fetchall_hashref(
    $self->sql_maillog_of_email($email)
  );
}

sub sql_maillog_of_email {
  (my MY $self, my $email) = @_;
  # "", qq{} は $変数や \x が中で使える
  # '', q{} は↑これらも使えない
  my $sql = q{with qid_email as (
  select qid, email_id from "from" where email_id = (select email_id from email where email = ?)
  union
  select qid, email_id from "to" where email_id = (select email_id from email where email = ?)
)

select * from maillog
left join "to" on maillog.qid = "to".qid and ("to".qid , "to".email_id) in (select * from qid_email)
left join  "from" on maillog.qid = "from".qid and ("from".qid, "from".email_id) in  (select * from qid_email)
where maillog.qid in (select qid from qid_email)
};

  ($sql, $email, $email);
}

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
