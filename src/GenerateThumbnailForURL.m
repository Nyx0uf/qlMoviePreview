//
//  GenerateThumbnailForURL.m
//  qlMoviePreview
//
//  Created by @Nyx0uf on 15/04/14.
//  Copyright (c) 2014 Nyx0uf. All rights reserved.
//  www.cocoaintheshell.com
//


#import <QuickLook/QuickLook.h>
#import "Tools.h"


OSStatus GenerateThumbnailForURL(void* thisInterface, QLThumbnailRequestRef thumbnail, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options, CGSize maxSize);
void CancelThumbnailGeneration(void* thisInterface, QLThumbnailRequestRef thumbnail);


OSStatus GenerateThumbnailForURL(void* thisInterface, QLThumbnailRequestRef thumbnail, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options, CGSize maxSize)
{
	@autoreleasepool
	{
		DLog(@"uti=%@\nopts=%@", contentTypeUTI, options);
		// Verify if we support this type of file
		NSString* filepath = [(__bridge NSURL*)url path];
		if (![Tools isValidFilepath:filepath])
		{
			QLThumbnailRequestSetImageAtURL(thumbnail, url, NULL);
			return kQLReturnNoError;
		}

		// Check if cancel since thumb generation can take a long time
		if (QLThumbnailRequestIsCancelled(thumbnail))
			return kQLReturnNoError;

		// Create thumbnail
		NSString* thumbnailPath = [Tools createThumbnailForFilepath:filepath];
		if (!thumbnailPath)
		{
			QLThumbnailRequestSetImageAtURL(thumbnail, url, NULL);
			return kQLReturnNoError;
		}

		// Set thumbnail icon
		NSURL* outURL = [[NSURL alloc] initFileURLWithPath:thumbnailPath];
		QLThumbnailRequestSetImageAtURL(thumbnail, (__bridge CFURLRef)outURL, NULL);
		// The following functions do not work. There is no doc (it's Apple, why bother seriously) and nothin' on the net.
		// First you need to set the QLNeedsToBeRunInMainThread to true in the Info.plist then...
		// It fails with "[QL] UTI set by CFBundle/CFPlugIn 0x7f9041415bd0 <plugin_path> (bundle, loaded) is not a supported content type for QLThumbnailRequestSetThumbnailWithURLRepresentation()"
		//QLThumbnailRequestSetThumbnailWithURLRepresentation(thumbnail, (__bridge CFURLRef)outURL, kUTTypePNG, NULL, NULL);
		//NSData* data = [NSData dataWithContentsOfURL:outURL];
		//QLThumbnailRequestSetThumbnailWithDataRepresentation(thumbnail, (__bridge CFDataRef)data, kUTTypePNG, NULL, NULL);

		// Delete thumbnail
		//[[NSFileManager defaultManager] removeItemAtPath:thumbnailPath error:nil];

		return kQLReturnNoError;
	}
}

void CancelThumbnailGeneration(void* thisInterface, QLThumbnailRequestRef thumbnail)
{
}
