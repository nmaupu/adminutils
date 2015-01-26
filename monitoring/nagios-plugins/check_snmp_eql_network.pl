#!/usr/bin/perl -w
# nagios: -epn
# adminutils - Scripts and resources for admins
# Copyright (C) 2015  nmaupu_at_gmail_dot_com
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
## check_snmp_eql_network is script to monitor network interfaces of Equallogic SANs through SNMP
## Author: nmaupu@gmail.com
## Version: 1.0
####################
#
# help: ./check_snmp_eql_network -h

use strict;
use Net::SNMP;
use Getopt::Long;
use Nagios::Plugin;
use Data::Dumper;

my $NAME="check_snmp_eql_network";
my $VERSION="1.0";

## Opts
my $np = Nagios::Plugin->new(
  usage => "Usage: $NAME [--host|-H <host>] [--port|-p <port>] [--community|-C <community>] [--if|-i ifname]",
  version => $VERSION,
  blurb => 'Check Equallogic network if status through SNMP'
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
  spec     => 'if|i=s',
  help     => 'if name to retrieve information for',
  required => 1,
);

$np->getopts();

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
## IF-MIB::ifOperStatus
my $oid_ifs_index       = '.1.3.6.1.2.1.2.2.1.2';
my $oid_if_oper_status  = '.1.3.6.1.2.1.2.2.1.8';
my $oid_if_mtu          = '.1.3.6.1.2.1.2.2.1.4';
my $oid_if_in_octets    = '.1.3.6.1.2.1.2.2.1.10';
my $oid_if_out_octets   = '.1.3.6.1.2.1.2.2.1.16';
my $oid_if_in_errors    = '.1.3.6.1.2.1.2.2.1.14';
my $oid_if_out_errors   = '.1.3.6.1.2.1.2.2.1.20';
my $oid_if_in_discards  = '.1.3.6.1.2.1.2.2.1.13';
my $oid_if_out_discards = '.1.3.6.1.2.1.2.2.1.19';


## IF status code
my ($IF_UP, $IF_DOWN, $IF_TESTING) = (1, 2, 3);

$session->translate(Net::SNMP->TRANSLATE_NONE);

my $if_names = $session->get_table(-baseoid => $oid_ifs_index);

if (!defined($if_names)) {
  $np->nagios_die("Error getting values from SNMP, timeout reaching host.\n");
}

my ($key, $value,$idx) = (0,0,-1);
while (($key, $value) = each(%{$if_names})) {
  if($value eq $np->opts->if) {
    $key =~ /.*\.([0-9+])/;
    $idx = $1;
  }
}

if($idx == -1) {
  $np->nagios_die("ERROR: Interface '".$np->opts->if."' not found.\n");
}

## Getting values
my $oid_status       = $oid_if_oper_status.".".$idx;
$oid_if_mtu          = $oid_if_mtu.".".$idx;
$oid_if_in_octets    = $oid_if_in_octets.".".$idx;
$oid_if_out_octets   = $oid_if_out_octets.".".$idx;
$oid_if_in_errors    = $oid_if_in_errors.".".$idx;
$oid_if_out_errors   = $oid_if_out_errors.".".$idx;
$oid_if_in_discards  = $oid_if_in_discards.".".$idx;
$oid_if_out_discards = $oid_if_out_discards.".".$idx;

my $result = $session->get_request(-varbindlist => [
	$oid_status,
	$oid_if_mtu,
	$oid_if_in_octets,
	$oid_if_out_octets,
	$oid_if_in_errors,
	$oid_if_out_errors,
	$oid_if_in_discards,
	$oid_if_out_discards
]);

$np->add_perfdata(
  label => $np->opts->if.' in octets',
  value => $result->{$oid_if_in_octets},
  uom   => 'c',
);

$np->add_perfdata(
  label => $np->opts->if.' out octets',
  value => $result->{$oid_if_out_octets},
  uom   => 'c',
);

$np->add_perfdata(
  label => $np->opts->if.' in errors',
  value => $result->{$oid_if_in_errors},
  uom   => 'c',
);

$np->add_perfdata(
  label => $np->opts->if.' out errors',
  value => $result->{$oid_if_out_errors},
  uom   => 'c',
);

$np->add_perfdata(
  label => $np->opts->if.' in discards',
  value => $result->{$oid_if_in_discards},
  uom   => 'c',
);

$np->add_perfdata(
  label => $np->opts->if.' out discards',
  value => $result->{$oid_if_out_discards},
  uom   => 'c',
);

my $if_status = $result->{$oid_status};
my $mtu = $result->{$oid_if_mtu};
my ($nagios_retcode, $nagios_message);
my $message_interface = "Interface ".$np->opts->if." (mtu=".$mtu.")";

if($if_status == $IF_UP) {
  $nagios_retcode = OK;
  $nagios_message = $message_interface." is UP";
} elsif($if_status == $IF_DOWN || $if_status == $IF_TESTING) {
  $nagios_retcode = CRITICAL;
  $nagios_message = $message_interface." is DOWN";
}

$np->nagios_exit($nagios_retcode, $nagios_message);

__END__
