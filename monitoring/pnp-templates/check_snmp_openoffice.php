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

$DS_time   = $this->DS[0];
$DS_status = $this->DS[1];

$opt[1] = "-l0 --title \"$hostname / Openoffice server\" ";

$def[1]  = rrd::def("var1", $DS_time['RRDFILE'], $DS_time['DS']);
$def[1] .= rrd::def("var2", $DS_status['RRDFILE'], $DS_status['DS']);

$def[1] .= rrd::gradient("var1", "#00FFFF", "#0000FF", "Time");
$def[1] .= rrd::gprint("var1", array("LAST", "AVERAGE", "MIN", "MAX"), "%4.2lfs");

$def[1] .= rrd::ticker("var2", 2, 1, -0.05, "ff", "#00ff00","#ff8c00","#ff0000");

?>
