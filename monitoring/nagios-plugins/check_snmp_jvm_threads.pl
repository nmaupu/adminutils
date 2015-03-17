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
## check_snmp_jvm_threads get threads values from remote JVM through SNMP
## Author: nmaupu_at_gmail_dot_com
## Version: 1.0
####################
#
# help: ./check_snmp_jvm_threads -h

use strict;
use Net::SNMP;
use Getopt::Long;
use Nagios::Plugin;
use Data::Dumper;

my $NAME="check_snmp_jvm_threads";
my $VERSION="1.0";

## Opts
my $np = Nagios::Plugin->new(
  usage => "Usage: $NAME [--host|-H <host>] [--port|-p <port>] [--community|-C <community>] [--type|-y <heap|nonheap>] [-c|--critical <critial>] [-w|--warning <warning>]",
  version => $VERSION,
  blurb => 'Check JVM threads through SNMP'
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
$np->add_arg(
  spec     => 'critical|c=i',
  help     => 'Critical threshold',
  required => 1,
);
$np->add_arg(
  spec     => 'warning|w=i',
  help     => 'Warning threshold',
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

# OIDs
my $oid_threads_count = '.1.3.6.1.4.1.42.2.145.3.163.1.1.3.1.0';
my $oid_threads_daemon_count = '.1.3.6.1.4.1.42.2.145.3.163.1.1.3.2.0';
my $oid_threads_peak = '.1.3.6.1.4.1.42.2.145.3.163.1.1.3.3.0';
my $oid_threads_total_started_count = '.1.3.6.1.4.1.42.2.145.3.163.1.1.3.4.0';

$session->translate(Net::SNMP->TRANSLATE_NONE);
my $result = $session->get_request(-varbindlist => 
  [$oid_threads_count, $oid_threads_daemon_count, $oid_threads_peak, $oid_threads_total_started_count]);

my $threads_count = $result->{$oid_threads_count};
my $threads_daemon_count = $result->{$oid_threads_daemon_count};
my $threads_peak = $result->{$oid_threads_peak};
my $threads_total_started_count = $result->{$oid_threads_total_started_count};

$np->add_perfdata(
  label => 'threads count',
  value => $threads_count,
  uom   => 'T',
  warning => $np->opts->warning,
  critical => $np->opts->critical
);


$np->add_perfdata(
  label => 'threads daemon count',
  value => $threads_daemon_count,
  uom   => 'T'
);

$np->add_perfdata(
  label => 'threads peak',
  value => $threads_peak,
  uom   => 'T'
);

$np->add_perfdata(
  label => 'threads total started count',
  value => $threads_total_started_count,
  uom   => 'T'
);

my $exit_status = OK;
if($threads_count > $np->opts->critical) {
  $exit_status = CRITICAL;
} elsif($threads_count > $np->opts->warning) {
  $exit_status = WARNING;
}

$np->nagios_exit($exit_status, "JVM threads count : $threads_count");

__END__
