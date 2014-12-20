//
//  MediainfoOutputParser.m
//  qlMoviePreview
//
//  Created by @Nyx0uf on 15/04/14.
//  Copyright (c) 2014 Nyx0uf. All rights reserved.
//  www.cocoaintheshell.com
//


#import "MediainfoParser.h"
#import "MediaInfoDLL.h"


@implementation MediainfoParser
{
	/// Mediainfo output
	NSString* _path;
}

#pragma mark - Allocations
-(instancetype)initWithPath:(NSString*)path
{
	if ((self = [super init]))
	{
		_path = path;
	}
	return self;
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
		  
@end
