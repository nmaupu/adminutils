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
## check_snmp_eql_member_raid is script to monitor member raid status on an EQL storage array
## Author: nmaupu@gmail.com
## Version: 1.0
####################
#
# help: ./check_snmp_eql_member_raid -h

use strict;
use Net::SNMP;
use Getopt::Long;
use Nagios::Plugin;
use Data::Dumper;

my $NAME="check_snmp_eql_member_raid";
my $VERSION="1.0";

## Opts
my $np = Nagios::Plugin->new(
  usage => "Usage: $NAME [--host|-H <host>] [--port|-p <port>] [--community|-C <community>] [--name|-n <membername>]",
  version => $VERSION,
  blurb => 'Check Equallogic member raid status on an EQL storage array'
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
my $oid_raid_status  = '.1.3.6.1.4.1.12740.2.1.13.1.1.1';
my $oid_raid_percent = '.1.3.6.1.4.1.12740.2.1.13.1.2'; # if verifying or reconstructing

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

## Getting values
$oid_raid_status = $oid_raid_status.".".$idx;
$oid_raid_percent = $oid_raid_percent.".".$idx;
my $result = $session->get_request(-varbindlist => [$oid_raid_status, $oid_raid_percent]);


##
my $raid_status = $result->{$oid_raid_status};
my $percent = $result->{$oid_raid_percent} ? $result->{$oid_raid_percent} : 0;
my $nagios_message = "Member ".$np->opts->name." RAID status ";
my $nagios_status = OK;

if($raid_status == $RAID_CATASTROPHIC_LOSS || $raid_status == $RAID_FAILED) {
  $nagios_status = CRITICAL;
  $nagios_message .= "CATASTROPHIC LOSS" if $raid_status == $RAID_CATASTROPHIC_LOSS;
  $nagios_message .= "FAILED" if $raid_status == $RAID_FAILED;
} elsif($raid_status == $RAID_OK) {
  $nagios_status = OK;
  $nagios_message .= "OK";
} else {
  ## All other statuses -> WARNING (attention required)
  $nagios_status = WARNING;
  $nagios_message .= "VERIFYING (".$percent."%)" if $raid_status == $RAID_VERIFYING;
  $nagios_message .= "RECONSTRUCTING (".$percent."%)" if $raid_status == $RAID_RECONSTRUCTING;
  $nagios_message .= "DEGRADED" if $raid_status == $RAID_DEGRADED;
  $nagios_message .= "EXPANDING" if $raid_status == $RAID_EXPANDING;
  $nagios_message .= "MIRRORING" if $raid_status == $RAID_MIRRORING;
}

$np->nagios_exit($nagios_status, $nagios_message);

__END__
