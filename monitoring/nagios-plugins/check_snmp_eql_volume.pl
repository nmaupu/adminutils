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
## check_snmp_eql_volume is a script to monitor an Equallogic SAN volume through SNMP
## Author: nmaupu_at_gmail_dot_com
## Version: 1.0
####################
#
# help: ./check_snmp_eql_volume -h

use strict;
use Net::SNMP;
use Getopt::Long;
use Nagios::Plugin;
use Data::Dumper;

my $NAME="check_snmp_eql_volume";
my $VERSION="1.0";

## Opts
my $np = Nagios::Plugin->new(
  usage => "Usage: $NAME [--host|-H <host>] [--port|-p <port>] [--community|-C <community>] [--volume|-d <volume-name>]",
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

## Getting all members' id and name
my $oid_all_members = '.1.3.6.1.4.1.12740.2.1.1.1.9.1';

$session->translate(Net::SNMP->TRANSLATE_NONE);
my $members = $session->get_table(-baseoid => $oid_all_members);

if (!defined($members)) {
  $np->nagios_die("Error getting values from SNMP, timeout reaching host.\n");
}

my %members_idx = ();
my ($keymem, $valuemem) = (0,0);
while (($keymem, $valuemem) = each(%{$members})) {
  $keymem =~ /.*\.([0-9]+)/;
  $members_idx{$valuemem} = $1;
}

#print Dumper(%members_idx);

## Getting volume index in oid tree
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
  my $oid_size = "1.3.6.1.4.1.12740.5.1.7.1.1.8.".$idx;
  my $oid_allocated = "1.3.6.1.4.1.12740.5.1.7.3.1.3.".$idx;
  my $oid_num_con = "1.3.6.1.4.1.12740.5.1.7.7.1.18.".$idx;

  my @oids = ();
  my ($key_member, $val_member);
  while (($key_member, $val_member) = each(%{members_idx})) {
    push(@oids, $oid_size.".".$val_member);
    push(@oids, $oid_allocated.".".$val_member);
    push(@oids, $oid_num_con.".".$val_member);
  }

  $session->translate(Net::SNMP->TRANSLATE_NONE);
  my $result = $session->get_request(-varbindlist => \@oids);

  #print Dumper($result);

  if (!defined($result)) {
    $np->nagios_die("Error getting values from SNMP, timeout reaching host.\n");
  }

  my ($size, $allocated, $num_con) = (0, 0, 0);
  my $nb_san_members = 0;
  while (($key_member, $val_member) = each(%{members_idx})) {
    # Member name = $key_member
    # Member idx = $val_member
    $size += $result->{$oid_size.".".$val_member};
    $allocated += $result->{$oid_allocated.".".$val_member};
    $num_con += $result->{$oid_num_con.".".$val_member};
    $nb_san_members++;
  }
  $np->add_perfdata(
    label => 'size',
    value => $size,
    uom   => 'MB',
  );
  $np->add_perfdata(
    label => 'allocated',
    value => $allocated,
    uom   => 'MB',
  );
  $np->add_perfdata(
    label => 'con_count',
    value => $num_con,
    uom   => 'c',
  );
  $np->add_perfdata(
    label => 'san_count',
    value => $nb_san_members,
    uom   => 'c',
  );


  ## Exit status and message handling
  my $exit_code = OK;
  my $message = "# iSCSI sessions for volume ".$np->opts->volume." : ".$num_con." / ".$nb_san_members." SAN members";
  #my $message = "Number of iscsi sessions for the volume ".$np->opts->volume." (# SAN member(s): ".$nb_san_members.")";
  #if($np->opts->sessions < $num_con) {
  #  $exit_code = WARNING;
  #  $message = $message." is more than expected, please check !";
  #} elsif($np->opts->sessions > $num_con) {
  #  $exit_code = CRITICAL;
  #  $message = $message." is less than expected. One or more sessions are dead, please check !";
  #} else {
  #  $exit_code = OK;
  #  $message = $message." is OK";
  #}

  $np->nagios_exit($exit_code, $message);
}

__END__
