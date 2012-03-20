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

$ds_threads = $this->DS[0];
$ds_daemon  = $this->DS[1];
$ds_peak    = $this->DS[2];
$ds_total   = $this->DS[3];

$unit = $ds_threads['UNIT'];

$max = $ds_threads['ACT'] > $ds_threads['CRIT'] ? $ds_threads['ACT'] : $ds_threads['CRIT'];
$opt[1] = "--vertical-label Load -l0 -u $max --title \"JVM threads for $hostname\" ";

$def[1]  = rrd::def("var1", $ds_threads['RRDFILE'],  $ds_threads['DS']);
$def[1] .= rrd::def("var2", $ds_daemon['RRDFILE'],  $ds_daemon['DS']);
$def[1] .= rrd::def("var3", $ds_peak['RRDFILE'], $ds_peak['DS']);
$def[1] .= rrd::def("var4", $ds_total['RRDFILE'], $ds_total['DS']);


$def[1] .= rrd::line2("var1", "#66ccff", "Live threads");
$def[1] .= rrd::gprint("var1", array("LAST", "AVERAGE", "MIN", "MAX"), "%.0lf$unit");

$def[1] .= rrd::line1("var2", "#CCCC33", "Daemon threads");
$def[1] .= rrd::gprint("var2", array("LAST", "AVERAGE", "MIN", "MAX"), "%.0lf$unit");

$def[1] .= rrd::hrule($ds_threads['WARN'], "#FFFF00", "Warning (".$ds_threads['WARN'].") \\n" );
$def[1] .= rrd::hrule($ds_threads['CRIT'], "#FF0000", "Critical (".$ds_threads['CRIT'].") \\n" );

$def[1] .= rrd::gprint("var3", "LAST", "Last peak \: %.0lf$unit");
?>
