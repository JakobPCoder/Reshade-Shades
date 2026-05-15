/*=============================================================================
    samplers
    Texture sampling and pyramid helpers for Shades shaders.
    Copyright, Jakob Wapenhensch
    License: CC BY-NC 4.0 (https://creativecommons.org/licenses/by-nc/4.0/)
    https://creativecommons.org/licenses/by-nc/4.0/legalcode
=============================================================================*/

#pragma once

#include "macros.fxh"


#define DOWNSAMPLE_GAUSS_FIXED(T, S) \
    float2 texel_size = rcp(tex2Dsize(smp, 0)); \
    float2 offset = texel_size * 0.75; \
    T result = 0; \
    result += tex2Dlod(smp, float4(texcoord + float2(-offset.x, -offset.y), 0.0, 0.0)).S; \
    result += tex2Dlod(smp, float4(texcoord + float2( offset.x, -offset.y), 0.0, 0.0)).S; \
    result += tex2Dlod(smp, float4(texcoord + float2(-offset.x,  offset.y), 0.0, 0.0)).S; \
    result += tex2Dlod(smp, float4(texcoord + float2( offset.x,  offset.y), 0.0, 0.0)).S; \
    return result * 0.25;

DEFINE_VARIANTS(downsample_gauss_fixed, (sampler smp, float2 texcoord), DOWNSAMPLE_GAUSS_FIXED)




#define SAMPLE_CATMULLROM(T, S) \
     \
    int2 tex_size = tex2Dsize(source, 0); \
    float2 pixel_coord = texcoord * tex_size; \
     \
    float2 tc = floor(pixel_coord - 0.5) + 0.5; \
     \
    float2 f = pixel_coord - tc; \
     \
    float2 f2 = f * f; \
    float2 f3 = f2 * f; \
     \
    float2 w0 = f2 - 0.5 * (f3 + f); \
    float2 w1 = 1.5 * f3 - 2.5 * f2 + 1.0; \
    float2 w3 = 0.5 * (f3 - f2); \
    float2 w12 = 1.0 - w0 - w3; \
     \
    float4 ws[3]; \
    ws[0].xy = w0; \
    ws[1].xy = w12; \
    ws[2].xy = w3; \
     \
    ws[0].zw = tc - 1.0; \
    ws[1].zw = tc + 1.0 - w1 / w12; \
    ws[2].zw = tc + 2.0; \
     \
    ws[0].zw /= tex_size; \
    ws[1].zw /= tex_size; \
    ws[2].zw /= tex_size; \
     \
    T ret = 0; \
    ret += tex2Dlod(source, float4(ws[1].z, ws[0].w, 0, 0)).S * ws[1].x * ws[0].y; \
    ret += tex2Dlod(source, float4(ws[0].z, ws[1].w, 0, 0)).S * ws[0].x * ws[1].y; \
    ret += tex2Dlod(source, float4(ws[1].z, ws[1].w, 0, 0)).S * ws[1].x * ws[1].y; \
    ret += tex2Dlod(source, float4(ws[2].z, ws[1].w, 0, 0)).S * ws[2].x * ws[1].y; \
    ret += tex2Dlod(source, float4(ws[1].z, ws[2].w, 0, 0)).S * ws[1].x * ws[2].y; \
     \
    float normfact = 1.0 / (1.0 - (f.x - f2.x) * (f.y - f2.y) * 0.25); \
    return max(0, ret * normfact);

DEFINE_VARIANTS(sample_catmullrom, (sampler source, float2 texcoord), SAMPLE_CATMULLROM)


float lanczos_sinc(float x)
{
    const float eps = 1e-5;
    if (abs(x) < eps)
        return 1.0;
    float pix = 3.14159265358979323846 * x;
    return sin(pix) / pix;
}

float lanczos_weight(float x, float a)
{
    if (abs(x) >= a)
        return 0.0;
    return lanczos_sinc(x) * lanczos_sinc(x / a);
}





#define SAMPLE_LANCZOS_BASIC(T, S, A) \
    int2 tex_size_i = tex2Dsize(source, 0); \
    float2 tex_size = float2(tex_size_i); \
    float2 pixel_coord = texcoord * tex_size; \
    float _lanczos_a = (float)(A); \
    int kx0 = (int)floor(pixel_coord.x - _lanczos_a); \
    int ky0 = (int)floor(pixel_coord.y - _lanczos_a); \
    T acc = 0; \
    float wsum = 0.0; \
    for (int jy = 0; jy < (2 * (A)); ++jy) \
    for (int jx = 0; jx < (2 * (A)); ++jx) \
    { \
        int kx = kx0 + jx; \
        int ky = ky0 + jy; \
        float cx = (float)kx + 0.5; \
        float cy = (float)ky + 0.5; \
        float wx = lanczos_weight(pixel_coord.x - cx, _lanczos_a); \
        float wy = lanczos_weight(pixel_coord.y - cy, _lanczos_a); \
        float w = wx * wy; \
        float2 uvTap = float2(cx, cy) / tex_size; \
        acc += tex2Dlod(source, float4(uvTap, 0.0, 0.0)).S * w; \
        wsum += w; \
    } \
    return acc * rcp(max(wsum, 1e-8));

#define SAMPLE_LANCZOS2_BASIC(T, S) SAMPLE_LANCZOS_BASIC(T, S, 2)
#define SAMPLE_LANCZOS3_BASIC(T, S) SAMPLE_LANCZOS_BASIC(T, S, 3)
#define SAMPLE_LANCZOS4_BASIC(T, S) SAMPLE_LANCZOS_BASIC(T, S, 4)

DEFINE_VARIANTS(sample_lanczos2_basic, (sampler source, float2 texcoord), SAMPLE_LANCZOS2_BASIC)
DEFINE_VARIANTS(sample_lanczos3_basic, (sampler source, float2 texcoord), SAMPLE_LANCZOS3_BASIC)
DEFINE_VARIANTS(sample_lanczos4_basic, (sampler source, float2 texcoord), SAMPLE_LANCZOS4_BASIC)



#define SAMPLE_LANCZOS2(T, S) \
    int2 tex_size_i = tex2Dsize(source, 0); \
    float2 tex_size = float2(tex_size_i); \
    float2 inv_size = rcp(tex_size); \
    float2 pixel_coord = texcoord * tex_size; \
    float nX = floor(pixel_coord.x); \
    float nY = floor(pixel_coord.y); \
    float fx = pixel_coord.x - nX; \
    float fy = pixel_coord.y - nY; \
    const float _a = 2.0; \
    float wx0 = lanczos_weight(fx + 1.5, _a); \
    float wx1 = lanczos_weight(fx + 0.5, _a); \
    float wx2 = lanczos_weight(fx - 0.5, _a); \
    float wx3 = lanczos_weight(fx - 1.5, _a); \
    float wy0 = lanczos_weight(fy + 1.5, _a); \
    float wy1 = lanczos_weight(fy + 0.5, _a); \
    float wy2 = lanczos_weight(fy - 0.5, _a); \
    float wy3 = lanczos_weight(fy - 1.5, _a); \
    float wxC = wx1 + wx2; \
    float wyC = wy1 + wy2; \
    float uvX0 = (nX - 1.5) * inv_size.x; \
    float uvY0 = (nY - 1.5) * inv_size.y; \
    float uvXC = (nX - 0.5 + wx2 / wxC) * inv_size.x; \
    float uvYC = (nY - 0.5 + wy2 / wyC) * inv_size.y; \
    float uvX3 = uvX0 + 3.0 * inv_size.x; \
    float uvY3 = uvY0 + 3.0 * inv_size.y; \
    T acc = 0; \
    float wsum = 0.0; \
    float w; \
    w = wx0 * wy0; acc += tex2Dlod(source, float4(uvX0, uvY0, 0.0, 0.0)).S * w; wsum += w; \
    w = wxC * wy0; acc += tex2Dlod(source, float4(uvXC, uvY0, 0.0, 0.0)).S * w; wsum += w; \
    w = wx3 * wy0; acc += tex2Dlod(source, float4(uvX3, uvY0, 0.0, 0.0)).S * w; wsum += w; \
    w = wx0 * wyC; acc += tex2Dlod(source, float4(uvX0, uvYC, 0.0, 0.0)).S * w; wsum += w; \
    w = wxC * wyC; acc += tex2Dlod(source, float4(uvXC, uvYC, 0.0, 0.0)).S * w; wsum += w; \
    w = wx3 * wyC; acc += tex2Dlod(source, float4(uvX3, uvYC, 0.0, 0.0)).S * w; wsum += w; \
    w = wx0 * wy3; acc += tex2Dlod(source, float4(uvX0, uvY3, 0.0, 0.0)).S * w; wsum += w; \
    w = wxC * wy3; acc += tex2Dlod(source, float4(uvXC, uvY3, 0.0, 0.0)).S * w; wsum += w; \
    w = wx3 * wy3; acc += tex2Dlod(source, float4(uvX3, uvY3, 0.0, 0.0)).S * w; wsum += w; \
    return acc * rcp(max(wsum, 1e-8));

#define SAMPLE_LANCZOS3(T, S) \
    int2 tex_size_i = tex2Dsize(source, 0); \
    float2 tex_size = float2(tex_size_i); \
    float2 inv_size = rcp(tex_size); \
    float2 pixel_coord = texcoord * tex_size; \
    float nX = floor(pixel_coord.x); \
    float nY = floor(pixel_coord.y); \
    float fx = pixel_coord.x - nX; \
    float fy = pixel_coord.y - nY; \
    const float _a = 3.0; \
    float wx0 = lanczos_weight(fx + 2.5, _a); \
    float wx1 = lanczos_weight(fx + 1.5, _a); \
    float wx2 = lanczos_weight(fx + 0.5, _a); \
    float wx3 = lanczos_weight(fx - 0.5, _a); \
    float wx4 = lanczos_weight(fx - 1.5, _a); \
    float wx5 = lanczos_weight(fx - 2.5, _a); \
    float wy0 = lanczos_weight(fy + 2.5, _a); \
    float wy1 = lanczos_weight(fy + 1.5, _a); \
    float wy2 = lanczos_weight(fy + 0.5, _a); \
    float wy3 = lanczos_weight(fy - 0.5, _a); \
    float wy4 = lanczos_weight(fy - 1.5, _a); \
    float wy5 = lanczos_weight(fy - 2.5, _a); \
    float wxC = wx2 + wx3; \
    float wyC = wy2 + wy3; \
    float uvX0 = (nX - 2.5) * inv_size.x; \
    float uvY0 = (nY - 2.5) * inv_size.y; \
    float uvX1 = uvX0 + inv_size.x; \
    float uvY1 = uvY0 + inv_size.y; \
    float uvXC = (nX - 0.5 + wx3 / wxC) * inv_size.x; \
    float uvYC = (nY - 0.5 + wy3 / wyC) * inv_size.y; \
    float uvX4 = uvX0 + 4.0 * inv_size.x; \
    float uvX5 = uvX0 + 5.0 * inv_size.x; \
    float uvY4 = uvY0 + 4.0 * inv_size.y; \
    float uvY5 = uvY0 + 5.0 * inv_size.y; \
    T acc = 0; \
    float wsum = 0.0; \
    float w; \
    w = wx0 * wy0; acc += tex2Dlod(source, float4(uvX0, uvY0, 0.0, 0.0)).S * w; wsum += w; \
    w = wx1 * wy0; acc += tex2Dlod(source, float4(uvX1, uvY0, 0.0, 0.0)).S * w; wsum += w; \
    w = wxC * wy0; acc += tex2Dlod(source, float4(uvXC, uvY0, 0.0, 0.0)).S * w; wsum += w; \
    w = wx4 * wy0; acc += tex2Dlod(source, float4(uvX4, uvY0, 0.0, 0.0)).S * w; wsum += w; \
    w = wx5 * wy0; acc += tex2Dlod(source, float4(uvX5, uvY0, 0.0, 0.0)).S * w; wsum += w; \
    w = wx0 * wy1; acc += tex2Dlod(source, float4(uvX0, uvY1, 0.0, 0.0)).S * w; wsum += w; \
    w = wx1 * wy1; acc += tex2Dlod(source, float4(uvX1, uvY1, 0.0, 0.0)).S * w; wsum += w; \
    w = wxC * wy1; acc += tex2Dlod(source, float4(uvXC, uvY1, 0.0, 0.0)).S * w; wsum += w; \
    w = wx4 * wy1; acc += tex2Dlod(source, float4(uvX4, uvY1, 0.0, 0.0)).S * w; wsum += w; \
    w = wx5 * wy1; acc += tex2Dlod(source, float4(uvX5, uvY1, 0.0, 0.0)).S * w; wsum += w; \
    w = wx0 * wyC; acc += tex2Dlod(source, float4(uvX0, uvYC, 0.0, 0.0)).S * w; wsum += w; \
    w = wx1 * wyC; acc += tex2Dlod(source, float4(uvX1, uvYC, 0.0, 0.0)).S * w; wsum += w; \
    w = wxC * wyC; acc += tex2Dlod(source, float4(uvXC, uvYC, 0.0, 0.0)).S * w; wsum += w; \
    w = wx4 * wyC; acc += tex2Dlod(source, float4(uvX4, uvYC, 0.0, 0.0)).S * w; wsum += w; \
    w = wx5 * wyC; acc += tex2Dlod(source, float4(uvX5, uvYC, 0.0, 0.0)).S * w; wsum += w; \
    w = wx0 * wy4; acc += tex2Dlod(source, float4(uvX0, uvY4, 0.0, 0.0)).S * w; wsum += w; \
    w = wx1 * wy4; acc += tex2Dlod(source, float4(uvX1, uvY4, 0.0, 0.0)).S * w; wsum += w; \
    w = wxC * wy4; acc += tex2Dlod(source, float4(uvXC, uvY4, 0.0, 0.0)).S * w; wsum += w; \
    w = wx4 * wy4; acc += tex2Dlod(source, float4(uvX4, uvY4, 0.0, 0.0)).S * w; wsum += w; \
    w = wx5 * wy4; acc += tex2Dlod(source, float4(uvX5, uvY4, 0.0, 0.0)).S * w; wsum += w; \
    w = wx0 * wy5; acc += tex2Dlod(source, float4(uvX0, uvY5, 0.0, 0.0)).S * w; wsum += w; \
    w = wx1 * wy5; acc += tex2Dlod(source, float4(uvX1, uvY5, 0.0, 0.0)).S * w; wsum += w; \
    w = wxC * wy5; acc += tex2Dlod(source, float4(uvXC, uvY5, 0.0, 0.0)).S * w; wsum += w; \
    w = wx4 * wy5; acc += tex2Dlod(source, float4(uvX4, uvY5, 0.0, 0.0)).S * w; wsum += w; \
    w = wx5 * wy5; acc += tex2Dlod(source, float4(uvX5, uvY5, 0.0, 0.0)).S * w; wsum += w; \
    return acc * rcp(max(wsum, 1e-8));

#define SAMPLE_LANCZOS4(T, S) \
    int2 tex_size_i = tex2Dsize(source, 0); \
    float2 tex_size = float2(tex_size_i); \
    float2 inv_size = rcp(tex_size); \
    float2 pixel_coord = texcoord * tex_size; \
    float nX = floor(pixel_coord.x); \
    float nY = floor(pixel_coord.y); \
    float fx = pixel_coord.x - nX; \
    float fy = pixel_coord.y - nY; \
    const float _a = 4.0; \
    float wx0 = lanczos_weight(fx + 3.5, _a); \
    float wx1 = lanczos_weight(fx + 2.5, _a); \
    float wx2 = lanczos_weight(fx + 1.5, _a); \
    float wx3 = lanczos_weight(fx + 0.5, _a); \
    float wx4 = lanczos_weight(fx - 0.5, _a); \
    float wx5 = lanczos_weight(fx - 1.5, _a); \
    float wx6 = lanczos_weight(fx - 2.5, _a); \
    float wx7 = lanczos_weight(fx - 3.5, _a); \
    float wy0 = lanczos_weight(fy + 3.5, _a); \
    float wy1 = lanczos_weight(fy + 2.5, _a); \
    float wy2 = lanczos_weight(fy + 1.5, _a); \
    float wy3 = lanczos_weight(fy + 0.5, _a); \
    float wy4 = lanczos_weight(fy - 0.5, _a); \
    float wy5 = lanczos_weight(fy - 1.5, _a); \
    float wy6 = lanczos_weight(fy - 2.5, _a); \
    float wy7 = lanczos_weight(fy - 3.5, _a); \
    float wxC = wx3 + wx4; \
    float wyC = wy3 + wy4; \
    float uvX0 = (nX - 3.5) * inv_size.x; \
    float uvY0 = (nY - 3.5) * inv_size.y; \
    float uvX1 = uvX0 + inv_size.x; \
    float uvX2 = uvX0 + 2.0 * inv_size.x; \
    float uvY1 = uvY0 + inv_size.y; \
    float uvY2 = uvY0 + 2.0 * inv_size.y; \
    float uvXC = (nX - 0.5 + wx4 / wxC) * inv_size.x; \
    float uvYC = (nY - 0.5 + wy4 / wyC) * inv_size.y; \
    float uvX5 = uvX0 + 5.0 * inv_size.x; \
    float uvX6 = uvX0 + 6.0 * inv_size.x; \
    float uvX7 = uvX0 + 7.0 * inv_size.x; \
    float uvY5 = uvY0 + 5.0 * inv_size.y; \
    float uvY6 = uvY0 + 6.0 * inv_size.y; \
    float uvY7 = uvY0 + 7.0 * inv_size.y; \
    T acc = 0; \
    float wsum = 0.0; \
    float w; \
    w = wx0 * wy0; acc += tex2Dlod(source, float4(uvX0, uvY0, 0.0, 0.0)).S * w; wsum += w; \
    w = wx1 * wy0; acc += tex2Dlod(source, float4(uvX1, uvY0, 0.0, 0.0)).S * w; wsum += w; \
    w = wx2 * wy0; acc += tex2Dlod(source, float4(uvX2, uvY0, 0.0, 0.0)).S * w; wsum += w; \
    w = wxC * wy0; acc += tex2Dlod(source, float4(uvXC, uvY0, 0.0, 0.0)).S * w; wsum += w; \
    w = wx5 * wy0; acc += tex2Dlod(source, float4(uvX5, uvY0, 0.0, 0.0)).S * w; wsum += w; \
    w = wx6 * wy0; acc += tex2Dlod(source, float4(uvX6, uvY0, 0.0, 0.0)).S * w; wsum += w; \
    w = wx7 * wy0; acc += tex2Dlod(source, float4(uvX7, uvY0, 0.0, 0.0)).S * w; wsum += w; \
    w = wx0 * wy1; acc += tex2Dlod(source, float4(uvX0, uvY1, 0.0, 0.0)).S * w; wsum += w; \
    w = wx1 * wy1; acc += tex2Dlod(source, float4(uvX1, uvY1, 0.0, 0.0)).S * w; wsum += w; \
    w = wx2 * wy1; acc += tex2Dlod(source, float4(uvX2, uvY1, 0.0, 0.0)).S * w; wsum += w; \
    w = wxC * wy1; acc += tex2Dlod(source, float4(uvXC, uvY1, 0.0, 0.0)).S * w; wsum += w; \
    w = wx5 * wy1; acc += tex2Dlod(source, float4(uvX5, uvY1, 0.0, 0.0)).S * w; wsum += w; \
    w = wx6 * wy1; acc += tex2Dlod(source, float4(uvX6, uvY1, 0.0, 0.0)).S * w; wsum += w; \
    w = wx7 * wy1; acc += tex2Dlod(source, float4(uvX7, uvY1, 0.0, 0.0)).S * w; wsum += w; \
    w = wx0 * wy2; acc += tex2Dlod(source, float4(uvX0, uvY2, 0.0, 0.0)).S * w; wsum += w; \
    w = wx1 * wy2; acc += tex2Dlod(source, float4(uvX1, uvY2, 0.0, 0.0)).S * w; wsum += w; \
    w = wx2 * wy2; acc += tex2Dlod(source, float4(uvX2, uvY2, 0.0, 0.0)).S * w; wsum += w; \
    w = wxC * wy2; acc += tex2Dlod(source, float4(uvXC, uvY2, 0.0, 0.0)).S * w; wsum += w; \
    w = wx5 * wy2; acc += tex2Dlod(source, float4(uvX5, uvY2, 0.0, 0.0)).S * w; wsum += w; \
    w = wx6 * wy2; acc += tex2Dlod(source, float4(uvX6, uvY2, 0.0, 0.0)).S * w; wsum += w; \
    w = wx7 * wy2; acc += tex2Dlod(source, float4(uvX7, uvY2, 0.0, 0.0)).S * w; wsum += w; \
    w = wx0 * wyC; acc += tex2Dlod(source, float4(uvX0, uvYC, 0.0, 0.0)).S * w; wsum += w; \
    w = wx1 * wyC; acc += tex2Dlod(source, float4(uvX1, uvYC, 0.0, 0.0)).S * w; wsum += w; \
    w = wx2 * wyC; acc += tex2Dlod(source, float4(uvX2, uvYC, 0.0, 0.0)).S * w; wsum += w; \
    w = wxC * wyC; acc += tex2Dlod(source, float4(uvXC, uvYC, 0.0, 0.0)).S * w; wsum += w; \
    w = wx5 * wyC; acc += tex2Dlod(source, float4(uvX5, uvYC, 0.0, 0.0)).S * w; wsum += w; \
    w = wx6 * wyC; acc += tex2Dlod(source, float4(uvX6, uvYC, 0.0, 0.0)).S * w; wsum += w; \
    w = wx7 * wyC; acc += tex2Dlod(source, float4(uvX7, uvYC, 0.0, 0.0)).S * w; wsum += w; \
    w = wx0 * wy5; acc += tex2Dlod(source, float4(uvX0, uvY5, 0.0, 0.0)).S * w; wsum += w; \
    w = wx1 * wy5; acc += tex2Dlod(source, float4(uvX1, uvY5, 0.0, 0.0)).S * w; wsum += w; \
    w = wx2 * wy5; acc += tex2Dlod(source, float4(uvX2, uvY5, 0.0, 0.0)).S * w; wsum += w; \
    w = wxC * wy5; acc += tex2Dlod(source, float4(uvXC, uvY5, 0.0, 0.0)).S * w; wsum += w; \
    w = wx5 * wy5; acc += tex2Dlod(source, float4(uvX5, uvY5, 0.0, 0.0)).S * w; wsum += w; \
    w = wx6 * wy5; acc += tex2Dlod(source, float4(uvX6, uvY5, 0.0, 0.0)).S * w; wsum += w; \
    w = wx7 * wy5; acc += tex2Dlod(source, float4(uvX7, uvY5, 0.0, 0.0)).S * w; wsum += w; \
    w = wx0 * wy6; acc += tex2Dlod(source, float4(uvX0, uvY6, 0.0, 0.0)).S * w; wsum += w; \
    w = wx1 * wy6; acc += tex2Dlod(source, float4(uvX1, uvY6, 0.0, 0.0)).S * w; wsum += w; \
    w = wx2 * wy6; acc += tex2Dlod(source, float4(uvX2, uvY6, 0.0, 0.0)).S * w; wsum += w; \
    w = wxC * wy6; acc += tex2Dlod(source, float4(uvXC, uvY6, 0.0, 0.0)).S * w; wsum += w; \
    w = wx5 * wy6; acc += tex2Dlod(source, float4(uvX5, uvY6, 0.0, 0.0)).S * w; wsum += w; \
    w = wx6 * wy6; acc += tex2Dlod(source, float4(uvX6, uvY6, 0.0, 0.0)).S * w; wsum += w; \
    w = wx7 * wy6; acc += tex2Dlod(source, float4(uvX7, uvY6, 0.0, 0.0)).S * w; wsum += w; \
    w = wx0 * wy7; acc += tex2Dlod(source, float4(uvX0, uvY7, 0.0, 0.0)).S * w; wsum += w; \
    w = wx1 * wy7; acc += tex2Dlod(source, float4(uvX1, uvY7, 0.0, 0.0)).S * w; wsum += w; \
    w = wx2 * wy7; acc += tex2Dlod(source, float4(uvX2, uvY7, 0.0, 0.0)).S * w; wsum += w; \
    w = wxC * wy7; acc += tex2Dlod(source, float4(uvXC, uvY7, 0.0, 0.0)).S * w; wsum += w; \
    w = wx5 * wy7; acc += tex2Dlod(source, float4(uvX5, uvY7, 0.0, 0.0)).S * w; wsum += w; \
    w = wx6 * wy7; acc += tex2Dlod(source, float4(uvX6, uvY7, 0.0, 0.0)).S * w; wsum += w; \
    w = wx7 * wy7; acc += tex2Dlod(source, float4(uvX7, uvY7, 0.0, 0.0)).S * w; wsum += w; \
    return acc * rcp(max(wsum, 1e-8));

DEFINE_VARIANTS(sample_lanczos2, (sampler source, float2 texcoord), SAMPLE_LANCZOS2)
DEFINE_VARIANTS(sample_lanczos3, (sampler source, float2 texcoord), SAMPLE_LANCZOS3)
DEFINE_VARIANTS(sample_lanczos4, (sampler source, float2 texcoord), SAMPLE_LANCZOS4)


void _easu_tap(
    inout float3 aC, inout float aW,
    float2 off, float2 dir, float2 len,
    float lob, float clp,
    float3 c
){
    float2 v = float2(dot(off, dir), dot(off, float2(-dir.y, dir.x)));
    v *= len;

    float d2 = min(dot(v, v), clp);
    float wB = 0.4 * d2 - 1.0;
    float wA = lob * d2 - 1.0;
    wB *= wB;
    wA *= wA;
    wB = 1.5625 * wB - 0.5625;

    float w = wB * wA;
    aC += c * w;
    aW += w;
}


void _easu_set(
    inout float2 dir, inout float len,
    float w,
    float lA, float lB, float lC, float lD, float lE
){
    float lenX = max(abs(lD - lC), abs(lC - lB));
    float dirX = lD - lB;
    dir.x += dirX * w;
    lenX = clamp(abs(dirX) / lenX, 0.0, 1.0);
    lenX *= lenX;
    len += lenX * w;

    float lenY = max(abs(lE - lC), abs(lC - lA));
    float dirY = lE - lA;
    dir.y += dirY * w;
    lenY = clamp(abs(dirY) / lenY, 0.0, 1.0);
    lenY *= lenY;
    len += lenY * w;
}


float4 sample_easu_p(sampler2D s, float2 uv, int2 srcSize, int2 dstSize)
{
    float2 srcF = float2(srcSize);
    float2 dstF = float2(dstSize);

    float4 con0 = float4(srcF / dstF,  -0.5, -0.5);
    float4 con1 = float4( 1,  1,  1, -1) / srcF.xyxy;
    float4 con2 = float4(-1,  2,  1,  2) / srcF.xyxy;
    float4 con3 = float4( 0,  4,  0,  0) / srcF.xyxy;

    float2 ip = uv * dstF;
    float2 pp = ip * con0.xy + con0.zw;
    float2 fp = floor(pp);
    pp -= fp;

    float2 p0  = fp * con1.xy + con1.zw;
    float2 p1  = p0 + con2.xy;
    float2 p2  = p0 + con2.zw;
    float2 p3  = p0 + con3.xy;
    float4 off = float4(-0.5, 0.5, -0.5, 0.5) * con1.xxyy;

    float3 bC = tex2Dlod(s, float4(p0+off.xw,0,0)).rgb; float bL = bC.g+0.5*(bC.r+bC.b);
    float3 cC = tex2Dlod(s, float4(p0+off.yw,0,0)).rgb; float cL = cC.g+0.5*(cC.r+cC.b);
    float3 iC = tex2Dlod(s, float4(p1+off.xw,0,0)).rgb; float iL = iC.g+0.5*(iC.r+iC.b);
    float3 jC = tex2Dlod(s, float4(p1+off.yw,0,0)).rgb; float jL = jC.g+0.5*(jC.r+jC.b);
    float3 fC = tex2Dlod(s, float4(p1+off.yz,0,0)).rgb; float fL = fC.g+0.5*(fC.r+fC.b);
    float3 eC = tex2Dlod(s, float4(p1+off.xz,0,0)).rgb; float eL = eC.g+0.5*(eC.r+eC.b);
    float3 kC = tex2Dlod(s, float4(p2+off.xw,0,0)).rgb; float kL = kC.g+0.5*(kC.r+kC.b);
    float3 lC = tex2Dlod(s, float4(p2+off.yw,0,0)).rgb; float lL = lC.g+0.5*(lC.r+lC.b);
    float3 hC = tex2Dlod(s, float4(p2+off.yz,0,0)).rgb; float hL = hC.g+0.5*(hC.r+hC.b);
    float3 gC = tex2Dlod(s, float4(p2+off.xz,0,0)).rgb; float gL = gC.g+0.5*(gC.r+gC.b);
    float3 oC = tex2Dlod(s, float4(p3+off.yz,0,0)).rgb; float oL = oC.g+0.5*(oC.r+oC.b);
    float3 nC = tex2Dlod(s, float4(p3+off.xz,0,0)).rgb; float nL = nC.g+0.5*(nC.r+nC.b);

    float2 dir = 0;
    float  len = 0;
    _easu_set(dir, len, (1.0-pp.x)*(1.0-pp.y), bL,eL,fL,gL,jL);
    _easu_set(dir, len,      pp.x *(1.0-pp.y), cL,fL,gL,hL,kL);
    _easu_set(dir, len, (1.0-pp.x)*     pp.y,  fL,iL,jL,kL,nL);
    _easu_set(dir, len,      pp.x *     pp.y,   gL,jL,kL,lL,oL);

    float2 dir2 = dir * dir;
    float  dirR = dir2.x + dir2.y;
    bool   zro  = dirR < (1.0 / 32768.0);
    dirR  = rsqrt(dirR);
    dirR  = zro ? 1.0 : dirR;
    dir.x = zro ? 1.0 : dir.x;
    dir  *= dirR;

    len = len * 0.5;
    len *= len;
    float  stretch = dot(dir, dir) / max(abs(dir.x), abs(dir.y));
    float2 len2    = float2(1.0 + (stretch - 1.0) * len, 1.0 - 0.5 * len);
    float  lob     = 0.5 - 0.29 * len;
    float  clp     = 1.0 / lob;

    float3 min4 = min(min(fC, gC), min(jC, kC));
    float3 max4 = max(max(fC, gC), max(jC, kC));

    float3 aC = 0;
    float  aW = 0;
    _easu_tap(aC,aW,float2( 0,-1)-pp,dir,len2,lob,clp,bC);
    _easu_tap(aC,aW,float2( 1,-1)-pp,dir,len2,lob,clp,cC);
    _easu_tap(aC,aW,float2(-1, 1)-pp,dir,len2,lob,clp,iC);
    _easu_tap(aC,aW,float2( 0, 1)-pp,dir,len2,lob,clp,jC);
    _easu_tap(aC,aW,float2( 0, 0)-pp,dir,len2,lob,clp,fC);
    _easu_tap(aC,aW,float2(-1, 0)-pp,dir,len2,lob,clp,eC);
    _easu_tap(aC,aW,float2( 1, 1)-pp,dir,len2,lob,clp,kC);
    _easu_tap(aC,aW,float2( 2, 1)-pp,dir,len2,lob,clp,lC);
    _easu_tap(aC,aW,float2( 2, 0)-pp,dir,len2,lob,clp,hC);
    _easu_tap(aC,aW,float2( 1, 0)-pp,dir,len2,lob,clp,gC);
    _easu_tap(aC,aW,float2( 1, 2)-pp,dir,len2,lob,clp,oC);
    _easu_tap(aC,aW,float2( 0, 2)-pp,dir,len2,lob,clp,nC);

    return float4(min(max4, max(min4, aC / aW)), 1.0);
}


float4 sample_easu(sampler2D s, float2 uv, int2 dstSize)
{
    return sample_easu_p(s, uv, tex2Dsize(s, 0), dstSize);
}


float4 sample_easu_same(sampler2D s, float2 uv)
{
    int2 sz = tex2Dsize(s, 0);
    return sample_easu_p(s, uv, sz, sz);
}
