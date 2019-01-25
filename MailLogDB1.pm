#!/usr/bin/env perl
package MailLogDB1;
use strict;
use MOP4Import::Base::CLI_JSON -as_base
  ;

MY->run(\@ARGV) unless caller;

1;
