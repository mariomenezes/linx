#!/bin/bash

chmod a+x ~/.bashrc
PS1='$ '
source ~/.bashrc

MAX_CPU=`cat /proc/cpuinfo | awk '/^processor/{print $3}' | wc -l`

. ~/.bashrc
_USER=$USER
LINX_BASEDIR=$PWD

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


#concurrent=100
#FAILURE=0
#TIME_=20
#BEST=0.00
#while [ $FAILURE -eq 0 ]; do
#     echo "Server tested with $concurrent connections";
#     echo "Server tested with $TIME_ seconds";
#     sleep 3;
#     echo "starting....";
#     sudo siege -f $LINX_BASEDIR/hosts_siege.list -c $concurrent -t $TIME_\s
     #TRHOUGHPUT=`cat /var/log/siege.log | awk '{print $8}' | tail -1 | sed 's/,$//'`;
     #FAILURE=`cat /var/log/siege.log | awk '{print $11}' | tail -1`;
#     let concurrent=concurrent+50;
#     let TIME_=TIME_+0
   #  echo "Failure(s) = $FAILURE";
    # echo "Time(s) = $TIME_";
     #echo "Throughput = $TRHOUGHPUT";
     #if (( $(echo "$TRHOUGHPUT > $BEST" |bc -l) ));
    # if [ $TRHOUGHPUT -gt $BEST ]
      #   then
#               let BEST=TRHOUGHPUT;
 #    fi
     #if [ ${TRHOUGHPUT%.*} -eq ${BEST%.*} ] && [ ${TRHOUGHPUT#*.} \> ${BEST#*.} ] || [ ${TRHOUGHPUT%.*} -gt ${BEST%.*} ]; then
     #   echo "${THROUGHPUT} > ${BEST}";
     #   BEST=$TRHOUGHPUT;
     #else
     #   echo "${THROUGHPUT} <= ${BEST}";
     #fi
     #sleep 5;
#done

#echo "Print last lines from /var/log/siege.log"
#head -n1 /var/log/siege.log
#tail -n10 /var/log/siege.log

#echo -e "\n\n\nStart to fail with $concurrent concurrent connections"
#echo -e "number of failures = $FAILURE";
#echo -e "BEST Throughput = $BEST\n\n\n";


echo -e "Log Parser:\n\n\n"
awk '{print $9,$7}' /var/log/nginx/access.log | sort | uniq -c | sort -rn


