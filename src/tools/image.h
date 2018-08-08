#ifndef IMAGE_H
#define IMAGE_H

#include <stdint.h>

typedef struct {
	int width;
	int height;
	uint8_t *data;
} image_t;

#endif // IMAGE_H