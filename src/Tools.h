#import <Foundation/Foundation.h>


@interface Tools : NSObject

+(BOOL)isValidFilepath:(NSString*)filepath;

+(NSString*)createThumbnailForFilepath:(NSString*)filepath;

+(NSDictionary*)mediainfoForFilepath:(NSString*)filepath;

@end
