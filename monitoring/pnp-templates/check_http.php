<?php
/*
  adminutils - Scripts and resources for admins
  Copyright (C) 2012  nmaupu_at_gmail_dot_com
  
  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.
  
  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.
  
  You should have received a copy of the GNU General Public License
  along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/


$DS_time = $this->DS[0];

$opt[1] = "--vertical-label \"Response time\" -l0 --title \"HTTP response time for $hostname / $servicedesc\" ";

$def[1]  = rrd::def("var1", $DS_time['RRDFILE'], $DS_time['DS']);
$def[1] .= rrd::cdef("v_n", "var1,1000,*"); // display in ms

$def[1] .= rrd::gradient("v_n", "#33CCFF", "#3300FF", "time");
$def[1] .= rrd::line1("v_n", "#000000");
$def[1] .= rrd::gprint("v_n", array("LAST", "AVERAGE", "MIN", "MAX"), "%6.3lfms");

?>
