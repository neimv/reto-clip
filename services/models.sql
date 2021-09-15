CREATE DATABASE IF NOT EXISTS reto;

USE reto;

CREATE TABLE IF NOT EXISTS pet (
    name    VARCHAR(20) NULL,
    owner   VARCHAR(20) NULL,
    species VARCHAR(20) NULL,
    sex     CHAR(1) NULL
);

INSERT INTO pet
    VALUES ('prueba', 'prueba', 'test', 'H');
INSERT INTO pet
    VALUES ('prueba2', 'prueba2', 'test2', 'M');