#!/usr/bin/env python3

from __future__ import print_function
from __future__ import division
from __future__ import absolute_import
from __future__ import unicode_literals

import sys
import argparse

if sys.version_info.major == 2:
    import urllib2
    from BeautifulSoup import BeautifulSoup
else:
    import urllib.request as urllib2
    from bs4 import BeautifulSoup

class Apache_server_status:

    def _get_args(self):
        '''Get and parse cmd arguments'''
        self.conf = dict()
        parser = argparse.ArgumentParser()
        parser.add_argument('--print_slow_requests', action='store_true', help='find and print all slow requests if response time > max_request_time')
        parser.add_argument('--have_slow_requests', action='store_true', help='find and exit with status 1 if have slow requests')
        parser.add_argument('--max_request_time', default=10, type=int, help='set max requst time in seconds')
        parser.add_argument('--html_file', help='file name with saved server status in html')
        parser.add_argument('--status_url', default='http://127.0.0.1:8080/server-status', type=str, help='apache server status url')
        parser.add_argument('--debug', action='store_true', help='enable debug mode')
        args = parser.parse_args()
        for key in vars(args):
            self.conf[key] = vars(args)[key]

    def _get_html(self, url):
        '''Request URL and read response'''
        self.req = req = urllib2.Request(url)
        self.resp = resp = urllib2.urlopen(req)
        return resp.read()

    def _get_html_from_file(self, file_name):
        '''Read html from file'''
        with open(file_name) as html_file:
            self.resp = resp = html_file.read()
        return resp

    def _parse_connections(self, html):
        '''Parse connections info from html status'''
        parsed_data = list()
        soup_html = BeautifulSoup(html, "html.parser")
        threads_table = soup_html.find('table', attrs={'border': '0'})
        keys = threads_table.findAll('th')
        columns = list()
        # get cloumns
        for k in keys:
            col = k.find(text=True).strip()
            columns.append(col)
        rows = threads_table.findAll('tr')
        i = 0
        # get rows
        for r in rows:
            cells = r.findAll('td')
            if not cells:
                continue
            parsed_data.append(dict())
            for col, cel in zip(columns, cells):
                cel_out = cel.find(text=True)
                if cel_out:
                    parsed_data[i][col] = cel_out.strip()
            i += 1
        return parsed_data

    def _print_slow_requests(self, data):
        '''Print slow connections'''
        for i in data:
            if int(i['SS']) >= self.conf['max_request_time'] and i['PID'] != '-' and i['M'] != '_':
                l = 'Method: {0} URL: {1}{2} Client: {3} Seconds: {4} PID: {5}'.format(i['Request'].split()[0], i['VHost'], i['Request'].split()[1], i['Client'], i['SS'], i['PID'])
                print(l)

    def _have_slow_requests(self, data):
        '''return exit status 1 if have slow requests'''
        for i in data:
            if int(i['SS']) > self.conf['max_request_time'] and i['PID'] != '-':
                sys.exit(1)

    def run(self):
        self._get_args()
        if self.conf.get('html_file'):
            html = self._get_html_from_file(self.conf.get('html_file'))
        else:
            html = self._get_html(self.conf.get('status_url'))
        parsed_data = self._parse_connections(html)
        if self.conf.get('debug'):
            print(parsed_data[0].keys())
        if self.conf.get('print_slow_requests'):
            self._print_slow_requests(parsed_data)
        if self.conf.get('have_slow_requests'):
            self._have_slow_requests(parsed_data)
                
        
if __name__ == '__main__':
    C = Apache_server_status()
    C.run()
    
