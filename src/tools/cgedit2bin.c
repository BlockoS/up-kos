#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

int main(int argc, char **argv) {
	if(argc != 3) {
		fprintf(stderr, "usage: cgedit2bin input.txt output.bin\n");
		return EXIT_FAILURE;
	}

	int width = 40;
	int height = 25;
	int i;
	unsigned int c;
	uint8_t *attr;
	uint8_t *color;

	attr = (uint8_t*)malloc(width*height);
	color = (uint8_t*) malloc(width*height);
	
	FILE *input = fopen(argv[1], "rb");
	for(i=0; i<width*height; i++) {
		fscanf(input,"%d,", &c);
		attr[i] = c & 0xff;	
		color[i] = (c > 255) ? 0x80 : 0x00;
	}
	for(i=0; i<width*height; i++) {
		fscanf(input,"%d,", &c);
		color[i] |= (c&0x07)<<4;
	}	
	for(i=0; i<width*height; i++) {
		fscanf(input,"%d,", &c);
		color[i] |= (c&0x07);
	}	
	fclose(input);

	FILE *output = fopen(argv[2], "wb");
	fwrite(attr, 1, width*height, output);
	fwrite(color, 1, width*height, output);
	fclose(output);

	free(color);
	free(attr);	
	return EXIT_SUCCESS;
}