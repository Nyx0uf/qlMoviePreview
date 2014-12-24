//
//  MediainfoParser.mm
//  qlMoviePreview
//
//  Created by @Nyx0uf on 15/04/14.
//  Copyright (c) 2014 Nyx0uf. All rights reserved.
//  www.cocoaintheshell.com
//


#import "MediainfoParser.h"
#import "MediaInfoDLL.h"
#import "Tools.h"


@implementation MediainfoParser
{
	/// Mediainfo output
	NSString* _path;
	/// Symlink was created for the file
	BOOL _symlinked;
}

#pragma mark - Allocations / Deallocations
-(instancetype)initWithFilepath:(NSString*)filepath
{
	if ((self = [super init]))
	{
		if (nil == filepath)
			return nil;

		// mediainfo can't handle paths with some characters, like '?!*'...
		// So we create a symlink to make it happy... this is so moronic.
		if ([filepath rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@"?!*"]].location != NSNotFound)
		{
			NSString* pp = [@"/tmp/qlmoviepreview/" stringByAppendingPathComponent:[Tools md5String:filepath]];
			if ([[NSFileManager defaultManager] createSymbolicLinkAtPath:pp withDestinationPath:filepath error:nil])
			{
				_path = [pp copy];
				_symlinked = YES;
			}
			else
				return nil;
		}
		else
		{
			_path = [filepath copy];
			_symlinked = NO;
		}
	}
	return self;
}

-(void)dealloc
{
	// Remove the symlink, me -> zetsuboushita.
	if (_symlinked)
		[[NSFileManager defaultManager] removeItemAtPath:_path error:nil];
}

#pragma mark - Public
-(NSDictionary*)analyze
{
	MediaInfoDLL::MediaInfo MI;
	MI.Open(__T([_path UTF8String]));
	NSString* string = [[NSString alloc] initWithUTF8String:MI.Inform().c_str()];

	NSCharacterSet* csWhiteSpaces = [NSCharacterSet whitespaceAndNewlineCharacterSet];
	NSCharacterSet* csASCII = [NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ/ \r\n\t"];

	NSMutableDictionary* dict = [[NSMutableDictionary alloc] init];
	NSMutableDictionary* tmpDict = nil;
	NYXTrackType trackType = NYXTrackTypeNO;
	NSArray* list = [string componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
	for (NSString* str in list)
	{
		NSString* line = [str stringByTrimmingCharactersInSet:csWhiteSpaces];
		NSMutableArray* pair = [[line componentsSeparatedByString:@":"] mutableCopy];
		const NSUInteger count = [pair count];
		if (1 == count) // sections name
		{
			NSNumber* key = @(trackType);
			if (NYXTrackTypeGeneral == trackType)
				dict[key] = tmpDict;
			else if (NYXTrackTypeVideo == trackType || NYXTrackTypeAudio == trackType || NYXTrackTypeText == trackType)
			{
				NSArray* tracks = dict[key];
				if (tracks != nil)
				{
					NSMutableArray* tmp = [[NSMutableArray alloc] initWithArray:tracks];
					[tmp addObject:tmpDict];
					tracks = [tmp copy];
				}
				else
				{
					tracks = [[NSArray alloc] initWithObjects:tmpDict, nil];
				}
				dict[key] = tracks;
			}
		
			if ([line isEqualToString:@"General"])
				trackType = NYXTrackTypeGeneral;
			else if ([line rangeOfString:@"Video"].location != NSNotFound)
				trackType = NYXTrackTypeVideo;
			else if ([line rangeOfString:@"Audio"].location != NSNotFound)
				trackType = NYXTrackTypeAudio;
			else if ([line rangeOfString:@"Text"].location != NSNotFound)
				trackType = NYXTrackTypeText;
			else
			{
				trackType = NYXTrackTypeNO;
				continue;
			}
			tmpDict = [[NSMutableDictionary alloc] init];
		}
		else
		{
			if (NYXTrackTypeNO == trackType)
				continue;

			// Sanitize strings
			NSString* key = [pair[0] stringByTrimmingCharactersInSet:csWhiteSpaces];
			if (count > 2)
			{
				NSArray* atmp = [pair subarrayWithRange:(NSRange){1, count - 1}];
				NSString* stmp = [atmp componentsJoinedByString:@":"];
				pair[1] = [stmp stringByTrimmingCharactersInSet:csWhiteSpaces];
			}
			else
			{
				pair[1] = [pair[1] stringByTrimmingCharactersInSet:csWhiteSpaces];
			}

			if (NYXTrackTypeGeneral == trackType)
			{
				if ([key isEqualToString:@"Complete name"])
				{
					tmpDict[NYX_GENERAL_FILENAME] = [pair[1] lastPathComponent];
				}
				else if ([key isEqualToString:@"Movie name"])
				{
					tmpDict[NYX_GENERAL_MOVIENAME] = pair[1];
				}
				else if ([key isEqualToString:@"File size"])
				{
					tmpDict[NYX_GENERAL_FILESIZE] = pair[1];
				}
				else if ([key isEqualToString:@"Duration"])
				{
					tmpDict[NYX_GENERAL_DURATION] = pair[1];
				}
			}
			else if (NYXTrackTypeVideo == trackType)
			{
				if ([key isEqualToString:@"Display aspect ratio"])
				{
					tmpDict[NYX_VIDEO_ASPECT] = pair[1];
				}
				else if ([key isEqualToString:@"Bit depth"])
				{
					tmpDict[NYX_VIDEO_BITDEPTH] = pair[1];
				}
				else if ([key isEqualToString:@"Bit rate"])
				{
					tmpDict[NYX_VIDEO_BITRATE] = pair[1];
				}
				else if ([key isEqualToString:@"Codec ID"])
				{
					tmpDict[NYX_VIDEO_CODEC] = pair[1];
				}
				else if ([key isEqualToString:@"Color space"])
				{
					tmpDict[NYX_VIDEO_COLORSPACE] = pair[1];
				}
				else if ([key isEqualToString:@"Format"])
				{
					tmpDict[NYX_VIDEO_FORMAT] = pair[1];
				}
				else if ([key isEqualToString:@"Frame rate"])
				{
					tmpDict[NYX_VIDEO_FRAMERATE] = [[pair[1] stringByReplacingOccurrencesOfString:@" " withString:@""] stringByTrimmingCharactersInSet:csASCII];
				}
				else if ([key isEqualToString:@"Frame rate mode"])
				{
					tmpDict[NYX_VIDEO_FRAMERATE_MODE] = pair[1];
				}
				else if ([key isEqualToString:@"Original frame rate"])
				{
					tmpDict[NYX_VIDEO_FRAMERATE_ORIGINAL] = [[pair[1] stringByReplacingOccurrencesOfString:@" " withString:@""] stringByTrimmingCharactersInSet:csASCII];
				}
				else if ([key isEqualToString:@"Height"])
				{
					tmpDict[NYX_VIDEO_HEIGHT] = [[pair[1] stringByReplacingOccurrencesOfString:@" " withString:@""] stringByTrimmingCharactersInSet:csASCII];
				}
				else if ([key isEqualToString:@"Format profile"])
				{
					tmpDict[NYX_VIDEO_PROFILE] = pair[1];
				}
				else if ([key isEqualToString:@"Format settings, ReFrames"])
				{
					tmpDict[NYX_VIDEO_REFRAMES] = [[pair[1] stringByReplacingOccurrencesOfString:@" " withString:@""] stringByTrimmingCharactersInSet:csASCII];
				}
				else if ([key isEqualToString:@"Title"])
				{
					tmpDict[NYX_VIDEO_TITLE] = pair[1];
				}
				else if ([key isEqualToString:@"Default"])
				{
					tmpDict[NYX_VIDEO_TRACK_DEFAULT] = ([pair[1] isEqualToString:@"No"]) ? @NO : @YES;
				}
				else if ([key isEqualToString:@"Forced"])
				{
					tmpDict[NYX_VIDEO_TRACK_FORCED] = ([pair[1] isEqualToString:@"No"]) ? @NO : @YES;
				}
				else if ([key isEqualToString:@"Width"])
				{
					tmpDict[NYX_VIDEO_WIDTH] = [[pair[1] stringByReplacingOccurrencesOfString:@" " withString:@""] stringByTrimmingCharactersInSet:csASCII];
				}
			}
			else if (NYXTrackTypeAudio == trackType)
			{
				if ([key isEqualToString:@"Bit depth"])
				{
					tmpDict[NYX_AUDIO_BITDEPTH] = pair[1];
				}
				else if ([key isEqualToString:@"Bit rate"])
				{
					tmpDict[NYX_AUDIO_BITRATE] = pair[1];
				}
				else if ([key isEqualToString:@"Channel(s)"])
				{
					tmpDict[NYX_AUDIO_CHANNELS] = [[[pair[1] stringByReplacingOccurrencesOfString:@" " withString:@""] stringByTrimmingCharactersInSet:csASCII] substringToIndex:1];
				}
				else if ([key isEqualToString:@"Codec ID"])
				{
					tmpDict[NYX_AUDIO_CODEC] = pair[1];
				}
				else if ([key isEqualToString:@"Format"])
				{
					tmpDict[NYX_AUDIO_FORMAT] = pair[1];
				}
				else if ([key isEqualToString:@"Language"])
				{
					tmpDict[NYX_AUDIO_LANGUAGE] = pair[1];
				}
				else if ([key isEqualToString:@"Format profile"])
				{
					tmpDict[NYX_AUDIO_PROFILE] = pair[1];
				}
				else if ([key isEqualToString:@"Sampling rate"])
				{
					tmpDict[NYX_AUDIO_SAMPLING] = pair[1];
				}
				else if ([key isEqualToString:@"Title"])
				{
					tmpDict[NYX_AUDIO_TITLE] = pair[1];
				}
				else if ([key isEqualToString:@"Default"])
				{
					tmpDict[NYX_AUDIO_TRACK_DEFAULT] = ([pair[1] isEqualToString:@"No"]) ? @NO : @YES;
				}
				else if ([key isEqualToString:@"Forced"])
				{
					tmpDict[NYX_AUDIO_TRACK_FORCED] = ([pair[1] isEqualToString:@"No"]) ? @NO : @YES;
				}
			}
			else if (NYXTrackTypeText == trackType)
			{
				if ([key isEqualToString:@"Format"])
				{
					tmpDict[NYX_SUB_FORMAT] = pair[1];
				}
				else if ([key isEqualToString:@"Language"])
				{
					tmpDict[NYX_SUB_LANGUAGE] = pair[1];
				}
				else if ([key isEqualToString:@"Title"])
				{
					tmpDict[NYX_SUB_TITLE] = pair[1];
				}
				else if ([key isEqualToString:@"Default"])
				{
					tmpDict[NYX_SUB_TRACK_DEFAULT] = ([pair[1] isEqualToString:@"No"]) ? @NO : @YES;
				}
				else if ([key isEqualToString:@"Forced"])
				{
					tmpDict[NYX_SUB_TRACK_FORCED] = ([pair[1] isEqualToString:@"No"]) ? @NO : @YES;
				}
			}
		}
	}

	return dict;
}

#pragma mark - Static
+(NSDictionary*)format:(NSDictionary*)tracks
{
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
					case 1:
					tmp = @"1.0 [Mono]";
					break;
					case 2:
					tmp = @"2.0 [Stereo]";
					break;
					case 3:
					tmp = @"2.1 [Surround]";
					break;
					case 6:
					tmp = @"5.1 [Surround]";
					break;
					case 7:
					tmp = @"6.1 [Surround]";
					break;
					case 8:
					tmp = @"7.1 [Surround]";
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
		  
@end
