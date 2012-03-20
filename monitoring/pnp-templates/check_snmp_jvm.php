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

$DS_mem = $this->DS[0];
$DS_pool = $this->DS[1];

$fmt = '%4.2lf';

$unit = $DS_mem['UNIT'];
$max = pnp::adjust_unit($DS_mem['MAX'].$unit, 1024, $fmt);
$upper = "-u $max[1]";

# set graph labels
$opt[1] = "--vertical-label $unit -l 0 $upper --title \"JVM ".$DS_mem['NAME']."\" ";

# Graph Definitions
$def[1] = rrd::def("var1", $DS_mem['RRDFILE'], $DS_mem['DS']);
$def[1] .= rrd::def("var2", $DS_pool['RRDFILE'], $DS_pool['DS']);

# "normalize" graph values
$divis = $max[3];
$def[1] .= rrd::cdef("v_n", "var1,$divis,/");
$def[1] .= rrd::cdef("v_pool","var2,$divis,/");

$def[1] .= rrd::gradient("v_n", "00FF33", "339900", $DS_mem['NAME']);
$def[1] .= rrd::line1( "v_n", "#003300" );
$def[1] .= rrd::gprint("v_n", array("LAST", "MAX", "AVERAGE"), "$fmt $unit");


$def[1] .= rrd::gradient("v_pool", "00FFDD", "3399DD", $DS_pool['NAME']);
$def[1] .= rrd::line1("v_pool", "#003300");
$def[1] .= rrd::gprint("v_pool", "LAST", "$fmt $unit\\n");


# create max line and legend
//$def[1] .= rrd::gprint("v_n", "MAX", "$fmt $unit max used \\n");
$def[1] .= rrd::hrule($max[1], "#003300", "Max size ($max[0]) \\n");

# create warning line and legend
$warn = pnp::adjust_unit( $DS_mem['WARN'].$unit, 1024, $fmt );
$def[1] .= rrd::hrule( $warn[1], "#ffff00", "Warning ($warn[0]) \\n" );

# create critical line and legend
$crit = pnp::adjust_unit( $DS_mem['CRIT'].$unit, 1024, $fmt );
$def[1] .= rrd::hrule( $crit[1], "#ff0000", "Critical ($crit[0])\\n" );

# Create pool line and legend


## Legend header
#$def[1] .= rrd::gprint("v_n", "MAX", "Max used \: $fmt $unit\\t");
#$def[1] .= rrd::gprint("v_n", "AVERAGE", "Average used \: $fmt $unit\\n");


//print_r($def[1]);



// Debug
//$content = ob_get_clean();
//fwrite($fp, "$content\n");
//fclose($fp);
?>
