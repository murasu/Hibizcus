//
//  hb_tracer.h
//
//  Created by Muthu Nedumaran on 24/2/21.
//

#ifndef hb_tracer_h
#define hb_tracer_h

typedef void(*callback_t)(const char *);
void set_callback(callback_t _callback);
void start_trace_with_callback(const char* fontfile, const char* text, const char *script, const char *language, const char *trace_id);

#endif /* hb_tracer_h */
