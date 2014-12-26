//
//  NYXMovie.h
//  qlMoviePreview
//
//  Created by @Nyx0uf on 24/12/14.
//  Copyright (c) 2014 Nyx0uf. All rights reserved.
//  www.cocoaintheshell.com
//


#import <Foundation/Foundation.h>


typedef struct _nyx_size_struct
{
	size_t w;
	size_t h;
} NYXSize;


@interface NYXMovie : NSObject

-(instancetype)initWithFilepath:(NSString*)filepath;

-(bool)createThumbnailAtPath:(NSString*)path ofSize:(NYXSize)size atPosition:(int64_t)position;

-(void)fillDictionary:(NSMutableDictionary*)attrs;

-(NSDictionary*)informations;

@end
