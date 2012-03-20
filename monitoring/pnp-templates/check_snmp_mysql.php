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

$DS_threads    = $this->DS[0];
$DS_questions  = $this->DS[1];
$DS_slowq      = $this->DS[2];
$DS_opentables = $this->DS[3];
$DS_status     = $this->DS[4];

$opt[1] = "-l0 --title \"$hostname / Mysql Activity\" ";

$def[1]  = rrd::def("var1", $DS_threads['RRDFILE'], $DS_threads['DS']);
$def[1] .= rrd::def("var2", $DS_questions['RRDFILE'], $DS_questions['DS']);
$def[1] .= rrd::def("var3", $DS_slowq['RRDFILE'], $DS_slowq['DS']);
$def[1] .= rrd::def("var4", $DS_opentables['RRDFILE'], $DS_opentables['DS']);
$def[1] .= rrd::def("var5", $DS_status['RRDFILE'], $DS_status['DS']);

$def[1] .= rrd::line2("var1", "#00FFFF", "Threads");
$def[1] .= rrd::gprint("var1", array("LAST", "AVERAGE", "MIN", "MAX"), "%4.2lfT");

$def[1] .= rrd::gradient("var2", "#00FF0099", "#00880099", "Query");
$def[1] .= rrd::gprint("var2", array("LAST", "AVERAGE", "MIN", "MAX"), "%4.2lfq/s");

$def[1] .= rrd::line2("var3", "#FF0000", "Slow Query");
$def[1] .= rrd::gprint("var3", array("LAST", "AVERAGE", "MAX"), "%4.2lfq/s");

#$def[1] .= rrd::line1("var4", "#0000FF", "Open Tables");
#$def[1] .= rrd::gprint("var3", array("LAST", "AVERAGE", "MAX"), "%4.2lfc");

$def[1] .= rrd::ticker("var1", $DS_threads['WARN'], $DS_threads['CRIT'], -0.05, "ff", "#00ff00","#ff8c00","#ff0000");
$def[1] .= rrd::ticker("var5", 2, 1, -0.05, "ff", "#00ff00","#ff8c00","#ff0000");


?>
