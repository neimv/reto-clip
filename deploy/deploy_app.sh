#!/bin/bash

EC2_CF=reto-ec2
RDS_CF=reto-rds

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

# echo "Connect and update, upgrade and install deps server EC2"
# ssh -i reto.pem ubuntu@$output_ec2 'sudo apt-get update && sudo apt-get upgrade -y && sudo apt-get install docker.io git mysql-client-core-8.0 -y'

# echo "Set permissions to docker"
# ssh -i reto.pem ubuntu@$output_ec2 'sudo usermod -aG docker ${USER}'

# echo "git clone"
# ssh -i reto.pem ubuntu@$output_ec2 'git clone https://github.com/neimv/reto-clip.git && cd reto-clip && git checkout v1'

echo "set credentials"
SQL_CONNECT="$username:$password@tcp($output_rds:$output_db_port)/$output_db_name"
echo $SQL_CONNECT
ssh -i reto.pem ubuntu@$output_ec2 'export SQLCONNECT='"'$SQL_CONNECT'"'; echo SQLCONNECT=$SQLCONNECT > .envs'

echo "runing docker"
