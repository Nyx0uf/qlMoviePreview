//
//  Tools.m
//  qlMoviePreview
//
//  Created by @Nyx0uf on 15/04/14.
//  Copyright (c) 2014 Nyx0uf. All rights reserved.
//  www.cocoaintheshell.com
//


#import "Tools.h"
#import <CommonCrypto/CommonDigest.h>


@implementation Tools

+(BOOL)isValidFilepath:(NSString*)filepath
{
	// Add extensions in the array to support more file types
	static NSArray* __valid_exts = nil;
	if (!__valid_exts)
		__valid_exts = [[NSArray alloc] initWithObjects:@"avi", @"divx", @"dv", @"flv", @"hevc", @"mkv", @"mk3d", @"mov", @"mp4", @"mts", @"m2ts", @"m4v", @"ogv", @"rmvb", @"ts", @"vob", @"webm", @"wmv", @"yuv", @"y4m", @"264", @"3gp", @"3gpp", @"3g2", @"3gp2", nil];
	NSString* extension = [filepath pathExtension];
	return [__valid_exts containsObject:extension];
}

+(NSString*)md5String:(NSString*)string
{
	uint8_t digest[CC_MD5_DIGEST_LENGTH];
	CC_MD5([string UTF8String], (CC_LONG)[string length], digest);
	NSMutableString* ret = [[NSMutableString alloc] init];
	for (NSUInteger i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
		[ret appendFormat:@"%02x", (int)(digest[i])];
	return [ret copy];
}

@end
