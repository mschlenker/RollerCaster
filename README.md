RollerCaster
============

This application started as a prove of concept that it can be easy and comfortable to stream video from an HTTP server in the local network to ChromeCast devices. The media is streamed directly from the HTTP server to the Chromecast, no transcoding is done. Currently the app is implemented in HTML/CSS/JavaScript using Chrome's JavaScript API to access the Chromecast.

![screen shot](https://raw.githubusercontent.com/mschlenker/RollerCaster/master/screenshots/rollercaster-alpha.png)

Since the media list is a static HTML file, streaming can be done from nearly any web server that supports setting mime types and allows seekable access to files. This project borrows heavily from https://github.com/googlecast/CastVideos-chrome, thus the Apache license is kept. 

## Prepare your web server

Put some files on your web server, to test if the mime types are set correctly:

1. This Big Buck Bunny is known to play in Chrome, if opened from the local server it should play fine within Chrome http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4
2. Prepare an MKV with a h.264 video track and MP3 audio track(s), if Chrome tries to download the file, cheat a bit by declaring a mime type that Chrome accepts, like `AddType video/mp4 .mkv` in Apaches `mime.conf`

## Create the HTML file

Now add a directory structure for your videos below the RollerCaster directory. I usually use bind mounts to do so, depending on your configuration softlinks might also work. 

Then run the supplied ruby script to generate the static HTML file. the script takes two parameters, local web root and http web root and writes to standard output. Assuming your RollerCaster installation lives in `/var/www/html/RollerCaster` and this directory maps to `http://12.34.56.78/RollerCaster` you run:

```shell
ruby traverse_dir.rb /var/www/html/RollerCaster http://12.34.56.78/RollerCaster \
  > /var/www/html/RollerCaster/video.html
```

## Open the player

Now navigate to `http://12.34.56.78/RollerCaster/video.html`, navigate through your media directories, select a video and play it. Have fun! 

You can send the video to Chromecast by clicking on the cast icon. The "Toggle player" in the upper left corner toggles the players visibility, which is useful on screens smaller than 1366px wide. 

## What's next?

In it's current state, this app "just works": You can select a video, play fullscreen, toggle between local and Chromecast playback. But the interface is ugly, clunky and rough, I will clean this up during the next days. 

