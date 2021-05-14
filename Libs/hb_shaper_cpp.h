//
//  hb_shaper_cpp.h
//
//  Created by Muthu Nedumaran on 16/2/21.
//

#ifndef hb_shaper_cpp_h
#define hb_shaper_cpp_h

#include <stdio.h>
#include <string>
#include <hb.h>

using namespace std;

struct hb_font_metrics {
    unsigned int upem;
    int32_t baseline;
    int32_t xheight;
    int32_t capheight;
    int32_t ascender;
    int32_t descender;
    int32_t underline_pos;
    int32_t underline_thickness;
};

class hb_shaper_cpp {
private:
    string font_file;
    string language;        // e.g: "ta"
    hb_script_t script;     // e.g: HB_SCRIPT_TAMIL
    hb_font_t *font;        // hb font object
    hb_blob_t *blob;
    hb_face_t *face;
    
    string get_name_entry(unsigned int hb_ot_name_id_t);
    
public:
    void init_with_font_file(string file);
    void clean_up();
    string get_hb_version();
    string get_font_display_name();
    string get_font_version();
    hb_font_metrics *get_font_metrics();
    string shape_text(std::string text, std::string language);
    hb_set_t * collect_unicodes();
};

#endif /* hb_shaper_cpp_h */
