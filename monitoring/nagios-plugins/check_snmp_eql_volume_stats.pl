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
## check_snmp_eql_volume_stats is a script to get stats on an Equallogic SAN volume through SNMP
## Author: nmaupu_at_gmail_dot_com
## Version: 1.0
####################
#
# help: ./check_snmp_eql_volume_stats -h

use strict;
use Net::SNMP;
use Getopt::Long;
use Nagios::Plugin;
use Data::Dumper;

my $NAME="check_snmp_eql_volume_stats";
my $VERSION="1.0";

## Opts
my $np = Nagios::Plugin->new(
  usage => "Usage: $NAME [--host|-H <host>] [--port|-p <port>] [--community|-C <community>] [--volume|-d <volume-name>]",
  version => $VERSION,
  blurb => 'Check Equallogic volume stats through SNMP'
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
  spec     => 'volume|d=s',
  help     => 'Volume name to check',
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


## Getting member id and volume id
my $oid_all_volumes = '1.3.6.1.4.1.12740.5.1.7.1.1.4';

$session->translate(Net::SNMP->TRANSLATE_NONE);
my $result_volumes = $session->get_table(-baseoid => $oid_all_volumes);

if (!defined($result_volumes)) {
  $np->nagios_die("Error getting values from SNMP, timeout reaching host.\n");
}

my ($key, $value, $oid_suffix) = (0,0,-1);
while (($key, $value) = each(%{$result_volumes})) {
  if($value eq $np->opts->volume) {
    $key =~ /.*\.([0-9]+\.[0-9]+)/;
    $oid_suffix = $1;
    last;
  }
}
##

if ($oid_suffix eq "-1") {
  $np->nagios_exit(UNKNOWN, "This volume cannot be found (".$np->opts->volume.")");
} else {
  my $oid_vol_tx = "1.3.6.1.4.1.12740.5.1.7.34.1.3.".$oid_suffix;
  my $oid_vol_rx = "1.3.6.1.4.1.12740.5.1.7.34.1.4.".$oid_suffix;
  my $oid_vol_read_lat = "1.3.6.1.4.1.12740.5.1.7.34.1.6.".$oid_suffix;
  my $oid_vol_write_lat = "1.3.6.1.4.1.12740.5.1.7.34.1.7.".$oid_suffix;
  my $oid_vol_num_read_ops = "1.3.6.1.4.1.12740.5.1.7.34.1.8.".$oid_suffix;
  my $oid_vol_num_write_ops = "1.3.6.1.4.1.12740.5.1.7.34.1.9.".$oid_suffix;
  my $oid_vol_avg_lat_read_op = "1.3.6.1.4.1.12740.5.1.7.34.1.10.".$oid_suffix;
  my $oid_vol_avg_lat_write_op = "1.3.6.1.4.1.12740.5.1.7.34.1.11.".$oid_suffix;
  my $oid_vol_num_readwrite_cmd_recv = "1.3.6.1.4.1.12740.5.1.7.34.1.12.".$oid_suffix;
  my $oid_vol_num_readwrite_cmd_comp = "1.3.6.1.4.1.12740.5.1.7.34.1.13.".$oid_suffix;
  
  $session->translate(Net::SNMP->TRANSLATE_NONE);
  my $result_stats = $session->get_request(-varbindlist => [
    $oid_vol_tx,
    $oid_vol_rx,
    $oid_vol_read_lat,
    $oid_vol_write_lat,
    $oid_vol_num_read_ops,
    $oid_vol_num_write_ops,
    $oid_vol_avg_lat_read_op,
    $oid_vol_avg_lat_write_op,
    $oid_vol_num_readwrite_cmd_recv,
    $oid_vol_num_readwrite_cmd_comp,
  ]);
  
  $np->add_perfdata(
    label => 'tx',
    value => $result_stats->{$oid_vol_tx},
    uom   => 'B',
  );
  $np->add_perfdata(
    label => 'rx',
    value => $result_stats->{$oid_vol_rx},
    uom   => 'B',
  );
  $np->add_perfdata(
    label => 'read_latency',
    value => $result_stats->{$oid_vol_read_lat},
    uom   => 'ms',
  );
  $np->add_perfdata(
    label => 'write_latency',
    value => $result_stats->{$oid_vol_write_lat},
    uom   => 'ms',
  );
  $np->add_perfdata(
    label => 'num_read_ops',
    value => $result_stats->{$oid_vol_num_read_ops},
    uom   => 'c',
  );
  $np->add_perfdata(
    label => 'num_write_ops',
    value => $result_stats->{$oid_vol_num_write_ops},
    uom   => 'c',
  );
  $np->add_perfdata(
    label => 'avg_latency_read_op',
    value => $result_stats->{$oid_vol_avg_lat_read_op},
    uom   => 'ms',
  );
  $np->add_perfdata(
    label => 'avg_latency_write_op',
    value => $result_stats->{$oid_vol_avg_lat_write_op},
    uom   => 'ms',
  );
  $np->add_perfdata(
    label => 'num_readwrite_cmd_recv',
    value => $result_stats->{$oid_vol_num_readwrite_cmd_recv},
    uom   => 'c',
  );
  $np->add_perfdata(
    label => 'num_readwrite_cmd_completed',
    value => $result_stats->{$oid_vol_num_readwrite_cmd_comp},
    uom   => 'c',
  );
  
  $np->nagios_exit(OK, "-");
}

__END__
