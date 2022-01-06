#!/usr/bin/env bash

: '
    Copyright (C) 2022 IBM Corporation
    Rafael Sene <rpsene@br.ibm.com> - Initial implementation.
'

# Trap ctrl-c and call ctrl_c()
trap ctrl_c INT

function ctrl_c() {
    echo "Bye!"
    exit 0
}

function check_dependencies() {

    DEPENDENCIES=(ibmcloud curl sh wget jq)
    check_connectivity
    for i in "${DEPENDENCIES[@]}"
    do
        if ! command -v "$i" &> /dev/null; then
            echo "$i could not be found, exiting!"
            exit
        fi
    done
}

function check_connectivity() {

    if ! curl --output /dev/null --silent --head --fail http://cloud.ibm.com; then
        echo
        echo "ERROR: please, check your internet connection."
        exit 1
    fi
}

function authenticate() {
    echo "authenticate"
    local APY_KEY="$1"

    if [ -z "$APY_KEY" ]; then
        echo "API KEY was not set."
        exit 1
    fi
    ibmcloud update -f > /dev/null 2>&1
    ibmcloud plugin update --all -f > /dev/null 2>&1
    ibmcloud login --no-region --apikey "$APY_KEY"
}

function set_powervs() {

    local CRN="$1"

    if [ -z "$CRN" ]; then
        echo "CRN was not set."
        exit 1
    fi
    ibmcloud pi st "$CRN"
}

function delete_unused_volumes() {

    local JSON=/tmp/volumes-log.json

    > "$JSON"
    ibmcloud pi volumes --json | jq -r '.Payload.volumes[] | "\(.volumeID),\(.pvmInstanceIDs)"' >> $JSON

    while IFS= read -r line; do
        VOLUME=$(echo "$line" | awk -F ',' '{print $1}')
        VMS_ATTACHED=$(echo "$line" | awk -F ',' '{print $2}' | tr -d "\" \[ \]")
        if [ -z "$VMS_ATTACHED" ]; then
            echo "No VMs attached, deleting ..."
	    ibmcloud pi volume-delete "$VOLUME"
        fi
    done < "$JSON"
}

function delete_vms(){
    echo "Deleting VMs..."

    if [ -z "$VM_ID" ]; then
        echo "VM_ID was not set."
        exit 1
    fi
    echo "Deleting VMs which matches $VM_ID..."
    ibmcloud pi instance-delete $VM_ID --delete-data-volumes
}

function clean_powervs(){
    echo "Cleaning PowerVS..."
    local POWERVS_CRN="$1"
    local VM_ID="$2"
    set_powervs "$POWERVS_CRN"
    delete_vms "$VM_ID"
    #    PowerVS takes some time to remove the VMs
    #    sleep for 1 min to avoid any issue deleting
    #    volumes andnetwork
    sleep 2m
    delete_unused_volumes
}

function help() {
    echo
    echo "clear-cluster.sh API_KEY POWERVS_CRN VM_ID"
    echo
    echo  "VM_ID is the ID which identifies the VM."
}

function run() {

    if [ -z "$API_KEY" ]; then
        echo "API_KEY was not set."
        exit 1
    fi
    if [ -z "$POWERVS_CRN" ]; then
        echo "POWERVS was not set."
	echo "ibmcloud pi service-list --json | jq '.[] | \"\(.CRN),\(.Name)\"'"
        exit 1
    fi
    if [ -z "$VM_ID" ]; then
        echo "VM_ID was not set."
      	echo "Some string which identify the cluster"
      	exit 1
    fi

    check_dependencies
    check_connectivity
	authenticate "$API_KEY"
	clean_powervs "$POWERVS_CRN" "$VM_ID"
}

run "$@"