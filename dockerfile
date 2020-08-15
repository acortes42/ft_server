FROM debian:buster

# UPDATE
RUN apt-get update
RUN apt-get -y upgrade

# INSTALLATIONS
RUN apt-get -y install nginx
RUN apt-get -y install mariadb-server
RUN apt-get -y install php7.3 php-mysql php-fpm php-mbstring
RUN apt-get -y install wget

#COPY FILES

COPY ./srcs/wordpress.tar.gz /var/www/html/
COPY ./srcs/mysql_setup.sql /var
COPY ./srcs/wordpress.sql /var

# INSTALL PHPMYADMIN
WORKDIR /var/www/html/
RUN wget https://files.phpmyadmin.net/phpMyAdmin/4.9.1/phpMyAdmin-4.9.1-english.tar.gz
RUN tar xf phpMyAdmin-4.9.1-english.tar.gz && rm -rf phpMyAdmin-4.9.1-english.tar.gz
RUN mv phpMyAdmin-4.9.1-english phpmyadmin

#INSTALL WORDPRESS
RUN tar xf /var/www/html/wordpress.tar.gz && rm -rf /var/www/html/wordpress.tar.gz
RUN chmod 755 -R wordpress

# SETUP SERVER
RUN service mysql start && mysql -u root mysql < /var/mysql_setup.sql && mysql wordpress -u root --password= < /var/wordpress.sql
RUN openssl req -x509 -nodes -days 365 -newkey rsa:2048 -subj '/C=FR/ST=75/L=Paris/O=42/CN=sdunckel' -keyout /etc/ssl/certs/localhost.key -out /etc/ssl/certs/localhost.crt
RUN chown -R www-data:www-data *
RUN chmod 755 -R *

#START
COPY ./start.sh /var

CMD bash /var/start.sh

EXPOSE 80 443