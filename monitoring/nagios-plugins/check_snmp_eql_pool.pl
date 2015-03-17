#!/usr/bin/perl -w
# nagios: -epn
# adminutils - Scripts and resources for admins
# Copyright (C) 2015 nmaupu_at_gmail_dot_com
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
## check_snmp_eql_pool is a script to monitor pool space usage of an Equallogic SAN through SNMP
## Author: nmaupu_at_gmail_dot_com
## Version: 1.0
####################
#
# help: ./check_snmp_eql_pool -h
## Requirements : Number::Bytes::Human
## Can be installed under redhat with something like : yum install perl-Number-Bytes-Human

use strict;
use Net::SNMP;
use Getopt::Long;
use Nagios::Plugin;
use Number::Bytes::Human qw(format_bytes);
use Data::Dumper;

my $NAME="check_snmp_eql_pool";
my $VERSION="1.0";

## Opts
my $np = Nagios::Plugin->new(
  usage => "Usage: $NAME [--host|-H <host>] [--port|-p <port>] [--community|-C <community>] [--pool|-P <pool-name>] [--warning|-w <warning>] [--critical|-c <critical>]",
  version => $VERSION,
  blurb => 'Check Equallogic pool space usage through SNMP'
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
  spec     => 'pool|P=s',
  help     => 'Pool name to get info for',
  required => 1,
);
$np->add_arg(
  spec     => 'warning|w=i',
  help     => 'Usage warning threshold (in percent)',
  required => 1,
);
$np->add_arg(
  spec     => 'critical|c=i',
  help     => 'Usage critical threshold (in percent)',
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

## Getting pool name and index
my $oid_all_pools = "1.3.6.1.4.1.12740.16.1.1.1.3";

$session->translate(Net::SNMP->TRANSLATE_NONE);
my $result_pools = $session->get_table(-baseoid => $oid_all_pools);

if (!defined($result_pools)) {
  $np->nagios_die("Error getting values from SNMP, timeout reaching host.\n");
}

my ($key, $value, $grp_idx, $pool_idx) = (0,0,-1,-1);
while (($key, $value) = each(%{$result_pools})) {
  if($value eq $np->opts->pool) {
    $key =~ /.*\.([0-9]+)\.([0-9]+)/;
    $grp_idx = $1;
    $pool_idx = $2;
    last;
  }
}

if ($grp_idx eq "-1" || $pool_idx == -1) {
  $np->nagios_exit(UNKNOWN, "This pool cannot be found (".$np->opts->pool.")");
} else {
  ## Getting information about this pool
  my $oid_suffix = $grp_idx.".".$pool_idx;
  my $oid_pool_space_used = "1.3.6.1.4.1.12740.16.1.2.1.2.".$oid_suffix;
  my $oid_pool_space_free = "1.3.6.1.4.1.12740.16.1.2.1.3.".$oid_suffix;
  my $oid_pool_snaps_res = "1.3.6.1.4.1.12740.16.1.2.1.9.".$oid_suffix;
  my $oid_pool_snaps_used = "1.3.6.1.4.1.12740.16.1.2.1.10.".$oid_suffix;
  my $oid_pool_snaps_num_in_use = "1.3.6.1.4.1.12740.16.1.2.1.11.".$oid_suffix;
  my $oid_pool_snaps_num_online = "1.3.6.1.4.1.12740.16.1.2.1.12.".$oid_suffix;
  my $oid_pool_snaps_count = "1.3.6.1.4.1.12740.16.1.2.1.13.".$oid_suffix;
  my $oid_pool_vols_in_use = "1.3.6.1.4.1.12740.16.1.2.1.14.".$oid_suffix;
  my $oid_pool_vols_online = "1.3.6.1.4.1.12740.16.1.2.1.15.".$oid_suffix;
  my $oid_pool_vols_count = "1.3.6.1.4.1.12740.16.1.2.1.16.".$oid_suffix;
  
  $session->translate(Net::SNMP->TRANSLATE_NONE);
  my $result_info = $session->get_request(-varbindlist => [
    $oid_pool_space_used,
    $oid_pool_space_free,
    $oid_pool_snaps_res,
    $oid_pool_snaps_used,
    $oid_pool_snaps_num_in_use,
    $oid_pool_snaps_num_online,
    $oid_pool_snaps_count,
    $oid_pool_vols_in_use,
    $oid_pool_vols_online,
    $oid_pool_vols_count
  ]);
  
  ## Some computation
  my $used_space = $result_info->{$oid_pool_space_used};
  my $free_space = $result_info->{$oid_pool_space_free};
  my $total_space = $used_space + $free_space;
  my $percent_used = sprintf("%.1f", ($used_space * 100) / $total_space);
  
  $np->add_perfdata(
    label => 'used_space',
    value => $used_space,
    uom   => 'MB',
  );
  $np->add_perfdata(
    label => 'total_space',
    value => $total_space,
    uom   => 'MB',
  );
  $np->add_perfdata(
    label => 'snap_space_reservation',
    value => $result_info->{$oid_pool_snaps_res},
    uom   => 'MB',
  );
  $np->add_perfdata(
    label => 'snap_space_used',
    value => $result_info->{$oid_pool_snaps_used},
    uom   => 'MB',
  );
  $np->add_perfdata(
    label => 'num_snaps_in_use',
    value => $result_info->{$oid_pool_snaps_num_in_use},
    uom   => 'c',
  );
  $np->add_perfdata(
    label => 'num_snaps_online',
    value => $result_info->{$oid_pool_snaps_num_online},
    uom   => 'c',
  );
  $np->add_perfdata(
    label => 'num_snaps_count',
    value => $result_info->{$oid_pool_snaps_count},
    uom   => 'c',
  );
  $np->add_perfdata(
    label => 'num_volumes_in_use',
    value => $result_info->{$oid_pool_vols_in_use},
    uom   => 'c',
  );
  $np->add_perfdata(
    label => 'num_volumes_online',
    value => $result_info->{$oid_pool_vols_online},
    uom   => 'c',
  );
  $np->add_perfdata(
    label => 'num_volumes_count',
    value => $result_info->{$oid_pool_vols_count},
    uom   => 'c',
  );
  
  ## Handling exit status
  my $exit_status = OK;
  my $used_human = format_bytes($used_space * 1048576); ## 1048576 = 1024*1024
  my $total_human = format_bytes($total_space * 1048576);
  my $message = "Pool ".$np->opts->pool." : (".$used_human."/".$total_human.") - ".$percent_used."% used";
  if($percent_used >= $np->opts->critical) {
    $exit_status = CRITICAL;
    $message .= " (>=".$np->opts->critical."%)";
  } elsif($percent_used >= $np->opts->warning) {
    $exit_status = WARNING;
    $message .= " (>=".$np->opts->warning."%)";
  } else {
    $exit_status = OK;
    $message .= " (<".$np->opts->warning."%)";
  }
  
  $np->nagios_exit($exit_status, $message);
}

__END__
