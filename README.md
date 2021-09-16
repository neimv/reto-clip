# reto-clip

in this branch exists, one docker-compose to test:

1. `cd services`
2. `docker-compose up`
3. exists another service with name: *adminer*, is possible accesing in `localhost:8080`
4. load files `models.sql` and `models.inserts.sql` to test app
5. get test with `localhost:3030/api/pet/prueba`

to deploy in aws:

1. enter folder `deploy`
2. create virtualenv: `virtualenv venv`
3. install libraries `pip install -r requirements.txt`
4. execute `python deploy_destroy.py deploy`
5. execute `bash deploy_app.sh -d`

to update is possible with `bash deploy_app.sh -u`

to destroy all: `python deploy_destroy.py destroy`
