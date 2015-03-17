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
## check_snmp_eql_member is script to monitor member of Equallogic SAN groups through SNMP
## Author: nmaupu_at_gmail_dot_com
## Version: 1.0
####################
#
# help: ./check_snmp_eql_member -h

use strict;
use Net::SNMP;
use Getopt::Long;
use Nagios::Plugin;
use Data::Dumper;

my $NAME="check_snmp_eql_member";
my $VERSION="1.0";

## Opts
my $np = Nagios::Plugin->new(
  usage => "Usage: $NAME [--host|-H <host>] [--port|-p <port>] [--community|-C <community>] [--warning|-w <count>] [--critical|-c <count>]",
  version => $VERSION,
  blurb => 'Check Equallogic member status through SNMP'
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
  spec     => 'warning|w=s',
  help     => 'warning is generated for warning<=count<critical (count being the number of members not in status online)',
  required => 1,
);
$np->add_arg(
  spec     => 'critical|c=s',
  help     => 'critical is generated for critical<=count (count being the number of members not in status online)',
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
my $oid_all_members = '.1.3.6.1.4.1.12740.2.1.1.1.9.1';

$session->translate(Net::SNMP->TRANSLATE_NONE);
my $members = $session->get_table(-baseoid => $oid_all_members);

if (!defined($members)) {
  $np->nagios_die("Error getting values from SNMP, timeout reaching host.\n");
}

my %oids_status = ();
my ($key, $value, $idx) = (0,0,-1);
while (($key, $value) = each(%{$members})) {
  $key =~ /.*\.([0-9]+)/;
  $oids_status{'.1.3.6.1.4.1.12740.2.1.4.1.2.1.'.$1} = $value;
}

$session->translate(Net::SNMP->TRANSLATE_NONE);
my $result = $session->get_request(-varbindlist => [keys(%oids_status)]);

## Definition of all status code
my ($status_online, $status_offline, $status_vacating, $status_vacated) = (1,2,3,4);

my ($nb_online, $nb_offline, $nb_vacating, $nb_vacated, $nb_members) = (0,0,0,0,0);
while (($key, $value) = each %oids_status) {
  if($result->{$key} == $status_online) {
    $nb_online++;
  } elsif($result->{$key} == $status_offline) {
    $nb_offline++;
  } elsif($result->{$key} == $status_vacating) {
    $nb_vacating++;
  } elsif($result->{$key} == $status_vacated) {
    $nb_vacated++;
  }
  $nb_members++;
}

##
my $nb_not_online = $nb_members - $nb_online;
my $message_stats = $nb_online."/".$nb_members." member(s) online";

## Default ok message
my ($nagios_retcode, $nagios_message) = (OK, "SAN group OK, ".$message_stats);

if($nb_not_online >= $np->opts->critical) {
  $nagios_retcode = CRITICAL;
  $nagios_message = "SAN group CRITICAL, ".$message_stats;
} elsif($nb_not_online >= $np->opts->warning) {
  $nagios_retcode = WARNING;
  $nagios_message = "SAN group WARNING, ".$message_stats;
}

$np->nagios_exit($nagios_retcode, $nagios_message);

__END__
