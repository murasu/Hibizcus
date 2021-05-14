//
//  ExtShaperHb.m
//
//  Created by Muthu Nedumaran on 16/2/21.
//

#import "HibizcusCppBridge.h"
// Silence documentation warnings
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdocumentation"
#import "hb_shaper_cpp.h"
#pragma clang diagnostic push

@interface HibizcusCppBridge()
@property hb_shaper_cpp *hb;
@end

@implementation HibizcusCppBridge

@synthesize hb;

- (id) init {
    self = [super init];
    hb = new hb_shaper_cpp();
    
    return self;
}

- (void)dealloc {
    hb->clean_up();
}

- (NSString *) hbGetHbVersion
{
    return [NSString stringWithUTF8String:hb->get_hb_version().c_str()];
}

- (NSString *) hbGetFontDisplayName
{
    return [NSString stringWithUTF8String:hb->get_font_display_name().c_str()];
}

- (NSString *) hbGetFontVersion
{
    return [NSString stringWithUTF8String:hb->get_font_version().c_str()];
}

- (void) hbSetFontFilePath:(const char *)cString //(NSString *) file
{
    //hb->init_with_font_file(file.UTF8String);
    hb->init_with_font_file(cString);
}

- (NSString *) hbShapeString:(NSString *) string inLanguage:(NSString *) language
{
    NSString *shapedJson = [NSString stringWithUTF8String:hb->shape_text(string.UTF8String, language.UTF8String).c_str()];
    
    return shapedJson;
}

- (NSDictionary *) hbGetFontMetrics
{
    hb_font_metrics *fm = hb->get_font_metrics();
    NSDictionary *metrics = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithInt:fm->upem], @"upem",
                             [NSNumber numberWithFloat:fm->baseline], @"baseline",
                             [NSNumber numberWithFloat:fm->ascender], @"ascender",
                             [NSNumber numberWithFloat:fm->capheight], @"capheight",
                             [NSNumber numberWithFloat:fm->descender], @"descender",
                             [NSNumber numberWithFloat:fm->underline_pos], @"underlinePos",
                             [NSNumber numberWithFloat:fm->underline_thickness], @"underlineThickness",
                             [NSNumber numberWithFloat:fm->xheight], @"xHeight", nil];
    return metrics;
}

- (NSArray *) hbCollectUnicodes
{
    hb_set_t *codepoints = hb->collect_unicodes();
    
    NSMutableArray *unicodes = [[NSMutableArray alloc] init];
    
    hb_codepoint_t codepoint;
    while ( hb_set_next (codepoints, &codepoint) ) {
        [unicodes addObject:[NSNumber numberWithInteger:codepoint]];
    }
    
    return unicodes;
}

@end

