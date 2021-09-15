#!/bin/bash
set -e
service mysql start
mysql < /mysql/models.sql
service mysql stop