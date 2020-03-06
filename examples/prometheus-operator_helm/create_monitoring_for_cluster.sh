#!/bin/bash

source ./secrets || exit 1

DST_DIR="${CLUSTER_NAME}"

dirs=$(find kubernetes/ -type d)
for dir in $dirs
    do
    mkdir -p ${DST_DIR}/${dir}
done

configs=$(find kubernetes/* -type f)
for conf in $configs
    do
    cat ${conf} | \
    sed -e "s@{{ PROJECT }}@$PROJECT@g" | \
    sed -e "s@{{ CLUSTER_NAME }}@$CLUSTER_NAME@g" | \
    sed -e "s@{{ ENV }}@$ENV@g" | \
    sed -e "s@{{ MAIN_DOMAIN }}@$MAIN_DOMAIN@g" | \
    sed -e "s@{{ PROMETHEUS_DOMAIN }}@$PROMETHEUS_DOMAIN@g" | \
    sed -e "s@{{ ALERTMANAGER_DOMAIN }}@$ALERTMANAGER_DOMAIN@g" | \
    sed -e "s@{{ GRAFANA_DOMAIN }}@$GRAFANA_DOMAIN@g" \
    > ${DST_DIR}/${conf}
done

