#! /usr/bin/env python

import base64
import json as js
import logging
import os
import pprint
import time

import boto3
import botocore
import click
import coloredlogs
import docker


logger = logging.getLogger(__name__)
coloredlogs.install(level='INFO')
pp = pprint.PrettyPrinter(indent=4)


path_cf = 'deploy/cloudformations/'
cloud_ecr = [
    ['reto-ecr', f'{path_cf}00-ecr-cloudformation.yml']
]
cloudformation_files = [
    ['reto-network', f'{path_cf}01-network-cloudformation.yml'],
    ['reto-security-group', f'{path_cf}02-securitygroup-cloudformation.yml'],
    ['reto-rds', f'{path_cf}03-rds-cloudformation.yml'],
]
ecs = ['reto-ecs', f'{path_cf}04-ecs-cloudformation.yml']


def create_destroy(name, path_cf, create=True, args=None):
    client = boto3.client('cloudformation')
    time_sleep = 1

    if create is True:
        with open(path_cf, 'r') as file_cf:
            cf = ''.join(file_cf.readlines())
            client.validate_template(TemplateBody=cf)

        if args is None:
            client.create_stack(
                StackName=name,
                TemplateBody=cf,
                Capabilities=['CAPABILITY_IAM', 'CAPABILITY_NAMED_IAM'],
                OnFailure='DELETE',
                Tags=[
                    {
                        'Key': 'project',
                        'Value': 'aerodrome'
                    },
                    {
                        'Key': 'area',
                        'Value': 'dataops'
                    }
                ]
            )
        else:
            client.create_stack(
                StackName=name,
                TemplateBody=cf,
                Capabilities=['CAPABILITY_IAM', 'CAPABILITY_NAMED_IAM'],
                OnFailure='DELETE',
                Tags=[
                    {
                        'Key': 'project',
                        'Value': 'aerodrome'
                    },
                    {
                        'Key': 'area',
                        'Value': 'dataops'
                    }
                ],
                Parameters=[
                    {
                        'ParameterKey': 'UsernameDB',
                        'ParameterValue': args['user']
                    }, {
                        'ParameterKey': 'PasswordDB',
                        'ParameterValue': args['password']
                    },
                ]
            )
    else:
        client.delete_stack(StackName=name)

    resp = client.describe_stacks(StackName=name)

    while True:
        try:
            status = resp.get('Stacks', [{}])[0].get('StackStatus')
            status_c = resp.get('Stacks', [{}])[0].get('StackStatusReason')

            if status == 'CREATE_IN_PROGRESS':
                logger.info('Creating infra')
                time.sleep(time_sleep)
            elif status == 'CREATE_FAILED':
                raise Exception(f'Error with creation: {status_c}')
            elif status == 'CREATE_COMPLETE':
                logger.info('Complete infra')
                break
            elif status == 'DELETE_IN_PROGRESS':
                logger.info('Deleting infra')
                time.sleep(time_sleep)
            elif status == 'DELETE_FAILED':
                raise Exception(f'Error with creation: {status_c}')
            elif status == 'DELETE_COMPLETE':
                logger.info('Infra is delete')
                return True
            else:
                logger.info('What')
                raise Exception('What')

            time_sleep *= 2

            if time_sleep > 30:
                time_sleep = 1

            resp = client.describe_stacks(StackName=name)

            logger.error(status)
        except botocore.exceptions.ClientError:
            return True


def submit_docker(name, username=None, password=None):
    client = docker.from_env()
    ecr = boto3.client("ecr")

    logger.warning('Creating image')
    client.images.build(
        path='.',
        tag=name,
        quiet=False
    )
    logger.warning("Logging")
    if username is None and password is None:
        token = ecr.get_authorization_token()
        username, password = base64.b64decode(
            token['authorizationData'][0]['authorizationToken']
        ).decode().split(':')
        registry = token['authorizationData'][0]['proxyEndpoint']

        client.login(username, password, registry=registry)
    else:
        client.login(username=username, password=password)

    logger.warning("submit image")
    for line in client.api.push(
        name,
        stream=True, decode=True
    ):
        logger.debug(line)
        try:
            logger.warning(f'{line["status"]} - {line["progress"]}')
            logging.warning(f'Pushing {name}')
        except Exception:
            pass


def get_value(name_cf, output_name):
    client = boto3.client('cloudformation')
    response = client.describe_stacks(StackName=name_cf)

    values = response.get(
        'Stacks', [{}]
    ).pop().get(
        'Outputs', []
    )

    if not values:
        raise Exception('Cloudformation has not Outputs')

    for value in values:
        export_value = value.get('ExportName', '')

        if export_value == output_name:
            return_value = value['OutputValue']

            return return_value


def get_secrets(name_secret):
    client = boto3.client('secretsmanager')
    secret = client.get_secret_value(
        SecretId=name_secret
    )

    try:
        secret_dict = js.loads(secret['SecretString'])
    except js.decoder.JSONDecodeError:
        secret_dict = ast.literal_eval(secret['SecretString'])

    userpg = secret_dict['username']
    passw = secret_dict['password']

    return userpg, passw


@click.group()
def cli():
    pass


@cli.command()
def deploy():
    for values in cloud_ecr:
        create_destroy(values[0], values[1], True)

    uri = get_value('reto-ecr', 'Repository')
    submit_docker(uri)

    for values in cloudformation_files:
        create_destroy(values[0], values[1], True)

    secrets = get_value('reto-rds', 'DatabaseSecretsName')
    us, ps = get_secrets(secrets)
    print(us, ps)

    create_destroy(ecs[0], ecs[1], True, {'user': us, 'password': ps})


@cli.command()
def destroy():
    deletes = cloudformation_files[::-1]

    for values in cloud_ecr:
        create_destroy(values[0], values[1], False)

    create_destroy(ecs[0], ecs[1], False, {'user': us, 'password': ps})

    for values in deletes:
        create_destroy(values[0], values[1], False)


if __name__ == '__main__':
    cli()
