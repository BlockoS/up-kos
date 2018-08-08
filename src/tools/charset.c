#include "charset.h"

#include <stdio.h>
#include <string.h>
#include <math.h>
#include <float.h>

#include "stb_image.h"
#include "dssim.h"

int charset_load(charset_t *set, const char* filename, int page_count) {
	set->font.data = (uint8_t*)stbi_load(filename, &set->font.width, &set->font.height, NULL, STBI_grey);    
    if(set->font.data == NULL) {
        fprintf(stderr, "failed to load %s", filename);
        return 0;
    }
    if(set->font.width != 8) {
        fprintf(stderr, "invalid image size (%d,%d). Expected (8,8*char_count).", set->font.width, set->font.height);
        charset_delete(set);
        return 0;
    }
    set->page_count = page_count;
    set->total_count = set->font.height / 8;
    set->char_per_page = set->total_count / page_count;
    return 1;
}

void charset_delete(charset_t *set) {
    if(set->font.data) {
        stbi_image_free(set->font.data);
    }
    memset(set, 0, sizeof(charset_t));
}

uint8_t charset_find(charset_t *set, uint8_t *in, int line, uint8_t flip, int page) {
    int chr = -1;
    int x, y;
    
    int y0 = page * set->char_per_page * 8;
    int y1 = y0 + set->char_per_page * 8;
    uint8_t mask = flip ? 0xff : 0x00;
    
    float last = FLT_MAX;
    int best = -1;
    
    for(y=y0; (y<y1) && (chr < 0); y+=8) {
        uint8_t *chr_ptr = &set->font.data[(y+line)*set->font.width];
        
        for(x=0; (x<8) && (in[x] == (chr_ptr[x] ^ mask)); x++) {
        }
        if(x >= 8) {
            chr = y/8;
        }
        else {
            // compute dssim on a single line of 8 pixels
            float dssim = compute_dssim(in, 0, chr_ptr, 0, 8, 1, mask);
            if(dssim < last) {
                last = dssim;
                best = y/8;
            }
        }
    }
    if(chr < 0) {
        return best;
    }
    return chr;
}
