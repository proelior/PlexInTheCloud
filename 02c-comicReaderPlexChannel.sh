#!/bin/bash
source vars

## INFO
# This script installs and configures the ComicReader Channel for Plex
##

#######################
# Pre-Install
#######################
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root. Execute 'sudo su' to swap to the root user." 
   exit 1
fi

#######################
# Install
#######################
wget https://github.com/coryo/ComicReader.bundle/archive/master.zip
unzip master.zip -d /var/lib/plexmediaserver/Library/Application\ Support/Plex\ Media\ Server/Plug-ins/
mv /var/lib/plexmediaserver/Library/Application\ Support/Plex\ Media\ Server/Plug-ins/ComicReader.bundle-master /var/lib/plexmediaserver/Library/Application\ Support/Plex\ Media\ Server/Plug-ins/ComicReader.bundle
rm master.zip

#######################
# Permissions
#######################
chown -R $username:$username /var/lib/plexmediaserver/Library/Application\ Support/Plex\ Media\ Server/Plug-ins/ComicReader.bundle

#######################
# Misc.
#######################
systemctl restart plexmediaserver



