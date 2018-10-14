#!/bin/bash

LINX_BASEDIR=$PWD
_USER=$USER

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

echo "performing a profile update..."
sleep 5
#. /home/$_USER/.bashrc
#source /home/$_USER/.profile
PATH=$PATH:/home/$_USER/local/bin/
export PATH
. ~/.bashrc

echo "Init npm and Install express"
sleep 5
#Init NPM and create package.json#TODO verify wht it does
echo "Apenas confirme todas as escolhas"
npm init
#### Install NPM and Express
npm install -g express
#Installing the module globally will let you run commands from the command line, but you'll have to link the package into your local sphere to require it from within a program:
npm link express

#Building and run app.js
mkdir -p ~/app

#cp /home/$_USER/linx/app.js /home/$_USER/app/
cp $LINX_BASEDIR/app.js /home/$_USER/app/

#Install nginx to use reverse proxy
#sudo apt update
#echo "Install nginx web serve and siege for load test"
sleep 3
sudo apt install nginx -y

#Make a copy of /etc/nginx/nginx.conf
sudo cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bak

#Change nginx.conf file
sudo sed -i 's/include \/etc\/nginx\/sites-enabled\/\*;/include \/etc\/nginx\/sites-enabled\/\*;\
server {\
    listen 80;\
    #server_name test.linx.intra;\
    location \/ {\
                        proxy_pass http:\/\/localhost:3000;\
                        proxy_http_version 1.1;\
                        proxy_set_header Upgrade $http_upgrade;\
                        proxy_set_header Connection 'upgrade';\
                        proxy_set_header Host $host;\
                        proxy_cache_bypass $http_upgrade;\
                }\
    location \/static {\
        root \/home\/'$_USER'\/app\/;\
    }\
}/1' /etc/nginx/nginx.conf

#sudo rm /etc/nginx/sites-enabled/default.conf
#echo -e "\n\n\nBASEDIR: $LINX_BASEDIR\n\n\n"
#Preparing NGINX server and app.conf
#sudo cp /home/$_USER/linx/app.conf /etc/nginx/sites-available/
#sudo cp $LINX_BASEDIR/app.conf /etc/nginx/sites-available/
#sudo sed -i 's/USER/'$_USER'/' /etc/nginx/sites-available/app.conf
#sudo ln -s /etc/nginx/sites-available/app.conf /etc/nginx/sites-enabled/
sudo cp $LINX_BASEDIR/ssl/nginx-selfsigned.crt /etc/ssl/certs/
sudo cp $LINX_BASEDIR/ssl/nginx-selfsigned.key /etc/ssl/private/
sudo openssl dhparam -out /etc/ssl/certs/dhparam.pem 2048
sudo cp $LINX_BASEDIR/ssl/ssl-params.conf /etc/nginx/snippets/
sudo cp $LINX_BASEDIR/ssl/self-signed.conf /etc/nginx/snippets/

#Test and Restart nginx
echo "Verify the status of the file"
sleep 5
sudo nginx -t 
sudo service nginx restart
sudo systemctl enable nginx

sudo rm /etc/nginx/sites-enabled/default
echo -e "\n\n\nBASEDIR: $LINX_BASEDIR\n\n\n"
#Preparing NGINX server and app.conf
#sudo cp /home/$_USER/linx/app.conf /etc/nginx/sites-available/
sudo cp $LINX_BASEDIR/app.conf /etc/nginx/sites-available/
sudo sed -i 's/USER/'$_USER'/' /etc/nginx/sites-available/app.conf
sudo ln -s /etc/nginx/sites-available/app.conf /etc/nginx/sites-enabled/


#PM2 -Best way to run in multicore configuration, better than use cluster function
#Deploy and rollback using PM2
#pm2 deploy <configuration_file> <environment> <command> 
#Install pm2
npm install -g pm2
sleep 5

echo "Copying express module..."
#Copy express module to the correct place, so we can run pm2 correctly
cp -r /home/$_USER/local/lib/node_modules/express/ /home/$_USER/app/node_modules/

sleep 5
#Create ecoystem file with PM2 to provide deploy and rollback func
cd /home/$_USER/app/
pm2 ecosystem

#Generate a sample ecosystem.json file that lists the processes and the deployment environment.
#pm2 ecosystem

#cd ~/app
#Backup orignal file
cp ecosystem.config.js ecosystem.config.js.bak

#cd ~/linx
cd $LINX_BASEDIR

#do some changes in file
sed -i 's/username/'$_USER'/1' ecosystem.config.js
sed -i 's/INSERT_IP/localhost/1' ecosystem.config.js
sed -i 's/USERNAME/mariomenezes/1' ecosystem.config.js
sed -i 's/REPOSITORY/linx/1' ecosystem.config.js
sed -i 's/PATH_TO_APP/\/home\/'$_USER'\/app\//1' ecosystem.config.js

cp ecosystem.config.js /home/$_USER/app/

cd /home/$_USER/app/

#copy ssh credentials. NOTE that is not the best way or the most security
#but is the only way we can do in this test
#best way is using ssh-copy-id and append ssh private keys.
mkdir -p /home/$_USER/.ssh/
#cp /home/$_USER/linx/ssh_key/id_rsa /home/$_USER/.ssh/
cp $LINX_BASEDIR/ssh_key/id_rsa /home/$_USER/.ssh/

#Start the ssh-agent in the background.
eval "$(ssh-agent -s)"
chmod 0400 /home/$_USER/.ssh/id_rsa

echo "INSERT RSA_KEY_PASSWORD WHEN PROMPTED: 123456"
sleep 3

ssh-add /home/$_USER/.ssh/id_rsa

echo "PM2 - Deploy using github version - possible to do a rolback"
echo "Deploy code"
echo " 	pm2 deploy ecosystem.config.js production"
echo "Update remote version"
echo "		pm2 deploy production update"
echo "Revert to -1 deployment"
echo "		pm2 deploy production revert 1"

echo "Setup deployment at remote location"
pm2 deploy ecosystem.config.js production setup

echo -e "\n\n\n***********************************************************\n\n\n"
chmod a+x ~/.bashrc
PS1='$ '
source ~/.bashrc
#exec "$BASH"

MAX_CPU=`cat /proc/cpuinfo | awk '/^processor/{print $3}' | wc -l`

if [ $MAX_CPU -gt 32 ];then
	MAX_CPU=32
fi
echo -e "\n\n\nNumber of CPU Cores: $MAX_CPU\n\n\n"


cp -r $HOME/local/lib/node_modules/express/ /home/$_USER/app/node_modules/
#sudo service nginx restart
sudo rm /etc/nginx/sites-enabled/app.conf
sudo rm /etc/nginx/sites-enabled/default
sudo rm /etc/nginx/sites-available/default
sudo ln -s /etc/nginx/sites-available/app.conf /etc/nginx/sites-enabled/
sudo service nginx restart

sleep 5

cd $HOME/app/
echo "Start node process, one process per core dynamically"
pm2 start app.js -i $MAX_CPU
sleep 5
pm2 list
sleep 5
echo "To ADD app.js in startup"
echo "sudo env PATH=$PATH:/home/$_USER/local/bin /home/$_USER/local/lib/node_modules/pm2/bin/pm2 startup app.js -u $_USER --hp /home/$_USER"

sleep 3
#tarefa
echo -e "\n\n\nAdded"
echo -e "MAILTO="mario@linx.intra"\n@daily /home/$_USER/cron_job/relatorio.sh\n\n\n"

mkdir -p /home/$_USER/cron_job
cp $LINX_BASEDIR/relatorio.sh /home/$_USER/cron_job/
crontab -l ; echo -e "MAILTO="mario@linx.intra"\n@daily /home/$_USER/cron_job/relatorio.sh" | crontab

cd $LINX_BASEDIR

echo -e "\n\n\nStating server load test\n\n\n"
sleep 5
#Throughput test using siege -  a command line load test tool
echo "starting test with 100 concurrent request, $MAX_CPU threads - duration 60s"
sleep 5
./wrk -t$MAX_CPU -c100 -d60s https://localhost > saida_wrk
cat saida
out100=`cat saida | tail -n1 | awk '{print $2}'| sed 's/MB$//'`
echo "starting test with 1000 concurrent request, $MAX_CPU threads - duration 60s"
sleep 5
./wrk -t$MAX_CPU -c1000 -d60s https://localhost > saida_wrk
cat saida
out1000=`cat saida | tail -n1 | awk '{print $2}'| sed 's/MB$//'`
echo "starting test with 10000 concurrent request, $MAX_CPU threads - duration 60s"
sleep 5
./wrk -t$MAX_CPU -c10000 -d60s https://localhost > saida_wrk
cat saida
out10000=`cat saida | tail -n1 | awk '{print $2}'| sed 's/MB$//'`

echo -e "\n\n\n\nBest Throughput: \n\n\n"
echo -e "$out100\n $out1000\n $out10000" | sort -n -r| head -n 1
echo -e "\n\n\n"




#echo "Print last lines from /var/log/siege.log"
#head -n1 /var/log/siege.log
#tail -n10 /var/log/siege.log

#echo -e "\n\n\nStart to fail with $concurrent concurrent connections"
#echo -e "number of failures = $FAILURE";
#echo -e "BEST Throughput = $BEST\n\n\n";


echo -e "Log Parser:\n\n\n"
awk '{print $9,$7}' /var/log/nginx/access.log | sort | uniq -c | sort -rn
