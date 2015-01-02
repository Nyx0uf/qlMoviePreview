//
//  GenerateThumbnailForURL.m
//  qlMoviePreview
//
//  Created by @Nyx0uf on 15/04/14.
//  Copyright (c) 2014 Nyx0uf. All rights reserved.
//  www.cocoaintheshell.com
//


#import <QuickLook/QuickLook.h>
#import "NYXMovie.h"
#import "Tools.h"


OSStatus GenerateThumbnailForURL(void* thisInterface, QLThumbnailRequestRef thumbnail, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options, CGSize maxSize);
void CancelThumbnailGeneration(void* thisInterface, QLThumbnailRequestRef thumbnail);


OSStatus GenerateThumbnailForURL(__unused void* thisInterface, QLThumbnailRequestRef thumbnail, CFURLRef url, CFStringRef contentTypeUTI, __unused CFDictionaryRef options, __unused CGSize maxSize)
{
	@autoreleasepool
	{
		// Check if the UTI is movie
		NSString* filepath = [(__bridge NSURL*)url path];
		if (!UTTypeConformsTo(contentTypeUTI, kUTTypeMovie))
		{
			// NO. Check the extension
			if (![Tools isValidFilepath:filepath])
				return kQLReturnNoError;
		}

		// Check if cancelled since thumbnailing can take a long time
		if (QLThumbnailRequestIsCancelled(thumbnail))
			return kQLReturnNoError;

		// Create thumbnail
		NYXMovie* movie = [[NYXMovie alloc] initWithFilepath:filepath];
		if (nil == movie)
		{
			return kQLReturnNoError;
		}
		NSString* thumbnailpath = [[@"/tmp/qlmoviepreview/" stringByAppendingPathComponent:[Tools md5String:filepath]] stringByAppendingPathExtension:@"png"];
		if (![movie createThumbnailAtPath:thumbnailpath ofSize:(NYXSize){.w = 1280, .h = 720} atPosition:60])
		{
			return kQLReturnNoError;
		}

		// Re-check if cancelled
		if (QLThumbnailRequestIsCancelled(thumbnail))
			return kQLReturnNoError;

		// Set thumbnail icon
		NSURL* img_url = [[NSURL alloc] initFileURLWithPath:thumbnailpath];
		QLThumbnailRequestSetImageAtURL(thumbnail, (__bridge CFURLRef)img_url, NULL);

		return kQLReturnNoError;
	}
}

void CancelThumbnailGeneration(__unused void* thisInterface, __unused QLThumbnailRequestRef thumbnail)
{
}
