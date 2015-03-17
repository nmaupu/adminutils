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
## check_snmp_eql_snap is a script to monitor snapshots usage on an Equallogic SAN volume through SNMP
## Author: nmaupu_at_gmail_dot_com
## Version: 1.0
####################
#
# help: ./check_snmp_eql_snap -h
## Requirements : Number::Bytes::Human
## Can be installed under redhat with something like : yum install perl-Number-Bytes-Human

use strict;
use Net::SNMP;
use Getopt::Long;
use Nagios::Plugin;
use Number::Bytes::Human qw(format_bytes);
use Data::Dumper;

my $NAME="check_snmp_eql_snap";
my $VERSION="1.0";

## Opts
my $np = Nagios::Plugin->new(
  usage => "Usage: $NAME [--host|-H <host>] [--port|-p <port>] [--community|-C <community>] [--volume|-d <volume-name>] [--warning|-w <warning>] [--critical|-c <critical>]",
  version => $VERSION,
  blurb => 'Check Equallogic volume status through SNMP'
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
$np->add_arg(
  spec     => 'warning|w=i',
  help     => 'Warning threshold usage snapshot space',
  required => 1,
);
$np->add_arg(
  spec     => 'critical|c=i',
  help     => 'Critical threshold usage snapshot space',
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


## Getting all volumes name and index in oid tree
my $oid_all_volumes = '1.3.6.1.4.1.12740.5.1.7.1.1.4';

$session->translate(Net::SNMP->TRANSLATE_NONE);
my $volumes = $session->get_table(-baseoid => $oid_all_volumes);

if (!defined($volumes)) {
  $np->nagios_die("Error getting values from SNMP, timeout reaching host.\n");
}

#print(Dumper($volumes));

my ($key, $value, $idx) = (0,0,-1);
while (($key, $value) = each(%{$volumes})) {
  if($value eq $np->opts->volume) {
    $key =~ /.*\.([0-9]+\.[0-9]+)/;
    $idx = $1;
    last;
  }
}

if ($idx eq "-1") {
  $np->nagios_exit(UNKNOWN, "This volume cannot be found (".$np->opts->volume.")");
} else {
  ## Getting infos of the specified volume
  my $oid_nb_snaps_online = "1.3.6.1.4.1.12740.5.1.7.7.1.16.".$idx;
  my $oid_nb_snaps = "1.3.6.1.4.1.12740.5.1.7.7.1.5.".$idx;
  my $oid_res_space = "1.3.6.1.4.1.12740.5.1.7.1.1.10.".$idx;
  my $oid_free_space = "1.3.6.1.4.1.12740.5.1.7.7.1.3.".$idx;
  my $oid_volume_size = "1.3.6.1.4.1.12740.5.1.7.1.1.8.".$idx;

  $session->translate(Net::SNMP->TRANSLATE_NONE);
  my $result = $session->get_request(-varbindlist => [
    $oid_nb_snaps_online,
    $oid_nb_snaps,
    $oid_res_space,
    $oid_free_space,
    $oid_volume_size
  ]);

  #print Dumper($result);

  if (!defined($result)) {
    $np->nagios_die("Error getting values from SNMP, timeout reaching host.\n");
  }
  
  ## Some computations
  my $vol_size = $result->{$oid_volume_size};
  my $snap_percent = $result->{$oid_res_space};
  my $snap_total_space = $vol_size * $snap_percent / 100;
  my $snap_used_space = $snap_total_space - $result->{$oid_free_space};
  my $snap_percent_used = sprintf("%.1f", ($snap_used_space * 100) / $snap_total_space);

  $np->add_perfdata(
    label => 'nb_snaps_online',
    value => $result->{$oid_nb_snaps_online},
    uom   => 'c',
  );
  $np->add_perfdata(
    label => 'nb_snaps',
    value => $result->{$oid_nb_snaps},
    uom   => 'c',
  );
  $np->add_perfdata(
    label => 'snap_total_space',
    value => $snap_total_space,
    uom   => 'MB',
  );
  $np->add_perfdata(
    label => 'snap_used_space',
    value => $snap_used_space,
    uom   => 'MB',
  );

  ## Exit status and message handling
  my $exit_code = OK;
  my $used_human = format_bytes($snap_used_space * 1048576); ## 1048576 = 1024*1024
  my $total_human = format_bytes($snap_total_space * 1048576);
  my $message = "Snapshot space for volume ".$np->opts->volume. " : ".$used_human."/".$total_human." - ".$snap_percent_used."% used";
  if($snap_percent_used >= $np->opts->critical) {
    $exit_code = CRITICAL;
    $message .= " (>=".$np->opts->warning."%)";
  } elsif($snap_percent_used >= $np->opts->warning) {
    $exit_code = WARNING;
    $message .= " (>=".$np->opts->warning."%)";
  } else {
    $exit_code = OK;
    $message .= " (<".$np->opts->warning."%)";
  }

  $np->nagios_exit($exit_code, $message);
}

__END__
