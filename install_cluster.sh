#!/bin/bash

usage() {
    echo "Usage: ./install_cluster.sh node_type node_count csp_type(aws|gcp|azure)"
    exit 1
}

if [ "$1" == "" ] || [ "$2" == "" ] || [ "$3" == "" ]; then
    usage
fi

#### configurable variables #####
INTEL=true
CSP_USER=ubuntu
prefix="myvm"
#################################

CURRENT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
LOCAL_USER=$(whoami)

idx=1
var=""
nodes=""
node_count=1
node1=$(printf "%s1" $prefix)

if [ $2 -gt 1 ]; then
    ((node_count = $2))
fi

until [ $idx -gt $node_count ]; do
    var="${var}$1\",\""
    nodes="${nodes}$prefix$idx\",\""
    ((idx = idx + 1))
done
finalvar="${var::-3}"
finalnodes="${nodes::-3}"

cp terraform/$3/variables.tf.template terraform/$3/variables.tf
sed -i "s/CNB_NODE_TYPE/$finalvar/" terraform/$3/variables.tf
sed -i "s/CNB_NODE_NAME/$finalnodes/" terraform/$3/variables.tf

# create ssh keys if not exist
if [ ! -f ~/.ssh/id_rsa ]; then
    ssh-keygen -t rsa -N "" <<<""
    cat ~/.ssh/id_rsa.pub >>~/.ssh/authorized_keys
fi

cd $CURRENT_DIRECTORY/terraform/$3
terraform init
terraform apply -auto-approve
terraform output -json instance_ip_addresses | jq --arg key1 $node1 '.[$key1][0]' >$CURRENT_DIRECTORY/inventory
terraform output -json instance_ip_addresses >$CURRENT_DIRECTORY/terraform_output.json

cd $CURRENT_DIRECTORY
args=""
idx=1

until [ $idx -gt $node_count ]; do
    name=$(printf "%s%d" $prefix $idx)
    ip=$(cat terraform_output.json | jq --arg key1 $name '.[$key1][1]' | tr -d \")
    args="${args}$ip "
    ((idx = idx + 1))
done

# create cluster_config.file
python3 create_cfg.py $args

# create ssh proxy file for Intel only
if [ "$INTEL" = true ] && [ ! -f ~/.ssh/config ]; then
    echo "Host *" >~/.ssh/config
    echo "ProxyCommand nc -X 5 -x proxy-us.intel.com:1080 %h %p" >>~/.ssh/config
fi

IP_ADDR=$(cat terraform_output.json | jq --arg key1 $node1 '.[$key1][0]' | tr -d \")
echo "K8s cluster for $1 X$node_count will be installed at $IP_ADDR"
#echo "K8s cluster for $1 X$node_count will be installed at $IP_ADDR" >>$CURRENT_DIRECTORY/runs.log

# wait until remote VM is available to access, default is 600 seconds
echo ""
echo "Waiting for VM to be available......"
ansible all -m wait_for_connection

# run the playbook to install k8s cluster
ansible-playbook cnbrun.yaml -e "user=$CSP_USER luser=$LOCAL_USER cdir=$CURRENT_DIRECTORY"

#cd $CURRENT_DIRECTORY/terraform/$3
#terraform destroy -auto-approve

echo ""
echo "K8s cluster installed successfully"
