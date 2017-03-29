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
# Repository
#######################
apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF
echo "deb http://download.mono-project.com/repo/debian wheezy main" | sudo tee /etc/apt/sources.list.d/mono-xamarin.list

#######################
# Dependencies
#######################
apt-get update
apt-get install mono-devel mediainfo sqlite3 libmono-cil-dev -y

#######################
# Install
#######################
cd /tmp
wget https://github.com/Radarr/Radarr/releases/download/v0.2.0.535/Radarr.develop.0.2.0.535.linux.tar.gz
tar -xf Radarr* -C /opt/
chown -R $username:$username /opt/Radarr

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
echo 'Now you need to create your Plex Movie Library.'
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

# Wait for NZBget/Sickrage to finish moving files
sleep 10s

# Upload
rclone move -c /home/$username/$local/movies $encrypted:movies

# Tell Plex to update the Library
wget http://localhost:32400/library/sections/$movieID/refresh?X-Plex-Token=$token

# Send PP Success code
exit 93
EOF

#######################
# Systemd Service File
#######################
tee "/etc/systemd/system/radarr.service" > /dev/null <<EOF
[Unit]
Description=Radarr Daemon
After=syslog.target network.target

[Service]
User=$username
Group=$username
Type=simple
ExecStart=/usr/bin/mono /opt/Radarr/Radarr.exe -nobrowser
TimeoutStopSec=20
KillMode=process
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

#######################
# Permissions
#######################
chown -R $username:$username /home/$username/$local/movies
chown -R $username:$username /opt/Radarr
chmod +x /home/$username/nzbget/scripts/uploadMovies.sh
chown root:root /etc/systemd/system/radarr.service
chmod +x /etc/systemd/system/radarr.service
chmod 644 /etc/systemd/system/radarr.service

#######################
# Autostart
#######################
sudo systemctl enable radarr
sudo service radarr start

#######################
# Remote Access
#######################
echo ''
echo "Do you want to allow remote access to Radarr?"
echo "If so, you need to tell UFW to open the port."
echo "Otherwise, you can use SSH port forwarding."
echo ''
echo "Would you like us to open the port in UFW?"
select yn in "Yes" "No"; do
    case $yn in
        Yes ) ufw allow 7878; echo ''; echo "Port 7878 open, Radarr is now available over the internet."; echo ''; break;;
        No ) echo "Port 7878 left closed. You can still access it on your local machine by issuing the following command: ssh $username@$ipaddr -L 7878:localhost:7878"; echo "and then open localhost:7878 on your browser."; exit;;
    esac
done

