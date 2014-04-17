//
//  MediainfoOutputParser.m
//  qlMoviePreview
//
//  Created by @Nyx0uf on 15/04/14.
//  Copyright (c) 2014 Nyx0uf. All rights reserved.
//  www.cocoaintheshell.com
//


#import "MediainfoOutputParser.h"


@implementation MediainfoOutputParser
{
	/// XML parser
	NSXMLParser* _parser;
	/// current parsed track dictionary
	NSMutableDictionary* _dictTrack;
	/// Final dictionary
	NSMutableDictionary* _dict;
	/// To trim some fields
	NSCharacterSet* _charSetToRemove;

	/* general */
	/// parsed track type
	NYXTrackType _trackType;
	/// parsed filename
	NSMutableString* _gfilename;
	/// parsed movie name
	NSMutableString* _gmovieName;
	/// parsed file size
	NSMutableString* _gfilesize;
	/// parsed duration
	NSMutableString* _gduration;

	/* video */
	/// parsed video aspect ratio
	NSMutableString* _vaspect;
	/// parsed video bit depth
	NSMutableString* _vbitd;
	/// parsed video bitrate
	NSMutableString* _vbitrate;
	/// parsed video codec
	NSMutableString* _vcodec;
	/// parsed video colorspace
	NSMutableString* _vcolorspace;
	/// parsed video format
	NSMutableString* _vformat;
	/// parsed video fps
	NSMutableString* _vfps;
	/// parsed fps mode
	NSMutableString* _vfpsmode;
	/// parsed original fps
	NSMutableString* _vfpsorig;
	/// parsed video height
	NSMutableString* _vheight;
	/// parsed video profile
	NSMutableString* _vprofile;
	/// parsed video ReFrames
	NSMutableString* _vreframes;
	/// parsed video title
	NSMutableString* _vtitle;
	/// parsed video width
	NSMutableString* _vwidth;

	/* audio */
	/// parsed audio bit depth
	NSMutableString* _abitd;
	/// parsed audio bit rate
	NSMutableString* _abitr;
	/// parsed audio channels
	NSMutableString* _achannels;
	/// parsed audio codec
	NSMutableString* _acodec;
	/// parsed audio format
	NSMutableString* _aformat;
	/// parsed audio language
	NSMutableString* _alang;
	/// parsed audio profile
	NSMutableString* _aprofile;
	/// parsed audio sampling
	NSMutableString* _asampling;
	/// parsed audio title
	NSMutableString* _atitle;

	/* text */
	/// parsed text format
	NSMutableString* _tformat;
	/// parsed text language
	NSMutableString* _tlang;
	/// parsed text title
	NSMutableString* _ttitle;
}

#pragma mark - Allocations
-(instancetype)initWithData:(NSData*)data;
{
	if ((self = [super init]))
	{
		_parser = [[NSXMLParser alloc] initWithData:data];
        [_parser setDelegate:self];
		_charSetToRemove = [NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ/ \r\n\t"];
	}
	return self;
}

#pragma mark - Public
-(NSDictionary*)parse
{
	_dict = [[NSMutableDictionary alloc] init];
	_trackType = NYXTrackTypeNO;
	[_parser parse];
	return [_dict copy];
}

#pragma mark - NSXMLParserDelegate
-(void)parser:(NSXMLParser*)parser didStartElement:(NSString*)elementName namespaceURI:(NSString*)namespaceURI qualifiedName:(NSString*)qualifiedName attributes:(NSDictionary*)attributeDict
{
	// Determine the type of track
	if ([elementName isEqualToString:@"track"])
	{
		NSString* trackType = attributeDict[@"type"];
		if ([trackType isEqualToString:@"General"])
		{
			_trackType = NYXTrackTypeGeneral;
		}
		else if ([trackType isEqualToString:@"Video"])
		{
			_trackType = NYXTrackTypeVideo;
		}
		else if ([trackType isEqualToString:@"Audio"])
		{
			_trackType = NYXTrackTypeAudio;
		}
		else if ([trackType isEqualToString:@"Text"])
		{
			_trackType = NYXTrackTypeText;
		}
		else
			_trackType = NYXTrackTypeNO;
		_dictTrack = [[NSMutableDictionary alloc] init];
	}

	// We are only interested in a few tags for each type of track
	switch (_trackType)
	{
		case NYXTrackTypeNO:
		{
			break;
		}
		case NYXTrackTypeGeneral:
		{
			if ([elementName isEqualToString:@"Complete_name"])
			{
				_gfilename = [[NSMutableString alloc] init];
			}
			else if ([elementName isEqualToString:@"Movie_name"])
			{
				_gmovieName = [[NSMutableString alloc] init];
			}
			else if ([elementName isEqualToString:@"File_size"])
			{
				_gfilesize = [[NSMutableString alloc] init];
			}
			else if ([elementName isEqualToString:@"Duration"])
			{
				_gduration = [[NSMutableString alloc] init];
			}
			break;
		}
		case NYXTrackTypeVideo:
		{
			if ([elementName isEqualToString:@"Display_aspect_ratio"])
			{
				_vaspect = [[NSMutableString alloc] init];
			}
			else if ([elementName isEqualToString:@"Bit_depth"])
			{
				_vbitd = [[NSMutableString alloc] init];
			}
			else if ([elementName isEqualToString:@"Bit_rate"])
			{
				_vbitrate = [[NSMutableString alloc] init];
			}
			else if ([elementName isEqualToString:@"Codec_ID"])
			{
				_vcodec = [[NSMutableString alloc] init];
			}
			else if ([elementName isEqualToString:@"Color_space"])
			{
				_vcolorspace = [[NSMutableString alloc] init];
			}
			else if ([elementName isEqualToString:@"Format"])
			{
				_vformat = [[NSMutableString alloc] init];
			}
			else if ([elementName isEqualToString:@"Frame_rate"])
			{
				_vfps = [[NSMutableString alloc] init];
			}
			else if ([elementName isEqualToString:@"Frame_rate_mode"])
			{
				_vfpsmode = [[NSMutableString alloc] init];
			}
			else if ([elementName isEqualToString:@"Original_frame_rate"])
			{
				_vfpsorig = [[NSMutableString alloc] init];
			}
			else if ([elementName isEqualToString:@"Height"])
			{
				_vheight = [[NSMutableString alloc] init];
			}
			else if ([elementName isEqualToString:@"Format_profile"])
			{
				_vprofile = [[NSMutableString alloc] init];
			}
			else if ([elementName isEqualToString:@"Format_settings__ReFrames"])
			{
				_vreframes = [[NSMutableString alloc] init];
			}
			else if ([elementName isEqualToString:@"Title"])
			{
				_vtitle = [[NSMutableString alloc] init];
			}
			else if ([elementName isEqualToString:@"Width"])
			{
				_vwidth = [[NSMutableString alloc] init];
			}
			break;
		}
		case NYXTrackTypeAudio:
		{
			if ([elementName isEqualToString:@"Bit_depth"])
			{
				_abitd = [[NSMutableString alloc] init];
			}
			else if ([elementName isEqualToString:@"Bit_rate"])
			{
				_abitr = [[NSMutableString alloc] init];
			}
			else if ([elementName isEqualToString:@"Channel_s_"])
			{
				_achannels = [[NSMutableString alloc] init];
			}
			else if ([elementName isEqualToString:@"Codec_ID"])
			{
				_acodec = [[NSMutableString alloc] init];
			}
			else if ([elementName isEqualToString:@"Format"])
			{
				_aformat = [[NSMutableString alloc] init];
			}
			else if ([elementName isEqualToString:@"Language"])
			{
				_alang = [[NSMutableString alloc] init];
			}
			else if ([elementName isEqualToString:@"Format_profile"])
			{
				_aprofile = [[NSMutableString alloc] init];
			}
			else if ([elementName isEqualToString:@"Sampling_rate"])
			{
				_asampling = [[NSMutableString alloc] init];
			}
			else if ([elementName isEqualToString:@"Title"])
			{
				_atitle = [[NSMutableString alloc] init];
			}
			break;
		}
		case NYXTrackTypeText:
		{
			if ([elementName isEqualToString:@"Format"])
			{
				_tformat = [[NSMutableString alloc] init];
			}
			else if ([elementName isEqualToString:@"Language"])
			{
				_tlang = [[NSMutableString alloc] init];
			}
			else if ([elementName isEqualToString:@"Title"])
			{
				_ttitle = [[NSMutableString alloc] init];
			}
			break;
		}
		case NYXTrackTypeMenu:
		{
			break;
		}
		default:
			break;
	}
}

-(void)parser:(NSXMLParser*)parser didEndElement:(NSString*)elementName namespaceURI:(NSString*)namespaceURI qualifiedName:(NSString*)qName
{
	if ([elementName isEqualToString:@"track"])
	{
		NSNumber* key = @(_trackType);

		if (NYXTrackTypeGeneral == _trackType)
			_dict[key] = _dictTrack;

		else if (NYXTrackTypeVideo == _trackType || NYXTrackTypeAudio == _trackType || NYXTrackTypeText == _trackType)
		{
			NSArray* tracks = _dict[key];
			if (tracks != nil)
			{
				NSMutableArray* tmp = [[NSMutableArray alloc] initWithArray:tracks];
				[tmp addObject:_dictTrack];
				tracks = [tmp copy];
			}
			else
			{
				tracks = [[NSArray alloc] initWithObjects:_dictTrack, nil];
			}
			_dict[key] = tracks;
		}

		_trackType = NYXTrackTypeNO;
		_dictTrack = nil;
		return;
	}

	// We are only interested in a few tags for each type of track
	switch (_trackType)
	{
		case NYXTrackTypeNO:
		{
			break;
		}
		case NYXTrackTypeGeneral:
		{
			if ([elementName isEqualToString:@"Complete_name"])
			{
				_dictTrack[NYX_GENERAL_FILENAME] = [_gfilename lastPathComponent];
				_gfilename = nil;
			}
			else if ([elementName isEqualToString:@"Movie_name"])
			{
				_dictTrack[NYX_GENERAL_MOVIENAME] = _gmovieName;
				_gmovieName = nil;
			}
			else if ([elementName isEqualToString:@"File_size"])
			{
				_dictTrack[NYX_GENERAL_FILESIZE] = _gfilesize;
				_gfilesize = nil;
			}
			else if ([elementName isEqualToString:@"Duration"])
			{
				_dictTrack[NYX_GENERAL_DURATION] = _gduration;
				_gduration = nil;
			}
			break;
		}
		case NYXTrackTypeVideo:
		{
			if ([elementName isEqualToString:@"Display_aspect_ratio"])
			{
				_dictTrack[NYX_VIDEO_ASPECT] = _vaspect;
				_vaspect = nil;
			}
			else if ([elementName isEqualToString:@"Bit_depth"])
			{
				_dictTrack[NYX_VIDEO_BITDEPTH] = _vbitd;
				_vbitd = nil;
			}
			else if ([elementName isEqualToString:@"Bit_rate"])
			{
				_dictTrack[NYX_VIDEO_BITRATE] = _vbitrate;
				_vbitrate = nil;
			}
			else if ([elementName isEqualToString:@"Codec_ID"])
			{
				_dictTrack[NYX_VIDEO_CODEC] = _vcodec;
				_vcodec = nil;
			}
			else if ([elementName isEqualToString:@"Color_space"])
			{
				_dictTrack[NYX_VIDEO_COLORSPACE] = _vcolorspace;
				_vcolorspace = nil;
			}
			else if ([elementName isEqualToString:@"Format"])
			{
				_dictTrack[NYX_VIDEO_FORMAT] = _vformat;
				_vformat = nil;
			}
			else if ([elementName isEqualToString:@"Frame_rate"])
			{
				_dictTrack[NYX_VIDEO_FRAMERATE] = [[_vfps stringByReplacingOccurrencesOfString:@" " withString:@""] stringByTrimmingCharactersInSet:_charSetToRemove];
				_vfps = nil;
			}
			else if ([elementName isEqualToString:@"Frame_rate_mode"])
			{
				_dictTrack[NYX_VIDEO_FRAMERATE_MODE] = _vfpsmode;
				_vfpsmode = nil;
			}
			else if ([elementName isEqualToString:@"Original_frame_rate"])
			{
				_dictTrack[NYX_VIDEO_FRAMERATE_ORIGINAL] = [[_vfpsorig stringByReplacingOccurrencesOfString:@" " withString:@""] stringByTrimmingCharactersInSet:_charSetToRemove];
				_vfpsorig = nil;
			}
			else if ([elementName isEqualToString:@"Height"])
			{
				_dictTrack[NYX_VIDEO_HEIGHT] = [[_vheight stringByReplacingOccurrencesOfString:@" " withString:@""] stringByTrimmingCharactersInSet:_charSetToRemove];
				_vheight = nil;
			}
			else if ([elementName isEqualToString:@"Format_profile"])
			{
				_dictTrack[NYX_VIDEO_PROFILE] = _vprofile;
				_vprofile = nil;
			}
			else if ([elementName isEqualToString:@"Format_settings__ReFrames"])
			{
				_dictTrack[NYX_VIDEO_REFRAMES] = [[_vreframes stringByReplacingOccurrencesOfString:@" " withString:@""] stringByTrimmingCharactersInSet:_charSetToRemove];
				_vreframes = nil;
			}
			else if ([elementName isEqualToString:@"Title"])
			{
				_dictTrack[NYX_VIDEO_TITLE] = _vtitle;
				_vtitle = nil;
			}
			else if ([elementName isEqualToString:@"Width"])
			{
				_dictTrack[NYX_VIDEO_WIDTH] = [[_vwidth stringByReplacingOccurrencesOfString:@" " withString:@""] stringByTrimmingCharactersInSet:_charSetToRemove];
				_vwidth = nil;
			}
			break;
		}
		case NYXTrackTypeAudio:
		{
			if ([elementName isEqualToString:@"Bit_depth"])
			{
				_dictTrack[NYX_AUDIO_BITDEPTH] = _abitd;
				_abitd = nil;
			}
			else if ([elementName isEqualToString:@"Bit_rate"])
			{
				_dictTrack[NYX_AUDIO_BITRATE] = _abitr;
				_abitr = nil;
			}
			else if ([elementName isEqualToString:@"Channel_s_"])
			{
				_dictTrack[NYX_AUDIO_CHANNELS] = [[[_achannels stringByReplacingOccurrencesOfString:@" " withString:@""] stringByTrimmingCharactersInSet:_charSetToRemove] substringToIndex:1];
				_achannels = nil;
			}
			else if ([elementName isEqualToString:@"Codec_ID"])
			{
				_dictTrack[NYX_AUDIO_CODEC] = _acodec;
				_acodec = nil;
			}
			else if ([elementName isEqualToString:@"Format"])
			{
				_dictTrack[NYX_AUDIO_FORMAT] = _aformat;
				_aformat = nil;
			}
			else if ([elementName isEqualToString:@"Language"])
			{
				_dictTrack[NYX_AUDIO_LANGUAGE] = _alang;
				_alang = nil;
			}
			else if ([elementName isEqualToString:@"Format_profile"])
			{
				_dictTrack[NYX_AUDIO_PROFILE] = _aprofile;
				_aprofile = nil;
			}
			else if ([elementName isEqualToString:@"Sampling_rate"])
			{
				_dictTrack[NYX_AUDIO_SAMPLING] = _asampling;
				_asampling = nil;
			}
			else if ([elementName isEqualToString:@"Title"])
			{
				_dictTrack[NYX_AUDIO_TITLE] = _atitle;
				_atitle = nil;
			}
			break;
		}
		case NYXTrackTypeText:
		{
			if ([elementName isEqualToString:@"Format"])
			{
				_dictTrack[NYX_TEXT_FORMAT] = _tformat;
				_tformat = nil;
			}
			else if ([elementName isEqualToString:@"Language"])
			{
				_dictTrack[NYX_TEXT_LANGUAGE] = _tlang;
				_tlang = nil;
			}
			else if ([elementName isEqualToString:@"Title"])
			{
				_dictTrack[NYX_TEXT_TITLE] = _ttitle;
				_ttitle = nil;
			}
			break;
		}
		case NYXTrackTypeMenu:
		{
			break;
		}
		default:
			break;
	}
}

-(void)parser:(NSXMLParser*)parser foundCharacters:(NSString*)string
{
	switch (_trackType)
	{
		case NYXTrackTypeNO:
			break;
		case NYXTrackTypeGeneral:
		{
			if (_gfilename)
			{
				[_gfilename appendString:string];
				return;
			}
			if (_gmovieName)
			{
				[_gmovieName appendString:string];
				return;
			}
			if (_gfilesize)
			{
				[_gfilesize appendString:string];
				return;
			}
			if (_gduration)
			{
				[_gduration appendString:string];
				return;
			}
			break;
		}
		case NYXTrackTypeVideo:
		{
			if (_vaspect)
			{
				[_vaspect appendString:string];
				return;
			}
			if (_vbitd)
			{
				[_vbitd appendString:string];
				return;
			}
			if (_vbitrate)
			{
				[_vbitrate appendString:string];
				return;
			}
			if (_vcodec)
			{
				[_vcodec appendString:string];
				return;
			}
			if (_vcolorspace)
			{
				[_vcolorspace appendString:string];
				return;
			}
			if (_vformat)
			{
				[_vformat appendString:string];
				return;
			}
			if (_vfps)
			{
				[_vfps appendString:string];
				return;
			}
			if (_vfpsmode)
			{
				[_vfpsmode appendString:string];
				return;
			}
			if (_vfpsorig)
			{
				[_vfpsorig appendString:string];
				return;
			}
			if (_vheight)
			{
				[_vheight appendString:string];
				return;
			}
			if (_vprofile)
			{
				[_vprofile appendString:string];
				return;
			}
			if (_vreframes)
			{
				[_vreframes appendString:string];
				return;
			}
			if (_vtitle)
			{
				[_vtitle appendString:string];
				return;
			}
			if (_vwidth)
			{
				[_vwidth appendString:string];
				return;
			}
			break;
		}
		case NYXTrackTypeAudio:
		{
			if (_abitd)
			{
				[_abitd appendString:string];
				return;
			}
			if (_abitr)
			{
				[_abitr appendString:string];
				return;
			}
			if (_achannels)
			{
				[_achannels appendString:string];
				return;
			}
			if (_acodec)
			{
				[_acodec appendString:string];
				return;
			}
			if (_aformat)
			{
				[_aformat appendString:string];
				return;
			}
			if (_alang)
			{
				[_alang appendString:string];
				return;
			}
			if (_aprofile)
			{
				[_aprofile appendString:string];
				return;
			}
			if (_asampling)
			{
				[_asampling appendString:string];
				return;
			}
			if (_atitle)
			{
				[_atitle appendString:string];
				return;
			}
			break;
		}
		case NYXTrackTypeText:
		{
			if (_tformat)
			{
				[_tformat appendString:string];
				return;
			}
			if (_tlang)
			{
				[_tlang appendString:string];
				return;
			}
			if (_ttitle)
			{
				[_ttitle appendString:string];
				return;
			}
			break;
		}
		case NYXTrackTypeMenu:
		{
			break;
		}
		default:
			break;
	}
}
		  
@end
