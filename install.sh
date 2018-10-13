#!/bin/bash

LINX_BASEDIR = $PWD

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
print "Apenas confirme todas as escolhas"
npm init
#### Install NPM and Express
npm install -g express
#Installing the module globally will let you run commands from the command line, but you'll have to link the package into your local sphere to require it from within a program:
npm link express

#Building and run app.js
mkdir -p ~/app

#cp /home/$USER/linx/app.js /home/$USER/app/
cp LINX_BASEDIR/app.js /home/$USER/app/

#Install nginx to use reverse proxy
sudo apt update
print "Install nginx web serve and siege for load test"
sleep 3
sudo apt install nginx siege -y

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
        root \/home\/'$USER'\/app\/;\
    }\
}/1' /etc/nginx/nginx.conf

#Preparing NGINX server and app.conf
#sudo cp /home/$USER/linx/app.conf /etc/nginx/sites-available/
sudo cp LINX_BASEDIR/app.conf /etc/nginx/sites-available/
sudo sed -i 's/USER/'$USER'/' /etc/nginx/sites-available/app.conf
sudo ln -s /etc/nginx/sites-available/app.conf /etc/nginx/sites-enabled/

#Test and Restart nginx
print "Verify the status of the file"
sleep 3
sudo nginx -t 
sudo service nginx restart
sudo systemctl enable nginx

#PM2 -Best way to run in multicore configuration, better than use cluster function
#Deploy and rollback using PM2
#pm2 deploy <configuration_file> <environment> <command> 
#Install pm2
npm install -g pm2

#Copy express module to the correct place, so we can run pm2 correctly
cp -r /home/$USER/local/lib/node_modules/express/ /home/$USER/app/node_modules/

#Create ecoystem file with PM2 to provide deploy and rollback func
pm2 ecosystem

#Generate a sample ecosystem.json file that lists the processes and the deployment environment.
#pm2 ecosystem

cd ~/app
#Backup orignal file
cp ecosystem.config.js ecosystem.config.js.bak

#cd ~/linx
cd LINX_BASEDIR

#do some changes in file
sed -i 's/username/'$USER'/1' ecosystem.config.js
sed -i 's/INSERT_IP/localhost/1' ecosystem.config.js
sed -i 's/USERNAME/mariomenezes/1' ecosystem.config.js
sed -i 's/REPOSITORY/linx/1' ecosystem.config.js
sed -i 's/PATH_TO_APP/\/home\/'$USER'\/app\//1' ecosystem.config.js

cp ecosystem.config.js /home/$USER/app/

cd /home/$USER/app/

#copy ssh credentials. NOTE that is not the best way or the most security
#but is the only way we can do in this test
#best way is using ssh-copy-id and append ssh private keys.
mkdir -p /home/$USER/.ssh/
#cp /home/$USER/linx/ssh_key/id_rsa /home/$USER/.ssh/
cp LINX_BASEDIR/ssh_key/id_rsa /home/$USER/.ssh/

#Start the ssh-agent in the background.
eval "$(ssh-agent -s)"
chmod 0400 /home/$USER/.ssh/id_rsa

print "INSERT RSA_KEY_PASSWORD WHEN PROMPTED: 123456"
sleep 3

ssh-add /home/$USER/.ssh/id_rsa

print "PM2 - Deploy using github version - possible to do a rolback"
print "Deploy code"
print " 	pm2 deploy ecosystem.config.js production"
print "Update remote version"
print "		pm2 deploy production update"
print "Revert to -1 deployment"
print "		pm2 deploy production revert 1"

print "Setup deployment at remote location"
pm2 deploy ecosystem.config.js production setup

print "Start node process, one process per core dynamically"
pm2 start app.js -i max
pm2 list

print "To ADD app.js in startup"
print "sudo env PATH=$PATH:/home/$USER/local/bin /home/$USER/local/lib/node_modules/pm2/bin/pm2 startup app.js -u $USER --hp /home/$USER"

#tarefa
mkdir -p /home/$USER/cron_job
cp LINX_BASEDIR/envia_relatorio.sh /home/$USER/cron_job/
crontab -l ; echo -e "MAILTO="mario@linx.intra"\n@daily /home/$USER/cron_job/envia_relatorio.sh" | crontab

#Throughput test using siege -  a command line load test tool
print "starting test with 100 concurrent request - duration 10s"
sleep 5
concurrent=100
FAILURE=0
TIME_=5
BEST=0.00
while [ $FAILURE -eq 0 ]; do
     echo "Server tested with $concurrent connections";
     echo "Server tested with $TIME_ seconds";
     sleep 1;
     echo "starting....";
     sudo siege  -c $concurrent -t $TIME_\s http://localhost
     TRHOUGHPUT=`cat /var/log/siege.log | awk '{print $8}' | tail -1 | sed 's/,$//'`;
     FAILURE=`cat /var/log/siege.log | awk '{print $11}' | tail -1`;
     let concurrent=concurrent+50;
     let TIME_=TIME_+0
     echo "Failure(s) = $FAILURE";
     echo "Time(s) = $TIME_";
     echo "Throughput = $TRHOUGHPUT";
     #if (( $(echo "$TRHOUGHPUT > $BEST" |bc -l) ));
    # if [ $TRHOUGHPUT -gt $BEST ]
      #   then
#               let BEST=TRHOUGHPUT;
 #    fi
     if [ ${TRHOUGHPUT%.*} -eq ${BEST%.*} ] && [ ${TRHOUGHPUT#*.} \> ${BEST#*.} ] || [ ${TRHOUGHPUT%.*} -gt ${BEST%.*} ]; then
        echo "${THROUGHPUT} > ${BEST}";
        BEST=$TRHOUGHPUT;
     else
        echo "${THROUGHPUT} <= ${BEST}";
     fi
     sleep 5;
done

print "Print last lines from /var/log/siege.log"
head -n1 /var/log/siege.log
tail -n10 /var/log/siege.log

echo -e "\n\n\nStart to fail with $concurrent concurrent connections"
echo -e "number of failures = $FAILURE";
echo -e "BEST Throughput = $BEST\n\n\n";


#TODO Log Parser
#Command working, already added in crontab - file envia_relatorio.sh"
awk '{print $9,$7}' /var/log/nginx/access.log | sort | uniq -c | sort -rn



