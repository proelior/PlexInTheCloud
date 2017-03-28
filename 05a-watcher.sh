#!/bin/bash
source vars

## INFO
# This script installs and configures medusa
##

#######################
# Pre-Install
#######################
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root. Execute 'sudo su' to swap to the root user." 
   exit 1
fi

#######################
# Dependencies
#######################
apt-get update && sudo apt-get install unrar-free git-core openssl libssl-dev python2.7 git

#######################
# Install
#######################
mkdir /opt/watcher && sudo chown $username:$username /opt/watcher
git clone https://github.com/nosmokingbandit/watcher.git /opt/watcher

# Run Watcher for the first time to create default config files
timeout 5s python /opt/watcher/watcher.py

#######################
# Configure
#######################


#######################
# Structure
#######################
# Create our local directory
mkdir -p /home/$username/$local/movies

# Create our directory for completed downloads
mkdir -p /home/$username/nzbget/completed/movies

# Create our ACD directory
## Run the commands as our user since the rclone config is stored in the user's home directory and root can't access it.
su $username <<EOF
cd /home/$username
rclone mkdir $encrypted:movies
EOF

# Create our Plex library
# Must be done manually for now
echo ''
echo ''
echo 'Now you need to create your Plex TV Library.'
echo '1) In a browser open https://app.plex.tv/web/app'
echo '2) In the left hand side, click on "Add Library"'
echo '3) Select "Movies", leave the default name, and choose your preferred language before clicking "Next"'
echo "4) Click 'Browse for media folder' and navigate to /home/$username/$encrypted/movies"
echo '5) Click on the "Add" button and then click on "Add library"'
echo ''

# Create a Plex Token
token=$(curl -H "Content-Length: 0" -H "X-Plex-Client-Identifier: PlexInTheCloud" -u "${plexUsername}":"${plexPassword}" -X POST https://my.plexapp.com/users/sign_in.xml | cut -d "\"" -s -f22 | tr -d '\n')

# Grab the Plex Section ID of our new library
tvID=$(curl -H "X-Plex-Token: ${token}" http://127.0.0.1:32400/library/sections | grep "show" | grep "title=" | awk -F = '{print $6" "$7" "$8}' | sed 's/ art//g' | sed 's/title//g' | sed 's/type//g' | awk -F \" '{print "Section=\""$6"\" ID="$2}' | cut -d '"' -f2)

#######################
# Helper Scripts
#######################
tee "/home/$username/nzbget/scripts/uploadMovies.sh" > /dev/null <<EOF
#!/bin/bash

#######################################
### NZBGET POST-PROCESSING SCRIPT   ###

# Rclone upload to Amazon Cloud Drive

# Wait for NZBget/Watcher to finish moving files
sleep 10s

# Upload
rclone move -c /home/$username/$local/movies $encrypted:movies

# Tell Plex to update the Library
wget http://localhost:32400/library/sections/$tvID/refresh?X-Plex-Token=$token

# Send PP Success code
exit 93
EOF

#######################
# Systemd Service File
#######################
tee "/etc/systemd/system/watcher.service" > /dev/null <<EOF
### BEGIN INIT INFO
# Provides:          watcher
# Required-Start:    $local_fs $network
# Required-Stop:     $local_fs
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: watcher
# Description:       watcher server
### END INIT INFO

####
# Watcher systemd run script
#
# How to use
#
#    - Modify ExecStart= to poitn toward your Python binary and Watcher script
#
#    - Modify User= and Group= to the user/group to run Watcher as.
#
#    - Append additional options to ExecStart= if desired
#      -a [address] Address to host Watcher. Default 0.0.0.0.
#      -p [port]    Port to host Watcher. Default 9090
#      -b           Open browser on launch.
####

[Unit]
Description=Watcher Daemon

[Service]
User=kurt
Group=kurt

Type=forking
GuessMainPID=no
ExecStart=/usr/bin/python2.7 /opt/watcher/watcher.py -d
Restart=no
[Install]
WantedBy=multi-user.target

EOF

#######################
# Permissions
#######################
chown -R $username:$username /home/$username/$local/movies
chown -R $username:$username /opt/watcher
chmod +x /home/$username/nzbget/scripts/uploadMovies.sh
chown root:root /etc/systemd/system/watcher.service
chmod 644 /etc/systemd/system/watcher.service

#######################
# Autostart
#######################
systemctl daemon-reload
systemctl start watcher
systemctl enable watcher

#######################
# Remote Access
#######################
echo ''
echo "Do you want to allow remote access to Watcher?"
echo "If so, you need to tell UFW to open the port."
echo "Otherwise, you can use SSH port forwarding."
echo ''
echo "Would you like us to open the port in UFW?"
select yn in "Yes" "No"; do
    case $yn in
        Yes ) ufw allow 9090; echo ''; echo "Port 9090 open, Watcher is now available over the internet."; echo ''; break;;
        No ) echo "Port 9090 left closed. You can still access it on your local machine by issuing the following command: ssh $username@$ipaddr -L 9090:localhost:9090"; echo "and then open localhost:9090 on your browser."; exit;;
    esac
done

