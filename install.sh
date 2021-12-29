#! /usr/bin/env bash

echo -e "-->Domain defintion"
while :; do
    read -r -p 'Pls define the domain for this server: ' domain
    if [ $domain ]; then
        echo -e "Are you sure to use the domain: $domain ?"
        select opt in "Yes" "No"; do
            if [[ $opt == "Yes" ]]; then
                echo -e "Domain definded: $domain"
                break 2
            else
                break
            fi
        done
    fi
done


echo -e "-->Verifing os enabled system"
os_enabled="ubuntu"
os=`cat /etc/os-release | awk  -F '=' '{if ($1 == "ID") print $2}'`
if [ "$os" != "$os_enabled" ]; then 
    echo -e "OS $os not compatible with this script. Only for $os_enabled"
    exit 1
fi
os_version_enabled='"20.04"'
os_version=`cat /etc/os-release | awk -F '=' '{if ($1 == "VERSION_ID") print $2}'`
if [ "$os_version" != "$os_version_enabled" ]; then
    echo -e "OS version $os_version not valid to run this script, only enabled for $os_version_enabled"
    exit 1
fi

echo -e "-->Updating the system"
apt update -y
apt upgrade -y

echo -e "-->Installing Nginx"
apt install nginx -y
ufw app list 
ufw allow 'Nginx HTTP'
ufw status

echo -e "-->Intalling PHP"
apt install php-fpm php-mysql

echo -e "-->Configurate Nginx - PHP"
mkdir /var/www/$domain
chown -R www-data:www-data /var/www/$domain
if [ -f "/etc/nginx/sites-available/$domain" ]; then
    rm /etc/nginx/sites-available/$domain
fi
tee -a /etc/nginx/sites-available/$domain <<EOF
server {
    listen 80;
    server_name $domain www.$domain;
    root /var/www/$domain;

    index index.html index.htm index.php;

    location / {
        try_files \$uri \$uri/ =404;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php7.4-fpm.sock;
     }

    location ~ /\.ht {
        deny all;
    }
}
EOF
ln -s /etc/nginx/sites-available/$domain /etc/nginx/sites-enabled/
unlink /etc/nginx/sites-available/default
nginx -t
systemctl reload nginx

echo -e "-->Install Cerbot"
apt install certbot python3-certbot-nginx
certbot --nginx -d $domain -d www.$domain
systemctl status certbot.timer
