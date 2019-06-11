#!/usr/bin/env python

from __future__ import print_function
from __future__ import division
from __future__ import absolute_import
from __future__ import unicode_literals

import os
import json
import sys

file_name = '{{ monit_collector_log_file }}'
pattern = 'CRITICAL'
results_dir = '/root/scripts_tmp/'
results_file = '{0}{1}.results'.format(results_dir, os.path.split(file_name)[-1])
matched_lines = list()

# get last results
current_file_size = os.stat(file_name)[6]

start_possition = 0
if os.path.isdir(results_dir):
    if os.path.isfile(results_file):
        last_results = json.loads(open(results_file).read())
        last_file_size = last_results['last_file_size']
        if current_file_size > last_file_size:
            start_possition = last_file_size
        elif current_file_size == last_file_size:
            sys.exit()

else:
    os.mkdir(results_dir)

with open(file_name) as f:
    f.seek(start_possition)
    line = f.readline()
    while line:
        if line.find(pattern) != -1:
            matched_lines.append(line.strip())
        line = f.readline()
    current_file_size = f.tell()

results = {
    'last_file_size': current_file_size,
}

json.dump(results, open(results_file, 'w'))

if matched_lines:
    print('Found {0} exceptions:'.format(len(matched_lines)))
    for line in matched_lines:
        print(line)
    sys.exit(1)

