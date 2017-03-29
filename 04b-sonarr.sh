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
apt-get install apt-transport-https -y

#######################
# Repository HTTPS
#######################
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys FDA5DFFC
echo "deb https://apt.sonarr.tv/ master main" | sudo tee -a /etc/apt/sources.list.d/sonarr.list

#######################
# Install
#######################
apt-get update
apt-get -y install nzbdrone
rm /etc/apt/sources.list.d/sonarr.list
chown -R $username:$username /opt/NzbDrone

#######################
# Configure
#######################


#######################
# Structure
#######################
# Create our local directory
mkdir -p /home/$username/$local/tv

# Create our directory for completed downloads
mkdir -p /home/$username/nzbget/completed/tv

# Create our ACD directory
## Run the commands as our user since the rclone config is stored in the user's home directory and root can't access it.
su $username <<EOF
cd /home/$username
rclone mkdir $encrypted:tv
EOF

# Create our Plex library
# Must be done manually for now
echo ''
echo ''
echo 'Now you need to create your Plex TV Library.'
echo '1) In a browser open https://app.plex.tv/web/app'
echo '2) In the left hand side, click on "Add Library"'
echo '3) Select "TV Shows", leave the default name, and choose your preferred language before clicking "Next"'
echo "4) Click 'Browse for media folder' and navigate to /home/$username/$encrypted/tv"
echo '5) Click on the "Add" button and then click on "Add library"'
echo ''

# Create a Plex Token
token=$(curl -H "Content-Length: 0" -H "X-Plex-Client-Identifier: PlexInTheCloud" -u "${plexUsername}":"${plexPassword}" -X POST https://my.plexapp.com/users/sign_in.xml | cut -d "\"" -s -f22 | tr -d '\n')

# Grab the Plex Section ID of our new library
tvID=$(curl -H "X-Plex-Token: ${token}" http://127.0.0.1:32400/library/sections | grep "show" | grep "title=" | awk -F = '{print $6" "$7" "$8}' | sed 's/ art//g' | sed 's/title//g' | sed 's/type//g' | awk -F \" '{print "Section=\""$6"\" ID="$2}' | cut -d '"' -f2)

#######################
# Helper Scripts
#######################
tee "/home/$username/nzbget/scripts/uploadTV.sh" > /dev/null <<EOF
#!/bin/bash

#######################################
### NZBGET POST-PROCESSING SCRIPT   ###

# Rclone upload to Amazon Cloud Drive

# Wait for NZBget/Sickrage to finish moving files
sleep 10s

# Upload
rclone move -c /home/$username/$local/tv $encrypted:tv

# Tell Plex to update the Library
wget http://localhost:32400/library/sections/$tvID/refresh?X-Plex-Token=$token

# Send PP Success code
exit 93
EOF

#######################
# Systemd Service File
#######################
tee "/etc/init.d/nzbdrone" > /dev/null <<EOF
#! /bin/sh
### BEGIN INIT INFO
# Provides: NzbDrone
# Required-Start: $local_fs $network $remote_fs
# Required-Stop: $local_fs $network $remote_fs
# Should-Start: $NetworkManager
# Should-Stop: $NetworkManager
# Default-Start: 2 3 4 5
# Default-Stop: 0 1 6
# Short-Description: starts instance of NzbDrone
# Description: starts instance of NzbDrone using start-stop-daemon
### END INIT INFO

############### EDIT ME ##################
# path to app
APP_PATH=/opt/NzbDrone

# user
RUN_AS=kurt

# path to mono bin
DAEMON=$(which mono)

# Path to store PID file
PID_FILE=/var/run/nzbdrone/nzbdrone.pid
PID_PATH=$(dirname $PID_FILE)

# script name
NAME=nzbdrone

# app name
DESC=NzbDrone

# startup args
EXENAME="NzbDrone.exe"
DAEMON_OPTS=" "$EXENAME

############### END EDIT ME ##################

NZBDRONE_PID=`ps auxf | grep NzbDrone.exe | grep -v grep | awk '{print $2}'`

test -x $DAEMON || exit 0

set -e

#Look for PID and create if doesn't exist
if [ ! -d $PID_PATH ]; then
mkdir -p $PID_PATH
chown $RUN_AS $PID_PATH
fi

if [ ! -d $DATA_DIR ]; then
mkdir -p $DATA_DIR
chown $RUN_AS $DATA_DIR
fi

if [ -e $PID_FILE ]; then
PID=`cat $PID_FILE`
if ! kill -0 $PID > /dev/null 2>&1; then
echo "Removing stale $PID_FILE"
rm $PID_FILE
fi
fi

echo $NZBDRONE_PID > $PID_FILE

case "$1" in
start)
if [ -z "${NZBDRONE_PID}" ]; then
echo "Starting $DESC"
rm -rf $PID_PATH || return 1
install -d --mode=0755 -o $RUN_AS $PID_PATH || return 1
start-stop-daemon -d $APP_PATH -c $RUN_AS --start --background --pidfile $PID_FILE --exec $DAEMON -- $DAEMON_OPTS
else
echo "NzbDrone already running."
fi
;;
stop)
echo "Stopping $DESC"
echo $NZBDRONE_PID > $PID_FILE
start-stop-daemon --stop --pidfile $PID_FILE --retry 15
;;

restart|force-reload)
echo "Restarting $DESC"
start-stop-daemon --stop --pidfile $PID_FILE --retry 15
start-stop-daemon -d $APP_PATH -c $RUN_AS --start --background --pidfile $PID_FILE --exec $DAEMON -- $DAEMON_OPTS
;;
status)
# Use LSB function library if it exists
if [ -f /lib/lsb/init-functions ]; then
. /lib/lsb/init-functions
if [ -e $PID_FILE ]; then
status_of_proc -p $PID_FILE "$DAEMON" "$NAME" && exit 0 || exit $?
else
log_daemon_msg "$NAME is not running"
exit 3
fi

else
# Use basic functions
if [ -e $PID_FILE ]; then
PID=`cat $PID_FILE`
if kill -0 $PID > /dev/null 2>&1; then
echo " * $NAME is running"
exit 0
fi
else
echo " * $NAME is not running"
exit 3
fi
fi
;;
*)
N=/etc/init.d/$NAME
echo "Usage: $N {start|stop|restart|force-reload|status}" >&2
exit 1
;;
esac

exit 0
EOF

#######################
# Permissions
#######################
chown -R $username:$username /home/$username/$local/tv
chown -R $username:$username /opt/sonarr
chmod +x /home/$username/nzbget/scripts/uploadTV.sh
chown root:root /etc/init.d/nzbdrone
chmod +x /etc/init.d/nzbdrone
chmod 644 /etc/init.d/nzbdrone

#######################
# Autostart
#######################
sudo update-rc.d nzbdrone defaults
sudo service nzbdrone start

#######################
# Remote Access
#######################
echo ''
echo "Do you want to allow remote access to Sonarr?"
echo "If so, you need to tell UFW to open the port."
echo "Otherwise, you can use SSH port forwarding."
echo ''
echo "Would you like us to open the port in UFW?"
select yn in "Yes" "No"; do
    case $yn in
        Yes ) ufw allow 8989; echo ''; echo "Port 8989 open, Sonarr is now available over the internet."; echo ''; break;;
        No ) echo "Port 8989 left closed. You can still access it on your local machine by issuing the following command: ssh $username@$ipaddr -L 8989:localhost:8989"; echo "and then open localhost:8989 on your browser."; exit;;
    esac
done

