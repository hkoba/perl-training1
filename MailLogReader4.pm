#!/usr/bin/env perl
package MailLogReader4;
use strict;

# BEGIN {
#   unshift @INC, "......./training1/";
# }
use File::AddInc;

use MOP4Import::Base::CLI_JSON -as_base;

MY->run(\@ARGV) unless caller;

1;
