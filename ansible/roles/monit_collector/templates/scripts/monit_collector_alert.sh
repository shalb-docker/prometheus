#!/bin/bash

string='node_monit{type="monit_collector",name="stats_file_to_old"} 1'
echo $string > {{ monit_collector_textfile_directory }}monit.prom

