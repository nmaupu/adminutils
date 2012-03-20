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

//$fp = fopen('/tmp/test', 'a');
//ob_start();

$DS_in  = $this->DS[0];
$DS_out = $this->DS[1];

$unit = 'B';
$fmt = "%6.2lf";
$max_in  = pnp::adjust_unit($DS_in['ACT'].$unit, 1024, $fmt);
$max_out = pnp::adjust_unit($DS_out['ACT'].$unit, 1024, $fmt);
$max = $max_in;

$opt[1] = "--slope-mode --vertical-label \"bytes/s\" -u $max[1] -l0 --title \"Interface traffic / $hostname\"";
$divis = $max[3];


$def[1]  = rrd::def("var1", $DS_in['RRDFILE'], $DS_in['DS'], "AVERAGE");
$def[1] .= rrd::def("var2", $DS_out['RRDFILE'], $DS_out['DS'], "AVERAGE");

$def[1] .= rrd::cdef("v_in", "var1,-1,*");
$def[1] .= rrd::cdef("v_out", "var2,1,*");
$def[1] .= rrd::cdef("v_in_f", "var1,1024,/");  // KiB
$def[1] .= rrd::cdef("v_out_f", "var2,1024,/"); // KiB

$def[1] .= rrd::gradient("v_out", "#33CCFF", "#0000FF", $DS_out['NAME']);
$def[1] .= rrd::gprint("v_out_f", array("LAST", "AVERAGE", "MAX"), "$fmt KiB/s");

$def[1] .= rrd::gradient("v_in", "#FFCC66", "#FF0000", $DS_in['NAME']);
$def[1] .= rrd::gprint("v_in_f", array("LAST", "AVERAGE", "MAX"), "$fmt KiB/s");


// Debug
//$content = ob_get_clean();
//fwrite($fp, "$content\n");
//fclose($fp);

?>
