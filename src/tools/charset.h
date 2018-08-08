#ifndef CHARSET_H
#define CHARSET_H

#include "image.h"

typedef struct {
    image_t font;
    int total_count;
    int page_count;
    int char_per_page;
} charset_t;

int charset_load(charset_t *set, const char* filename, int page_count);
void charset_delete(charset_t *set);
uint8_t charset_find(charset_t *set, uint8_t *in, int line, uint8_t flip, int page);

#endif // CHARSET_H