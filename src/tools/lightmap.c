#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>
#include <math.h>

#define STB_IMAGE_IMPLEMENTATION
#include "stb_image.h"

int main(int argc, char **argv) {
    FILE *out;

    char filename[256];
    
    int8_t light_x[64];
    int8_t light_y[64];
    int x, y;
    int i;

    int frames = 64;

    int width = 32;
    int height = 25;

    int light_w = 32;
    int light_h = 32;
    uint8_t light_map[32*32];

    if(argc != 2) {
        fprintf(stderr, "usage: lightmap out_dir\n");
        return EXIT_FAILURE;
    }

    for(i=0; i<64; i++) {
        float theta = i * 2.0 * M_PI / (float)frames;
        light_x[i] = (32-width)/2  + 16. * sin(theta);
        light_y[i] = (32-height)/2 + 16. * sin(theta) * cos(theta);
    }

    i = ((light_w < light_h) ? light_w : light_h) / 2;
    for(y=0; y<light_h; y++) {
        int dy = light_h/2 - y;
        dy *= dy;
        for(x=0; x<light_w; x++) {
            int dx = light_w/2 - x;
            dx *= dx;
            int l = sqrt(dx + dy);
            if(l > i) { l = i; }
            int c = (9 * (i-l)) / i;
            if(c > 8) { c = 8; }
            light_map[x+y*light_w] = c;
        }
    }
    
    snprintf(filename, 256, "%s/light_x.bin", argv[1]);
    out = fopen(filename, "wb");
    fwrite(light_x, 1, frames, out);
    fclose(out);

    snprintf(filename, 256, "%s/light_y.bin", argv[1]);
    out = fopen(filename, "wb");
    fwrite(light_y, 1, frames, out);
    fclose(out);

    snprintf(filename, 256, "%s/light_map.bin", argv[1]);
    out = fopen(filename, "wb");
    fwrite(light_map, 1, light_w*light_h, out);
    fclose(out);

    return EXIT_SUCCESS;
}
