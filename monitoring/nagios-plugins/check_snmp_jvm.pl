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
## check_snmp_jvm_memory is script providing an efficient way for requesting jmx values using snmp
## Author: nmaupu@gmail.com
## Version: 1.0
####################
#
# help: ./check_snmp_jvm_memory -h

use strict;
use Net::SNMP;
use Getopt::Long;
use Nagios::Plugin;
use Data::Dumper;

my $NAME="check_snmp_jvm_memory";
my $VERSION="1.0";

## Opts
my $np = Nagios::Plugin->new(
  usage => "Usage: $NAME [--host|-H <host>] [--port|-p <port>] [--community|-C <community>] [--type|-y <heap|nonheap>] [-c|--critical <critial>] [-w|--warning <warning>]",
  version => $VERSION,
  blurb => 'Check jvm Sun Hotspot memory usage using SNMP'
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
  spec     => 'critical|c=i',
  help     => 'Critical threshold',
  required => 1,
);
$np->add_arg(
  spec     => 'warning|w=i',
  help     => 'Warning threshold',
  required => 1,
);
$np->add_arg(
  spec     => 'type|y=s',
  help     => 'Memory type to retrieve (heap or nonheap)',
  required => 1,
);

$np->getopts();

## Parameters checking
$np->nagios_die("Type option is not valid ! Only heap or nonheap is valid - you chose ".$np->opts->type."\n") if $np->opts->type !~ m/^(heap|nonheap)$/;

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

## names oid
my $oid_mem_names       = '1.3.6.1.4.1.42.2.145.3.163.1.1.2.110.1.2';
my $oid_mem_values_used = '1.3.6.1.4.1.42.2.145.3.163.1.1.2.110.1.11';
my $oid_mem_values_max  = '1.3.6.1.4.1.42.2.145.3.163.1.1.2.110.1.11';
my $oid_mem_heap_used   = '1.3.6.1.4.1.42.2.145.3.163.1.1.2.11';
my $oid_mem_heap_max    = '1.3.6.1.4.1.42.2.145.3.163.1.1.2.13';
my $oid_mem_nheap_used  = '.1.3.6.1.4.1.42.2.145.3.163.1.1.2.21';
my $oid_mem_nheap_max   = '.1.3.6.1.4.1.42.2.145.3.163.1.1.2.23';

$session->translate(Net::SNMP->TRANSLATE_NONE);
my $result_names  = $session->get_table(-baseoid => $oid_mem_names);
my $result_values_used = $session->get_table(-baseoid => $oid_mem_values_used);
my $result_values_max = $session->get_table(-baseoid => $oid_mem_values_max);
my $result_values_heap_max = $session->get_table(-baseoid => $oid_mem_heap_max);
my $result_values_heap_used = $session->get_table(-baseoid => $oid_mem_heap_used);

my $mem_name;
my $pool_name;
my $oid_mem_used;
my $oid_mem_max;
if($np->opts->type =~ m/^heap/) {
  $mem_name = "heap";
  $pool_name = "old";
  $oid_mem_used = $oid_mem_heap_used;
  $oid_mem_max  = $oid_mem_heap_max;
} else {
  $mem_name = "nonheap";
  $pool_name = "perm gen";
  $oid_mem_used = $oid_mem_nheap_used;
  $oid_mem_max  = $oid_mem_nheap_max;
}

## Add perfdata and exit with nagios status
extract_data_and_exit(
  get_snmp_jvm_pool_info($oid_mem_used, $oid_mem_max, $pool_name),
  $mem_name,
  $pool_name
);


##########
##########

sub extract_data_and_exit {
  my ($snmp_res, $mem_name, $pool_name) = @_;

  my $mem_max   = $snmp_res->{mem_max};
  my $mem_used  = $snmp_res->{mem_used};
  my $pool_used = $snmp_res->{pool_used};

  my $percent_mem_used = sprintf("%.2f", ($mem_used * 100) / $mem_max);
  my $warning_value_uom = ($np->opts->warning*$mem_max)/100;
  my $critical_value_uom = ($np->opts->critical*$mem_max)/100;

  my $newsize = adjust_size($mem_used);
  my $u                = $newsize->{unit};
  my $mem_used_fmt     = sprintf("%.2f", $newsize->{size});
  my $mem_max_fmt      = sprintf("%.2f", format_size($mem_max, $u));
  my $mem_warning_fmt  = sprintf("%.2f", format_size($warning_value_uom, $u));
  my $mem_critical_fmt = sprintf("%.2f", format_size($critical_value_uom, $u));
  my $pool_used_fmt    = sprintf("%.2f", format_size($pool_used, $u));

  $np->add_perfdata(
    label    => $mem_name,
    value    => $mem_used_fmt,
    uom      => $u,
    warning  => $mem_warning_fmt,
    critical => $mem_critical_fmt,
    max      => $mem_max_fmt
  );
  $np->add_perfdata(
    label    => $pool_name,
    value    => $pool_used_fmt,
    uom      => $u
  );

  my $exit_value = OK;
  if($percent_mem_used >= $np->opts->critical) {
    $exit_value = CRITICAL;
  } elsif ($percent_mem_used >= $np->opts->warning) {
    $exit_value = WARNING;
  }

  $np->nagios_exit($exit_value, "$mem_name : $percent_mem_used% (${mem_used_fmt}${u}/${mem_max_fmt}${u})");
}

sub adjust_size {
  my ($size) = @_;
  my @units = ("B", "KB", "MB", "GB", "TB");
  my $newsize = $size;
  my $unit_idx = 0;

  while ($newsize > 1024) {
    $unit_idx++;
    $newsize /= 1024;
  }

  return {size=>$newsize, unit=>$units[$unit_idx]};
}

sub format_size {
  my ($size, $unit) = @_;
  
  if($unit eq 'B') {
    return $size;
  } elsif ($unit eq 'KB') {
    return $size / 1024;
  } elsif ($unit eq 'MB') {
    return $size / 1024 / 1024;
  } elsif ($unit eq 'GB') {
    return $size / 1024 / 1024 / 1024;
  } elsif ($unit eq 'TB') {
    return $size / 1024 / 1024 / 1024 / 1024;
  }

  return $size;
}

## Retrieve info from snmp
## Params:
##   oid of mem max (heap or non heap)
##   oid of mem used (heap or non heap)
##   name of the pool to monitor (old, survivor, eden, perm gen, code cache, ...)
## Returns:
##   List {pool_used, mem_used, mem_max}
sub get_snmp_jvm_pool_info {
  my ($oid_mem_used, $oid_mem_max, $mem_pool_name) = @_;
  
  ## names oid
  my $oid_mem_names       = '1.3.6.1.4.1.42.2.145.3.163.1.1.2.110.1.2';
  my $oid_mem_values_used = '1.3.6.1.4.1.42.2.145.3.163.1.1.2.110.1.11';
  my $oid_mem_values_max  = '1.3.6.1.4.1.42.2.145.3.163.1.1.2.110.1.13';

  ## Getting value through snmp
  my $result_names  = $session->get_table(-baseoid => $oid_mem_names);
  my $result_values_used = $session->get_table(-baseoid => $oid_mem_values_used);
  my $result_values_max = $session->get_table(-baseoid => $oid_mem_values_max);
  my $result_values_pool_used = $session->get_table(-baseoid => $oid_mem_used);
  my $result_values_pool_max = $session->get_table(-baseoid => $oid_mem_max);

  my $key_name;
  if(defined ($mem_pool_name)) {
    my $result_names  = $session->get_table(-baseoid => $oid_mem_names);
    my $key;
    foreach $key (keys %{$result_names}) {
      my $val = $result_names->{$key};
      ## Extract oid's last digit
      $key =~ /^([0-9]+\.)*([0-9])$/;
      my $last_digit = $2;
      $key_name      = $last_digit if $val =~ m/$mem_pool_name/i;
    }
  }
  
  ## Getting values
  my $val_name_used = $result_values_used->{"$oid_mem_values_used.$key_name"}; # Getting pool used
  my $val_mem_max  = $result_values_pool_max->{"$oid_mem_max.0"}; # Getting heap/nheap max
  my $val_mem_used = $result_values_pool_used->{"$oid_mem_used.0"}; # Getting heap/nheap used

  return {pool_used => $val_name_used, mem_used => $val_mem_used, mem_max => $val_mem_max};
}

__END__
