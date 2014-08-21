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


#define NYX_CACHE_DIRECTORY @"/tmp/qlmoviepreview/"


@implementation Tools

+(BOOL)isValidFilepath:(NSString*)filepath
{
	// Add extensions in the array to support more file types
	static NSArray* __valid_exts = nil;
	if (!__valid_exts)
		__valid_exts = [[NSArray alloc] initWithObjects:@"avi", @"divx", @"dv", @"flv", @"hevc", @"mkv", @"mov", @"mp4", @"mts", @"m2ts", @"m4v", @"ogv", @"rmvb", @"ts", @"vob", @"webm", @"wmv", @"yuv", @"y4m", @"264", @"3gp", @"3gpp", @"3g2", @"3gp2", nil];
	NSString* extension = [filepath pathExtension];
	return [__valid_exts containsObject:extension];
}

+(NSString*)createThumbnailForFilepath:(NSString*)filepath
{
	// Create a directory to hold generated thumbnails
	NSFileManager* fileManager = [[NSFileManager alloc] init];
	if (![fileManager fileExistsAtPath:NYX_CACHE_DIRECTORY])
		[fileManager createDirectoryAtPath:NYX_CACHE_DIRECTORY withIntermediateDirectories:YES attributes:nil error:nil];

	// Create thumbnail path, need to append png for ffmpeg to guess the type
	NSString* md5 = [Tools __md5String:filepath];
	NSString* thumbnailPath = [NYX_CACHE_DIRECTORY stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.png", md5]];

	// Thumbnail only once
	if ([fileManager fileExistsAtPath:thumbnailPath])
		return thumbnailPath;

	// ffmpeg -y -loglevel quiet -ss 8 -i bla.mp4 -vframes 1 -f image2 thumbnail.png
	// Get movie duration
	const NSInteger duration = [self getAccurateMovieDurationInSecondsForFilepath:filepath];
	NSTask* task = [[NSTask alloc] init];
	[task setLaunchPath:@"/usr/local/bin/ffmpeg"];
	if (duration <= 0) // Invalid duration, attempt to thumbnail the first frame
		[task setArguments:@[@"-y", @"-loglevel", @"quiet", @"-i", filepath, @"-vframes", @"1", @"-f", @"image2", thumbnailPath]];
	else // Thumbnail at 12%
		[task setArguments:@[@"-y", @"-loglevel", @"quiet", @"-ss", [NSString stringWithFormat:@"%ld", (NSInteger)((float)duration * 0.12f)], @"-i", filepath, @"-vframes", @"1", @"-f", @"image2", thumbnailPath]];
	[task launch];
	[task waitUntilExit];

	// Success
	if (0 == [task terminationStatus])
		return thumbnailPath;

	// Failure, create an empty file to avoid cycling
	[fileManager createFileAtPath:thumbnailPath contents:nil attributes:nil];

	return nil;
}

+(NSInteger)getAccurateMovieDurationInSecondsForFilepath:(NSString*)filepath
{
	// ffprobe is part of ffmpeg
	NSTask* task = [[NSTask alloc] init];
	[task setLaunchPath:@"/usr/local/bin/ffprobe"];
	[task setArguments:@[filepath, @"-show_format", @"-loglevel", @"quiet"]];
	NSPipe* outputPipe = [NSPipe pipe];
	[task setStandardOutput:outputPipe];
	[task launch];
	[task waitUntilExit];

	NSData* outputData = [[outputPipe fileHandleForReading] readDataToEndOfFile];
	if (!outputData)
		return 0;

	// Search for duration
	NSString* string = [[NSString alloc] initWithData:outputData encoding:NSUTF8StringEncoding];
	const NSRange r = [string rangeOfString:@"duration="];
	if (r.location != NSNotFound)
	{
		NSString* durationString = [string substringFromIndex:r.location + 9];
		const char* cs = [durationString cStringUsingEncoding:NSUTF8StringEncoding];
		if (!cs)
			return 0;
		NSMutableString* seconds = [[NSMutableString alloc] init];
		char* ptr = (char*)cs;
		while (*ptr != 10)
			[seconds appendFormat:@"%c", *ptr++];
		return (NSInteger)floor([seconds doubleValue]);
	}

	return 0;
}

+(NSDictionary*)mediainfoForFilepath:(NSString*)filepath
{
#define NYX_MEDIAINFO_SYMLINK_PATH @"/tmp/qlmoviepreview/tmp-symlink-for-mediainfo-to-be-happy-lulz"
	// mediainfo can't handle paths with some characters, like '?!'...
	// So we create a symlink to make it happy... this is so moronic.
	NSString* okFilepath = filepath;
	if ([filepath rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@"?!*"]].location != NSNotFound)
	{
		if ([[NSFileManager defaultManager] createSymbolicLinkAtPath:NYX_MEDIAINFO_SYMLINK_PATH withDestinationPath:filepath error:nil])
			okFilepath = NYX_MEDIAINFO_SYMLINK_PATH;
	}

	// mediainfo can be installed via homebrew
	// Output infos as XML
	NSTask* task = [[NSTask alloc] init];
	[task setLaunchPath:@"/usr/local/bin/mediainfo"];
	[task setArguments:@[okFilepath, @"--Output=XML"]];
	NSPipe* outputPipe = [NSPipe pipe];
	[task setStandardOutput:outputPipe];
	[task launch];
	[task waitUntilExit];
	// Remove the symlink, me -> zetsuboushita.
	if ([okFilepath isEqualToString:NYX_MEDIAINFO_SYMLINK_PATH])
		[[NSFileManager defaultManager] removeItemAtPath:NYX_MEDIAINFO_SYMLINK_PATH error:nil];

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
