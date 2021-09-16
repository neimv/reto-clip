#!/bin/bash

EC2_CF=reto-ec2
RDS_CF=reto-rds
PORT=80

Help() {
    echo "Script to deploy app or only update server"
    echo
    echo "Syntax: scriptTemplate [-d|u|h]"
    echo "options:"
    echo "d     Deploy app"
    echo "u     Update server"
    echo "h     Print this Help"
    echo
}

echo "Get the dns to connect"
output_ec2=$(aws cloudformation describe-stacks \
    --stack-name $EC2_CF \
    --query "Stacks[0].Outputs[?OutputKey=='PublicDNS'].OutputValue" \
    --output text)
echo $output_ec2

echo "Get URL to database"
output_rds=$(aws cloudformation describe-stacks \
    --stack-name $RDS_CF \
    --query "Stacks[0].Outputs[?OutputKey=='DatabaseUrl'].OutputValue" \
    --output text)
echo $output_rds

echo "Get name of database"
output_db_name=$(aws cloudformation describe-stacks \
    --stack-name $RDS_CF \
    --query "Stacks[0].Outputs[?OutputKey=='DatabaseName'].OutputValue" \
    --output text)
echo $output_db_name

output_db_port=$(aws cloudformation describe-stacks \
    --stack-name $RDS_CF \
    --query "Stacks[0].Outputs[?OutputKey=='DatabasePort'].OutputValue" \
    --output text)
echo $output_db_port

echo "Get secrets"
output_secrets_name=$(aws cloudformation describe-stacks \
    --stack-name $RDS_CF \
    --query "Stacks[0].Outputs[?OutputKey=='DatabaseSecretsName'].OutputValue" \
    --output text)
echo $output_secrets_name

secrets=$(aws secretsmanager get-secret-value --secret-id $output_secrets_name --query "SecretString" --output text)
echo $secrets

username=$(echo $secrets | jq '.username' | tr -d '"')
echo $username
password=$(echo $secrets | jq '.password' | tr -d '"')
echo $password

chmod 600 reto.pem

# Operations
function update_server() {
    ssh -i reto.pem -o "StrictHostKeyChecking no" ubuntu@$output_ec2 'sudo apt-get update && sudo apt-get upgrade -y'
}

function setup_init() {
    echo "Connect and update, upgrade and install deps server EC2"
    ssh -i reto.pem -o "StrictHostKeyChecking no" ubuntu@$output_ec2 'sudo apt-get update && sudo apt-get install docker.io git mysql-client-core-8.0 -y'

    echo "Set permissions to docker"
    ssh -i reto.pem ubuntu@$output_ec2 'sudo usermod -aG docker ${USER}'
}

function clone_and_pull() {
    echo "git clone"
    ssh -i reto.pem -o "StrictHostKeyChecking no" ubuntu@$output_ec2 'git clone https://github.com/neimv/reto-clip.git && cd reto-clip && git checkout v1 && git pull origin v1'
}

function create_credentials() {
    echo "set credentials"
    SQL_CONNECT="$username:$password@tcp($output_rds:$output_db_port)/$output_db_name"
    echo $SQL_CONNECT
    ssh -i reto.pem -o "StrictHostKeyChecking no" ubuntu@$output_ec2 'printf "SQLCONNECT='"$SQL_CONNECT"'\nPORT='"$PORT"'" > .envs'
    ssh -i reto.pem -o "StrictHostKeyChecking no" ubuntu@$output_ec2 'printf "[mysql]\nuser='"$username"'\npassword='"$password"'" > .my.cnf; chmod 0600 .my.cnf'
}

function create_table() {
    echo "running sql"
    ssh -i reto.pem -o "StrictHostKeyChecking no" ubuntu@$output_ec2 'cd reto-clip/services; mysql -u '"$username"' -h '"$output_rds"' -P '"$output_db_port"' '"$output_db_name"' < models.sql'
}

function insert_data_test() {
    ssh -i reto.pem -o "StrictHostKeyChecking no" ubuntu@$output_ec2 'cd reto-clip/services; mysql -u '"$username"' -h '"$output_rds"' -P '"$output_db_port"' '"$output_db_name"' < models.inserts.sql'
}

# echo "running docker"
function run_docker() {
    ssh -i reto.pem -o "StrictHostKeyChecking no" ubuntu@$output_ec2 'cd reto-clip/services; docker build -t go-ws-pet . && docker run -d -p '"$PORT"':'"$PORT"' --env-file=/home/ubuntu/.envs go-ws-pet'
}

function Deploy() {
    echo "In deploy"
    update_server
    setup_init
    clone_and_pull
    create_credentials
    create_table
    insert_data_test
    run_docker
}

function Update() {
    echo "In update"
    update_server
}

while getopts ":hud" option; do
    echo "test"
    case $option in
        h) # display Help
            Help
            exit;;

        d) # deploy
            Deploy
            exit;;

        u) # update
            Update
            exit;;

        \?) # Invalid option
            echo "Error: Invalid option"
            exit;;
    esac
done
