#!/usr/bin/perl -w
# nagios: -epn
# adminutils - Scripts and resources for admins
# Copyright (C) 2012  nmaupu_at_gmail_dot_com
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
####################
## check_snmp_jvm_gc is script providing an efficient way for requesting jmx values using snmp
## Author: nmaupu@gmail.com
## Version: 1.0
####################
#
# help: ./check_snmp_jvm_gc -h

use strict;
use Net::SNMP;
use Getopt::Long;
use Nagios::Plugin;
use Data::Dumper;

my $NAME="check_snmp_jvm_memory";
my $VERSION="1.0";

## Opts
my $np = Nagios::Plugin->new(
  usage => "Usage: $NAME [--host|-H <host>] [--port|-p <port>] [--community|-C <community>]",
  version => $VERSION,
  blurb => 'Check jvm Sun Hotspot Garbage Collector usage through SNMP'
);

$np->add_arg(
  spec     => 'host|H=s',
  help     => "Host to connect to",
  required => 1,
);
$np->add_arg(
  spec     => 'port|p=i',
  help     => "Port to use for connection",
  required => 1,
);
$np->add_arg(
  spec     => 'community|C=s',
  help     => 'SNMP community to use',
  required => 1,
);

$np->getopts();

##

my ($session, $error) = Net::SNMP->session(
      -hostname  => $np->opts->host,
      -port      => $np->opts->port,
      -community => $np->opts->community,
      -version   => '2',
      -timeout   => 10,
    );

if (!defined($session)) {
  $np->nagios_die("ERROR: %s.\n", $error);
}

## names oid
my $oid_mem_gc_values = '.1.3.6.1.4.1.42.2.145.3.163.1.1.2.101.1';
my $oid_mem_gc_names  = '.1.3.6.1.4.1.42.2.145.3.163.1.1.2.100.1.2';
my $oid_mem_gc_states = '.1.3.6.1.4.1.42.2.145.3.163.1.1.2.100.1.3';

$session->translate(Net::SNMP->TRANSLATE_NONE);
my $result_values = $session->get_table(-baseoid => $oid_mem_gc_values);
my $result_names  = $session->get_table(-baseoid => $oid_mem_gc_names);
my $result_states = $session->get_table(-baseoid => $oid_mem_gc_states);

my $gc2_name  = $result_names->{$oid_mem_gc_names.'.2'};
my $gc3_name  = $result_names->{$oid_mem_gc_names.'.3'};
my $gc2_state = $result_states->{$oid_mem_gc_states.'.2'};
my $gc3_state = $result_states->{$oid_mem_gc_states.'.3'};
my $gc2_count = $result_values->{$oid_mem_gc_values.'.2.2'};
my $gc3_count = $result_values->{$oid_mem_gc_values.'.2.3'};
my $gc2_time  = $result_values->{$oid_mem_gc_values.'.3.2'};
my $gc3_time  = $result_values->{$oid_mem_gc_values.'.3.3'};

$np->add_perfdata(
  label   => $gc2_name." count",
  value   => $gc2_count,
  uom     => 'c',
);
$np->add_perfdata(
  label   => $gc3_name.' count',
  value   => $gc3_count,
  uom     => 'c',
);
$np->add_perfdata(
  label   => $gc2_name.' time',
  value   => $gc2_time,
  uom     => 'c',
);
$np->add_perfdata(
  label   => $gc3_name.' time',
  value   => $gc3_time,
  uom     => 'c',
);
$np->add_perfdata(
  label   => $gc2_name.' state',
  value   => $gc2_state,
);
$np->add_perfdata(
  label   => $gc3_name.' state',
  value   => $gc3_state,
);

my $exit_status = OK;
my $message = "GC status";
if($gc2_state < 2 || $gc3_state < 2) {
  $exit_status = CRITICAL;
  $message .= " problem";
} else {
  $message .= " ok";
}

$np->nagios_exit($exit_status, $message);

__END__
