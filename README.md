# qlMoviePreview #

This is a *QuickLook* plugin for Mac OS X *10.9* that allows to have a thumbnail of a video as an icon instead of a generic one. When you trigger QuickLook it displays the thumbnail of the video along with the video informations such as title, size, resolution, etc...

![qlMoviePreview finder icons](http://static.whine.fr/images/2014/qlmoviepreview1.jpg)
![qlMoviePreview QL preview](http://static.whine.fr/images/2014/qlmoviepreview2.jpg)

Currently it only supports **.mkv** files because I don't care about other formats, but adding support for them should be quite easy.


### Build / Install ###

First you need to have *ffmpegthumbnailer* and *mediainfo* installed. The easiest way to do this is via [homebrew](http://brew.sh)

	brew install ffmpegthumbnailer media-info

Then, for those who don't want to build from the sources, you can download the plugin here : [qlMoviePreview for Mavericks](http://repo.whine.fr/qlmoviepreview.qlgenerator-10.9.zip)

Unzip it, and place it in */Library/QuickLook* or *~/Library/QuickLook*.

Perhaps you will need to restart the *QuickLook* daemon by running this command in Terminal.app :

	qlmanage -r
	qlmanage -r cache

For the others, open **qlMoviePreview.xcodeproj**. If you hit the run button, it will build the plugin, place it in *~/Library/QuickLook* and restart the *QuickLook* server automatically.


### License ###

***qlMoviePreview*** is released under the *Simplified BSD license*, see **LICENSE**.

Blog : [Cocoa in the Shell](http://www.cocoaintheshell.com "Cocoa in the Shell")

Twitter : [@Nyx0uf](https://twitter.com/Nyx0uf)
