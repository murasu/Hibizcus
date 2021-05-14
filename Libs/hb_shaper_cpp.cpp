//
//  hb_shaper_cpp.cpp
//
//  Created by Muthu Nedumaran on 16/2/21.
//

#include <sstream>
// Silence documentation warnings
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdocumentation"
#include "hb_shaper_cpp.h"
#include <hb-ot.h>
#pragma clang diagnostic pop

string hb_shaper_cpp::get_hb_version() {
    uint major = 0;
    uint minor = 0;
    uint micro = 0;
    hb_version(&major, &minor, &micro);
    std::ostringstream vss;
    vss << "Version: " << major << "." << minor << "." << micro;
    return vss.str();
}

void hb_shaper_cpp::init_with_font_file(string font_file) {
    font_file = font_file;
    
    // Create a face and a font from a font file.
    blob = hb_blob_create_from_file(font_file.c_str());
    face = hb_face_create(blob, 0);
    font = hb_font_create(face);
}

string hb_shaper_cpp::get_font_display_name() {
    if ( font == nullptr ) {
        return "";
    }
    return get_name_entry(HB_OT_NAME_ID_FULL_NAME);
}

string hb_shaper_cpp::get_font_version() {
    if ( font == nullptr ) {
        return "";
    }
    return get_name_entry(HB_OT_NAME_ID_VERSION_STRING);
}

string hb_shaper_cpp::get_name_entry(unsigned int hb_ot_name_id_t) {

    unsigned int text_size = 100;
    char text[text_size];
    auto size = hb_ot_name_get_utf8 (face, hb_ot_name_id_t, HB_LANGUAGE_INVALID, &text_size, text);
    if ( size > 0 ) {
        return string(text);
    }
    
    return "";
}

void hb_shaper_cpp::clean_up() {
    hb_font_destroy(font);
    hb_face_destroy(face);
    hb_blob_destroy(blob);
}

hb_font_metrics * hb_shaper_cpp::get_font_metrics() {
    if ( font == nullptr ) {
        return nullptr;
    }
    
    hb_font_metrics *m = new hb_font_metrics();
    
    // UPEM
    m->upem = hb_face_get_upem (face);
    
    // baseline
    m->baseline = 0;
    // xheight
    hb_ot_metrics_get_position (font, HB_OT_METRICS_TAG_X_HEIGHT, &m->xheight);
    // capheight
    hb_ot_metrics_get_position (font, HB_OT_METRICS_TAG_CAP_HEIGHT, &m->capheight);
    // ascender
    hb_ot_metrics_get_position (font, HB_OT_METRICS_TAG_HORIZONTAL_ASCENDER, &m->ascender);
    // descender
    hb_ot_metrics_get_position (font, HB_OT_METRICS_TAG_HORIZONTAL_DESCENDER, &m->descender);
    // underline_pos
    hb_ot_metrics_get_position (font, HB_OT_METRICS_TAG_UNDERLINE_OFFSET, &m->underline_pos);
    // underline_thickness
    hb_ot_metrics_get_position (font, HB_OT_METRICS_TAG_UNDERLINE_SIZE, &m->underline_thickness);
    
    return m;
}

string hb_shaper_cpp::shape_text(std::string text, std::string language) {
    string out_string = "[";
    
    hb_buffer_t *buf;
    buf = hb_buffer_create();
    hb_buffer_add_utf8(buf, text.c_str(), -1, 0, -1);
    
    // Copied from hb-shape command line.
    // hb_direction_from_string is returning invalid. We hard-code it as LTR for now
    hb_buffer_set_direction(buf, HB_DIRECTION_LTR);
    //hb_buffer_set_script (buf, hb_script_from_string ("deva", -1));
    
    if ( language.length() > 0 ) {
        auto lang = hb_language_from_string (language.c_str(), -1);
        hb_buffer_set_language(buf, lang);
    }
    
    hb_buffer_guess_segment_properties(buf);
    
    // Shape
    hb_shape(font, buf, NULL, 0);
    
    // Get the glyph and position information.
    unsigned int glyph_count;
    hb_glyph_info_t *glyph_info    = hb_buffer_get_glyph_infos(buf, &glyph_count);
    hb_glyph_position_t *glyph_pos = hb_buffer_get_glyph_positions(buf, &glyph_count);
    
    // Iterate over each glyph.
    hb_position_t cursor_x = 0;
    hb_position_t cursor_y = 0;
    char glyph_name[100];
    hb_glyph_extents_t extents;
    for (unsigned int i = 0; i < glyph_count; i++) {
        hb_codepoint_t glyphid  = glyph_info[i].codepoint;          // Glyph ID
        hb_font_get_glyph_name(font, glyphid, &glyph_name[0], 100); // Glyph Name
        hb_font_get_glyph_extents(font, glyphid, &extents);         // Bounding Box
        
        // If we can't get a glyph name, construct one with the glyph id
        if ( strlen(glyph_name) == 0 ) {
            sprintf(glyph_name, "gid%d", glyphid);
        }
        
        hb_position_t x_offset  = glyph_pos[i].x_offset;
        hb_position_t y_offset  = glyph_pos[i].y_offset;
        hb_position_t x_advance = glyph_pos[i].x_advance;
        hb_position_t y_advance = glyph_pos[i].y_advance;
        // draw_glyph(glyphid, cursor_x + x_offset, cursor_y + y_offset); */
        
        if (out_string.length() > 1) {
            out_string += ",";
        }
        std::ostringstream job;
        job << "{\"g\":\"" << glyph_name << "\",\"dx\":" << x_offset << ",\"dy\":" << y_offset << ",\"ax\":" << x_advance << ",\"ay\":" << y_advance << "}";
        out_string += job.str();
        
        cursor_x += x_advance;
        cursor_y += y_advance;
    }
    
    out_string += "]";
    
    // Tidy up.
    hb_buffer_destroy(buf);
    
    return out_string;
}


hb_set_t * hb_shaper_cpp::collect_unicodes()
{
    hb_set_t *unicodes = hb_set_create();
    hb_face_collect_unicodes(face, unicodes);
    
    return unicodes;
}
