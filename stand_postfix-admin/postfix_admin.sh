#!/bin/bash

# https://habr.com/ru/post/193220/
# https://www.dmosk.ru/miniinstruktions.php?mini=postfixadmin-centos7
# https://www.dmosk.ru/miniinstruktions.php?mini=nginx-centos-install


# Установка репозиториев
rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
rpm -Uvh http://repository.it4i.cz/mirrors/repoforge/redhat/el7/en/x86_64/rpmforge/RPMS/rpmforge-release-0.5.3-1.el7.rf.x86_64.rpm

# Selinux
setenforce 0

# Install ntp
yum install ntp -y
ntpdate  ntp3.stratum2.ru
systemctl enable ntpd && systemctl start ntpd

# Other utils
yum install -y \
wget \
mlocate \
bind-utils \
telnet \
mailx \
sharutils

# Install MySQL
yum install https://www.percona.com/redir/downloads/percona-release/redhat/1.0-21/percona-release-1.0-21.noarch.rpm -y
yum install Percona-Server-server-57 -y
systemctl enable mysqld && systemctl start mysqld
echo [client] > /root/.my.cnf
echo "password=`grep -i root@localhost /var/log/mysqld.log |awk '{print $NF}'`" >> /root/.my.cnf
mysql --connect-expired-password -e "ALTER USER USER() IDENTIFIED BY 'P@ssw0rd';"
sed -i 's/password/\#password/' /root/.my.cnf
echo "password=\"P@ssw0rd\"" >> /root/.my.cnf

# Add user mySQL
mysql -e "CREATE DATABASE postfix DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;"
mysql -e "GRANT ALL ON postfix.* TO 'postfix'@'localhost' IDENTIFIED BY 'P@ssw0rd';"

# ClamAV
yum -y install \
clamav-server \
clamav-data \
clamav-update \
clamav-filesystem \
clamav \
clamav-scanner-systemd \
clamav-devel \
clamav-lib \
clamav-server-systemd
sed -i 's/#LocalSocket/LocalSocket/' /etc/clamd.d/scan.conf
freshclam
systemctl enable clamd@scan && systemctl start clamd@scan

# Postfix Admin + NGINX + PHP
# ngnx
yum install -y nginx
firewall-cmd --permanent --add-port=80/tcp
firewall-cmd --permanent --add-port=443/tcp
firewall-cmd --reload

# php php-fpm
yum install -y php php-fpm php-mysql php-mbstring php-imap
sed -i 's/\#\ \ \ \ \ \ \ \ location/\#\ \ \ \ \ \ \ \ #location/' /etc/nginx/nginx.conf
sed -i '/\ \ \ \ \ \ \ \ location \/ {/a \ \ \ \ \ \ \ \ \ \ \ root   \/usr\/share\/nginx\/html;\n \ \ \ \ \ \ \ \ \ \ \index  index.php;' /etc/nginx/nginx.conf

cat<<EOF>/etc/nginx/default.d/php.conf
location ~ \.php$ {
        set \$root_path /usr/share/nginx/html;
        #fastcgi_pass 127.0.0.1:9000;
        fastcgi_pass unix:/var/run/php-fpm/php5-fpm.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME \$root_path\$fastcgi_script_name;
        include fastcgi_params;
        fastcgi_param DOCUMENT_ROOT \$root_path;
    }
EOF
mv /usr/share/nginx/html/index.html /usr/share/nginx/html/index.php
cat<<EOF>/usr/share/nginx/html/index.php
<?php phpinfo(); ?>
EOF

sed -i 's/listen = 127.0.0.1:9000/listen = \/var\/run\/php-fpm\/php5-fpm.sock/' /etc/php-fpm.d/www.conf
mkfifo /var/run/php-fpm/php5-fpm.sock && chown root:root /var/run/php-fpm/php5-fpm.sock

# Postfix Admin
wget https://sourceforge.net/projects/postfixadmin/files/latest/download -O postfixadmin.tar.gz
tar -C /usr/share/nginx/html -xvf postfixadmin.tar.gz
mv /usr/share/nginx/html/postfixadmin{-3.2,}
chown vagrant:vagrant /usr/share/nginx/html/ -R
chmod 777 /usr/share/nginx/html/postfixadmin/ -R
sed -i 's!CONF\['"'configured'"'\] = false;!CONF\['"'configured'"'\] = true;!g'  /usr/share/nginx/html/postfixadmin/config.inc.php
sed -i 's!CONF\['"'default_language'"'\] = '"'en'"';!CONF\['"'default_language'"'\] = '"'ru'"';!' /usr/share/nginx/html/postfixadmin/config.inc.php
sed -i 's!CONF\['"'database_password'"'\] = '"'postfixadmin'"';!CONF\['"'database_password'"'\] = '"'P@ssw0rd'"';!' /usr/share/nginx/html/postfixadmin/config.inc.php
sed -i 's!CONF\['"'emailcheck_resolve_domain'"'\]='"'YES'"';!CONF\['"'emailcheck_resolve_domain'"'\]='"'NO'"';!' /usr/share/nginx/html/postfixadmin/config.inc.php
ln -s /usr/share/nginx/html/postfixadmin/config.inc.php /usr/share/nginx/html/postfixadmin/config.local.php
mkdir /usr/share/nginx/html/postfixadmin/templates_c
chown vagrant:vagrant /usr/share/nginx/html/postfixadmin/templates_c
chmod 777 /usr/share/nginx/html/postfixadmin/templates_c

# Запуск nginx и php-fpm
systemctl enable nginx && systemctl start nginx
systemctl enable php-fpm && systemctl start php-fpm


# Далее необходимо перейти на http://192.168.100.101/postfixadmin/public/setup.php
# Авторизоваться, полученую строку вставить вместо искомой строки в файле /usr/share/nginx/htmp/postfixadmin/config.inc.php
# Далее на этойже странице создать учетную запись суперпользователя Postfix Admin, указывая тот же пароль
# Перейти на http://192.168.100.101/postfixadmin/public/login.php для логина под суперпользователем
