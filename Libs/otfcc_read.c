//
//  otfcc_read.cpp
//
//  Created by Muthu Nedumaran on 23/2/21.
//

//  Taken from otfccdump

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdocumentation"
#include "otfcc_read.h"
#include "dep/json-builder.h"
#include "otfcc/sfnt.h"
#include "otfcc/font.h"
#pragma clang diagnostic pop

char *get_data_as_json_from_font_file(const char* inPath)
{
    printf("==> get_data_as_json_from_font_file \"%s\"\n", inPath);
    
    // TODO: ttcindex probably points to the index of the ttc file - revisit this when we test TTCs
    uint32_t ttcindex = 0;
    
    // TODO: figure out what else I can do with the options
    otfcc_Options *options = otfcc_newOptions();
    options->logger = otfcc_newLogger(otfcc_newStdErrTarget());
    options->logger->indent(options->logger, "otfccdump");
    options->decimal_cmap = true;
    
    otfcc_SplineFontContainer *sfnt;
    
    FILE *file = fopen(inPath, "rb");
    sfnt = otfcc_readSFNT(file);
    if (!sfnt || sfnt->count == 0) {
        printf("Cannot read SFNT file \"%s\". Exit.\n", inPath);
        return "";
    }
    
    if (ttcindex >= sfnt->count) {
        printf("Subfont index %d out of range for \"%s\" (0 -- %d). Exit.\n", ttcindex,
               inPath, (sfnt->count - 1));
        return "";
    }
    
    otfcc_Font *font;
    otfcc_IFontBuilder *reader = otfcc_newOTFReader();
    font = reader->read(sfnt, ttcindex, options);
    if (!font) {
        printf("Font structure broken or corrupted \"%s\". Exit.\n", inPath);
        exit(EXIT_FAILURE);
    }
    reader->free(reader);
    if (sfnt) otfcc_deleteSFNT(sfnt);
    otfcc_iFont.consolidate(font, options);
    
    json_value *root;
    otfcc_IFontSerializer *dumper = otfcc_newJsonWriter();
    root = (json_value *)dumper->serialize(font, options);
    if (!root) {
        printf("Font structure broken or corrupted \"%s\". Exit.\n", inPath);
        exit(EXIT_FAILURE);
    }
    dumper->free(dumper);
    
    char *buf;
    size_t buflen;
    json_serialize_opts jsonOptions;
    jsonOptions.mode = json_serialize_mode_packed;
    jsonOptions.opts = 0;
    jsonOptions.indent_size = 4;
    buflen = json_measure_ex(root, jsonOptions);
    buf = (char *) calloc(1, buflen);
    json_serialize_ex(buf, root, jsonOptions);
    
    // TODO: Return only a requested table instead of the entire font in json
    
    return buf;
}
