#!/bin/bash
# Env variable 
export ENTRYPOINT=""

# Install PHP 8.2
yum update -y 
dnf install php8.2 -y
yum install php8.2-mysqlnd -y

# Install Apache web server 
yum install httpd -y 

# Start and enable Apache 
systemctl start httpd
systemctl enable httpd 

# Add User to Apache Group 
usermod -aG apache ec2-user

# Change Ownership and Permissions for Web Dir
chown -R ec2-user:apache /var/www
chmod 2775 /var/www && find /var/www -type d -exec chmod 2775 {} \;
find /var/www -type f -exec chmod 0664 {} \;

# Install Additional PHP Modules 
yum install php-mbstring php-xml -y 
yum install php-fpm -y 

# Restart Apache and PHP-FPM 
systemctl restart httpd
systemctl restart php-fpm 

# Download and setup phpMyAdmin 
cd /var/www/html
wget https://www.phpmyadmin.net/downloads/phpMyAdmin-latest-all-languages.tar.gz
mkdir phpMyAdmin && tar -xvzf phpMyAdmin-latest-all-languages.tar.gz -C phpMyAdmin --strip-components 1
rm -rf phpMyAdmin-latest-all-languages.tar.gz

# Copy RDS entry-point and paste into the php config file 
cd /var/www/html/phpMyAdmin
mv config.sample.inc.php config.inc.php
sed -i "s/localhost/$ENTRYPOINT/g" config.inc.php
