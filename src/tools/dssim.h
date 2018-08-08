#ifndef DSSIM_H
#define DSSIM_H

#include <stdint.h>

// computes the dissimilarity index between two blocks
float compute_dssim(const uint8_t *data_0, int stride_0, const uint8_t *data_1, int stride_1, int w, int h, uint8_t mask);

#endif // DSSIM_H