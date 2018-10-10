#!/bin/bash

sudo apt update
sudo apt install icu-devtools
echo 'export PATH=$HOME/local/bin:$PATH' >> ~/.bashrc
. ~/.bashrc
mkdir -p ~/local
mkdir -p ~/node-install
cd ~/node-install
wget http://nodejs.org/dist/node-latest.tar.gz
#| tar xzvf --strip-components=1
tar -xzvf node-latest.tar.gz --strip-components 1
./configure --prefix=~/local
make install

#Init NPM and create package.json#TODO verify wht it does
npm init
#### Install NPM and Express
npm install -g express
#Installing the module globally will let you run commands from the command line, but you'll have to link the package into your local sphere to require it from within a program:
npm link express

#Building and run app.js
mkdir -p ~/app
cd ~/app
touch app.js
echo "var express = require('express');
var app = express();
app.get('/', function (req, res) {
res.send('Hello World!');
});					
app.listen(3000, function () {
console.log('Example app listening on port 3000!');
});" > app.js


#Install nginx to use reverse proxy
#sudo apt update
sudo apt install nginx -y

#Edit nginx config file

#new_text = "include /etc/nginx/sites-enabled/*;\
#server {\
#    listen 80;\
#    server_name test.linx.intra;\
#    location / {\
#        proxy_pass http://127.0.0.1:8000;\
#    }\
#    location /static {\
#        root /var/www/html/nodejs;\
#    }\
#}" #>> /etc/ngnix/nginx.conf

#Esse funciona
#sed 's/include \/etc\/nginx\/sites-enabled\/*;/linux/1' nginx.conf.bkp 
#Agora funciona também

#Make a copy of /etc/nginx/nginx.conf
sudo cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bak

#sudo sed -i 's/include \/etc\/nginx\/sites-enabled\/\*;/include \/etc\/nginx\/sites-enabled\/\*;\
#server {\
#    listen 80;\
#    server_name test.linx.intra;\
#    location \/ {\
#        proxy_pass http:\/\/127.0.0.1:8000;\
#    }\
#    location \/static {\
#        root \/home\/'$USER'\/app\/;\
#    }\
#}/1' /etc/nginx/nginx.conf

echo "server {
                listen 80;
                server_name test.linx.intra;

                location / {
                        proxy_pass http://127.0.0.1:3000;
                        proxy_http_version 1.1;
                        proxy_set_header Upgrade $http_upgrade;
                        proxy_set_header Connection 'upgrade';
                        proxy_set_header Host $host;
                        proxy_cache_bypass $http_upgrade;
                }
                location /static {
                        root /home/mario/app/;
                }
        }" >> app.conf

sudo cp app.conf /etc/nginx/sites-available/
sudo ln -s /etc/nginx/sites/available/app.conf /etc/nginx/sites-enabled/

#sudo sed -i 's/_USER_/$USER/' /etc/nginx/nginx.conf


#Test and Restart nginx
#TODO remeber to test de return of the commando above
sudo nginx -t ##TODO remember do verify the status of the file
sudo service nginx restart
sudo systemctl enable nginx


#Install Forever
#npm install -g forever

#run app.js using forever
#forever start /var/www/html/nodejs/app.js

#Deploy and rollback using PM2
#pm2 deploy <configuration_file> <environment> <command> 

#Best way to run in multicore configuration, better than use cluster function
#TODO verificar se realment o PM2 reinica em caso de falha, sem parar a aplicacao
#se sim, nao precisa usar o forever

#Copy express module to the correct place, so we can run pm2 correctly
cp -r /home/$USER/local/lib/node_modules/express/ /home/$USER/app/node_modules/


npm install -g pm2
pm2 start app.js -i max
#To ADD app.js in startup
#sudo env PATH=$PATH:/home/$USER/local/bin /home/$USER/local/lib/node_modules/pm2/bin/pm2 startup app.js -u $USER --hp /home/$USER





