//
//  Tools.m
//  qlMoviePreview
//
//  Created by @Nyx0uf on 15/04/14.
//  Copyright (c) 2014 Nyx0uf. All rights reserved.
//  www.cocoaintheshell.com
//


#import "Tools.h"
#import "MediainfoOutputParser.h"
#import <CommonCrypto/CommonDigest.h>


@implementation Tools

+(BOOL)isValidFilepath:(NSString*)filepath
{
	// Add extensions in the array to support more file types
	static NSArray* __valid_exts = nil;
	if (!__valid_exts)
		__valid_exts = [[NSArray alloc] initWithObjects:@"avi", @"divx", @"dv", @"flv", @"hevc", @"mkv", @"mov", @"mp4", @"mts", @"m2ts", @"m4v", @"ogv", @"rmvb", @"ts", @"vob", @"wmv", @"yuv", @"y4m", @"264", @"3gp", @"3gpp", @"3g2", @"3gp2", nil];
	NSString* extension = [filepath pathExtension];
	return [__valid_exts containsObject:extension];
}

+(NSString*)createThumbnailForFilepath:(NSString*)filepath
{
	// Create a directory to hold generated thumbnails
	NSFileManager* fileManager = [[NSFileManager alloc] init];
	NSString* cacheDirectory = [@"/tmp/" stringByAppendingPathComponent:@"qlmoviepreview/"];
	if (![fileManager fileExistsAtPath:cacheDirectory])
		[fileManager createDirectoryAtPath:cacheDirectory withIntermediateDirectories:YES attributes:nil error:nil];

	// Create thumbnail path
	NSString* md5 = [Tools __md5String:filepath];
	NSString* thumbnailPath = [cacheDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.png", md5]];

	// Thumbnail only once
	if ([fileManager fileExistsAtPath:thumbnailPath])
		return thumbnailPath;

	// ffmpegthumbnailer can be installed via homebrew
	// make a thumbnail at 12% of the movie
	// image format will be inferred from the path (png)
	// ffmpeg -y -ss 8 -i bla.mp4 -vframes 1 -f image2 _thb.jpg
	NSTask* task = [[NSTask alloc] init];
	[task setLaunchPath:@"/usr/local/bin/ffmpegthumbnailer"];
	[task setArguments:@[@"-i", filepath, @"-o", thumbnailPath, @"-s", @"0", @"-t", @"12%"]];
	[task launch];
	[task waitUntilExit];

	if (0 == [task terminationStatus])
		return thumbnailPath;

	DLog(@"THUMBNAILING %@ FAILED", filepath);

	return nil;
}
#if 0
+(NSInteger)getAccurateMovieDurationInSecondsForFilepath:(NSString*)filepath
{
	//mediainfo --Inform="Video;%Duration%" Spirited\ Away.mkv
	NSTask* task = [[NSTask alloc] init];
	[task setLaunchPath:@"/usr/local/bin/mediainfo"];
	[task setArguments:@[@"--Inform='Video;%Duration%'", filepath]];
	NSPipe* outputPipe = [NSPipe pipe];
	[task setStandardOutput:outputPipe];
	[task launch];
	[task waitUntilExit];

	NSData* outputData = [[outputPipe fileHandleForReading] readDataToEndOfFile];
	if (!outputData)
		return 0;

	NSString* dumbTimeFormatAsString = [[NSString alloc] initWithData:outputData encoding:NSASCIIStringEncoding];
	DLog(@"dumbTimeFormatAsString = %@", dumbTimeFormatAsString);
	const NSUInteger strSize = [dumbTimeFormatAsString length];

	// only ms if I understood correctly
	if (strSize < 4)
		return 0;

	NSString* b = [dumbTimeFormatAsString substringToIndex:strSize - 4];
	DLog(@"b = %@", b);

	// Will not be accurate
	//const float seconds = (float)strSize / 60.0f;

	//const NSInteger seconds = (NSInteger)floorf((float)strSize / 60.0f);
	//return seconds;

	return 0;
}
#endif

+(NSDictionary*)mediainfoForFilepath:(NSString*)filepath
{
	// mediainfo can be installed via homebrew
	// Output infos as XML
	NSTask* task = [[NSTask alloc] init];
	[task setLaunchPath:@"/usr/local/bin/mediainfo"];
	[task setArguments:@[filepath, @"--Output=XML"]];
	NSPipe* outputPipe = [NSPipe pipe];
	[task setStandardOutput:outputPipe];
	[task launch];
	[task waitUntilExit];

	NSData* outputData = [[outputPipe fileHandleForReading] readDataToEndOfFile];
	if (!outputData)
		return nil;

	// Parse the mediainfo XML output
	MediainfoOutputParser* parser = [[MediainfoOutputParser alloc] initWithData:[[[NSString alloc] initWithData:outputData encoding:NSISOLatin1StringEncoding] dataUsingEncoding:NSUTF8StringEncoding]];
	NSDictionary* tracks = [parser parse];

	/* General file info */
	NSMutableDictionary* outDict = [[NSMutableDictionary alloc] init];
	NSDictionary* generalDict = tracks[@(NYXTrackTypeGeneral)];
	NSMutableString* strGeneral = [[NSMutableString alloc] initWithString:@"<h2 class=\"stitle\">General</h2><ul>"];
	// Movie name
	NSString* moviename = generalDict[NYX_GENERAL_MOVIENAME];
	if (moviename && ![moviename isEqualToString:@""])
		[strGeneral appendFormat:@"<li><span class=\"st\">Title:</span> <span class=\"sc\">%@</span></li>", moviename];
	else
		[strGeneral appendString:@"<li><span class=\"st\">Title:</span> <span class=\"sc\"><em>Undefined</em></span></li>"];
	// Duration
	NSString* duration = generalDict[NYX_GENERAL_DURATION];
	[strGeneral appendFormat:@"<li><span class=\"st\">Duration:</span> <span class=\"sc\">%@</span></li>", duration];
	// Filesize
	NSString* filesize = generalDict[NYX_GENERAL_FILESIZE];
	[strGeneral appendFormat:@"<li><span class=\"st\">Size:</span> <span class=\"sc\">%@</span></li>", filesize];
	[strGeneral appendString:@"</ul>"];
	outDict[@"general"] = strGeneral;

	/* Video stream(s) */
	NSArray* videoArray = tracks[@(NYXTrackTypeVideo)];
	NSUInteger nbTracks = [videoArray count];
	if (nbTracks > 0)
	{
		NSMutableString* strVideo = [[NSMutableString alloc] initWithFormat:@"<h2 class=\"stitle\">Video%@</h2><ul>", (nbTracks > 1) ? @"s" : @""];
		NSUInteger i = 1;
		for (NSDictionary* track in videoArray)
		{
			// WIDTHxHEIGHT (aspect ratio)
			NSString* width = track[NYX_VIDEO_WIDTH];
			NSString* height = track[NYX_VIDEO_HEIGHT];
			NSString* aspect = track[NYX_VIDEO_ASPECT];
			[strVideo appendFormat:@"<li><span class=\"st\">Resolution:</span> <span class=\"sc\">%@x%@ <em>(%@)</em></span></li>", width, height, aspect];
			// Format, profile, bitrate, reframe
			NSString* format = track[NYX_VIDEO_FORMAT];
			NSString* profile = track[NYX_VIDEO_PROFILE];
			NSString* bitrate = track[NYX_VIDEO_BITRATE];
			NSString* ref = track[NYX_VIDEO_REFRAMES];
			[strVideo appendFormat:@"<li><span class=\"st\">Format/Codec:</span> <span class=\"sc\">%@", format];
			if (profile)
				[strVideo appendFormat:@" / %@", profile];
			if (bitrate)
				[strVideo appendFormat:@" / %@", bitrate];
			if (ref)
				[strVideo appendFormat:@" / %@ ReF", ref];
			[strVideo appendString:@"</span></li>"];
			// Framerate (mode)
			NSString* fps = track[NYX_VIDEO_FRAMERATE];
			NSString* fpsmode = track[NYX_VIDEO_FRAMERATE_MODE];
			if (!fps)
			{
				fps = track[NYX_VIDEO_FRAMERATE_ORIGINAL];
				if (!fps) // assume variable framerate
					fps = @"Undefined";
			}
			[strVideo appendFormat:@"<li><span class=\"st\">Framerate:</span> <span class=\"sc\">%@ <em>(%@)</em></span></li>", fps, fpsmode];
			// Bit depth
			NSString* bitdepth = track[NYX_VIDEO_BITDEPTH];
			[strVideo appendFormat:@"<li><span class=\"st\">Bit depth:</span> <span class=\"sc\">%@</span></li>", bitdepth];
			// Title
			NSString* title = track[NYX_VIDEO_TITLE];
			if (title)
				[strVideo appendFormat:@"<li><span class=\"st\">Title:</span> <span class=\"sc\">%@</span></li>", title];
			// Separator if multiple streams
			if (i < [videoArray count])
			{
				[strVideo appendString:@"<div class=\"sep\">----</div>"];
				i++;
			}
		}
		[strVideo appendString:@"</ul>"];
		outDict[@"video"] = strVideo;
	}

	/* Audio stream(s) */
	NSArray* audioArray = tracks[@(NYXTrackTypeAudio)];
	nbTracks = [audioArray count];
	if (nbTracks > 0)
	{
		NSMutableString* strAudio = [[NSMutableString alloc] initWithFormat:@"<h2 class=\"stitle\">Audio%@</h2><ul>", (nbTracks > 1) ? @"s" : @""];
		NSUInteger i = 1;
		for (NSDictionary* track in audioArray)
		{
			// Language
			NSString* lang = track[NYX_AUDIO_LANGUAGE];
			const BOOL def = [track[NYX_AUDIO_TRACK_DEFAULT] boolValue];
			[strAudio appendFormat:@"<li><span class=\"st\">Language:</span> <span class=\"sc\">%@ %@</span></li>", (lang) ? lang : @"<em>Undefined</em>", (def) ? @"<em>(Default)</em>" : @""];
			// Format, profile, bit depth, bitrate, sampling rate
			NSString* format = track[NYX_AUDIO_FORMAT];
			NSString* profile = track[NYX_AUDIO_PROFILE];
			NSString* bitdepth = track[NYX_AUDIO_BITDEPTH];
			NSString* bitrate = track[NYX_AUDIO_BITRATE];
			NSString* sampling = track[NYX_AUDIO_SAMPLING];
			[strAudio appendFormat:@"<li><span class=\"st\">Format/Codec:</span> <span class=\"sc\">%@", format];
			if (profile)
				[strAudio appendFormat:@" %@", profile];
			if (bitdepth)
				[strAudio appendFormat:@" / %@", bitdepth];
			if (bitrate)
				[strAudio appendFormat:@" / %@", bitrate];
			if (sampling)
				[strAudio appendFormat:@" / %@", sampling];
			[strAudio appendString:@"</span></li>"];
			// Channels
			NSString* channels = track[NYX_AUDIO_CHANNELS];
			const NSUInteger ich = (NSUInteger)[channels integerValue];
			NSString* tmp = nil;
			switch (ich)
			{
				case 2:
					tmp = @"2.0";
					break;
				case 3:
					tmp = @"2.1";
					break;
				case 6:
					tmp = @"5.1";
					break;
				case 7:
					tmp = @"6.1";
					break;
				case 8:
					tmp = @"7.1";
					break;
				default:
					tmp = @"???";
					break;
			}
			[strAudio appendFormat:@"<li><span class=\"st\">Channels:</span> <span class=\"sc\">%@ <em>(%@)</em></span></li>", channels, tmp];
			// Title
			NSString* title = track[NYX_AUDIO_TITLE];
			if (title)
				[strAudio appendFormat:@"<li><span class=\"st\">Title:</span> <span class=\"sc\">%@</span></li>", title];
			// Separator if multiple streams
			if (i < [audioArray count])
			{
				[strAudio appendString:@"<div class=\"sep\">----</div>"];
				i++;
			}
		}
		[strAudio appendString:@"</ul>"];
		outDict[@"audio"] = strAudio;
	}

	/* Subs stream(s) */
	NSArray* subsArray = tracks[@(NYXTrackTypeText)];
	nbTracks = [subsArray count];
	if (nbTracks > 0)
	{
		NSMutableString* strSubs = [[NSMutableString alloc] initWithFormat:@"<h2 class=\"stitle\">Subtitle%@</h2><ul>", (nbTracks > 1) ? @"s" : @""];
		NSUInteger i = 1;
		for (NSDictionary* track in subsArray)
		{
			// Language
			NSString* lang = track[NYX_SUB_LANGUAGE];
			const BOOL def = [track[NYX_SUB_TRACK_DEFAULT] boolValue];
			[strSubs appendFormat:@"<li><span class=\"st\">Language:</span> <span class=\"sc\">%@ %@</span></li>", (lang) ? lang : @"<em>Undefined</em>", (def) ? @"<em>(Default)</em>" : @""];
			// Format
			NSString* format = track[NYX_SUB_FORMAT];
			[strSubs appendFormat:@"<li><span class=\"st\">Format:</span> <span class=\"sc\">%@</span></li>", format];
			// Title
			NSString* title = track[NYX_SUB_TITLE];
			if (title)
				[strSubs appendFormat:@"<li><span class=\"st\">Title:</span> <span class=\"sc\">%@</span></li>", title];
			// Separator if multiple streams
			if (i < [subsArray count])
			{
				[strSubs appendString:@"<div class=\"sep\">----</div>"];
				i++;
			}
		}
		[strSubs appendString:@"</ul>"];
		outDict[@"subs"] = strSubs;
	}

	return outDict;
}

#pragma mark - Private
+(NSString*)__md5String:(NSString*)string
{
	uint8_t digest[CC_MD5_DIGEST_LENGTH];
	CC_MD5([string UTF8String], (CC_LONG)[string length], digest);
	NSMutableString* ret = [[NSMutableString alloc] init];
	for (NSUInteger i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
		[ret appendFormat:@"%02x", (int)(digest[i])];
	return [ret copy];
}

@end
