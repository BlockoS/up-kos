#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

#define STB_IMAGE_IMPLEMENTATION
#include "stb_image.h"

#define STB_IMAGE_WRITE_IMPLEMENTATION
#include "stb_image_write.h"

#include "charset.h"

#define SIZE   23
#define SRC_HEIGHT 32
#define SRC_WIDTH (8*2*4)
#define WIDTH  256
#define HEIGHT 240
#define COL_COUNT 6

void draw_face(float x0, float z0, float u0,
               float x1, float z1, float u1,
               float *zbuffer, uint8_t *out) {
    int x;
    int xa;
    int xb;

    float z;
    float za;
    float zb;
    float dz;

    float ua;
    float ub;

    if(x0 < x1){
        xa = x0; xb = x1;
        za = z0; zb = z1;
        ua = u0; ub = u1; 
    }
    else{
        xa = x1; xb = x0;
        za = z1; zb = z0;
        ua = u1; ub = u0;
    }
   
    za = (SIZE+za) / (2.0*SIZE);
    zb = (SIZE+zb) / (2.0*SIZE);

    dz = (zb - za) / ((float)(xb - xa));
    
    xa += SRC_WIDTH/2;
    xb += SRC_WIDTH/2;
   
    for(x=xa, z=za; x<xb; x++, z+=dz) {
        if(z < zbuffer[x]) {
            float xx0 = (SIZE+xa) / (2.0*SIZE);
            float xx1 = (SIZE+xb) / (2.0*SIZE);
            float zz0 = (SIZE+za) / (2.0*SIZE);
            float zz1 = (SIZE+zb) / (2.0*SIZE);

            double a = (float)((SIZE+x) / (2.0*SIZE) -xx0) / ((float)(xx1-xx0));
            double s = ((1-a) * (ua/zz0) + a * (ub/zz1)) 
                    / ((1-a) / zz0 + a / zz1);
            if(ua > ub) {
                if(s >= ua) { s = ua-1.0; }
                else if(s < ub) { s = ub; }
            }
            if(ub > ua)
            {
                if(s >= ub) { s = ub-1.0; }
                else if(s < ua) { s = ua; }
            }
            
            int m = (int)(1+s);
            out[x] = (m & 1) * 255; 
            zbuffer[x] = z;
        }
    }
}

uint8_t* generate_pattern(int width, int height) {
    int x, y;
    float *zbuffer = (float*)malloc(width*height*sizeof(float));
    uint8_t *source = (uint8_t*)malloc(width*height);
    memset(source, 0, width*height);
    for(x=0; x<(width*height); x++) {
        zbuffer[x] = 32768;
    }
    for(y=0; y<height; y++) {
        float theta = M_PI * y / (2. * (float)height);

        float cs = cos(theta);
        float sn = sin(theta);

        float x0 = (cs + sn) * SIZE;
        float z0 = (cs - sn) * SIZE;
        
        float x1 =  z0;
        float z1 = -x0;

        float x2 = -x0;
        float z2 = -z0;
        
        float x3 = -z0;
        float z3 =  x0;

        draw_face(x0, z0, 0.0, x1, z1, 3.0, 
                  zbuffer+(y*width), source+(y*width));
        draw_face(x1, z1, 0.0, x2, z2, 3.0,
                  zbuffer+(y*width), source+(y*width));
        draw_face(x2, z2, 0.0, x3, z3, 3.0, 
                  zbuffer+(y*width), source+(y*width));
        draw_face(x3, z3, 0.0, x0, z0, 3.0,
                  zbuffer+(y*width), source+(y*width));
    }
    free(zbuffer);
    return source;
}

void build_mz_patterns(image_t out[8], charset_t *set, uint8_t *source, int width, int height, int flip, int page) {
    int i, j;
    int x, y;
    for(j=0; j<8; j++) {
        out[j].height = height;
        out[j].width = width/8;
        out[j].data = (uint8_t*)malloc(out[j].width * out[j].height);
        
        for(y=0; y<height; y++) {
            for(x=0, i=0; x<width; x+=8, i++) {
                uint8_t chr = charset_find(set, &source[x+(y*width)], j, flip, page);
                out[j].data[i + (y*out[j].width)] = chr;
            }
        }
    }
}

void reconstruct(image_t *txt, charset_t *set, image_t *out, int line, int flip, int page) {
    int i;
    int x, y;
    uint8_t mask = flip ? 0xff : 0x00;
    if((out->height != txt->height) && (out->width != (txt->width*8))) {
        if(out->data) {
            free(out->data);
        }
        out->height = txt->height;
        out->width = txt->width * 8;
        out->data = (uint8_t*)malloc(out->height * (out->width * 8));
    }

    uint8_t *dst = out->data;
    uint8_t *chr = txt->data;
    for(y=0; y<txt->height; y++) {
        for(x=0; x<txt->width; x++) {
            unsigned int offset = (*chr++ + (page * set->char_per_page)) * 8; 
            uint8_t *src = &set->font.data[(offset+line) * set->font.width];
            for(i=0; i<8; i++) {
                *dst++ = (*src++) ^ mask;
            }
        }
    }
}

int main() {
    char filename[64];
    int i, j;
    int x;
    uint8_t *source;
    
    int8_t  cosTable[256];

    charset_t set;
    image_t pattern[8];
    image_t tmp[8];
    
    if(!charset_load(&set, "charset.pgm", 2)) {
        return EXIT_FAILURE;
    }
    
    source = generate_pattern(SRC_WIDTH, SRC_HEIGHT);

    for(i=0; i<8; i++) {
        memset(&pattern[i], 0, sizeof(image_t));
        memset(&tmp[i], 0, sizeof(image_t));
    }

    build_mz_patterns(pattern, &set, source, SRC_WIDTH, SRC_HEIGHT, 0, 1);
    for(j=0; j<8; j++) {   
        snprintf(filename, 64, "data/pattern%02d.bin", j);
        FILE *stream = fopen(filename, "wb");
        fwrite(pattern[j].data, 1, pattern[j].width*pattern[j].height, stream);
        fclose(stream);
    }

    for(x=0; x<256; x++) {
        cosTable[x] = 255. * (0.5 + 0.5*cos(2.0*M_PI*x/256.0));
        //128. * (0.5 + 0.5*cos(2.0*M_PI*x/256.0)) / 4.;
    }
    {
       FILE *stream = fopen("data/cos.bin", "wb");
        fwrite(cosTable, 1, 256, stream);
        fclose(stream);
    }

    charset_delete(&set);
    free(source);
    for(i=0; i<8; i++) {
        free(pattern[i].data);
        free(tmp[i].data);	
    }
    return EXIT_SUCCESS;
}
