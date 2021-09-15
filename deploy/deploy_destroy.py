#! /usr/bin/env python

import base64
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


path_cf = 'cloudformations/'
cloudformation_files = [
    ['reto-network', f'{path_cf}01-network-cloudformation.yml'],
    ['reto-security-group', f'{path_cf}02-securitygroup-cloudformation.yml'],
    ['reto-rds', f'{path_cf}03-rds-cloudformation.yml'],
    ['reto-ec2', f'{path_cf}04-ec2-cloudformation.yml'],
]


def create_destroy(name, path_cf, create=True):
    client = boto3.client('cloudformation')
    time_sleep = 1

    if create is True:
        with open(path_cf, 'r') as file_cf:
            cf = ''.join(file_cf.readlines())
            client.validate_template(TemplateBody=cf)

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


@click.group()
def cli():
    pass


@cli.command()
def deploy():
    for values in cloudformation_files:
        create_destroy(values[0], values[1], True)


@cli.command()
def destroy():
    deletes = cloudformation_files[::-1]

    for values in deletes:
        create_destroy(values[0], values[1], False)


if __name__ == '__main__':
    cli()
