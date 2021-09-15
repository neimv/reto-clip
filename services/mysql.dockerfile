FROM mysql:5.7.34

COPY mysql-setup.sh /mysql/setup.sh
COPY models.sql /mysql/models.sql
RUN chmod +x /mysql/setup.sh

RUN /mysql/setup.sh