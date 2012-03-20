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
## check_snmp_nfs monitors nfs server statistics
## Author: nmaupu@gmail.com
## Version: 1.0
####################
#
# help: ./check_snmp_nfs -h

use strict;
use Net::SNMP;
use Getopt::Long;
use Nagios::Plugin;
use Data::Dumper;

my $NAME="check_snmp_nfs";
my $VERSION="1.0";

## Opts
my $np = Nagios::Plugin->new(
  usage => "Usage: $NAME [--host|-H <host>] [--port|-p <port>] [--community|-C <community>] [-c|--check]",
  version => $VERSION,
  blurb => 'Check NFS server statistics',
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
  spec     => 'check|c',
  help     => 'Check server mode',
);

$np->getopts();

##

my $server_mode = $np->opts->check;

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
my $oid = ".1.3.6.1.4.1.111111.3.101";
my $result = $session->get_table(-baseoid => $oid);

my $status   = 0;
if($server_mode) {
  $status = $result->{$oid.'.1'};
}
my $read     = $result->{$oid.'.2'};
my $write    = $result->{$oid.'.3'};
my $create   = $result->{$oid.'.4'};
my $mkdir    = $result->{$oid.'.5'};
my $symlink  = $result->{$oid.'.6'};
my $mknod    = $result->{$oid.'.7'};
my $remove   = $result->{$oid.'.8'};
my $rmdir    = $result->{$oid.'.9'};
my $rename   = $result->{$oid.'.10'};
my $link     = $result->{$oid.'.11'};
my $readdir  = $result->{$oid.'.12'};
my $readdirp = $result->{$oid.'.13'};



$np->add_perfdata(
  label => 'status',
  value => $status,
);
$np->add_perfdata(
  label => 'read',
  value => $read,
  uom   => 'c',
);
$np->add_perfdata(
  label => 'write',
  value => $write,
  uom   => 'c',
);
$np->add_perfdata(
  label => 'create',
  value => $create,
  uom   => 'c',
);
$np->add_perfdata(
  label => 'mkdir',
  value => $mkdir,
  uom   => 'c',
);
$np->add_perfdata(
  label => 'symlink',
  value => $symlink,
  uom   => 'c',
);
$np->add_perfdata(
  label => 'mknod',
  value => $mknod,
  uom   => 'c',
);
$np->add_perfdata(
  label => 'remove',
  value => $remove,
  uom   => 'c',
);
$np->add_perfdata(
  label => 'rmdir',
  value => $rmdir,
  uom   => 'c',
);
$np->add_perfdata(
  label => 'rename',
  value => $rename,
  uom   => 'c',
);
$np->add_perfdata(
  label => 'readdir',
  value => $readdir,
  uom   => 'c',
);
$np->add_perfdata(
  label => 'readdirplus',
  value => $readdirp,
  uom   => 'c',
);

my $exit_status = OK;
my $message = "NFS ";

if($status != 0) {
  $exit_status = CRITICAL;
  $message .= "CRITICAL"
} else {
  $message .= "OK"
}

$np->nagios_exit($exit_status, $message);

__END__
