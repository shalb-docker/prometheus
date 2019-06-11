#!/usr/bin/env python

from __future__ import print_function
from __future__ import division
from __future__ import absolute_import
from __future__ import unicode_literals

import subprocess
import os
import sys
import re

conf = dict()
conf['mailq_bins'] = [
    '/usr/bin/mailq_custom.sh',
    '/usr/bin/mailq',
    ]
conf['patterns'] = [
    r'^\d+\s+matches\s+out\s+of\s+(\d+)\s+messages$',
    r'^total\s+requests:\s+(\d+)',
    r'^\-\-\s+\d+\s+kbytes\s+in\s+(\d+)\s+requests\.$',
    ]
conf['exporter_file'] = '{{ node_exporter_textfile_directory }}mail_queue.prom'

data = dict()

def find_mailq():
    for mq in conf['mailq_bins']:
        if os.path.isfile(mq):
            return mq
    data['mail_count'] = -1
    write_to_exporter()

def get_mailq():
    command = find_mailq().split()
    proc0 = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    proc = proc0.communicate()
    stdout = proc[0]
    if isinstance(stdout, bytes):
        stdout = stdout.decode().split('\n')[-3:-1]
    else:
        stdout = stdout.split('\n')[-3:-1]
    for line in stdout:
        line = line.strip().lower()
        for pat in conf['patterns']:
            match = re.search(pat, line)
            if match:
                data['mail_count'] = match.group(1)
                break
            elif re.search(r'^mail\s+queue\s+is\s+empty$', line):
                data['mail_count'] = 0
                break

def write_to_exporter():
    if data.get('mail_count') == None:
        print('Have no mail_count, please check parsing code')
        sys.exit(0)
    with open(conf['exporter_file'], 'w') as exporter_file:
        exporter_file.write('node_mail_queue {0}\n'.format(float(data['mail_count'])))
    sys.exit(0)

get_mailq()
write_to_exporter()

