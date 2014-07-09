# qlMoviePreview

This is a **QuickLook** plugin for Mac OS X *10.9* that allows to have a thumbnail of a video as an icon instead of a generic one. When you trigger QuickLook it displays the thumbnail of the video along with the video informations such as its title, size, resolution, etc...

![qlMoviePreview finder icons](http://static.whine.fr/images/2014/qlmoviepreview1.jpg)

![qlMoviePreview QL preview](http://static.whine.fr/images/2014/qlmoviepreview3.jpg)


### Installation

#### 1. Xcode-tools

Open **Terminal.app** and type :

	xcode-select --install


#### 2. Homebrew

If you don't have [homebrew](http://brew.sh "homebrew website") already installed :

	ruby -e "$(curl -fsSL https://raw.github.com/Homebrew/homebrew/go/install)"

	brew update


#### 3. ffmpeg & mediainfo

Then you need [ffmpeg](https://www.ffmpeg.org/ "ffmpeg website") and [mediainfo](http://mediaarea.net/en/MediaInfo "mediainfo website").

	brew install ffmpeg --with-tools media-info


#### 4. Install the plugin

Finally you can download the plugin [here](http://repo.whine.fr/qlmoviepreview.qlgenerator-10.9.zip "qlmoviepreview.qlgenerator-10.9.zip").

Unzip it, and place it in */Library/QuickLook* or *~/Library/QuickLook*.

You will need to restart the *QuickLook* daemon by running these commands in the terminal :

	qlmanage -r
	qlmanage -r cache


### License

***qlMoviePreview*** is released under the *Simplified BSD license*, see **LICENSE**.

Blog : [Cocoa in the Shell](http://www.cocoaintheshell.com "Cocoa in the Shell")

Twitter : [@Nyx0uf](https://twitter.com/Nyx0uf "Nyx0uf on Twitter")
