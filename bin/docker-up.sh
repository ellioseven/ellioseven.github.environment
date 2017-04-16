#!/usr/bin/env bash

set -e

function dkr_id () {
    basename "$PWD" | tr  -dc '[:alnum:]\n' | tr '[:upper:]' '[:lower:]'
}

function dkr_inspect () {
    docker inspect --format="$1" "$(dkr_id)_web_1"
}

function dkr_inspect_ip () {
    dkr_inspect "{{ .NetworkSettings.Networks.$(dkr_id)_default.IPAddress }}"
}

function dkr_inspect_hosts () {
    dkr_inspect "{{range \$conf := .HostConfig.ExtraHosts}}{{(println \$conf)}}{{end}}"
}

function dkr_compose () {
    docker-compose -p $(dkr_id) up -d
}

function host_remove () {
    sudo sed -i.bak "/$1/d" /etc/hosts
}

function host_add () {
    echo -e "$1\t$2" | sudo tee -a "/etc/hosts"
}

function host_manage () {
    HOST_IP=$(dkr_inspect_ip)
    host_remove $HOST_IP
    dkr_inspect_hosts | while read line; do
        if [ "$line" ] ; then
            CNTR_HOST="$(echo "$line" | cut -d ':' -f1)"
            host_remove $CNTR_HOST
            host_add $HOST_IP $CNTR_HOST
        fi
    done
}

dkr_compose && host_manage
