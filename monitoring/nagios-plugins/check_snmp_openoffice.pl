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
## check_snmp_mysql is a script to monitor some mysql metrics through snmp
## SNMPd must provide the following OID for this script to work as expected : .1.3.6.1.4.1.111111.1
## e.g. exec .1.3.6.1.4.1.111111.1 MySQLParameters /opt/scripts/check_mysql_status.sh
## Author: nmaupu_at_gmail_dot_com
## Version: 1.0
####################
#
# help: ./check_snmp_mysql -h

use strict;
use Net::SNMP;
use Getopt::Long;
use Nagios::Plugin;
use Data::Dumper;

my $NAME="check_snmp_mysql";
my $VERSION="1.0";

## Opts
my $np = Nagios::Plugin->new(
  usage => "Usage: $NAME [--host|-H <host>] [--port|-p <port>] [--community|-C <community>]",
  version => $VERSION,
  blurb => 'Check some mysql metrics through SNMP'
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

## OIDs
my $oid = '.1.3.6.1.4.1.111111.2';

$session->translate(Net::SNMP->TRANSLATE_NONE);
my $result = $session->get_table(-baseoid => $oid);

my $oid_status = "$oid.101.1";
my $oid_pid    = "$oid.101.2";
my $oid_time   = "$oid.101.3";

my $status = $result->{$oid_status};
my $pid = $result->{$oid_pid};

$np->add_perfdata(
  label    => "time",
  value    => $result->{$oid_time},
  uom      => 's',
);
$np->add_perfdata(
  label    => "status",
  value    => $result->{$oid_status},
  warning  => -1,
  critical => 1
);

my $exit_status = OK;
if($status != 0 || $pid <= 0) {
  $np->nagios_exit(CRITICAL, "Openoffice server is down");
} else {
  $np->nagios_exit($exit_status, "Openoffice server is up - PID=".$pid);
}

__END__
