#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

int main(int argc, char **argv) {
	if(argc != 3) {
		fprintf(stderr, "usage: cgedit2border input.txt output.bin\n");
		return EXIT_FAILURE;
	}

	int width = 40;
	int height = 25;
	int i, j;
	unsigned int c;
	uint8_t *attr;
	uint8_t *color;

	attr = (uint8_t*)malloc(width*height);
	color = (uint8_t*) malloc(width*height);
	
	FILE *input = fopen(argv[1], "rb");
	for(j=height-1; j>=0; j--) {
	    for(i=0; i<width; i++) {
		    fscanf(input,"%d,", &c);
		    attr[i+(j*width)] = c & 0xff;	
		    color[i+(j*width)] = (c > 255) ? 0x80 : 0x00;
	    }
    }
	for(j=height-1; j>=0; j--) {
	    for(i=0; i<width; i++) {
		    fscanf(input,"%d,", &c);
		    color[i+(j*width)] |= (c&0x07)<<4;
	    }
    }
	for(j=height-1; j>=0; j--) {
	    for(i=0; i<width; i++) {
		    fscanf(input,"%d,", &c);
		    color[i+(j*width)] |= (c&0x07);
	    }
    }
	fclose(input);

	FILE *output = fopen(argv[2], "wb");

    int offset;
    offset = 0;
    for(int j=0; j<height; j++) {
        fwrite(color + offset + 9, 1, 9, output);
        fwrite(color + offset, 1, 9, output);
        offset += 40;        
    }
    offset = 0;
    for(int j=0; j<height; j++) {
        fwrite(attr + offset + 9, 1, 9, output);
        fwrite(attr + offset, 1, 9, output);
        offset += 40;        
    }

	fclose(output);

	free(color);
	free(attr);	
	return EXIT_SUCCESS;
}
