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
## check_snmp_eql_network_tcp is script to monitor network interfaces of Equallogic SANs through SNMP
## Author: nmaupu@gmail.com
## Version: 1.0
####################
#
# help: ./check_snmp_eql_network_tcp -h

use strict;
use Net::SNMP;
use Getopt::Long;
use Nagios::Plugin;
use Data::Dumper;

my $NAME="check_snmp_eql_network_tcp";
my $VERSION="1.0";

## Opts
my $np = Nagios::Plugin->new(
  usage => "Usage: $NAME [--host|-H <host>] [--port|-p <port>] [--community|-C <community>]",
  version => $VERSION,
  blurb => 'Check Equallogic network tcp through SNMP'
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
      -timeout   => 3,
    );

if (!defined($session)) {
  $np->nagios_die("ERROR: %s.\n", $error);
}

## OIDs
my $oid_tcp_active_opens  = '.1.3.6.1.2.1.6.5.0';
my $oid_tcp_passive_opens = '.1.3.6.1.2.1.6.6.0';
my $oid_tcp_att_failed    = '.1.3.6.1.2.1.6.7.0';
my $oid_tcp_cur_estab     = '.1.3.6.1.2.1.6.9.0';
my $oid_tcp_in_segs       = '.1.3.6.1.2.1.6.10.0';
my $oid_tcp_out_segs      = '.1.3.6.1.2.1.6.11.0';
my $oid_tcp_retrans_segs  = '.1.3.6.1.2.1.6.12.0';
my $oid_tcp_in_segs_err   = '.1.3.6.1.2.1.6.14.0';
my $oid_tcp_out_rst       = '.1.3.6.1.2.1.6.15.0';

$session->translate(Net::SNMP->TRANSLATE_NONE);

my $result = $session->get_request(-varbindlist => [
	$oid_tcp_active_opens,
	$oid_tcp_passive_opens,
	$oid_tcp_cur_estab,
	$oid_tcp_in_segs,
	$oid_tcp_out_segs,
	$oid_tcp_retrans_segs,
	$oid_tcp_in_segs_err,
	$oid_tcp_out_rst
]);

if (!defined($result)) {
  $np->nagios_die("Error getting values from SNMP, timeout reaching host.\n");
}

$np->add_perfdata(
  label => 'TCP active opens',
  value => $result->{$oid_tcp_active_opens},
  uom   => 'c',
);

$np->add_perfdata(
  label => 'TCP passive opens',
  value => $result->{$oid_tcp_passive_opens},
  uom   => 'c',
);

$np->add_perfdata(
  label => 'TCP attempt fails',
  value => $result->{$oid_tcp_att_failed},
  uom   => 'c',
);

$np->add_perfdata(
  label => 'TCP cur estab',
  value => $result->{$oid_tcp_cur_estab},
  uom   => 'g',
);

$np->add_perfdata(
  label => 'TCP in segs',
  value => $result->{$oid_tcp_in_segs},
  uom   => 'c',
);

$np->add_perfdata(
  label => 'TCP out segs',
  value => $result->{$oid_tcp_out_segs},
  uom   => 'c',
);

$np->add_perfdata(
  label => 'TCP retrans segs',
  value => $result->{$oid_tcp_retrans_segs},
  uom   => 'c',
);

$np->add_perfdata(
  label => 'TCP in segs err',
  value => $result->{$oid_tcp_in_segs_err},
  uom   => 'c',
);

$np->add_perfdata(
  label => 'TCP out RST',
  value => $result->{$oid_tcp_out_rst},
  uom   => 'c',
);

$np->nagios_exit(OK, "no message");

__END__
