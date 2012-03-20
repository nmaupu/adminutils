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
## check_snmp_load is script to monitor load average through snmp
## Author: nmaupu@gmail.com
## Version: 1.0
####################
#
# help: ./check_snmp_load -h

use strict;
use Net::SNMP;
use Getopt::Long;
use Nagios::Plugin;
use Data::Dumper;

my $NAME="check_snmp_load";
my $VERSION="1.0";

## Opts
my $np = Nagios::Plugin->new(
  usage => "Usage: $NAME [--host|-H <host>] [--port|-p <port>] [--community|-C <community>] [-c|--critical <CLOAD1,CLOAD5,CLOAD15>] [-w|--warning <WLOAD1,WLOAD5,WLOAD15>]",
  version => $VERSION,
  blurb => 'Check load average through SNMP'
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
  spec     => 'critical|c=s',
  help     => 'Critical threshold',
  required => 1,
);
$np->add_arg(
  spec     => 'warning|w=s',
  help     => 'Warning threshold',
  required => 1,
);

$np->getopts();

##
## Extracting warning and critical values
my $warning  = $np->opts->warning;
my $critical = $np->opts->critical;
my @w = split(/,/, $warning);
my @c = split(/,/, $critical);

my ($w1,$w5,$w15) = @w;
$w5 = $w1 if ! defined $w5;
$w15 = $w5 if ! defined $w15;
my ($c1,$c5,$c15) = @c;
$c5 = $c1 if ! defined $c5;
$c15 = $c5 if ! defined $c15;

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

## OIDs
my $oid_load  = '.1.3.6.1.4.1.2021.10.1.3';

$session->translate(Net::SNMP->TRANSLATE_NONE);
my $result = $session->get_table(-baseoid => $oid_load);

my $load1  = $result->{"${oid_load}.1"};
my $load5  = $result->{"${oid_load}.2"};
my $load15 = $result->{"${oid_load}.3"};


$np->add_perfdata(
  label    => "load1",
  value    => $load1,
  uom      => '',
  warning  => $w1,
  critical => $c1
);
$np->add_perfdata(
  label    => "load5",
  value    => $load5,
  uom      => '',
  warning  => $w5,
  critical => $c5
);
$np->add_perfdata(
  label    => "load15",
  value    => $load15,
  uom      => '',
  warning  => $w15,
  critical => $c15
);

my $exit_value = OK;
if($load1 > $c1 || $load5 > $c5 || $load15 > $c15) {
  $exit_value = CRITICAL;
} elsif($load1 > $w1 || $load5 > $w5 || $load15 > $w15) {
  $exit_value = WARNING;
}

$np->nagios_exit($exit_value, "load average: $load1, $load5, $load15");

__END__
