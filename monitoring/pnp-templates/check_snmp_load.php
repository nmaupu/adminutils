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

$opt[1] = "--slope-mode --vertical-label Load -l0 --title \"CPU Load for $hostname / $servicedesc\" ";

$DS_1  = $this->DS[0];
$DS_5  = $this->DS[1];
$DS_15 = $this->DS[2];

$C15 = '#FF0000';
$C5  = '#0000FF';
$C1  = '#EACC00';

$def[1]  = rrd::def("var1", $DS_1['RRDFILE'],  $DS_1['DS']);
$def[1] .= rrd::def("var2", $DS_5['RRDFILE'],  $DS_5['DS']);
$def[1] .= rrd::def("var3", $DS_15['RRDFILE'], $DS_15['DS']);

$def[1] .= rrd::area("var1", $C1, "Load 1");
$def[1] .= rrd::gprint("var1", array("LAST", "AVERAGE", "MAX"), "%6.2lf");

$def[1] .= rrd::line1("var2", $C5, "Load 5");
$def[1] .= rrd::gprint("var2", array("LAST", "AVERAGE", "MAX"), "%6.2lf");

$def[1] .= rrd::line1("var3", $C15, "Load 15");
$def[1] .= rrd::gprint("var3", array("LAST", "AVERAGE", "MAX"), "%6.2lf");

?>
