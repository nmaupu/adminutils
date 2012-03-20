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
## Configure your snmpd server with something like :
## exec .1.3.6.1.4.1.111111.3 NfsServer /opt/scripts/check_nfs_stats.sh

RESULT=`/usr/sbin/nfsstat`

## One value by line
##
# 1  status (0=OK, 1=PROBLEM)
# 2  read
# 3  write
# 4  create
# 5  mkdir
# 6  symlink
# 7  mknod
# 8  remove
# 9  rmdir
# 10 rename
# 11 link
# 12 readdir
# 13 readdirplus

STATUS=`/etc/init.d/nfs status | grep "is running" | wc -l | grep -q "3"`
RES=$?

echo "$RES"
echo "$RESULT" | grep -A1 ^read   | tail -1 | awk '{printf("%d\n%d\n%d\n%d\n%d\n%d\n", $1, $3, $5, $7, $9, $11)}'
echo "$RESULT" | grep -A1 ^remove | tail -1 | awk '{printf("%d\n%d\n%d\n%d\n%d\n%d\n", $1, $3, $5, $7, $9, $11)}'
