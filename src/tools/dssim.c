#include "dssim.h"

// computes the dissimilarity index between two blocks
float compute_dssim(const uint8_t *data_0, int stride_0, const uint8_t *data_1, int stride_1, int w, int h, uint8_t mask) {
    static const float k1 = 0.01f*0.01f;
    static const float k2 = 0.03f*0.03f;
    float m0 = 0.f, m1  = 0.f, v0 = 0.f, v1 = 0.f;
    float cov = 0.f;        
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
