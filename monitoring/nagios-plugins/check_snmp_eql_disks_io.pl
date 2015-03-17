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
## check_snmp_eql_disks_io is a script to monitor disks IO on an Equallogic SAN volume through SNMP
## WARNING : Only first group is reported
## Author: nmaupu_at_gmail_dot_com
## Version: 1.0
####################
#
# help: ./check_snmp_eql_disks_io -h

use strict;
use Net::SNMP;
use Getopt::Long;
use Nagios::Plugin;
use Data::Dumper;

my $NAME="check_snmp_eql_disks_io";
my $VERSION="1.0";

## Opts
my $np = Nagios::Plugin->new(
  usage => "Usage: $NAME [--host|-H <host>] [--port|-p <port>] [--community|-C <community>]",
  version => $VERSION,
  blurb => 'Check Equallogic disks IO through SNMP'
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


## Getting all members' name and id
my $oid_all_members = "1.3.6.1.4.1.12740.2.1.1.1.9";
$session->translate(Net::SNMP->TRANSLATE_NONE);
my $result_members = $session->get_table(-baseoid => $oid_all_members);

if (!defined($result_members)) {
  $np->nagios_die("Error getting values from SNMP, timeout reaching host.\n");
}

my %members_info = ();
my ($key, $value, $idx) = (0,0,-1);
while (($key, $value) = each(%{$result_members})) {
  $key =~ /.*\.([0-9]+)/;
  $members_info{$1} = $value;
}

##

## Getting disks IO info on each member
while (($key, $value) = each(%{members_info})) {
  my $member_index = $key;
  my $member_name = $value;
  my $oid_io_read = "1.3.6.1.4.1.12740.3.1.2.1.2.1.".$member_index;
  my $oid_io_written = "1.3.6.1.4.1.12740.3.1.2.1.3.1.".$member_index;
  my $oid_io_busy = "1.3.6.1.4.1.12740.3.1.2.1.3.1.".$member_index;
  
  my $result_io_read = $session->get_table(-baseoid => $oid_io_read);
  my $result_io_written = $session->get_table(-baseoid => $oid_io_written);
  my $result_io_busy = $session->get_table(-baseoid => $oid_io_busy);
  
  if (!defined($result_io_read) || !defined($result_io_written) || !defined($result_io_busy)) {
    $np->nagios_die("Error getting values from SNMP, timeout reaching host.\n");
  }
  
  my ($k, $v);
  while (($k, $v) = each($result_io_read)) {
    $k =~ /.*\.([0-9]+)/;
    my $disk_num = $1;
    $np->add_perfdata(
      label => $member_name."_io_read_disk".$disk_num,
      value => $v,
      uom   => 'c',
    );
  }
  while (($k, $v) = each($result_io_written)) {
    $k =~ /.*\.([0-9]+)/;
    my $disk_num = $1;
    $np->add_perfdata(
      label => $member_name."_io_written_disk".$disk_num,
      value => $v,
      uom   => 'c',
    );
  }
  while (($k, $v) = each($result_io_busy)) {
    $k =~ /.*\.([0-9]+)/;
    my $disk_num = $1;
    $np->add_perfdata(
      label => $member_name."_io_busy_disk".$disk_num,
      value => $v,
      uom   => 's',
    );
  }
}

$np->nagios_exit(OK, "No message");

__END__
