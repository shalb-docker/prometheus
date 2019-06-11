#!/usr/bin/env python

from __future__ import print_function
from __future__ import division
from __future__ import absolute_import
from __future__ import unicode_literals

import datetime
import sys
import re

class Rsnapshot():
    def __init__(self):
        '''Init this class'''
        self.get_config()

    def get_config(self):
        '''Create or get config from source'''
        self.conf = conf = dict()
        conf['error_patterns'] = ['WARNING:', 'ERROR:']
        conf['error_patterns_to_ignore'] = [': completed, but with some warnings']
        conf['date_patterns'] = {
            '%d/%b/%Y:%H:%M:%S': re.compile(r'^\[(\d{2}/[A-Z]{1}[a-z]{2}/\d{4}:\d{2}:\d{2}:\d{2})'),
            '%Y-%m-%dT%H:%M:%S': re.compile(r'^\[(\d{4}\-\d{2}\-\d{2}T\d{2}:\d{2}:\d{2})')
        }
        if len(sys.argv) >= 2:
            conf['log_file_name'] = sys.argv[1]
        else:
            conf['log_file_name'] = '/var/log/rsnapshot'
        conf['log_file_min_num_of_lines'] = 3
        conf['multiline_pattern'] = '['
        conf['hours_to_check'] = 24
        conf['date_start'] = datetime.datetime.now() - datetime.timedelta(hours=24)
        conf['date_end'] = datetime.datetime.now()

    def _date_from_string(self, line):
        '''Get date from log string'''
        date = match = False
        for key in self.conf['date_patterns']:
            pat = self.conf['date_patterns'][key]
            match = pat.search(line)
            if match:
                date = datetime.datetime.strptime(match.group(1), key)
        return date

    def _get_log_to_check(self):
        '''Get log records which match to patterns'''
        self.log_to_check = list()
        with open(self.conf['log_file_name']) as log_file:
            for line in log_file:
                line_date = self._date_from_string(line)
                if not line_date:
                    continue
                elif self.log_to_check and not line_date:
                    self.log_to_check[-1] += line
                    continue
                if self.conf['date_end'] >= line_date >= self.conf['date_start']:
                    self.log_to_check.append(line.strip().replace('[', ''))
        if not self.log_to_check:
            print('Rsnapshot log: "{0}" have no records for current day'.format(self.conf['log_file_name']))
            sys.exit(1)
        elif len(self.log_to_check) < self.conf['log_file_min_num_of_lines']:
            print('Rsnapshot log: "{0}" to small - have < {1} records to check'.format(self.conf['log_file_name'], self.conf['log_file_min_num_of_lines']))
            sys.exit(1)

    def _get_errors(self):
        '''Get errors from given part of log'''
        self.errors = list()
        for line in self.log_to_check:
            for pat in self.conf['error_patterns']:
                if pat in line:
                    if not self._skip_error(line):
                        self.errors.append(line)

    def _skip_error(self, line):
        '''Skip errors if matched to ignored patterns'''
        for pat in self.conf['error_patterns_to_ignore']:
            if pat in line:
                return True
    
    def write_results(self):
        '''Write results of check to output'''
        if self.errors:
            print('Rsnapshot log: "{0}" have {1} errors today'.format(self.conf['log_file_name'], len(self.errors)))
            for line in self.errors[-3:]:
                print(line)
            if len(self.errors) > 3:
                print('...')
            sys.exit(1)

    def check_backup_success(self):
        '''Check if backup was successful'''
        self._get_log_to_check()
        self._get_errors()
        self.write_results()


if __name__ == '__main__':
    rsnap = Rsnapshot()
    rsnap.check_backup_success()

