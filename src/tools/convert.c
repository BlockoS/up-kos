#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <float.h>

#define STB_IMAGE_IMPLEMENTATION
#include "stb_image.h"

#define STB_IMAGE_WRITE_IMPLEMENTATION
#include "stb_image_write.h"

typedef struct {
	int width;
	int height;
	uint8_t *data;
} image_t;

void usage() {
	printf("convert image out\n");
}

void write_binary(image_t* text, const char* prefix) {
    char buffer[128];
	sprintf(buffer, "%s.bin", prefix);

	FILE *out = fopen(buffer, "wb");
	fwrite(text->data, 1, text->width*text->height, out);
	fclose(out);
	
    printf(
        "%s_width = %d\n"
        "%s_height = %d\n"
        "%s:\n"
        "incbin(\"%s\")\n",
        prefix, text->width, 
        prefix, text->height,
        prefix, buffer);
}

// computes the dissimilarity index between two blocks
float compute_dssim(const uint8_t *data_0, int stride_0, const uint8_t *data_1, int stride_1, int w, int h, uint8_t mask) {
    float m0 = 0.f, m1  = 0.f, v0 = 0.f, v1 = 0.f;
    float cov = 0.f;        
    float k1 = 0.01f*0.01f, k2 = 0.03f*0.03f;
    float n = w * h;
    int x, y;
    for(y=0; y<h; y++) {
        for(x=0; x<w; x++) {
            m0 += data_0[x + y*stride_0] / 255.f;
            m1 += (data_1[x + y*stride_1] ^ mask) / 255.f;
        }
    }
    m0 /= n;
    m1 /= n;

    for(y=0; y<h; y++) {
        for(x=0; x<w; x++) {
            float d0 = data_0[x + y*stride_0]/255.f - m0;
            float d1 = (data_1[x + y*stride_1]^mask)/255.f - m1;
            v0 += d0*d0;
            v1 += d1*d1;
            cov += d0 * d1;
        }
    }
    v0  /= n;
    v1  /= n;
    cov /= n;
    
    float ssim = (2.f*m0*m1 + k1) * (2.f*cov + k2) / ((m0*m0 + m1*m1 + k1) * (v0*v0 + v1*v1 + k2));
    return (1.f - ssim) / 2.f;
}

// find the char which line is the closest match
int find_char(image_t* charset, int line, int page, int flip_color, uint8_t* src) {
    int chr = -1;
    int x, y;
    
    int y0 = page * charset->height/2;
    int y1 = y0 + charset->height/2;
    uint8_t mask = flip_color ? 0xff : 0x00;
    
    float last = FLT_MAX;
    int best = -1;
    
    for(y=y0; (y<y1) && (chr < 0); y+=8) {
        uint8_t *chr_ptr = &charset->data[(y+line)*charset->width];
        
        for(x=0; (x<8) && (src[x] == (chr_ptr[x] ^ mask)); x++) {
        }
        if(x >= 8) {
            chr = y/8;
        }
        else {
            // compute dssim on a single line of 8 pixels
            float dssim = compute_dssim(src, 0, chr_ptr, 0, 8, 1, mask);
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


int create_bitmaps(image_t *source, image_t *bitmap, image_t *color, image_t *error) {
    int x, y;
    int i, j;
    
    int ret = 1;
    
    bitmap->width = source->width;
    bitmap->height = source->height;
    bitmap->data = (uint8_t*)malloc(bitmap->width * bitmap->height);    
    memset(bitmap->data, 0x00, bitmap->width * bitmap->height);

    color->width = source->width / 8;
    color->height = source->height / 8;
    color->data = (uint8_t*)malloc(color->width * color->height);
    memset(color->data, 0x00, color->width * color->height);
    
    error->width = source->width;
    error->height = source->height;
    error->data = (uint8_t*)malloc(error->width * error->height * 3);    
    memset(error->data, 0x00, error->width * error->height * 3);
    
    for(y=0; y<color->height; y++) {
        for(x=0; x<color->width; x++) {
            int k = 0;
            uint8_t current[2];
            current[0] = current[1] = 0;
            for(j=0; j<8; j++) {
                for(i=0; i<8; i++) {
                    int offset = 8*x + i + ((8*y + j) * source->width);
                    uint8_t r = source->data[3*offset  ] ? 2 : 0;
                    uint8_t g = source->data[3*offset+1] ? 4 : 0;
                    uint8_t b = source->data[3*offset+2] ? 1 : 0;
                    uint8_t c = r | g | b;
                    int l;

                    for(l=0; l<k; l++) {
                        if(current[l] == c) {
                            break;
                        }
                    }
                    if(l >= k) {
                        if(k < 2) {
                            current[k++] = c;
                        }
                        else {
                            error->data[3*offset] = 0xff;
                            ret = 0;
                        }
                    }                    
                    bitmap->data[offset] = l ? 0xff : 0x00;
                }
            }
            color->data[x+(y*color->width)] = current[0] | (current[1] << 4);
        }
    }
    
    return ret;
}


int main(int argc, char **argv) {
	image_t charset;
	image_t source;
	image_t bitmap;
	image_t attribute;
	image_t final;
    image_t error;
    uint8_t *out;
    
	int i, j, k, l;
	int x, y;
	
	char str[128];
	
	if(argc != 3) {
		usage();
		return EXIT_FAILURE;
	}

	source.data = (uint8_t*)stbi_load(argv[1], &source.width, &source.height, NULL, STBI_rgb);
	if((source.width & 7) || (source.height & 7)) {
	    fprintf(stderr, "input image dimension must be a multiple of 8\n");
    	stbi_image_free(source.data);
        return EXIT_FAILURE;
	}
	
	charset.data = (uint8_t*)stbi_load("charset.pgm", &charset.width, &charset.height, NULL, STBI_grey);
	
    create_bitmaps(&source, &bitmap, &attribute, &error);
	
    sprintf(str, "%s_bitmap.png", argv[2]);	
    stbi_write_png(str, bitmap.width, bitmap.height, 1, bitmap.data, 0);

    sprintf(str, "%s_error.png", argv[2]);	
    stbi_write_png(str, error.width, error.height, 3, error.data, 0);
    free(error.data);

	out = (uint8_t*)malloc(source.width*source.height*3);
	
	final.width = source.width / 8;
	final.height = source.height;
	final.data = (uint8_t*)malloc(final.width * final.height);
    
    uint8_t block[4][8*8];
    int text[4][8];
    
    for(y=0; y<attribute.height; y++) {
        for(x=0; x<attribute.width; x++) {
            uint8_t *line = &bitmap.data[8 * (x + y*bitmap.width)];
            uint8_t c = attribute.data[x+y*attribute.width];
            int best_k = 0;
            float best_score = FLT_MAX;
            for(int k=0; k<4; k++) {
                uint8_t page = (k >> 1) & 1;
                uint8_t swap = k & 1;
                for(j=0; j<8; j++) {
                    text[k][j] = find_char(&charset, j, page, swap, line + (j*bitmap.width));
                    uint8_t *ptr = charset.data + (text[k][j]*8 + j) * charset.width;
                    for(i=0; i<8; i++) {
                        block[k][i + j*8] = *ptr++ ^ (swap ? 255 : 0);
                    }
                }
                
                float dssim = compute_dssim(line, bitmap.width, block[k], 8, 8, 8, 0);
                if(dssim < best_score) {
                    best_score = dssim;
                    best_k = k;
                }
            }
            
            c = attribute.data[x + y*attribute.width];
            uint8_t rgb[2][3];
            rgb[0][0] = (c & 0x02) ? 0xff : 0x00; 
            rgb[0][1] = (c & 0x04) ? 0xff : 0x00; 
            rgb[0][2] = (c & 0x01) ? 0xff : 0x00; 
            
            rgb[1][0] = (c & 0x20) ? 0xff : 0x00; 
            rgb[1][1] = (c & 0x40) ? 0xff : 0x00; 
            rgb[1][2] = (c & 0x10) ? 0xff : 0x00; 
            
            for(j=0; j<8; j++) {
                for(i=0; i<8; i++) {
                    k = 8*x+i + (8*y+j) * source.width;
                    l = block[best_k][i + j*8] ? 0x01 : 0x00;
                    out[3*k  ] = rgb[l][0];
                    out[3*k+1] = rgb[l][1];
                    out[3*k+2] = rgb[l][2];
                }
            }

            if(best_k & 1) {
                c = (c >> 4) | (c << 4);
            }
            if(best_k & 2) {
                c |= 0x80;
            }
            attribute.data[x + y*attribute.width] = c;
            for(j=0; j<8; j++) {
                final.data[x + (y*8+j)*final.width] = text[best_k][j];
            }
        }
    }
    
    sprintf(str, "%s_out.png", argv[2]);
    stbi_write_png(str, source.width, source.height, 3, out, 0);

	sprintf(str, "%s_txt", argv[2]);
    write_binary(&final, str);

	sprintf(str, "%s_att", argv[2]);
    write_binary(&attribute, str);

	stbi_image_free(charset.data);
	stbi_image_free(source.data);
	free(out);
	free(attribute.data);
	free(final.data);
    free(bitmap.data);
	return EXIT_SUCCESS;
}
