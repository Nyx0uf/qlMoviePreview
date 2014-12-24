//
//  NYXMovie.m
//  qlMoviePreview
//
//  Created by @Nyx0uf on 24/12/14.
//  Copyright (c) 2014 Nyx0uf. All rights reserved.
//  www.cocoaintheshell.com
//


#import "NYXMovie.h"
#import <libavformat/avformat.h>
#import <libswscale/swscale.h>


@implementation NYXMovie
{
	NSString* _filepath;
	AVFormatContext* _fmt_ctx;
	AVCodecContext* _dec_ctx;
	AVStream* _stream;
	AVFrame* _frame;
	AVPicture _picture;
	int _stream_idx;
}

#pragma mark - Allocations / Deallocations
-(instancetype)initWithFilepath:(NSString*)filepath
{
	if ((self = [super init]))
	{
		if (nil == filepath)
			return nil;

		_filepath = [filepath copy];
		_fmt_ctx = NULL;
		_dec_ctx = NULL;
		_stream = NULL;
		_frame = NULL;
		_stream_idx = 0;

		if (avformat_open_input(&_fmt_ctx, [filepath UTF8String], NULL, NULL) != 0)
		{
			return nil;
		}

		if (avformat_find_stream_info(_fmt_ctx, NULL))
		{
			avformat_close_input(&_fmt_ctx);
			return nil;
		}

		// Find video stream
		AVCodec* codec = NULL;
		for (_stream_idx = 0; _stream_idx < (int)_fmt_ctx->nb_streams; _stream_idx++)
		{
			_stream = _fmt_ctx->streams[_stream_idx];
			_dec_ctx = _stream->codec;
			if ((_dec_ctx) && (_dec_ctx->codec_type == AVMEDIA_TYPE_VIDEO))
			{
				if (_dec_ctx->height > 0)
					codec = avcodec_find_decoder(_dec_ctx->codec_id);
				break;
			}
		}
		// Open codec
		if ((NULL == codec) || (avcodec_open2(_dec_ctx, codec, NULL) != 0))
		{
			avformat_close_input(&_fmt_ctx);
			return nil;
		}

		// Allocate frame
		if (NULL == (_frame = av_frame_alloc()))
		{
			avcodec_close(_dec_ctx);
			avformat_close_input(&_fmt_ctx);
			return nil;
		}
	}
	return self;
}

-(void)dealloc
{
	avpicture_free(&_picture);
	av_frame_free(&_frame);
	avcodec_close(_dec_ctx);
	avformat_close_input(&_fmt_ctx);
}

#pragma mark - Public
-(bool)createThumbnailAtPath:(NSString*)path ofSize:(NYXSize)size atPosition:(int64_t)position
{
	// Thumbnail only once
	NSFileManager* file_manager = [[NSFileManager alloc] init];
	if ([file_manager fileExistsAtPath:path])
		return true;

	// Set screenshot offset
	// If duration is unknown or less than 2 seconds, use the first frame
	if (_fmt_ctx->duration > (2 * AV_TIME_BASE))
	{
		int64_t timestamp = (_fmt_ctx->duration > (position * 2 * AV_TIME_BASE) ? av_rescale(position, _stream->time_base.den, _stream->time_base.num) : av_rescale(_fmt_ctx->duration, _stream->time_base.den, 2 * AV_TIME_BASE * _stream->time_base.num));
		if (_stream->start_time > 0)
			timestamp += _stream->start_time;
		if (av_seek_frame(_fmt_ctx, _stream_idx, timestamp, AVSEEK_FLAG_BACKWARD) < 0)
			av_seek_frame(_fmt_ctx, _stream_idx, 0, AVSEEK_FLAG_BYTE); // Fail, rewind
	}

	AVPacket packet;
	av_init_packet(&packet);
	packet.data = NULL;
	packet.size = 0;
	int got_frame = 0;
	while (av_read_frame(_fmt_ctx, &packet) >= 0)
	{
		if (packet.stream_index == _stream_idx)
			avcodec_decode_video2(_dec_ctx, _frame, &got_frame, &packet);
		av_free_packet(&packet);
		if (got_frame)
			break;
	}
	if (!got_frame) // No frame :<
	{
		return false;
	}

	// Allocate thumbnail
	avpicture_free(&_picture);
	if (avpicture_alloc(&_picture, AV_PIX_FMT_RGB24, (int)size.w, (int)size.h) != 0)
	{
		return false;
	}

	// Convert frame and scale if needed
	struct SwsContext* sws_ctx = sws_getContext(_dec_ctx->width, _dec_ctx->height, _dec_ctx->pix_fmt, (int)size.w, (int)size.h, AV_PIX_FMT_RGB24, SWS_SPLINE, NULL, NULL, NULL);
	if (NULL == sws_ctx)
	{
		return false;
	}
	sws_scale(sws_ctx, (const uint8_t* const*)_frame->data, _frame->linesize, 0, _dec_ctx->height, _picture.data, _picture.linesize);
	sws_freeContext(sws_ctx);

	// Create CGImageRef
	CGDataProviderRef data_provider = CGDataProviderCreateWithData(NULL, _picture.data[0], (size.w * size.h * 3), NULL);
	CGColorSpaceRef color_space = CGColorSpaceCreateDeviceRGB();
	CGImageRef img_ref = CGImageCreate(size.w, size.h, 8, 24, size.w * 3, color_space, kCGBitmapByteOrderDefault, data_provider, NULL, false, kCGRenderingIntentDefault);
	CGColorSpaceRelease(color_space);
	CGDataProviderRelease(data_provider);

	if (NULL == img_ref)
	{
		return false;
	}

	// Save
	CGImageDestinationRef dst = CGImageDestinationCreateWithURL((__bridge CFURLRef)[NSURL fileURLWithPath:path], kUTTypePNG, 1, NULL);
	if (NULL == dst)
	{
		CGImageRelease(img_ref);
		return false;
	}
	CGImageDestinationAddImage(dst, img_ref, NULL);
	const bool ret = CGImageDestinationFinalize(dst);
	CFRelease(dst);
	CGImageRelease(img_ref);

	return ret;
}

#pragma mark - Getters
-(double)getDuration
{
	return (double)((double)_fmt_ctx->duration / AV_TIME_BASE);
}

-(int)getBitRate
{
	return _fmt_ctx->bit_rate;
}

@end
