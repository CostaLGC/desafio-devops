CREATE DATABASE IF NOT EXISTS nodedb;

USE nodedb;

CREATE TABLE peoples(id int not null auto_increment, name varchar(255), primary key(id));
