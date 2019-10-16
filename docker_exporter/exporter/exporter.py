#!/usr/bin/env python

import docker
import traceback
import argparse
import sys
import time
import logging
import yaml
import prometheus_client
import prometheus_client.core
import datetime

# pip3 install prometheus_client docker pyaml

# parse arguments
parser = argparse.ArgumentParser()
parser.add_argument('--config', default=sys.argv[0] + '.yml', help='config file location')
parser.add_argument('--log_level', help='logging level')
parser.add_argument('--tasks', help='tasks to execute')
args = parser.parse_args()

# add prometheus decorators
REQUEST_TIME = prometheus_client.Summary('request_processing_seconds', 'Time spent processing request')

def get_config(args):
    '''Parse configuration file and merge with cmd args'''
    for key in vars(args):
        conf[key] = vars(args)[key]
    with open(conf['config']) as conf_file:
        conf_yaml = yaml.load(conf_file, Loader=yaml.FullLoader)
    for key in conf_yaml:
        if not conf.get(key):
            conf[key] = conf_yaml[key]

def configure_logging():
    '''Configure logging module'''
    log = logging.getLogger(__name__)
    log.setLevel(conf['log_level'])
    FORMAT = '%(asctime)s %(levelname)s %(message)s'
    logging.basicConfig(format=FORMAT)
    return log

# Decorate function with metric.
@REQUEST_TIME.time()
def get_data():
    '''Get data from target service'''
    for task_name in conf['tasks']:
        get_data_function = globals()['get_data_'+ task_name]
        get_data_function()
                
def get_data_containers(refresh=False):
    '''Get data from "containers" API'''
    containers = docker_client.api.containers()
    parse_data_containers(containers)

def parse_data_containers(containers):
    '''Parse data from "containers" API'''
    log.debug('Parsing job started')
    data_tmp.clear()
    parse_data_containers_info(containers)
    data.clear()
    for m in data_tmp:
        data.append(m)
    log.debug('Metrics collected: {0}'.format(len(data)))
    log.debug('Parsing job stopped')

def parse_data_containers_info(containers):
    '''Parse data from "containers" API'''
    log.debug('Containers to parse: {0}'.format(len(containers)))
    for cont in containers:
        # get info
        states_map = {
            'running': 1,
            'created': 0,
            'exited': -1,
            'restarting': -2,
            'removing': -3,
            'paused': -4,
            'dead': -5
        }
        c_id = cont['Id']
        state = cont['State'].lower()
        name = cont['Labels'].get('com.docker.compose.service')
        if not name:
            log.debug('No name, see labels: {0}'.format(cont['Labels']))
            continue
        log.debug('Parsing container: {0} {1}'.format(name, c_id))
        labels = {'container_name': name, 'id': c_id}
        # get state
        metric_name = '{0}_exporter_container_state'.format(conf['name'])
        description = 'Conainer state: {0}'.format(states_map)
        metric = {'metric_name': metric_name, 'labels': labels, 'description': description, 'value': states_map[state]}
        data_append(metric)
        # get other stats
        if state != 'running':
            continue
        stats_gen = docker_client.api.stats(c_id, decode=True, stream=True)
        for stats in stats_gen:
            break
        # get uptime
        inspect = docker_client.api.inspect_container(c_id)
        metric_name = '{0}_exporter_container_uptime_seconds'.format(conf['name'])
        description = 'Conainer uptime in seconds'
        current_time = datetime.datetime.strptime(stats['read'].split('.')[0], '%Y-%m-%dT%H:%M:%S')
        start_time = datetime.datetime.strptime(inspect['State']['StartedAt'].split('.')[0], '%Y-%m-%dT%H:%M:%S')
        value = (current_time - start_time).seconds
        metric = {'metric_name': metric_name, 'labels': labels, 'description': description, 'value': value}
        data_append(metric)
        # get stats
        parse_data_containers_io(labels, stats)
        parse_data_containers_cpu(labels, stats)
        parse_data_containers_memory(labels, stats)
        parse_data_containers_network(labels, stats)

def parse_data_containers_io(labels, stats):
    '''Get I/O stats'''
    for m1 in ['io_serviced_recursive', 'io_service_bytes_recursive']:
        if not stats['blkio_stats'][m1]:
            continue
        for i in range(len(stats['blkio_stats'][m1])):
            m2 = stats['blkio_stats'][m1][i]
            operation = m2['op'].lower()
            if operation in ['read', 'write']:
                if '_bytes_' in m1:
                    metric_name = '{0}_exporter_container_{1}_{2}_bytes'.format(conf['name'], m1, operation)
                else:
                    metric_name = '{0}_exporter_container_{1}_{2}'.format(conf['name'], m1, operation)
                description = 'Conainer metric: {0} {1}'.format(m1, operation)
                value = stats['blkio_stats'][m1][i]['value']
                metric = {'metric_name': metric_name, 'labels': labels, 'description': description, 'value': value}
                data_append(metric)

def parse_data_containers_cpu(labels, stats):
        '''Get CPU stats'''
        metric_name = '{0}_exporter_container_cpu_usage_total'.format(conf['name'])
        description = 'Conainer total cpu_usage: stats.cpu_stats.cpu_usage.total_usage'
        value = stats['cpu_stats']['cpu_usage']['total_usage']
        metric = {'metric_name': metric_name, 'labels': labels, 'description': description, 'value': value}
        data_append(metric)

def parse_data_containers_memory(labels, stats):
        '''Get Memory stats'''
        for m in ['usage', 'limit']:
            metric_name = '{0}_exporter_container_memory_{1}_bytes'.format(conf['name'], m)
            description = 'Conainer memory usage: stats.memory_stats.{0}'.format(m)
            value = stats['memory_stats'][m]
            metric = {'metric_name': metric_name, 'labels': labels, 'description': description, 'value': value}
            data_append(metric)

def parse_data_containers_network(labels, stats):
        '''Get Network stats'''
        net_devices = list(stats['networks'].keys())
        for dev_name in net_devices:
            dev = stats['networks'][dev_name]
            labels_net = labels.copy()
            labels_net['net_dev'] = label_clean(dev_name)
            for m in dev:
                if '_bytes' in m:
                    m1 = m.replace('_bytes', '_total')
                    metric_name = '{0}_exporter_container_network_{1}_bytes'.format(conf['name'], m1)
                else:
                    metric_name = '{0}_exporter_container_network_{1}_total'.format(conf['name'], m)
                description = 'Conainer network stat: stats.networks.dev_name.{0}'.format(m)
                value = stats['networks'][dev_name][m]
                metric = {'metric_name': metric_name, 'labels': labels_net, 'description': description, 'value': value}
                data_append(metric)

def data_append(metric):
    '''Add metrics to memory'''
    data_tmp.append(metric)

def label_clean(label):
    '''Replace not allowed characters in label name'''
    replace_map = {
        '\\': '',
        '"': '',
        '\n': '',
        '\t': '',
        '\r': '',
        '-': '_',
        ' ': '_'
    }
    for r in replace_map:
        label = label.replace(r, replace_map[r])
    return label

# run
conf = dict()
get_config(args)
log = configure_logging()
data = list()
data_tmp = list()
docker_client = docker.from_env()
conf['metrics_need_refresh'] = True

docker_exporter_up = prometheus_client.Gauge('docker_exporter_up', 'docker_exporter scrape status')
docker_exporter_errors_total = prometheus_client.Counter('docker_exporter_errors_total', 'exporter scrape errors total counter')

class Collector(object):
    def collect(self):
        # add static metrics
        gauge = prometheus_client.core.GaugeMetricFamily
        counter = prometheus_client.core.CounterMetricFamily
        # get dinamic data
        #### Warning - data collection always trigered by code, because data collection is slow and heavy right now. ####
       #try:
       #    get_data()
       #    docker_exporter_up.set(1)
       #except:
       #    trace = traceback.format_exception(sys.exc_info()[0], sys.exc_info()[1], sys.exc_info()[2])
       #    for line in trace:
       #        print(line[:-1])
       #    docker_exporter_up.set(0)
       #    docker_exporter_errors_total.inc()
        # add dinamic metrics
        to_yield = set()
       #for _ in range(len(data)):
        for i in range(len(data)):
           #metric = data.pop()
            metric = data[i]
            labels = list(metric['labels'].keys())
            labels_values = [ metric['labels'][k] for k in labels ]
            if metric['metric_name'] not in to_yield:
                setattr(self, metric['metric_name'], gauge(metric['metric_name'], metric['description'], labels=labels))
            if labels:
                getattr(self, metric['metric_name']).add_metric(labels_values, metric['value'])
                to_yield.add(metric['metric_name'])
        for metric in to_yield:
            yield getattr(self, metric)

registry = prometheus_client.core.REGISTRY
registry.register(Collector())

prometheus_client.start_http_server(conf['listen_port'])

# endless loop
while True:
    try:
        while True:
            try:
                get_data()
                docker_exporter_up.set(1)
                time.sleep(conf['check_interval'])
            except KeyboardInterrupt:
                break
            except:
                trace = traceback.format_exception(sys.exc_info()[0], sys.exc_info()[1], sys.exc_info()[2])
                for line in trace:
                    log.error(line[:-1])
                docker_exporter_up.set(0)
                docker_exporter_errors_total.inc()
            time.sleep(1)
    except KeyboardInterrupt:
        break
    except:
        trace = traceback.format_exception(sys.exc_info()[0], sys.exc_info()[1], sys.exc_info()[2])
        for line in trace:
            log.error(line[:-1])
    time.sleep(1)

