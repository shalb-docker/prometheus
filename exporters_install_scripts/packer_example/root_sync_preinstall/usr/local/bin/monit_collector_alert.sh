#!/bin/bash

string='node_monit{type="monit_collector",name="stats_file_to_old"} 1'
echo $string > /home/monitoring/node_exporter/textfile_directory/monit.prom
chown monitoring:monitoring /home/monitoring/node_exporter/textfile_directory/monit.prom
