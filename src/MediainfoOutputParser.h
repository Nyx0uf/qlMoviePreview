#import <Foundation/Foundation.h>


// General tags
#define NYX_GENERAL_DURATION @"general_duration"
#define NYX_GENERAL_FILENAME @"general_filename"
#define NYX_GENERAL_FILESIZE @"general_filesize"
#define NYX_GENERAL_MOVIENAME @"general_moviename"
// Videos tags
#define NYX_VIDEO_ASPECT @"video_aspect"
#define NYX_VIDEO_BITDEPTH @"video_bitdepth"
#define NYX_VIDEO_BITRATE @"video_bitrate"
#define NYX_VIDEO_CODEC @"video_codec"
#define NYX_VIDEO_COLORSPACE @"video_colorspace"
#define NYX_VIDEO_FORMAT @"video_format"
#define NYX_VIDEO_FRAMERATE @"video_framerate"
#define NYX_VIDEO_FRAMERATE_MODE @"video_framerate_mode"
#define NYX_VIDEO_FRAMERATE_ORIGINAL @"video_framerate_orig"
#define NYX_VIDEO_HEIGHT @"video_height"
#define NYX_VIDEO_PROFILE @"video_profile"
#define NYX_VIDEO_REFRAMES @"video_reframes"
#define NYX_VIDEO_TITLE @"video_title"
#define NYX_VIDEO_WIDTH @"video_width"
// Audio tags
#define NYX_AUDIO_BITDEPTH @"audio_bitdepth"
#define NYX_AUDIO_BITRATE @"audio_bitrate"
#define NYX_AUDIO_CHANNELS @"audio_channels"
#define NYX_AUDIO_CODEC @"audio_codec"
#define NYX_AUDIO_FORMAT @"audio_format"
#define NYX_AUDIO_LANGUAGE @"audio_lang"
#define NYX_AUDIO_PROFILE @"audio_profile"
#define NYX_AUDIO_SAMPLING @"audio_sampling"
#define NYX_AUDIO_TITLE @"audio_title"
// Text tags
#define NYX_TEXT_FORMAT @"text_format"
#define NYX_TEXT_LANGUAGE @"text_lang"
#define NYX_TEXT_TITLE @"text_title"


// Tracks type
typedef NS_ENUM(NSInteger, NYXTrackType)
{
	NYXTrackTypeNO = 0,
	NYXTrackTypeGeneral = 1,
	NYXTrackTypeVideo,
	NYXTrackTypeAudio,
	NYXTrackTypeText,
	NYXTrackTypeMenu,
};


@interface MediainfoOutputParser : NSObject <NSXMLParserDelegate>

-(instancetype)initWithData:(NSData*)data;

-(NSDictionary*)parse;

@end
