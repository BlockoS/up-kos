#include <math.h>
#include <values.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

#define VRAM_WIDTH 40
#define VRAM_HEIGHT 25

#define FRAME_COUNT 64

#define TEX_WIDTH 8
#define TEX_HEIGHT 8

uint8_t sqrt_tab_0[VRAM_WIDTH * VRAM_HEIGHT];
uint8_t sqrt_tab_1[VRAM_WIDTH * VRAM_HEIGHT];

int8_t angle_tab_0[VRAM_WIDTH * VRAM_HEIGHT];
int8_t angle_tab_1[VRAM_WIDTH * VRAM_HEIGHT];

void init_sqrt() {
    int i, j;
    float x, y, z, theta;
    float tmin =  FLT_MAX;
    float tmax = -FLT_MAX;
    for(j=0; j<VRAM_HEIGHT; j++) {
        for(i=0; i<VRAM_WIDTH; i++) {
            x = VRAM_WIDTH/2.f - i;
            y = 2.f*j - 2.f*VRAM_HEIGHT/2.f;
            z = 8.f * TEX_HEIGHT * 2.f / sqrt(x*x + y*y);
            theta = 2.f * TEX_WIDTH * (atan2(y,x) / M_PI);
            sqrt_tab_0[i + (j*VRAM_WIDTH)] = z*2.f;
            angle_tab_0[i + (j*VRAM_WIDTH)] = theta*8.f;
            
            if(tmin > theta) tmin = theta;
            if(tmax < theta) tmax = theta;
            
            y = 2.f*j+1 - 2.f*VRAM_HEIGHT/2.f;
            z = 8.f * TEX_HEIGHT * 2.f / sqrt(x*x + y*y);
            theta = 2.f * TEX_WIDTH * (atan2(y,x) / M_PI);
            sqrt_tab_1[i + (j*VRAM_WIDTH)] = z*2.f;
            angle_tab_1[i + (j*VRAM_WIDTH)] = theta*8.f;
        }
    }
}

int main(int argc, char **argv) {
    char filename[256];

    if(argc != 2) {
        fprintf(stderr, "usage: tunnel out_dir\n");
        return EXIT_FAILURE;
    }

    init_sqrt();

    FILE *out;
    
    snprintf(filename, 256, "%s/sqrt_tab_0.bin", argv[1]);
    out = fopen(filename, "wb");
    fwrite(sqrt_tab_0, 1, VRAM_WIDTH * VRAM_HEIGHT, out);
    fclose(out);

    snprintf(filename, 256, "%s/sqrt_tab_1.bin", argv[1]);
    out = fopen(filename, "wb");
    fwrite(sqrt_tab_1, 1, VRAM_WIDTH * VRAM_HEIGHT, out);
    fclose(out);

    snprintf(filename, 256, "%s/angle_tab_0.bin", argv[1]);
    out = fopen(filename, "wb");
    fwrite(angle_tab_0, 1, VRAM_WIDTH * VRAM_HEIGHT, out);
    fclose(out);

    snprintf(filename, 256, "%s/angle_tab_1.bin", argv[1]);
    out = fopen(filename, "wb");
    fwrite(angle_tab_1, 1, VRAM_WIDTH * VRAM_HEIGHT, out);
    fclose(out);

    return EXIT_SUCCESS;
}
