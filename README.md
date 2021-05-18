# GoPro MaxToEquirectPlugin  
This is a proof of concept for using -nearly- directly GoPro Max .360 files.  

I hope this can be the start for GoPro or anyone to provide decent tools for using the GoPro Max  

I place my work under MIT licence for giving the maximum possibilities.  

This is my own opinion but there is no place for direct 360° videos. Except for specific user the spectator will not move inside the video. The big advantage for recording 360° videos is to reframe the film to natural views. Dynamic reframing gives the scenarist the ability to have multiple view with a unique camera.  
I worked on an OpenFX plugin for doing the reframing inside DaVinci Resolve which is the non linear editing software I use for videos.  
You can find it on my repository here https://github.com/eltorio/reframe360XL  
But GoPro Max does not produce 'standard' 360° (aka equirectangular) so I decided to write a plugin for converting GoPro pseudo equiangular cubemap videos to standard equirectangulars movies.  

# Installation on MacOS (Intel and Apple Silicon)
* Build tested on MacOS 11.2.3 / XCode 12.4
* Install latest XCode from Apple App store
* Install Blackmagic DaVinci Resolve from Blackmagic website (studio version)
* clone this repository
* and build with make install

# Installation on Linux
* Build tested on Ubuntu 20.04
* Install make gcc opencl-headers
* Install Blackmagic DaVinci Resolve from Blackmagic website (studio version)
* clone this repository
* and build with make install (you might need to be root for writing to /usr/OFX)

# Installation on Windows  
* It needs more time and yet I did not port the GPU kernel to CUDA, but you are welcome !  

# Binaries for MacOS (Intel and Apple Silicon) and Linux (x86_64)
* I compiled and tested the plugin on MacOS Intel with Metal and OpenCL  
* I compiled and tested the plugin on Linux Ubuntu 20.04 x86_64
* just decompress the [binary](https://github.com/eltorio/MaxToEquirectPlugin/raw/master/MaxToEquirectPlugin.ofx.bundle.zip)
* And place it under /Library/OFS/Plugins on Mac and /usr/OFX/Plugins/ on Linux  

# Trying with DaVinci Resolve 17.2 studio
## First divide the .360 files in two movies
Today DaVinci Resolve does not support dual video stream in the same MP4 container  
So I divide my .360 in two files with ffmpeg  
Front stream is 0:0 in ffmpeg
````bash
FILE=in.360
ffmpeg -y -i "$FILE" \
    -copy_unknown -map_metadata 0 \
    -map 0:0 \
    -map 0:1 \
    -map 0:2 -tag:d:0 'tmcd' \
    -map 0:3 -tag:d:1 'gpmd' \
    -map 0:5 \
    -metadata:s:0 handler='GoPro H.265' \
    -metadata:s:1 handler='GoPro AAC' \
    -metadata:s:d:0 handler='GoPro TCD' \
    -metadata:s:d:1 handler='GoPro MET' \
    -metadata:s:4 handler='GoPro AMB' \
    -c copy ~/Desktop/temp360/out-p1.mov
````
Rear stream is 0:4 in ffmpeg
````bash
FILE=in.360
ffmpeg -y -i "$FILE" \
    -copy_unknown -map_metadata 0 \
    -map 0:4 \
    -map 0:1 \
    -map 0:2 -tag:d:0 'tmcd' \
    -map 0:3 -tag:d:1 'gpmd' \
    -map 0:5 \
    -metadata:s:0 handler='GoPro H.265' \
    -metadata:s:1 handler='GoPro AAC' \
    -metadata:s:d:0 handler='GoPro TCD' \
    -metadata:s:d:1 handler='GoPro MET' \
    -metadata:s:4 handler='GoPro AMB' \
    -c copy ~/Desktop/temp360/out-p2.mov

````
## Second import them in a timeline
* Import your front and rear movies
* Create a 4096x2688 timeline
* Insert front movie in the V1 channel (and the audio)
* Apply a translation in the inspector y=+672 for putting the front camera on the top
* Insert rear movie in the V2 channel (without the audio because it is the same)
* Apply a translcation of y=-672 for putting it on the bottom
## Third create a compound clip and a new timeline
* Create with this two clips a compound clip
* Create a new timeline 4096x2688 input and UHD or HD output depending on what you want  
* Insert your compound clip in the timeline
## Finally apply the filter(s)
* Apply first the MaxToEquirectPlugin on the newly inserted clip
* Apply Reframe360XL


For testing there is two 15s video (still image) front.mp4 and rear.mp4 corresponding to… [front](https://github.com/eltorio/MaxToEquirectPlugin/blob/master/SampleuseofMaxToEquirectPluginAndReframe360XL.dra/MediaFiles/front.mp4/?raw=true) and [rear](https://github.com/eltorio/MaxToEquirectPlugin/blob/master/SampleuseofMaxToEquirectPluginAndReframe360XL.dra/MediaFiles/rear.mp4/?raw=true) lenses !

But I also place a DaVinci Resolve project archive, just import the .dra in Resolve studio (free version does not seem to support OpenFX plugins)