#!/usr/bin/env python
from __future__ import print_function
from __future__ import division
from __future__ import absolute_import
from __future__ import unicode_literals

from xml.etree import cElementTree as ElementTree
import socket
import datetime
import gzip
import io
import time
import re
import sys
import traceback
import logging
import os
import argparse
import signal
import json
import errno
import subprocess
if sys.version_info.major == 2:
    import urllib2
else:
    import urllib.request as urllib2


def test_alert():
    events = list()
    alert_name = '{0}-{1}-team_{2}'.format(conf['test_alert_name'], conf['test_alert_priority'], conf['test_alert_team'])
    xml_data = {'server': {'localhostname': conf['host_name']}}
    xml_data['event'] = {'collected_usec': '999999', 'service': alert_name, 'state': '1', 'action': '9', 'message': conf['test_alert_message'], 'type': '999', 'id': '9999999', 'collected_sec': '9999999999'}
    check_alerts(xml_data)
    time.sleep(conf['test_alert_life_time'])
    xml_data['event']['state'] = '0'
    check_alerts(xml_data)
    sys.exit(0)

def parse_arguments():
    # parse args
    parser = argparse.ArgumentParser()
    parser.add_argument('--config_file', default=sys.argv[0] + '.conf', help='config file name')
    parser.add_argument('--host', help='IP to accept connections')
    parser.add_argument('--port', type=int, help='port to accept connections')
    parser.add_argument('--log_file', help='log file name')
    parser.add_argument('--log_level', help='logging level')
    parser.add_argument('--pid_file', help='pid file name')
    parser.add_argument('--textfile_directory', help='textfile_directory for node_exporter')
    parser.add_argument('--daemon', action='store_true', help='run in daemon mode')
    parser.add_argument('--alert_provider', help='send alert message via this alert provider name')
    parser.add_argument('--test_alert', action='store_true', help='open/close test alert')
    parser.add_argument('--test_alert_name', help='set message for test alert')
    parser.add_argument('--test_alert_priority', help='set priority for test alert')
    parser.add_argument('--test_alert_team', help='set team for test alert')
    parser.add_argument('--test_alert_message', help='set message for test alert')
    parser.add_argument('--test_alert_life_time', help='set how many seconds will live test alert')
    args = parser.parse_args()
    return args

def parse_config(args):
    # add config to conf
    with open(args.config_file) as config:
        conf = json.load(config)

    # add args to conf
    for key in vars(args):
        val = vars(args)[key]
        # do not override daemon key if argument is empty
        if val:
            conf[key] = val
    return conf

def configure_response():
    # configure response data
    response_date = datetime.datetime.now().strftime('Date: %a, %d %b %Y %H:%M:%S GMT')

    tmp_response = [ 'HTTP/1.1 200 OK',
        'Server: nginx/1.12.1',
        response_date,
        'Server: mmonit/3.7.1',
        'Content-Type: text/plain',
        'Content-Length: 0',
        'Expires: Sun, 21 Feb 1993 00:29:55 GMT',
        'Connection: keep-alive',
        'Cache-Control: no-cache',
        'Keep-Alive: timeout=15, max=99',
        'Pragma: no-cache'
        ]
    conf['response'] = '\r\n'.join(tmp_response) + '\r\n\r\n'

def configure_stop_condition():
    # add exit controll key
    conf['exit'] = False
    signal.signal(15, exit_daemon)

def configure_logging():
    # configure logging
    log = logging.getLogger(__name__)
    log.setLevel(conf['log_level'])
    FORMAT = '%(asctime)s %(levelname)s %(message)s'
    if conf['daemon']:
        logging.basicConfig(format=FORMAT, filename=conf['log_file'])
    elif conf['test_alert']:
        logging.basicConfig(format=FORMAT)
    else:
        logging.basicConfig(format=FORMAT, filename=conf['log_file'])
    return log

def enable_daemon_mode():
    # fork if daemon mode
    if conf['daemon']:
        if os.fork():
            sys.exit()

def write_pid_file():
    '''Write PID of current process'''
    with open(conf['pid_file'], 'w') as pid:
        parent_dir = os.path.dirname(conf['pid_file'])
        if not os.path.exists(parent_dir):
            if not os.path.isdir(parent_dir):
                log.critical('Cant create directory: "{0}" because file with same name exist'.format(parent_dir))
            os.mkdir(parent_dir, int('0755', base=8))
        pid.write(str(os.getpid()))

class XmlListConfig(list):
    '''First class for xml parsing'''
    def __init__(self, aList):
        for element in aList:
            if element:
                # treat like dict
                if len(element) == 1 or element[0].tag != element[1].tag:
                    self.append(XmlDictConfig(element))
                # treat like list
                elif element[0].tag == element[1].tag:
                    self.append(XmlListConfig(element))
            elif element.text:
                text = element.text.strip()
                if text:
                    self.append(text)


class XmlDictConfig(dict):
    '''
    Second class for xml parsing

    Example usage:

    >>> tree = ElementTree.parse('your_file.xml')
    >>> root = tree.getroot()
    >>> xmldict = XmlDictConfig(root)

    Or, if you want to use an XML string:

    >>> root = ElementTree.XML(xml_string)
    >>> xmldict = XmlDictConfig(root)

    And then use xmldict for what it is... a dict.
    '''
    def __init__(self, parent_element):
        if parent_element.items():
            self.update(dict(parent_element.items()))
        for element in parent_element:
            if element:
                # treat like dict - we assume that if the first two tags
                # in a series are different, then they are all different.
                if len(element) == 1 or element[0].tag != element[1].tag:
                    aDict = XmlDictConfig(element)
                # treat like list - we assume that if the first two tags
                # in a series are the same, then the rest are the same.
                else:
                    # here, we put the list in dictionary; the key is the
                    # tag name the list elements all share in common, and
                    # the value is the list itself 
                    aDict = {element[0].tag: XmlListConfig(element)}
                # if the tag has attributes, add those to the dict
                if element.items():
                    aDict.update(dict(element.items()))
                self.update({element.tag: aDict})
            # this assumes that if you've got an attribute in a tag,
            # you won't be having any text. This may or may not be a 
            # good idea -- time will tell. It works for the way we are
            # currently doing XML configuration files...
            elif element.items():
                self.update({element.tag: dict(element.items())})
            # finally, if there are no child tags and no attributes, extract
            # the text
            else:
                self.update({element.tag: element.text})

def open_alert_opsgenie_lamp(index):
    event = events[index]
    data_to_send = dict()
    data_to_send['help'] = conf['help'].format(host_name=conf['host_name'], service=event['service'])
    data_to_send['grafana'] = conf['grafana'].format(host_name=conf['host_name'], service=event['service'])
    data_to_send['message'] = conf['message'].format(host_name=conf['host_name'], service=event['service'])
    data_to_send['prometheus'] = conf['prometheus'].format(host_name=conf['host_name'], service=event['service'])
    data_to_send['source'] = conf['ip']
    data_to_send['alias'] = '{0}_{1}_{2}_{3}'.format(event['service'], event['priority'], conf['host_name'], event['team']).replace('/', '-')
    data_to_send['description'] = event['message']
    data_to_send['priority'] = event['priority']
    data_to_send['teams'] = event['team']
    data_to_send['host'] = conf['host_name']
    data_to_send['service'] = event['service']
    command_tmp = [
        "/opt/opsgenie_lamp/lamp", "createAlert",
        "--message={message}", "--source={source}",
        "--alias={alias}", "--description={description}",
        "--priority={priority}", "--teams={teams}",
        "-D", "host={host}", "-D", "service={service}",
        "-D", "help={help}", "-D", "grafana={grafana}",
        "-D", "prometheus={prometheus}"
        ]
    command = list(command_tmp)
    for ind in range(len(command_tmp)):
        command[ind] = command_tmp[ind].format(**data_to_send)
    try:
        response = run_proc(command)
        events.pop(index)
        log.info('Open alert: "{0} | {1}" Responce: "{2}"'.format(event['service'], event['message'], response))
    except:
        log.critical('Failed to open alert: "{0} | {1}" in opsgenie"'.format(event['service'], event['message']))
        trace = traceback.format_exception(sys.exc_info()[0], sys.exc_info()[1], sys.exc_info()[2])
        for line in trace:
            log.critical(line[:-1])

def open_alert_opsgenie_api(index):
    event = events[index]
    data_to_send = dict()
    help_message = conf['help'].format(host_name=conf['host_name'], service=event['service'])
    grafana_link = conf['grafana'].format(host_name=conf['host_name'], service=event['service'])
    prometheus_link = conf['prometheus'].format(host_name=conf['host_name'], service=event['service'])
    data_to_send['message'] = conf['message'].format(host_name=conf['host_name'], service=event['service'])
    data_to_send['source'] = conf['ip']
    data_to_send['alias'] = '{0}_{1}_{2}_{3}'.format(event['service'], event['priority'], conf['host_name'], event['team']).replace('/', '-')
    data_to_send['details'] = {'host': conf['host_name'], 'service': event['service'], 'help message': help_message, 'grafana': grafana_link, 'prometheus': prometheus_link}
    data_to_send['description'] = event['message']
    data_to_send['priority'] = event['priority']
    data_to_send['responders'] = [ {'name': event['team'], 'type': 'team'} ]
    url = '{0}/v2/alerts'.format(conf['opsgenie_url'])
    req = urllib2.Request(url)
    req.add_header('Content-Type', 'application/json; charset=utf-8')
    req.add_header('Authorization', conf['opsgenie_api_key'])
    try:
        response = urllib2.urlopen(req, json.dumps(data_to_send).encode('utf-8'), conf['http_timeout'])
        events.pop(index)
        log.info('Open alert: "{0} | {1}" Responce: "{2}"'.format(event['service'], event['message'], response.read()))
    except:
        log.critical('Failed to open alert: "{0} | {1}" in opsgenie'.format(event['service'], event['message']))
        trace = traceback.format_exception(sys.exc_info()[0], sys.exc_info()[1], sys.exc_info()[2])
        for line in trace:
            log.critical(line[:-1])

def open_alert(index):
    '''Open alert in opsgenie'''
    open_alert_function = globals()['open_alert_' + conf['alert_provider']]
    task_status = open_alert_function(index)

def close_alert_opsgenie_lamp(index):
    event = events[index]
    data_to_send = dict()
    data_to_send['user'] = 'monit_collector'
    data_to_send['alias'] = '{0}_{1}_{2}_{3}'.format(event['service'], event['priority'], conf['host_name'], event['team']).replace('/', '-')
    command_tmp = [
        "/opt/opsgenie_lamp/lamp", "closeAlert",
        "--user={user}", "--alias={alias}"
        ]
    command = list(command_tmp)
    for ind in range(len(command_tmp)):
        command[ind] = command_tmp[ind].format(**data_to_send)
    try:
        response = run_proc(command)
        log.info('Close alert: "{0} | {1}" Responce: "{2}"'.format(event['service'], event['message'], response))
        events.pop(index)
    except:
        log.critical('Failed to close alert: "{0} | {1}" in opsgenie'.format(event['service'], event['message']))
        trace = traceback.format_exception(sys.exc_info()[0], sys.exc_info()[1], sys.exc_info()[2])
        for line in trace:
            log.critical(line[:-1])

def close_alert_opsgenie_api(index):
    event = events[index]
    alias = '{0}_{1}_{2}_{3}'.format(event['service'], event['priority'], conf['host_name'], event['team']).replace('/', '-')
    url = '{0}/v2/alerts/{1}/close?identifierType=alias'.format(conf['opsgenie_url'], alias)
    data_to_send = dict()
    data_to_send['user'] = 'monit_collector'
    req = urllib2.Request(url)
    req.add_header('Content-Type', 'application/json; charset=utf-8')
    req.add_header('Authorization', conf['opsgenie_api_key'])
    try:
        response = urllib2.urlopen(req, json.dumps(data_to_send).encode('utf-8'), conf['http_timeout'])
        log.info('Close alert: "{0} | {1}" Responce: "{2}"'.format(event['service'], event['message'], response.read()))
        events.pop(index)
    except:
        log.critical('Failed to close alert: "{0} | {1}" in opsgenie'.format(event['service'], event['message']))
        trace = traceback.format_exception(sys.exc_info()[0], sys.exc_info()[1], sys.exc_info()[2])
        for line in trace:
            log.critical(line[:-1])

def close_alert(index):
    '''Close alert in opsgenie'''
    close_alert_function = globals()['close_alert_' + conf['alert_provider']]
    task_status = close_alert_function(index)

def check_alerts(xml_data):
    '''Open/Close alert'''
    event_raw = xml_data.get('event')
    event = dict()
    if event_raw:
        log.debug('Event: {0}'.format(event_raw))
        regexp = re.search(r'(?P<name>.*?)\-(?P<priority>P[1-5])\-(team_(?P<team>[A-Za-z]+))?$', event_raw['service'])
        if regexp:
            event['service'] = regexp.groupdict()['name']
            event['priority'] = regexp.groupdict()['priority']
            event['team'] = regexp.groupdict()['team']
            if not event['team']:
                event['team'] = conf['opsgenie_default_team']
        else:
            event['service'] = event_raw['service']
            event['priority'] = conf['opsgenie_default_priority']
            event['team'] = conf['opsgenie_default_team']
        event['message'] = event_raw['message']
        event['state'] = event_raw['state']
        if event['team'] == 'noalert':
            log.info('Team is "noalert", skipping event: {0}'.format(event_raw))
            return
        elif conf['disable_own_alerting_code']:
            log.info('Own alerts disabled, skipping event: {0}'.format(event_raw))
            return
        events.append(event)
    for index in range(len(events)):
        if events[index]['state'] == '1':
            open_alert(index)
        elif events[index]['state'] == '0':
            close_alert(index)
        else:
            log.info('Non-alert event: {0}'.format(events.pop(index)['message']))

def run_proc(command):
        proc = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        for _ in range(conf['http_timeout']):
            time.sleep(1)
            proc.poll()
            if proc.returncode != None:
                break
        if proc.returncode == None:
            proc.kill()
            response = 'Process killed, because reached timeout: {0} seconds'.format(conf['http_timeout'])
        else:
            response = proc.communicate()
            response = 'return code: {0} stdout: {1} stderr: {2}'.format(proc.returncode, *response)
        return response
            
def exit_daemon(*args):
    '''Remove pid_file, stop daemon'''
    log.info('Got signal to exit, exiting...')
    conf['exit'] = True
    if os.path.exists(conf['pid_file']):
        if os.path.isfile(conf['pid_file']):
            os.remove(conf['pid_file'])

def parse_headers(raw_data):
    '''Parse http headers'''
    headers = dict()
    lines = raw_data.decode(encoding='ISO-8859-1').split('\r\n')
    for line in lines[1:]:
        if line:
            key = line.split(':')[0].lower().strip()
            val = line.split(':')[1].lower().strip()
            headers[key] = val
        else:
            break
    headers['content-length'] = int(headers['content-length'])
    return headers

def get_data(raw_data, length, conn):
    '''Get data from connection'''
    data_start = raw_data.decode(encoding='ISO-8859-1').find('\r\n\r\n') + 4
    for _ in range(3):
        data = raw_data[data_start:]
        if len(data) != length:
            time.sleep(1)
            raw_data += conn.recv(10 * 1024 * 1024)
        else:
            return data
    return False

def collector_start_2(host, port):
    '''Listen port as monit collector for python2'''
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    log.debug('listen start')
    s.bind((host, port))
    s.listen(1)
    while True:
        if conf['exit']:
            break
        try:
            conn, addr = s.accept()
            log.debug('Connected by {0}'.format(addr))
            raw_data = conn.recv(10 * 1024 * 1024)
            headers = parse_headers(raw_data)
            data = get_data(raw_data, headers['content-length'], conn)
            if headers.get('content-encoding') == 'gzip':
                with open('/tmp/monit_collector.gz', 'wb') as compressed_data:
                    compressed_data.write(data)
                with gzip.open('/tmp/monit_collector.gz', 'rb') as compressed_data:
                    data = compressed_data.read()
            conn.sendall(conf['response'].encode(encoding='ISO-8859-1'))
            conn.close()
            if isinstance(data, bytes):
                data = data.decode(encoding='ISO-8859-1')
            if data.startswith('<?xml version='):
                root = ElementTree.XML(data)
                xml_data = XmlDictConfig(root)
                parsed_data = parse_data(xml_data)
                check_alerts(xml_data)
                write_data_to_file(parsed_data)
            else:
                log.warning('No xml data')
            write_pid_file()
        except KeyboardInterrupt:
            exit_daemon()
        except IOError as e:
            if e.errno != errno.EINTR:
                trace = traceback.format_exception(sys.exc_info()[0], sys.exc_info()[1], sys.exc_info()[2])
                for line in trace:
                    log.critical(line[:-1])
                time.sleep(1)
        except:
            trace = traceback.format_exception(sys.exc_info()[0], sys.exc_info()[1], sys.exc_info()[2])
            for line in trace:
                log.critical(line[:-1])
            time.sleep(1)

def collector_start_3(host, port):
    '''Listen port as monit collector for python3'''
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        log.debug('listen start')
        s.bind((host, port))
        s.listen(1)
        while True:
            if conf['exit']:
                break
            try:
                conn, addr = s.accept()
                with conn:
                    log.debug('Connected by {0}'.format(addr))
                    raw_data = conn.recv(10 * 1024 * 1024)
                    headers = parse_headers(raw_data)
                    data = get_data(raw_data, headers['content-length'], conn)
                    if headers.get('content-encoding') == 'gzip':
                        with open('/tmp/monit_collector.gz', 'wb') as compressed_data:
                            compressed_data.write(data)
                        with gzip.open('/tmp/monit_collector.gz', 'rb') as compressed_data:
                            data = compressed_data.read().decode(encoding='ISO-8859-1')
                    conn.sendall(conf['response'].encode(encoding='ISO-8859-1'))
                    if isinstance(data, bytes):
                        data = data.decode(encoding='ISO-8859-1')
                    if data.startswith('<?xml version='):
                        root = ElementTree.XML(data)
                        xml_data = XmlDictConfig(root)
                        parsed_data = parse_data(xml_data)
                        check_alerts(xml_data)
                        write_data_to_file(parsed_data)
                    else:
                        log.warning('No xml data')
                write_pid_file()
            except KeyboardInterrupt:
                exit_daemon()
            except InterruptedError as e:
                if e.errno != errno.EINTR:
                    trace = traceback.format_exception(sys.exc_info()[0], sys.exc_info()[1], sys.exc_info()[2])
                    for line in trace:
                        log.critical(line[:-1])
                    time.sleep(1)
            except:
                trace = traceback.format_exception(sys.exc_info()[0], sys.exc_info()[1], sys.exc_info()[2])
                for line in trace:
                    log.critical(line[:-1])
                time.sleep(1)

def get_labels(data):
    '''Get values which will be added as labels to final string'''
    priority_match = re.search(r'(?P<name>.+?)\-(?P<priority>P[1-5])\-', data['name'])
    labels_line = ''
    for key in data:
        if key in conf['labels']:
            labels_line += ',{0}="{1}"'.format(key, data[key])
    labels_line += ',{0}="{1}"'.format('type', conf['types'][int(data['type'])])
    if priority_match:
        labels_line += ',{0}="{1}"'.format('name', priority_match.groupdict()['name'])
        labels_line += ',{0}="{1}"'.format('priority', priority_match.groupdict()['priority'])
    else:
        labels_line += ',{0}="{1}"'.format('name', data['name'])
        labels_line += ',{0}="{1}"'.format('priority', 'P3')
    return labels_line

def write_data_to_file(parsed_data):
    '''Write text file fore node_exporter'''
    data_to_write = list()
    with open(conf['textfile_directory'], 'w') as report:
        for service in parsed_data:
            labels_line = get_labels(parsed_data[service])
            for key in parsed_data[service]:
                try:
                    if key in conf['labels']:
                        continue
                    elif key in conf['excluded_keys']:
                        continue
                    value = float(parsed_data[service][key])
                except ValueError:
                    log.debug('Not parsed float: service:{0} key: {1} value: {2}'.format(service, key, parsed_data[service][key]))
                    continue
                except:
                    trace = traceback.format_exception(sys.exc_info()[0], sys.exc_info()[1], sys.exc_info()[2])
                    for line in trace:
                        log.critical(line[:-1])
                    continue
                if key == "status" and value > 0:
                    value = 1.0
                line = 'node_monit{{key="{0}"{1}}} {2}'.format(key, labels_line, value)
                data_to_write.append(line)
        data_to_write.sort()
        data_to_write = '\n'.join(data_to_write)
        report.write(data_to_write + '\n')

def parse_data(xml_data):
    '''Parse input data from monit'''
    parsed_data = dict()
    for data_1 in xml_data['services']['service']:
        service_name = re.sub('[^0-9a-zA-Z]+', '_', data_1['name'])
        if 'system' in data_1:
            service_name = 'system'
        parsed_data[service_name] = dict()
        log.debug(service_name)
        for key_1 in data_1:
            value_1 = data_1[key_1]
            if isinstance(value_1, (int, float, str)):
                parsed_data[service_name][key_1] = value_1
                log.debug('{0} {1} {2}'.format(service_name, key_1, value_1))
            elif isinstance(value_1, dict):
                data_2 = value_1
                for key_2 in data_2:
                    value_2 = data_2[key_2]
                    if isinstance(value_2, (int, float, str)):
                        key_2 = '{0}_{1}'.format(key_1, key_2)
                        parsed_data[service_name][key_2] = value_2
                        log.debug('{0} {1} {2}'.format(service_name, key_2, value_2))
                    elif isinstance(value_2, dict):
                        data_3 = value_2
                        for key_3 in data_3:
                            value_3 = data_3[key_3]
                            if isinstance(value_3, (int, float, str)):
                                key_3 = '{0}_{1}_{2}'.format(key_1, key_2, key_3)
                                parsed_data[service_name][key_3] = value_3
                                log.debug('{0} {1} {2}'.format(service_name, key_3, value_3))
                            elif isinstance(value_2, dict):
                                data_4 = value_3
                                for key_4 in data_4:
                                    value_4 = data_4[key_4]
                                    if isinstance(value_4, (int, float, str)):
                                        key_4 = '{0}_{1}_{2}_{3}'.format(key_1, key_2, key_3, key_4)
                                        parsed_data[service_name][key_4] = value_4
                                        log.debug('{0} {1} {2}'.format(service_name, key_4, value_4))
                                    else:
                                        log.debug('Not parsed raw: service: {0} key: {1} value: {2}'.format(service_name, key_4, value_4))
    if parsed_data.get('system'):
        parsed_data['system']['nproc'] = xml_data['platform']['cpu']
    return parsed_data

# Run code
if __name__ == '__main__':
    # create events object
    events = list()
    args = parse_arguments()
    conf = parse_config(args)
    configure_response()
    configure_stop_condition()
    log = configure_logging()
    if conf['test_alert']:
        test_alert()
    enable_daemon_mode()
    write_pid_file()
    try:
        if sys.version_info.major == 2:
            collector_start_2(conf['host'], conf['port'])
        else:
            collector_start_3(conf['host'], conf['port'])
    except KeyboardInterrupt:
        exit_daemon()

