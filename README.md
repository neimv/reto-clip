# reto-clip

To Execute this project only is necesary:

1. Create python virtualenv: `virtualenv venv`
2. install dependencies: `pip install -r requirements.txt`
3. Execute: `python deploy_destroy.py deploy`
4. Execute sql `sql/models.sql` to create table
5. Execute sql `sql/models.insert.sql` to new data

To delete all:

1. Only execute `python deploy_destroy.py destroy`

TODO:
Error with loadbalancer in ecs
Destroy doesn't work