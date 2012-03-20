#!/bin/bash
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
## Script used to get some mysql metrics
## aimed to be queried by snmp
## result one by line from (status, threads, questions, slow queries, open tables)
## Configure your snmpd server with something like :
## exec .1.3.6.1.4.1.111111.1 MySQLParameters /opt/scripts/check_mysql_status.sh

/opt/mysql/bin/mysqladmin -S /var/lib/mysql/mysql.sock -uroot -ptoh4hoh8Ma ping &>/dev/null
RES=$?
echo $RES
[ $RES -eq 0 ] && /opt/mysql/bin/mysqladmin -S /var/lib/mysql/mysql.sock -uroot -ptoh4hoh8Ma status | awk '{printf("%d\n%d\n%d\n%d\n",$4,$6,$9,$17)}'
