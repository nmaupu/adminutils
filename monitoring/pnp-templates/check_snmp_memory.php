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


$fmt = '%4.2lf';
$unit = 'B';

// Array remap
foreach($this->DS as $key => $value) {
  $ds[$value['NAME']] = $value;
}

$max = pnp::adjust_unit($ds['real_used']['MAX'], 1024, $fmt);
$upper = "-u $max[1]";
$unit_scale = $max[2];
$divis = $max[3];
$opt[1]  = "--vertical-label $unit_scale -l 0 $upper --title \"RAM usage for $hostname\" ";
$def[1]  = rrd::def("var1", $ds['real_used']['RRDFILE'], $ds['real_used']['DS']);
$def[1] .= rrd::def("var2", $ds['total']['RRDFILE'], $ds['total']['DS']);
$def[1] .= rrd::def("var3", $ds['shared']['RRDFILE'], $ds['shared']['DS']);
$def[1] .= rrd::def("var4", $ds['buffered']['RRDFILE'], $ds['buffered']['DS']);
$def[1] .= rrd::def("var5", $ds['cached']['RRDFILE'], $ds['cached']['DS']);
$def[1] .= rrd::def("var6", $ds['free']['RRDFILE'], $ds['free']['DS']);
$def[1] .= rrd::def("var7", $ds['swap_total']['RRDFILE'], $ds['swap_total']['DS']);
$def[1] .= rrd::def("var8", $ds['swap_free']['RRDFILE'], $ds['swap_free']['DS']);

$def[1] .= rrd::cdef("v_real_used", "var1,$divis,/");
$def[1] .= rrd::cdef("v_total", "var2,$divis,/");
$def[1] .= rrd::cdef("v_shared", "var3,$divis,/");
$def[1] .= rrd::cdef("v_buffered", "var4,$divis,/");
$def[1] .= rrd::cdef("v_cached", "var5,$divis,/");
$def[1] .= rrd::cdef("v_used", "var2,var6,-,$divis,/"); // total - used / $divis
$def[1] .= rrd::cdef("v_free", "var6,$divis,/");
$def[1] .= rrd::cdef("v_swtotal", "var7,$divis,/");
$def[1] .= rrd::cdef("v_swfree", "var8,$divis,/");
$def[1] .= rrd::cdef("v_swused", "var7,var8,-,$divis,/");


// Stacking all other values (used, cached, buffered, cached
$def[1] .= rrd::gradient("v_real_used", "#FF9900", "#FF5555", "Real used");
$def[1] .= rrd::line1("v_real_used", "#00000000"); // Invisible to be able to stack with gradient
#$def[1] .= rrd::area("v_real_used", "#FF9900", "Real used");
$def[1] .= rrd::gprint("v_real_used", array("AVERAGE", "MIN", "MAX", "LAST"), "$fmt$unit_scale");

$def[1] .= rrd::area("v_cached", "#FFAAFF", "Cached", true);
$def[1] .= rrd::gprint("v_cached", "LAST", "$fmt$unit_scale\\n");

$def[1] .= rrd::area("v_shared", "#0000FF", "Shared", true);
$def[1] .= rrd::gprint("v_shared", "LAST", "$fmt$unit_scale\\n");

$def[1] .= rrd::area("v_buffered", "#AAFFFF", "Buffered", true);
$def[1] .= rrd::gprint("v_buffered", "LAST", "$fmt$unit_scale\\n");

$def[1] .= rrd::area("v_free", "#FAFAAA", "Free", true);
$def[1] .= rrd::gprint("v_free", "LAST", "$fmt$unit_scale\\n");


// Stack swap on the same graph
$def[1] .= rrd::area("v_swused", "#3D3D3D", "Swap used", true);
$def[1] .= rrd::gprint("v_swused", array("AVERAGE", "MAX", "LAST"), "$fmt$unit_scale");

$def[1] .= rrd::area("v_swfree", "#DDDDDD", "Swap free", true);
$def[1] .= rrd::gprint("v_swfree", "LAST", "$fmt$unit_scale\\n");

$def[1] .= rrd::line1("v_real_used", "#000000");

// Draw total
$def[1] .= rrd::line1("v_total", "#009900", "Total");
$def[1] .= rrd::gprint("v_total", "LAST", "$fmt$unit_scale\\n");

// Debug
//fwrite($fp, ob_get_clean());
//fclose($fp);

?>
