#!/bin/bash

# Tests:
# - Check Portgroups for the Edges 
# - Check to see if dVS is set to jumbo frames
# - VLAN IDs

echo Started vSphere Config task
# Check uplink portgroup, downlink portgroup, jumbo frames
# Check existence of clusters

export GOVC_URL=$vcenter-ip
export GOVC_USERNAME=$(vcenter-user)
export GOVC_PASSWORD=$(vcenter-password)

export GOVC_INSECURE="True"

export VCENTER_DC=$(vcenter-dc)
export VCENTER_CLUSTER=$(vcenter-cluster)


# check_portgroups_exist : Checks if portgroups exist
function check_portgroups_exist(){
    echo Running Check Portgroup $1
    govc host.portgroup.info -json=true | jq '.Portgroup[].Spec.Name' | grep $1 > /dev/null
    if [ $? -eq 0 ]; then 
        echo Portgroup $1 exists
    else 
        echo FAILED to find the portgroup $1
        exit 1
    fi
}

# check_portgroups_vlanid : Checks if portgroups has the correct VLANid
function check_portgroups_vlanid(){
    echo Running Check Portgroup $1 for VLAN ID: $2
    govc host.portgroup.info -json=true | jq -r --arg PGNAME "$1" '.Portgroup[].Spec | select(.Name==$PGNAME)' | jq '.VlanId' | grep $2 > /dev/null
    if [ $? -eq 0 ]; then 
        echo Portgroup $1 exists with VLANid $2
    else 
        echo FAILED portgroup $1 does not have the VLANid $2
        exit 1
    fi
}

# check_overlaydvs_mtu : Checks if OverLay distributed switch has the correct MTU > 1600
function check_overlaydvs_mtu(){
    echo Running Check Overlaydvs $1
    MTUsize=$(govc host.vswitch.info --json=true | jq -r --arg DVSNAME "$1" '.[][] | select (.Name==$DVSNAME)' | jq '.Mtu' )
    if [[ $MTUsize -ge 1600 ]]; then 
        echo vSwitch $1 is configured with JumboFrames
    else 
        echo ERROR vSwitch $1 is configured with MTU size: $MTUsize 
        #exit 1
    fi
}

# check_clusters : Checks if cluster exist
function check_cluster(){
    echo Running Check Cluster $1
    govc ls //$VCENTER_DC//host//$1 > /dev/null
    if [ $? -eq 0 ]; then 
        echo Cluster $1 exists
    else 
        echo FAILED to find the cluster $1
        exit 1
    fi
}

check_portgroups_exist $PG_UPLINK
check_portgroups_exist $PG_OVERLAY
check_portgroups_vlanid $PG_UPLINK $PG_UPLINK_VLANID
check_portgroups_vlanid $PG_OVERLAY $PG_OVERLAY_VLANID
check_cluster $VCENTER_CLUSTER