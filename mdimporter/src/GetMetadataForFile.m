//
//  GetMetadataForFile.m
//  mdMoviePreview
//
//  Created by @Nyx0uf on 24/12/14.
//  Copyright (c) 2014 Nyx0uf. All rights reserved.
//  www.cocoaintheshell.com
//


#import <CoreFoundation/CoreFoundation.h>
#import "Tools.h"
#import "NYXMovie.h"


Boolean GetMetadataForFile(void* thisInterface, CFMutableDictionaryRef attributes, CFStringRef contentTypeUTI, CFStringRef pathToFile);


Boolean GetMetadataForFile(void* thisInterface, CFMutableDictionaryRef attributes, CFStringRef contentTypeUTI, CFStringRef pathToFile)
{
    @autoreleasepool
	{
		// Check if the UTI is movie
		NSString* filepath = (__bridge NSString*)pathToFile;
		if (!UTTypeConformsTo(contentTypeUTI, kUTTypeMovie))
		{
			// NO. Check the extension
			if (![Tools isValidFilepath:filepath])
			{
				return FALSE;
			}
		}

		// Create movie object
		NYXMovie* movie = [[NYXMovie alloc] initWithFilepath:filepath];
		if (nil == movie)
		{
			return FALSE;
		}

		NSMutableDictionary* attrs = (__bridge NSMutableDictionary*)attributes;
		attrs[(__bridge NSString*)kMDItemDurationSeconds] = @([movie getDuration]);
		attrs[(__bridge NSString*)kMDItemTotalBitRate] = @([movie getBitRate]);
	
		return TRUE;
    }
	
    return FALSE;
}
