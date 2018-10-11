#Generate a sample ecosystem.json file that lists the processes and the deployment environment.
pm2 ecosystem

cd ~/app
#Backup orignal file
cp ecosystem.config.js ecosystem.config.js.bak

cd ~/linx

#do some changes in file
sed -i 's/username/'$USER'/1' ecosystem.config.js
sed -i 's/INSERT_IP/127.0.0.1/1' ecosystem.config.js
sed -i 's/USERNAME/mariomenezes/1' ecosystem.config.js
sed -i 's/REPOSITORY/linx/1' ecosystem.config.js
sed -i 's/PATH_TO_APP/\/home\/'$USER'\/app\//1' ecosystem.config.js

cp ecosystem.config.js /home/$USER/app/

cd /home/$USER/app/

# Setup deployment at remote location
pm2 deploy production setup

# Update remote version
pm2 deploy production update

# Revert to -1 deployment
pm2 deploy production revert 1

# execute command on remote machines
pm2 deploy production exec "pm2 reload all"



