# qlMoviePreview #

This is a **QuickLook** plugin for Mac OS X *10.9* that allows to have a thumbnail of a video as an icon instead of a generic one. When you trigger QuickLook it displays the thumbnail of the video along with the video informations such as its title, size, resolution, etc...

![qlMoviePreview finder icons](http://static.whine.fr/images/2014/qlmoviepreview1.jpg)

![qlMoviePreview QL preview](http://static.whine.fr/images/2014/qlmoviepreview3.jpg)


### Installation ###

You need to have Xcode-tools installed, if it's not the case open **Terminal.app** and type :

	xcode-select --install

Then you need [ffmpegthumbnailer](https://code.google.com/p/ffmpegthumbnailer/ "ffmpegthumbnailer website") and [mediainfo](http://mediaarea.net/en/MediaInfo "mediainfo website"). The easiest way is via [homebrew](http://brew.sh "homebrew website"), so follow the instructions and then :

	brew install ffmpegthumbnailer media-info

Last, for those who don't want to build from the sources, you can directly download the plugin [here](http://repo.whine.fr/qlmoviepreview.qlgenerator-10.9.zip "qlmoviepreview.qlgenerator-10.9.zip").

Unzip it, and place it in */Library/QuickLook* or *~/Library/QuickLook*.

Perhaps you will need to restart the *QuickLook* daemon by running these commands in the terminal :

	qlmanage -r
	qlmanage -r cache

For the others, open **qlMoviePreview.xcodeproj** and hit the run button, it will build the plugin, place it in *~/Library/QuickLook* and restart the *QuickLook* server automatically.


### License ###

***qlMoviePreview*** is released under the *Simplified BSD license*, see **LICENSE**.

Blog : [Cocoa in the Shell](http://www.cocoaintheshell.com "Cocoa in the Shell")

Twitter : [@Nyx0uf](https://twitter.com/Nyx0uf "Nyx0uf on Twitter")
