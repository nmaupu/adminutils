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
## check_snmp_if monitors unix network interfaces
## Author: nmaupu@gmail.com
## Version: 1.0
####################
#
# help: ./check_snmp_if -h

use strict;
use Net::SNMP;
use Getopt::Long;
use Nagios::Plugin;
use Data::Dumper;

my $NAME="check_snmp_if";
my $VERSION="1.0";

## Opts
my $np = Nagios::Plugin->new(
  ##usage => "Usage: $NAME [--host|-H <host>] [--port|-p <port>] [--community|-C <community>] [-c|--critical <critical>] [-w|--warning <warning>] [--if|-i <interface name>]",
  usage => "Usage: $NAME [--host|-H <host>] [--port|-p <port>] [--community|-C <community>] [--if|-i <interface name>]",
  version => $VERSION,
  blurb => 'Check interface traffic',
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
  required => 0,
);
$np->add_arg(
  spec     => 'warning|w=s',
  help     => 'Warning threshold',
  required => 0,
);
$np->add_arg(
  spec     => 'if|i=s',
  help     => 'Interface name',
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

## OIDs
my $oid_if_names   = ".1.3.6.1.2.1.31.1.1.1.1";
my $oid_in_values  = ".1.3.6.1.2.1.31.1.1.1.6";
my $oid_out_values = ".1.3.6.1.2.1.31.1.1.1.10";

## Looking for if name
my $if_names = $session->get_table(-baseoid => $oid_if_names);

my ($key,$value, $idx) = (0,0,-1);
while (($key, $value) = each(%{$if_names})) {
  if($value eq $np->opts->if) {
    $key =~ /.*\.([0-9]+)/;
    $idx = $1;
  }
}

if($idx == -1) {
  $np->nagios_die("ERROR: Interface '".$np->opts->if."' not found.\n");
}


## Getting values
my $oid_in_if_values = "$oid_in_values.$idx";
my $oid_out_if_values = "$oid_out_values.$idx";

my $result = $session->get_request(-varbindlist => [$oid_in_if_values, $oid_out_if_values]);

my $in  = $result->{$oid_in_if_values};
my $out = $result->{$oid_out_if_values};

$np->add_perfdata(
  label => $np->opts->if." inbound",
  value => $in,
  uom   => 'c'
);
$np->add_perfdata(
  label => $np->opts->if." outbound",
  value => $out,
  uom   => 'c'
);

$np->nagios_exit(OK, $np->opts->if." In=${in}B, Out=${out}B");

__END__
