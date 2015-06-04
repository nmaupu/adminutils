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
## check_snmp_memory is script to monitor RAM memory through SNMP
## Author: nmaupu_at_gmail_dot_com
## Version: 1.0
####################
#
# help: ./check_snmp_memory -h

use strict;
use Net::SNMP;
use Getopt::Long;
use Nagios::Plugin;
use Data::Dumper;

my $NAME="check_snmp_memory";
my $VERSION="1.0";

## Opts
my $np = Nagios::Plugin->new(
  usage => "Usage: $NAME [--host|-H <host>] [--port|-p <port>] [--community|-C <community>] [-c|--critical <critical>] [-w|--warning <warning>]",
  version => $VERSION,
  blurb => 'Check RAM memory through SNMP'
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

my $warning  = $np->opts->warning;
my $critical = $np->opts->critical;

##

my ($session, $error) = Net::SNMP->session(
      -hostname  => $np->opts->host,
      -port      => $np->opts->port,
      -community => $np->opts->community,
      -version   => '2',
      -timeout   => 3,
    );

if (!defined($session)) {
  $np->nagios_die("ERROR: %s.\n", $error);
}

## OIDs
my $oid_total    = '.1.3.6.1.4.1.2021.4.5.0';
my $oid_free     = '.1.3.6.1.4.1.2021.4.6.0';
my $oid_shared   = '.1.3.6.1.4.1.2021.4.13.0';
my $oid_buffered = '.1.3.6.1.4.1.2021.4.14.0';
my $oid_cached   = '.1.3.6.1.4.1.2021.4.15.0';
my $oid_swtotal  = '.1.3.6.1.4.1.2021.4.3.0';
my $oid_swfree   = '.1.3.6.1.4.1.2021.4.4.0';

$session->translate(Net::SNMP->TRANSLATE_NONE);

my $result = $session->get_request(-varbindlist => 
  [$oid_total, $oid_free, $oid_shared, $oid_buffered, $oid_cached, $oid_swtotal, $oid_swfree]);

if (!defined($result)) {
  $np->nagios_die("Error getting values from SNMP, timeout reaching host.\n");
}

## Values ares in KB !!!
my $ram_total     = $result->{$oid_total} ? $result->{$oid_total}*1024 : 0;
my $ram_free      = $result->{$oid_free} ? $result->{$oid_free}*1024 : 0;
## No shared info on some distros
my $ram_shared    = $result->{$oid_shared} ? $result->{$oid_shared}*1024 : 0;
my $ram_buffered  = $result->{$oid_buffered} ? $result->{$oid_buffered}*1024 : 0;
my $ram_cached    = $result->{$oid_cached} ? $result->{$oid_cached}*1024 : 0;
my $swap_total    = $result->{$oid_swtotal} ? $result->{$oid_swtotal}*1024 : 0;
my $swap_free     = $result->{$oid_swfree} ? $result->{$oid_swfree}*1024 : 0;
my $swap_used     = $swap_total - $swap_free;
my $ram_bufs      = $ram_shared + $ram_buffered + $ram_cached;
my $ram_used      = $ram_total - $ram_free + $ram_bufs;

my $percent_used  = $ram_total != 0 ? sprintf("%.2f", ($ram_used * 100) / $ram_total) : "undef";

my $warning_bytes  = ($ram_total * $np->opts->warning) / 100;
my $critical_bytes = ($ram_total * $np->opts->critical) / 100;

#printf("Ram total: %s, Ram free: %s, buf: %s, cached: %s, Ram used: %s\n", $ram_total, $ram_free, $ram_buffered, $ram_cached, $ram_used);


$np->add_perfdata(
  label    => 'free',
  value    => $ram_free,
  uom      => 'B'
);
$np->add_perfdata(
  label    => 'total',
  value    => $ram_total,
  uom      => 'B'
);
$np->add_perfdata(
  label    => 'shared',
  value    => $ram_shared,
  uom      => 'B'
);
$np->add_perfdata(
  label    => 'buffered',
  value    => $ram_buffered,
  uom      => 'B'
);
$np->add_perfdata(
  label    => 'cached',
  value    => $ram_cached,
  uom      => 'B'
);
$np->add_perfdata(
  label    => 'swap_total',
  value    => $swap_total,
  uom      => 'B'
);
$np->add_perfdata(
  label    => 'swap_free',
  value    => $swap_free,
  uom      => 'B'
);
$np->add_perfdata(
    label    => 'real_used',
    value    => $ram_used,
    uom      => 'B',
    warning  => $warning_bytes,
    critical => $critical_bytes,
    max      => $ram_total
);


my $percent_swap_used = $swap_total != 0 ? sprintf("%.2f", $swap_used*100 / $swap_total) : "undef";

my $exit_status = OK;

if($percent_used > $np->opts->critical) {
  $exit_status = CRITICAL;
} elsif($percent_used > $np->opts->warning || $percent_swap_used >= 10) {
  $exit_status = WARNING;
}

$np->nagios_exit($exit_status, "RAM used : $percent_used%, Swap used : $percent_swap_used%");

__END__

