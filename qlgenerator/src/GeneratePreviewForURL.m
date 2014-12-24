//
//  GeneratePreviewForURL.m
//  qlMoviePreview
//
//  Created by @Nyx0uf on 15/04/14.
//  Copyright (c) 2014 Nyx0uf. All rights reserved.
//  www.cocoaintheshell.com
//


#import <QuickLook/QuickLook.h>
#import "Tools.h"
#import "NYXMovie.h"


extern NSBundle* __selfBundle;


OSStatus GeneratePreviewForURL(void* thisInterface, QLPreviewRequestRef preview, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options);
void CancelPreviewGeneration(void* thisInterface, QLPreviewRequestRef preview);


OSStatus GeneratePreviewForURL(void* thisInterface, QLPreviewRequestRef preview, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options)
{
	@autoreleasepool
	{
		NSString* filepath = [(__bridge NSURL*)url path];

		// Check if the UTI is movie
		if (!UTTypeConformsTo(contentTypeUTI, kUTTypeMovie))
		{
			// NO. Check the extension
			if (![Tools isValidFilepath:filepath])
			{
				QLPreviewRequestSetURLRepresentation(preview, url, contentTypeUTI, NULL);
				return kQLReturnNoError;
			}
		}

		// Check if cancelled since thumbnailing can take a long time
		if (QLPreviewRequestIsCancelled(preview))
			return kQLReturnNoError;

		// Create thumbnail
		NYXMovie* movie = [[NYXMovie alloc] initWithFilepath:filepath];
		if (nil == movie)
		{
			QLPreviewRequestSetURLRepresentation(preview, url, contentTypeUTI, NULL);
			return kQLReturnNoError;
		}
		NSString* thumbnailpath = [[@"/tmp/qlmoviepreview/" stringByAppendingPathComponent:[Tools md5String:filepath]] stringByAppendingPathExtension:@"png"];
		if (![movie createThumbnailAtPath:thumbnailpath ofSize:(NYXSize){.w = 1280, .h = 720} atPosition:60])
		{
			QLPreviewRequestSetURLRepresentation(preview, url, contentTypeUTI, NULL);
			return kQLReturnNoError;
		}

		// Check if cancelled
		if (QLPreviewRequestIsCancelled(preview))
			return kQLReturnNoError;

		// Get the movie properties
		NSDictionary* mediainfo = [Tools mediainfoForFilepath:filepath];
		if (nil == mediainfo)
		{
			QLPreviewRequestSetURLRepresentation(preview, url, contentTypeUTI, NULL);
			return kQLReturnNoError;
		}

		// Load CSS && thumbnail
		NSURL* css_file = [__selfBundle URLForResource:@"style" withExtension:@"css"];
		NSData* css_data = [[NSData alloc] initWithContentsOfURL:css_file];
		NSData* thumbnail_data = [[NSData alloc] initWithContentsOfFile:thumbnailpath];
		// Create properties with all metadata and attachments
		NSDictionary* properties = @{ // properties for the HTML data
									 (__bridge NSString*)kQLPreviewPropertyTextEncodingNameKey : @"UTF-8",
									 (__bridge NSString*)kQLPreviewPropertyMIMETypeKey : @"text/html",
									 // CSS and thumbnail
									 (__bridge NSString*)kQLPreviewPropertyAttachmentsKey : @{
											 @"css" : @{
													 (__bridge NSString*)kQLPreviewPropertyMIMETypeKey : @"text/css",
													 (__bridge NSString*)kQLPreviewPropertyAttachmentDataKey: css_data,
													 },
											 @"thb" : @{
													 (__bridge NSString*)kQLPreviewPropertyMIMETypeKey : @"image/png",
													 (__bridge NSString*)kQLPreviewPropertyAttachmentDataKey: thumbnail_data,
													 },
											 },
									 };
		// Create HTML
		NSString* general = mediainfo[@"general"];
		NSString* video = mediainfo[@"video"];
		NSString* audio = mediainfo[@"audio"];
		NSString* subs = mediainfo[@"subs"];
		NSString* html = [[NSString alloc] initWithFormat:@"<!DOCTYPE html><html><head><link rel=\"stylesheet\" type=\"text/css\" href=\"cid:css\"></head><body><div id=\"c\"><div id=\"i\"><img src=\"cid:thb\"></div><div id=\"t\">%@%@%@%@</div></div></body></html>", general ?: @"", video ?: @"", audio ?: @"", subs ?: @""];

		// Give the HTML to QuickLook
		QLPreviewRequestSetDataRepresentation(preview, (__bridge CFDataRef)[html dataUsingEncoding:NSUTF8StringEncoding], kUTTypeHTML, (__bridge CFDictionaryRef)properties);
		
		return kQLReturnNoError;
	}
}

void CancelPreviewGeneration(void* thisInterface, QLPreviewRequestRef preview)
{
}
