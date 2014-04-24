//
//  Tools.h
//  qlMoviePreview
//
//  Created by @Nyx0uf on 15/04/14.
//  Copyright (c) 2014 Nyx0uf. All rights reserved.
//  www.cocoaintheshell.com
//


#import <Foundation/Foundation.h>


@interface Tools : NSObject

+(BOOL)isValidFilepath:(NSString*)filepath;

+(NSString*)createThumbnailForFilepath:(NSString*)filepath;

+(NSDictionary*)mediainfoForFilepath:(NSString*)filepath;

@end
