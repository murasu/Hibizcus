//
//  ExtShaperHb.h
//
//  Created by Muthu Nedumaran on 16/2/21.
//

#ifndef ExtShaperHb_h
#define ExtShaperHb_h

#import <Foundation/Foundation.h>

@interface HibizcusCppBridge : NSObject

// From Harfbuzz
- (NSString *) hbGetHbVersion;
- (NSString *) hbGetFontDisplayName;
- (NSString *) hbGetFontVersion;
- (NSString *) hbShapeString:(NSString *) string inLanguage:(NSString *)language;
//- (void) hbSetFontFilePath:(NSString *) path;
- (void) hbSetFontFilePath:(const char *)cString;
- (NSDictionary *)hbGetFontMetrics;
- (NSArray *) hbCollectUnicodes;

@end

#endif /* ExtShaperHb_h */
