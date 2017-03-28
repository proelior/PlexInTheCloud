# WHAT
Run Plex in the cloud. Use rclone crypt to mount and encrypt/decrypt your (unlimited) Amazon Drive storage on the fly.

Easily install NZBGet, SickRage, Medusa, CouchPotato, Watcher and Mylar with full post-processing enabled and configured.
Easily install rTorrent/ruTorrent for downloading torrents. (Post-processing coming soon).

# HOW
## GETTING STARTED
Please understand that the SOFTWARE scripts **WILL NOT** work without modifications unless you have successfully run the `00-setup.sh` and `01-rclone-acd.sh` scripts. These first 2 scripts create users, directories, and permissions that every other script relies on.

* [Getting Started](https://github.com/proelior/PlexInTheCloud/wiki/Getting_Started)

## SOFTWARE
Once you have completed the GETTING STARTED section you can run any of the following scripts to install and configure the software of your choice.

* [Software List](https://github.com/proelior/PlexInTheCloud/wiki/SOFTWARE%20LIST)

# TODO
[Issues](https://github.com/proelior/PlexInTheCloud/issues?q=is%3Aopen+is%3Aissue+label%3Aenhancement)

# AVAILABLE SOFTWARE
## Rclone / Crypt
[Rclone](https://github.com/ncw/rclone) is an amazing piece of software that allows you to easily mount your cloud storage locally and encrypt/decrypt it on the fly (via Crypt)!

## PLEX
Stream your personal media to any device with an internet connection.
- Plex | IP:32400/web
  - [PlexPy](https://github.com/JonnyWong16/plexpy) - Monitoring for Plex | [http://localhost:8181](http://localhost:8181)
  - [PlexRequests](https://github.com/lokenx/plexrequests-meteor) - Allow users to request movies/tv episodes and automatically download them | [http://localhost:3000](http://localhost:3000)
  - [ComicReader PlexChannel](https://github.com/coryo/ComicReader.bundle) - A way to read comics via plex. 'Functional' but very slow for now.

## NZBget
- [NZBget](http://nzbget.net/) - usenet downloader | [http://localhost:6789](http://localhost:6789)
    - [nzbToMedia Post-Processing](https://github.com/clinton-hall/nzbToMedia) - decompress, rename, and move your files, automatically.

## CouchPotato
- [CouchPotato](https://github.com/CouchPotato/CouchPotatoServer) - Search and track Movie downloads | [http://localhost:5050](http://localhost:5050)

## Watcher
- [Watcher](https://github.com/nosmokingbandit/watcher) - Search and track Movie show downloads | [http://localhost:9090](http://localhost:9090)

## rTorrent / ruTorrent
- [rtorrent](https://github.com/rakshasa/rtorrent) - an awesome bittorrent client
  - [ruTorrent](https://github.com/Novik/ruTorrent) - a web front end for rtorrent | [http://localhost:6060](http://localhost:6060)

## SickRage
- [SickRage](https://github.com/SickRage/SickRage) - Search and track TV show downloads | [http://localhost:8081](http://localhost:8081)

## Medusa
- [Medusa](https://github.com/pymedusa/Medusa) - Search and track TV show downloads | [http://localhost:8081](http://localhost:8081)

## Mylar
- [Mylar](https://github.com/evilhero/mylar) - Search and track Comic Book downloads | [http://localhost:8090](http://localhost:8090)

## Ubooquity
- [Ubooquity](https://vaemendis.net/ubooquity/) - a comic book server | [http://localhost:2202](http://localhost:2202)
    - Ubooquity Admin | [http://localhost:2202/admin](http://localhost:2202/admin)



