#!/usr/bin/perl -w
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

##########
## Name : backup_pfsense.pl
## Description : backup pfSense configuration
##########


use strict;

use Getopt::Long;
use WWW::Mechanize;
use HTTP::Cookies;
use Data::Dumper;

my $url_path="/diag_backup.php";

sub usage {
  my @usage = (
    "Usage: $0 [options]",
    "  -h              Display this help and exit",
    "  -url <url>      pfSense URL access",
    "  -u <username>   Username",
    "  -p <password>   Password",
    "  -b              Use basic authentication instead of form (old pfSense)",
    ""
    );

  foreach (@usage) {
    printf("%s\n", $_);
  }
}

my $help = '';
my $username = '';
my $password = '';
my $url = '';
my $basic = '';

GetOptions(
  'help|h' => \$help,
  'username|u=s' => \$username,
  'password|p=s' => \$password,
  'url=s' => \$url,
  'b' => \$basic,
  );

usage if $help;

if( ! $username || ! $password || ! $url) {
  die ("Please provide mandatory options, try -h for help");
}

## Ignore SSL certification failed error
$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;
my $mech = WWW::Mechanize->new();
my $response;
if($basic) {
  $mech->credentials($username, $password);
} else {
  ## Get login page
  $response = $mech->get($url."/index.php");

  ## Set form number, fields and submit
  $mech->form_number(1);
  $mech->set_fields(usernamefld=>$username, passwordfld => $password);
  $mech->click("login");
  die unless ($mech->success);
}

## Getting backup
$response = $mech->get($url.$url_path);
$mech->form_number(1);
#$mech->untick("donotbackuprrd", "false");
$response = $mech->click_button(value => "Download configuration");

print $response->as_string;

__END__

