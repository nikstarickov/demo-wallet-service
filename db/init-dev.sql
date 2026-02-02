-- db/init-dev.sql
CREATE DATABASE wallet_dev;
CREATE USER dev_user WITH PASSWORD 'dev_password';
GRANT ALL PRIVILEGES ON DATABASE wallet_dev TO dev_user;
\c wallet_dev
GRANT ALL ON SCHEMA public TO dev_user;