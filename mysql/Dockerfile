FROM mysql:5.7
LABEL maintainer="lgcosta"
COPY ./init.sql /docker-entrypoint-initdb.d/
EXPOSE 3306
CMD ["mysqld"]
