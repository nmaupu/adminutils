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
//print_r($this->DS);

$DS_gc1_count = $this->DS[0];
$DS_gc2_count = $this->DS[1];
$DS_gc1_time  = $this->DS[2];
$DS_gc2_time  = $this->DS[3];

$opt[1]  = "--vertical-label \"GC usage\" -l 0 --title \"$hostname - GC usage\" ";
$def[1]  = rrd::def("var1", $DS_gc1_count['RRDFILE'], $DS_gc1_count['DS']);
$def[1] .= rrd::def("var2", $DS_gc2_count['RRDFILE'], $DS_gc2_count['DS']);
$def[1] .= rrd::def("var3", $DS_gc1_time['RRDFILE'], $DS_gc1_time['DS']);
$def[1] .= rrd::def("var4", $DS_gc2_time['RRDFILE'], $DS_gc2_time['DS']);

$def[1] .= rrd::line1("var1", "#00FF00", $DS_gc1_count['NAME']);
$def[1] .= rrd::gprint("var1", array("LAST", "MAX", "AVERAGE"), "%3.2lfcount/s");

$def[1] .= rrd::line1("var2", "#0000FF", $DS_gc2_count['NAME']);
$def[1] .= rrd::gprint("var2", array("LAST", "MAX", "AVERAGE"), "%3.2lfcount/s");


$def[1] .= rrd::line2("var3", "#FFFF00", $DS_gc1_time['NAME']);
$def[1] .= rrd::gprint("var3", array("LAST", "MAX", "AVERAGE"), "%3.2lfms/s");

$def[1] .= rrd::line2("var4", "#FF00FF", $DS_gc2_time['NAME']);
$def[1] .= rrd::gprint("var4", array("LAST", "MAX", "AVERAGE"), "%3.2lfms/s");



// Debug
//$content = ob_get_clean();
//fwrite($fp, "$content\n");
//fclose($fp);
?>
