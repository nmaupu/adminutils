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
## exec .1.3.6.1.4.1.111111.2 OpenofficeServer /opt/scripts/check_openoffice_server.sh


PID=`pgrep -f soffice\.bin`
PID=${PID:-0}
OUT=`(time nc -z localhost 8100) 2>&1`
RES=$?
TIME=`echo "${OUT}" | grep real | sed 's/^real.*0m\(.*\)s$/\1/g'`

echo $RES
echo $PID
echo $TIME
