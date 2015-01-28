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
## check_snmp_eql_member_stats is script to monitor member stats on an EQL storage array
## Author: nmaupu@gmail.com
## Version: 1.0
####################
#
# help: ./check_snmp_eql_member_stats -h

use strict;
use Net::SNMP;
use Getopt::Long;
use Nagios::Plugin;
use Data::Dumper;

my $NAME="check_snmp_eql_member_stats";
my $VERSION="1.0";

## Opts
my $np = Nagios::Plugin->new(
  usage => "Usage: $NAME [--host|-H <host>] [--port|-p <port>] [--community|-C <community>] [--name|-n <membername>] [--readwarning|-r <readwarning>] [--readcritical|-R <critical>] [--writewarning|-w <writewarning>] [--writecritical|-W <writecritical>]",
  version => $VERSION,
  blurb => 'Check Equallogic member\'s statistics'
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
  spec     => 'name|n=s',
  help     => 'Member\'s name to check raid for',
  required => 1,
);
$np->add_arg(
  spec     => 'readwarning|r=s',
  help     => 'Latency warning read avg (milliseconds)',
  required => 1,
);
$np->add_arg(
  spec     => 'readcritical|R=s',
  help     => 'Latency critical read avg (milliseconds)',
  required => 1,
);
$np->add_arg(
  spec     => 'writewarning|w=s',
  help     => 'Latency critical write avg (milliseconds)',
  required => 1,
);
$np->add_arg(
  spec     => 'writecritical|W=s',
  help     => 'Latency critical write avg (milliseconds)',
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
my $oid_members_name = '.1.3.6.1.4.1.12740.2.1.1.1.9.1';

## RAID status code
my ($RAID_OK, $RAID_DEGRADED, $RAID_VERIFYING, $RAID_RECONSTRUCTING, $RAID_FAILED, $RAID_CATASTROPHIC_LOSS, $RAID_EXPANDING, $RAID_MIRRORING) = (1, 2, 3, 4, 5, 6, 7, 8);

## Determining member index from member's name
$session->translate(Net::SNMP->TRANSLATE_NONE);
my $members_name = $session->get_table(-baseoid => $oid_members_name);

if (!defined($members_name)) {
  $np->nagios_die("Error getting values from SNMP, timeout reaching host.\n");
}

my ($key, $value, $idx) = (0,0,-1);
while (($key, $value) = each(%{$members_name})) {
  if($value eq $np->opts->name) {
    $key =~ /.*\.([0-9]+)/;
    $idx = $1;
  }
}

if($idx == -1) {
  $np->nagios_die("ERROR: Member '".$np->opts->name."' not found.\n");
}

## Warning, I suppose there is only one group available !!!
my $group_id = 1;

## Getting values
my $oid_stats_read_latency      = '.1.3.6.1.4.1.12740.2.1.12.1.2.'.$group_id.'.'.$idx;
my $oid_stats_write_latency     = '.1.3.6.1.4.1.12740.2.1.12.1.3.'.$group_id.'.'.$idx;
my $oid_stats_read_avg_latency  = '.1.3.6.1.4.1.12740.2.1.12.1.4.'.$group_id.'.'.$idx;
my $oid_stats_write_avg_latency = '.1.3.6.1.4.1.12740.2.1.12.1.5.'.$group_id.'.'.$idx;
my $oid_stats_read_op_count     = '.1.3.6.1.4.1.12740.2.1.12.1.6.'.$group_id.'.'.$idx;
my $oid_stats_write_op_count    = '.1.3.6.1.4.1.12740.2.1.12.1.7.'.$group_id.'.'.$idx;
my $oid_stats_tx_data           = '.1.3.6.1.4.1.12740.2.1.12.1.8.'.$group_id.'.'.$idx;
my $oid_stats_rx_data           = '.1.3.6.1.4.1.12740.2.1.12.1.9.'.$group_id.'.'.$idx;


my $result = $session->get_request(-varbindlist => [
	$oid_stats_read_latency,
	$oid_stats_write_latency,
	$oid_stats_read_avg_latency,
	$oid_stats_write_avg_latency,
	$oid_stats_read_op_count,
	$oid_stats_write_op_count,
	$oid_stats_tx_data,
	$oid_stats_rx_data
]);


$np->add_perfdata(
  label => 'read latency',
  value => $result->{$oid_stats_read_latency},
  uom   => 'c',
);
$np->add_perfdata(
  label => 'write latency',
  value => $result->{$oid_stats_write_latency},
  uom   => 'c',
);
$np->add_perfdata(
  label => 'read avg latency',
  value => $result->{$oid_stats_read_avg_latency},
  uom   => 'ms',
);
$np->add_perfdata(
  label => 'write avg latency',
  value => $result->{$oid_stats_write_avg_latency},
  uom   => 'ms',
);
$np->add_perfdata(
  label => 'read op count',
  value => $result->{$oid_stats_read_op_count},
  uom   => 'c',
);
$np->add_perfdata(
  label => 'write op count',
  value => $result->{$oid_stats_write_op_count},
  uom   => 'c',
);
$np->add_perfdata(
  label => 'tx data',
  value => $result->{$oid_stats_tx_data},
  uom   => 'c',
);
$np->add_perfdata(
  label => 'rx data',
  value => $result->{$oid_stats_rx_data},
  uom   => 'c',
);

my ($nagios_status, $nagios_message) = (OK, "");

if($result->{$oid_stats_read_avg_latency} >= $np->opts->readcritical || $result->{$oid_stats_write_avg_latency} >= $np->opts->writecritical) {
  $nagios_status = CRITICAL;
  my $type = $result->{$oid_stats_read_avg_latency} >= $np->opts->readcritical ? 'read' : 'write';
  $nagios_message = $type." latency avg critical";
} elsif($result->{$oid_stats_read_avg_latency} >= $np->opts->readwarning || $result->{$oid_stats_write_avg_latency} >= $np->opts->writewarning) {
  $nagios_status = WARNING;
  my $type = $result->{$oid_stats_read_avg_latency} >= $np->opts->readwarning ? 'read' : 'write';
  $nagios_message = $type." latency avg warning";
} else {
  $nagios_status = OK;
  $nagios_message = "read / write avg latency OK";
}

$np->nagios_exit($nagios_status, $nagios_message);

__END__
