FROM debian:buster

# UPDATE
RUN apt-get update
RUN apt-get -y upgrade

# INSTALLATIONS
RUN apt-get -y install nginx
RUN apt-get -y install mariadb-server
RUN apt-get -y install php-mysql php-fpm php-mbstring
RUN apt-get -y install wget

#NGINX

COPY srcs/nginx.conf etc/nginx/sites-available/
RUN  ln -s /etc/nginx/sites-available/nginx.conf etc/nginx/sites-enabled/

#SLL SETUP

RUN mkdir ~/mkcert && \
  cd ~/mkcert && \
  wget https://github.com/FiloSottile/mkcert/releases/download/v1.1.2/mkcert-v1.1.2-linux-amd64 && \
  mv mkcert-v1.1.2-linux-amd64 mkcert && \
  chmod +x mkcert && \
./mkcert -install && \
./mkcert localhost

#COPY ALL

COPY srcs/wordpress.tar.gz /var/www/html/
COPY srcs/wp-config.php /var/www/html/
COPY srcs/mysql_setup.sql ./root/
COPY srcs/wordpress.sql ./root/
RUN service mysql start && \
    echo "CREATE DATABASE wordpress;"| mysql -u root && \
    echo "GRANT ALL PRIVILEGES ON wordpress.* TO 'root'@'localhost';"| mysql -u root && \
    echo "update mysql.user set plugin = 'mysql_native_password' where user='root';"| mysql -u root  && \
    mysql wordpress -u root --password=  < ./root/wordpress.sql

# INSTALL PHPMYADMIN
COPY srcs/config.inc.php ./root/
RUN wget https://files.phpmyadmin.net/phpMyAdmin/5.0.2/phpMyAdmin-5.0.2-english.tar.gz && \
mkdir /var/www/html/phpmyadmin && \
tar xzf phpMyAdmin-5.0.2-english.tar.gz --strip-components=1 -C /var/www/html/phpmyadmin && \
cp /root/config.inc.php /var/www/html/phpmyadmin/
RUN chmod 660 var/www/html/phpmyadmin/config.inc.php && chown -R www-data:www-data /var/www/html/phpmyadmin

#INSTALL WORDPRESS
RUN cd var/www/html && wget http://wordpress.org/latest.tar.gz  && \
tar -xzvf latest.tar.gz && rm latest.tar.gz 
RUN cd var/www/html && cp -a wordpress/* . 
RUN chown -R www-data:www-data /var/www/html/ && chmod -R 755 /var/www/html/  
COPY srcs/wp-config.php /var/www/html/wordpress

#START

COPY srcs/index.html var/www/html/index.html

EXPOSE 80 443

ENTRYPOINT 	service nginx start && \
			service php7.3-fpm start && \
			service mysql start && \
			sleep infinity && \
			wait
