#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>
#include <math.h>

#define STB_IMAGE_IMPLEMENTATION
#include "stb_image.h"

int main(int argc, char **argv) {
    FILE *out;
    int x, y;

    int width = 32;
    int height = 25;

    if(argc != 3) {
        fprintf(stderr, "usage: bump_tables image out\n");
        return EXIT_FAILURE;
    }

    uint8_t *in;
    int8_t *normal;
    
    in = (uint8_t*)stbi_load(argv[1], &width, &height, NULL, STBI_grey);    
    normal = (int8_t*)malloc(width*height*2);

    memset(normal, 0, 2*width*height);
    for(y=1; y<(height-1); y++) {
        for(x=1; x<(width-1); x++) {
            int offset = (x + y*width);
            normal[2*offset    ] = (in[offset+1    ] - in[offset-1    ]) / 2;
            normal[2*offset + 1] = (in[offset+width] - in[offset-width]) / 2;
        }
    }

    out = fopen(argv[2], "wb");
    fwrite(normal, 1, 2*width*height, out);
    fclose(out);
    
    stbi_image_free(in);
    free(normal);

    return EXIT_SUCCESS;
}
