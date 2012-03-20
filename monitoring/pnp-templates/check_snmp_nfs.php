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

$fp = fopen('/tmp/test', 'a');
ob_start();

$DS_status   = $this->DS[0];
$DS_read     = $this->DS[1];
$DS_write    = $this->DS[2];
$DS_create   = $this->DS[3];
$DS_mkdir    = $this->DS[4];
$DS_symlink  = $this->DS[5];
$DS_mknod    = $this->DS[6];
$DS_remove   = $this->DS[7];
$DS_rmdir    = $this->DS[8];
$DS_rename   = $this->DS[9];
$DS_readdir  = $this->DS[10];
$DS_readdirp = $this->DS[11];


$opt[1]  = "--vertical-label \"Requests / s\" -l0 --title \"$hostname - NFS statistics\" ";
$def[1]  = rrd::def("var_status", $DS_status['RRDFILE'], $DS_status['DS']);
$def[1] .= rrd::def("var_read", $DS_read['RRDFILE'], $DS_read['DS']);
$def[1] .= rrd::def("var_write", $DS_write['RRDFILE'], $DS_write['DS']);
//$def[1] .= rrd::def("var_create", $DS_create['RRDFILE'], $DS_create['DS']);
//$def[1] .= rrd::def("var_mkdir", $DS_mkdir['RRDFILE'], $DS_mkdir['DS']);
//$def[1] .= rrd::def("var_symlink", $DS_symlink['RRDFILE'], $DS_symlink['DS']);
//$def[1] .= rrd::def("var_mknod", $DS_mknod['RRDFILE'], $DS_mknod['DS']);
//$def[1] .= rrd::def("var_remove", $DS_remove['RRDFILE'], $DS_remove['DS']);
//$def[1] .= rrd::def("var_rmdir", $DS_rmdir['RRDFILE'], $DS_rmdir['DS']);
//$def[1] .= rrd::def("var_rename", $DS_rename['RRDFILE'], $DS_rename['DS']);
//$def[1] .= rrd::def("var_readdir", $DS_readdir['RRDFILE'], $DS_readdir['DS']);
//$def[1] .= rrd::def("var_readdirp", $DS_readdirp['RRDFILE'], $DS_readdirp['DS']);

$def[1] .= rrd::cdef("v_read", "var_read,-1,*");

$def[1] .= rrd::gradient("v_read", "#33CCFF", "#0000FF", "Read");
$def[1] .= rrd::gprint("var_read", array("LAST", "AVERAGE", "MAX"), "%6.2lfreq/s");

$def[1] .= rrd::gradient("var_write", "#FFCC66", "#FF0000", "Write");
$def[1] .= rrd::gprint("var_write", array("LAST", "AVERAGE", "MAX"), "%6.2lfreq/s");

$def[1] .= rrd::hrule(0, "#838383");

//$def[1] .= rrd::line1("var_create", "#0000AA", "Create");
//$def[1] .= rrd::gprint("var_create", array("LAST", "AVERAGE", "MAX"), "%6.2lf");
//
//$def[1] .= rrd::line1("var_mkdir", "#0000FF", "Mkdir");
//$def[1] .= rrd::gprint("var_mkdir", array("LAST", "AVERAGE", "MAX"), "%6.2lf");
//
//$def[1] .= rrd::line1("var_symlink", "#005500", "Symlink");
//$def[1] .= rrd::gprint("var_symlink", array("LAST", "AVERAGE", "MAX"), "%6.2lf");
//
//$def[1] .= rrd::line1("var_mknod", "#00AA00", "Mknod");
//$def[1] .= rrd::gprint("var_mknod", array("LAST", "AVERAGE", "MAX"), "%6.2lf");
//
//$def[1] .= rrd::line1("var_remove", "#00FF00", "Remove");
//$def[1] .= rrd::gprint("var_remove", array("LAST", "AVERAGE", "MAX"), "%6.2lf");
//
//$def[1] .= rrd::line1("var_rmdir", "#005555", "Rmdir");
//$def[1] .= rrd::gprint("var_rmdir", array("LAST", "AVERAGE", "MAX"), "%6.2lf");
//
//$def[1] .= rrd::line1("var_rename", "#0055AA", "Rename");
//$def[1] .= rrd::gprint("var_rename", array("LAST", "AVERAGE", "MAX"), "%6.2lf");
//
//$def[1] .= rrd::line1("var_readdir", "#0055FF", "Readdir");
//$def[1] .= rrd::gprint("var_readdir", array("LAST", "AVERAGE", "MAX"), "%6.2lf");
//
//$def[1] .= rrd::line1("var_readdirp", "#00AA55", "Readdirplus");
//$def[1] .= rrd::gprint("var_readdirp", array("LAST", "AVERAGE", "MAX"), "%6.2lf");



//$DS_1  = $this->DS[0];
//$DS_5  = $this->DS[1];
//$DS_15 = $this->DS[2];
//
//$def[1]  = rrd::def("var1", $DS_1['RRDFILE'],  $DS_1['DS']);
//$def[1] .= rrd::def("var2", $DS_5['RRDFILE'],  $DS_5['DS']);
//$def[1] .= rrd::def("var3", $DS_15['RRDFILE'], $DS_15['DS']);
//
//$def[1] .= rrd::area("var1", $C1, "Load 1");
//$def[1] .= rrd::gprint("var1", array("LAST", "AVERAGE", "MAX"), "%6.2lf");
//
//$def[1] .= rrd::line1("var2", $C5, "Load 5");
//$def[1] .= rrd::gprint("var2", array("LAST", "AVERAGE", "MAX"), "%6.2lf");
//
//$def[1] .= rrd::line1("var3", $C15, "Load 15");
//$def[1] .= rrd::gprint("var3", array("LAST", "AVERAGE", "MAX"), "%6.2lf");

// Debug
$content = ob_get_clean();
fwrite($fp, "$content\n");
fclose($fp);

?>
