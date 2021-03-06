#Generate a sample ecosystem.json file that lists the processes and the deployment environment.
pm2 ecosystem

cd ~/app
#Backup orignal file
cp ecosystem.config.js ecosystem.config.js.bak

cd ~/linx

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
cp /home/$USER/linx/ssh_key/id_rsa /home/$USER/.ssh/
#cp /home/$USER/linx/ssh_key/id_dsa /home/$USER/.ssh/

#Start the ssh-agent in the background.
eval "$(ssh-agent -s)"
chmod 0400 /home/$USER/.ssh/id_rsa

print "INSERT RSA_KEY_PASSWORD: 123456"
ssh-add /home/$USER/.ssh/id_rsa


# Setup deployment at remote location
#pm2 deploy production setup
#print "RSA_KEY_PASSWORD: 	123456"
pm2 deploy ecosystem.config.js production setup

#Deploy code
pm2 deploy ecosystem.config.js production
# Update remote version
pm2 deploy production update

# Revert to -1 deployment
pm2 deploy production revert 1

# execute command on remote machines
pm2 deploy production exec "pm2 reload all"


#copy ssh credentials. NOTE that is not the best way or the most security
#but is the only way we can do in this test
#best way is using ssh-copy-id and append ssh private keys.
#mkdir -p /home/$USER/.ssh/
#cp /home/$USER/linx/ssh_key/id_rsa /home/$USER/.ssh/
#cp /home/$USER/linx/ssh_key/id_dsa /home/$USER/.ssh/

#Start the ssh-agent in the background.
#eval "$(ssh-agent -s)"
#ssh-add /home/$USER/.ssh/id_rsa

#Install ssh and dependecies TODO maybe not necessary
#sudo apt install ssh -y
#Code to deploy app based on ecosystem.config.js file
#pm2 deploy ecosystem.config.js production setup



