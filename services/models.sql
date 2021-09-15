CREATE DATABASE IF NOT EXISTS reto;

USE reto;

CREATE TABLE IF NOT EXISTS pet (
    name    VARCHAR(20) NOT NULL,
    owner   VARCHAR(20) NULL,
    species VARCHAR(20) NULL,
    sex     CHAR(1) NULL,
    PRIMARY KEY (name)
);
