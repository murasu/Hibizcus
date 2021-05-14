//
//  hb_tracer.c
//
//  Created by Muthu Nedumaran on 24/2/21.
//

#include "hb_tracer.h"
#include <stdio.h>
#include <pthread.h>
#include <string.h>
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdocumentation"
#include <hb-ot.h>
#pragma clang diagnostic pop

callback_t trace_callback; // Callback is a global variable
hb_bool_t message_func (hb_buffer_t *buffer,hb_font_t *font, const char *message, void *user_data);
void *post_log(void *log_message);

void set_callback(callback_t _callback) {
    trace_callback = _callback;
}

void start_trace_with_callback(const char* font_file, const char* text, const char *script, const char *language, const char *trace_id)
{
    // Create a face and a font from a font file.
    hb_blob_t *blob = hb_blob_create_from_file(font_file);
    hb_face_t *face = hb_face_create(blob, 0);
    hb_font_t *font = hb_font_create(face);
    
    hb_buffer_t *buf;
    buf = hb_buffer_create();
    hb_buffer_add_utf8(buf, text, -1, 0, -1);
    
    // Set the language, if the parameter was passed
    if ( strlen(language) > 0 ) {
        hb_buffer_set_language(buf, hb_language_from_string(language, -1));
    }
        
    hb_buffer_guess_segment_properties(buf);
    
    // Get the callbacks
    hb_buffer_set_message_func(buf, message_func, (void *) trace_id, NULL);
    
    // Shape
    hb_shape(font, buf, NULL, 0);
    
    // Call the message func with the final output
    message_func(buf, font, "final output", (void *) trace_id);
    
    // Tidy up.
    hb_buffer_destroy(buf);
}


hb_bool_t message_func (hb_buffer_t *buffer,
      hb_font_t *font,
      const char *message,
      void *user_data)
{
    unsigned int num_glyphs = hb_buffer_get_length (buffer);
    //printf("Received : %s Glyph count: %d\n", message, num_glyphs);
    printf("Received : user_data: %s\n", (char *)user_data);
    
    unsigned int start = 0;
    
    while (start < num_glyphs)
    {
        char buf[32768];
        char callback_msg[33000];
        unsigned int consumed;
        
        // HB_BUFFER_SERIALIZE_FLAG_NO_GLYPH_NAMES will get us the glyph ids instead of glyph names.
        /*start += */hb_buffer_serialize (buffer, start, num_glyphs,
                                      buf, sizeof (buf), &consumed,
                                      font, HB_BUFFER_SERIALIZE_FORMAT_JSON, HB_BUFFER_SERIALIZE_FLAG_DEFAULT | HB_BUFFER_SERIALIZE_FLAG_GLYPH_EXTENTS | HB_BUFFER_SERIALIZE_FLAG_GLYPH_FLAGS | HB_BUFFER_SERIALIZE_FLAG_NO_GLYPH_NAMES);
        
        // consumed will have the number of bytes writted to buf. If none, we don't have any data
        if (!consumed) {
            break;
        }
        
        sprintf(callback_msg, "%s|%s %s\n", (char *)user_data, message, buf);
        
        // Without HB_BUFFER_SERIALIZE_FLAG_NO_GLYPH_NAMES will we get glyph names. We can omit the rest.
        start += hb_buffer_serialize (buffer, start, num_glyphs,
                                      buf, sizeof (buf), &consumed,
                                      font, HB_BUFFER_SERIALIZE_FORMAT_JSON, HB_BUFFER_SERIALIZE_FLAG_NO_ADVANCES | HB_BUFFER_SERIALIZE_FLAG_NO_CLUSTERS |
                                      HB_BUFFER_SERIALIZE_FLAG_NO_POSITIONS);
        
        if (!consumed) {
            break;
        }
        
        // append the glyph names to the callback_msg
        strcat(callback_msg, buf);
                
        if (trace_callback) {
            trace_callback((const char *)callback_msg);
        }
    }
    
    return 1;
}
