# qlMoviePreview

This is a **QuickLook** plugin for Mac OS X *10.11* that allows to have a thumbnail of a video as an icon instead of a generic one. When you trigger QuickLook it displays the thumbnail of the video along with the video informations such as its title, size, resolution, etc...

![qlMoviePreview finder icons](http://static.whine.fr/images/2014/qlmoviepreview1.jpg)

![qlMoviePreview QL preview](http://static.whine.fr/images/2014/qlmoviepreview3.jpg)


## Installation

You can download the plugin [here](http://repo.whine.fr/qlmoviepreview.qlgenerator.zip "qlmoviepreview.qlgenerator.zip").

Unzip it, and place it in `/Library/QuickLook` or `~/Library/QuickLook`.

You will need to restart the *QuickLook* daemon by running these commands in the terminal :

	qlmanage -r
	qlmanage -r cache


## License

***qlMoviePreview*** is released under the *Simplified BSD license*, see **LICENSE**.