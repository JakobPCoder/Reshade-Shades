/*=============================================================================
    samplers (2.0.2)
    Texture sampling and pyramid helpers for Shades shaders.
    Copyright, Jakob Wapenhensch
    License: CC BY-NC-ND 4.0 (https://creativecommons.org/licenses/by-nc-nd/4.0/)
    https://creativecommons.org/licenses/by-nc-nd/4.0/legalcode
=============================================================================*/

#pragma once

#include "shades_macros.fxh"

uniform uint Shades_framecount < source = "framecount"; >;


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




#define SAMPLE_CATMULLROM_5TAP_FAST(T, S) \
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

DEFINE_VARIANTS(sample_catmullrom_5tap_fast, (sampler source, float2 texcoord), SAMPLE_CATMULLROM_5TAP_FAST)

#define SAMPLE_CATMULLROM_9TAP(T, S) \
    int2 tex_size = tex2Dsize(source, 0); \
    float2 pixel_coord = texcoord * tex_size; \
    float2 tc = floor(pixel_coord - 0.5) + 0.5; \
    float2 f = pixel_coord - tc; \
    float2 f2 = f * f; \
    float2 f3 = f2 * f; \
    float2 w0 = f2 - 0.5 * (f3 + f); \
    float2 w1 = 1.5 * f3 - 2.5 * f2 + 1.0; \
    float2 w3 = 0.5 * (f3 - f2); \
    float2 w12 = 1.0 - w0 - w3; \
    float4 ws[3]; \
    ws[0].xy = w0; \
    ws[1].xy = w12; \
    ws[2].xy = w3; \
    ws[0].zw = tc - 1.0; \
    ws[1].zw = tc + 1.0 - w1 / w12; \
    ws[2].zw = tc + 2.0; \
    ws[0].zw /= tex_size; \
    ws[1].zw /= tex_size; \
    ws[2].zw /= tex_size; \
    T ret = 0; \
    ret += tex2Dlod(source, float4(ws[1].z, ws[0].w, 0, 0)).S * ws[1].x * ws[0].y; \
    ret += tex2Dlod(source, float4(ws[0].z, ws[1].w, 0, 0)).S * ws[0].x * ws[1].y; \
    ret += tex2Dlod(source, float4(ws[1].z, ws[1].w, 0, 0)).S * ws[1].x * ws[1].y; \
    ret += tex2Dlod(source, float4(ws[2].z, ws[1].w, 0, 0)).S * ws[2].x * ws[1].y; \
    ret += tex2Dlod(source, float4(ws[1].z, ws[2].w, 0, 0)).S * ws[1].x * ws[2].y; \
    ret += tex2Dlod(source, float4(ws[0].z, ws[0].w, 0, 0)).S * ws[0].x * ws[0].y; \
    ret += tex2Dlod(source, float4(ws[2].z, ws[0].w, 0, 0)).S * ws[2].x * ws[0].y; \
    ret += tex2Dlod(source, float4(ws[0].z, ws[2].w, 0, 0)).S * ws[0].x * ws[2].y; \
    ret += tex2Dlod(source, float4(ws[2].z, ws[2].w, 0, 0)).S * ws[2].x * ws[2].y; \
    return max(0, ret);

DEFINE_VARIANTS(sample_catmullrom_9tap, (sampler source, float2 texcoord), SAMPLE_CATMULLROM_9TAP)

#define SAMPLE_CATMULLROM(T, S) SAMPLE_CATMULLROM_9TAP(T, S)
DEFINE_VARIANTS(sample_catmullrom, (sampler source, float2 texcoord), SAMPLE_CATMULLROM)

#define SAMPLE_CATMULLROM_16TAP_BASIC(T, S) \
    int2 tex_size = tex2Dsize(source, 0); \
    float2 pixel_coord = texcoord * tex_size; \
    float2 tc = floor(pixel_coord - 0.5) + 0.5; \
    float2 f = pixel_coord - tc; \
    float2 f2 = f * f; \
    float2 f3 = f2 * f; \
    float2 w0 = f2 - 0.5 * (f3 + f); \
    float2 w1 = 1.5 * f3 - 2.5 * f2 + 1.0; \
    float2 w3 = 0.5 * (f3 - f2); \
    float2 w2 = 1.0 - w0 - w1 - w3; \
    T acc = 0; \
    [unroll] \
    for (int y = -1; y <= 2; ++y) \
    { \
        float wy = (y == -1) ? w0.y : ((y == 0) ? w1.y : ((y == 1) ? w2.y : w3.y)); \
        [unroll] \
        for (int x = -1; x <= 2; ++x) \
        { \
            float wx = (x == -1) ? w0.x : ((x == 0) ? w1.x : ((x == 1) ? w2.x : w3.x)); \
            float2 uvTap = (tc + float2(x, y)) / tex_size; \
            acc += tex2Dlod(source, float4(uvTap, 0.0, 0.0)).S * (wx * wy); \
        } \
    } \
    return max(0, acc);

DEFINE_VARIANTS(sample_catmullrom_16tap_basic, (sampler source, float2 texcoord), SAMPLE_CATMULLROM_16TAP_BASIC)

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

#define SAMPLE_LANCZOS_NTAP_BASIC(T, S, A) \
    int2 tex_size_i = tex2Dsize(source, 0); \
    float2 tex_size = float2(tex_size_i); \
    float2 pixel_coord = texcoord * tex_size; \
    float _lanczos_a = (float)(A); \
    int kx0 = (int)floor(pixel_coord.x - _lanczos_a + 0.5); \
    int ky0 = (int)floor(pixel_coord.y - _lanczos_a + 0.5); \
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

#define SAMPLE_LANCZOS2_16TAP_BASIC(T, S) SAMPLE_LANCZOS_NTAP_BASIC(T, S, 2)
#define SAMPLE_LANCZOS3_36TAP_BASIC(T, S) SAMPLE_LANCZOS_NTAP_BASIC(T, S, 3)
#define SAMPLE_LANCZOS4_64TAP_BASIC(T, S) SAMPLE_LANCZOS_NTAP_BASIC(T, S, 4)

DEFINE_VARIANTS(sample_lanczos2_16tap_basic, (sampler source, float2 texcoord), SAMPLE_LANCZOS2_16TAP_BASIC)
DEFINE_VARIANTS(sample_lanczos3_36tap_basic, (sampler source, float2 texcoord), SAMPLE_LANCZOS3_36TAP_BASIC)
DEFINE_VARIANTS(sample_lanczos4_64tap_basic, (sampler source, float2 texcoord), SAMPLE_LANCZOS4_64TAP_BASIC)


#define SAMPLE_LANCZOS2_5TAP_FAST(T, S) \
    int2 tex_size = tex2Dsize(source, 0); \
    float2 pixel_coord = texcoord * tex_size; \
    float2 nX = floor(pixel_coord - 0.5) + 0.5; \
    float2 fx = pixel_coord - nX; \
    float _a = 2.0; \
    float2 w0 = float2(lanczos_weight(fx.x + 1.0, _a), lanczos_weight(fx.y + 1.0, _a)); \
    float2 w1 = float2(lanczos_weight(fx.x, _a),       lanczos_weight(fx.y, _a)); \
    float2 w2 = float2(lanczos_weight(fx.x - 1.0, _a), lanczos_weight(fx.y - 1.0, _a)); \
    float2 w3 = float2(lanczos_weight(fx.x - 2.0, _a), lanczos_weight(fx.y - 2.0, _a)); \
    float2 w12 = w1 + w2; \
    float2 uvX0 = (nX - 1.0) / tex_size; \
    float2 uvXC = (nX + w2 / w12) / tex_size; \
    float2 uvX3 = uvX0 + 3.0 / tex_size; \
    T ret = 0; \
    float wsum = 0.0; \
    float w; \
    w = w12.x * w0.y;  ret += tex2Dlod(source, float4(uvXC.x, uvX0.y, 0, 0)).S * w; wsum += w; \
    w = w0.x  * w12.y; ret += tex2Dlod(source, float4(uvX0.x, uvXC.y, 0, 0)).S * w; wsum += w; \
    w = w12.x * w12.y; ret += tex2Dlod(source, float4(uvXC.x, uvXC.y, 0, 0)).S * w; wsum += w; \
    w = w3.x  * w12.y; ret += tex2Dlod(source, float4(uvX3.x, uvXC.y, 0, 0)).S * w; wsum += w; \
    w = w12.x * w3.y;  ret += tex2Dlod(source, float4(uvXC.x, uvX3.y, 0, 0)).S * w; wsum += w; \
    return max(0, ret / max(wsum, 1e-8));

DEFINE_VARIANTS(sample_lanczos2_5tap_fast, (sampler source, float2 texcoord), SAMPLE_LANCZOS2_5TAP_FAST)


#define SAMPLE_LANCZOS2_9TAP(T, S) \
    int2 tex_size = tex2Dsize(source, 0); \
    float2 pixel_coord = texcoord * tex_size; \
    float2 nX = floor(pixel_coord - 0.5) + 0.5; \
    float2 fx = pixel_coord - nX; \
    float _a = 2.0; \
    float2 w0 = float2(lanczos_weight(fx.x + 1.0, _a), lanczos_weight(fx.y + 1.0, _a)); \
    float2 w1 = float2(lanczos_weight(fx.x, _a),       lanczos_weight(fx.y, _a)); \
    float2 w2 = float2(lanczos_weight(fx.x - 1.0, _a), lanczos_weight(fx.y - 1.0, _a)); \
    float2 w3 = float2(lanczos_weight(fx.x - 2.0, _a), lanczos_weight(fx.y - 2.0, _a)); \
    float2 w12 = w1 + w2; \
    float2 uvX0 = (nX - 1.0) / tex_size; \
    float2 uvXC = (nX + w2 / w12) / tex_size; \
    float2 uvX3 = uvX0 + 3.0 / tex_size; \
    T ret = 0; \
    float wsum = 0.0; \
    float w; \
     \
    w = w12.x * w0.y;  ret += tex2Dlod(source, float4(uvXC.x, uvX0.y, 0, 0)).S * w; wsum += w; \
    w = w0.x  * w12.y; ret += tex2Dlod(source, float4(uvX0.x, uvXC.y, 0, 0)).S * w; wsum += w; \
    w = w12.x * w12.y; ret += tex2Dlod(source, float4(uvXC.x, uvXC.y, 0, 0)).S * w; wsum += w; \
    w = w3.x  * w12.y; ret += tex2Dlod(source, float4(uvX3.x, uvXC.y, 0, 0)).S * w; wsum += w; \
    w = w12.x * w3.y;  ret += tex2Dlod(source, float4(uvXC.x, uvX3.y, 0, 0)).S * w; wsum += w; \
    w = w0.x  * w0.y;  ret += tex2Dlod(source, float4(uvX0.x, uvX0.y, 0, 0)).S * w; wsum += w; \
    w = w3.x  * w0.y;  ret += tex2Dlod(source, float4(uvX3.x, uvX0.y, 0, 0)).S * w; wsum += w; \
    w = w0.x  * w3.y;  ret += tex2Dlod(source, float4(uvX0.x, uvX3.y, 0, 0)).S * w; wsum += w; \
    w = w3.x  * w3.y;  ret += tex2Dlod(source, float4(uvX3.x, uvX3.y, 0, 0)).S * w; wsum += w; \
    return max(0, ret / max(wsum, 1e-8));

#define SAMPLE_LANCZOS3_21TAP_FAST(T, S) \
    int2 tex_size = tex2Dsize(source, 0); \
    float2 pixel_coord = texcoord * tex_size; \
    float2 nX = floor(pixel_coord - 0.5) + 0.5; \
    float2 fx = pixel_coord - nX; \
    float _a = 3.0; \
    float2 w0 = float2(lanczos_weight(fx.x + 2.0, _a), lanczos_weight(fx.y + 2.0, _a)); \
    float2 w1 = float2(lanczos_weight(fx.x + 1.0, _a), lanczos_weight(fx.y + 1.0, _a)); \
    float2 w2 = float2(lanczos_weight(fx.x, _a), lanczos_weight(fx.y, _a)); \
    float2 w3 = float2(lanczos_weight(fx.x - 1.0, _a), lanczos_weight(fx.y - 1.0, _a)); \
    float2 w4 = float2(lanczos_weight(fx.x - 2.0, _a), lanczos_weight(fx.y - 2.0, _a)); \
    float2 w5 = float2(lanczos_weight(fx.x - 3.0, _a), lanczos_weight(fx.y - 3.0, _a)); \
    float2 w23 = w2 + w3; \
    float2 uvX0 = (nX - 2.0) / tex_size; \
    float2 uvXC = (nX + w3 / w23) / tex_size; \
    float2 uvX5 = uvX0 + 5.0 / tex_size; \
    float2 uvX1 = (nX - 1.0) / tex_size; \
    float2 uvX4 = (nX + 2.0) / tex_size; \
    T ret = 0; \
    float wsum = 0.0; \
    float w; \
    w = w1.x        * w0.y; ret += tex2Dlod(source, float4(uvX1.x, uvX0.y, 0, 0)).S * w; wsum += w; \
    w = w23.x       * w0.y; ret += tex2Dlod(source, float4(uvXC.x, uvX0.y, 0, 0)).S * w; wsum += w; \
    w = w4.x        * w0.y; ret += tex2Dlod(source, float4(uvX4.x, uvX0.y, 0, 0)).S * w; wsum += w; \
    w = w0.x        * w1.y; ret += tex2Dlod(source, float4(uvX0.x, uvX1.y, 0, 0)).S * w; wsum += w; \
    w = w1.x        * w1.y; ret += tex2Dlod(source, float4(uvX1.x, uvX1.y, 0, 0)).S * w; wsum += w; \
    w = w23.x       * w1.y; ret += tex2Dlod(source, float4(uvXC.x, uvX1.y, 0, 0)).S * w; wsum += w; \
    w = w4.x        * w1.y; ret += tex2Dlod(source, float4(uvX4.x, uvX1.y, 0, 0)).S * w; wsum += w; \
    w = w5.x        * w1.y; ret += tex2Dlod(source, float4(uvX5.x, uvX1.y, 0, 0)).S * w; wsum += w; \
    w = w0.x        * w23.y; ret += tex2Dlod(source, float4(uvX0.x, uvXC.y, 0, 0)).S * w; wsum += w; \
    w = w1.x        * w23.y; ret += tex2Dlod(source, float4(uvX1.x, uvXC.y, 0, 0)).S * w; wsum += w; \
    w = w23.x       * w23.y; ret += tex2Dlod(source, float4(uvXC.x, uvXC.y, 0, 0)).S * w; wsum += w; \
    w = w4.x        * w23.y; ret += tex2Dlod(source, float4(uvX4.x, uvXC.y, 0, 0)).S * w; wsum += w; \
    w = w5.x        * w23.y; ret += tex2Dlod(source, float4(uvX5.x, uvXC.y, 0, 0)).S * w; wsum += w; \
    w = w0.x        * w4.y; ret += tex2Dlod(source, float4(uvX0.x, uvX4.y, 0, 0)).S * w; wsum += w; \
    w = w1.x        * w4.y; ret += tex2Dlod(source, float4(uvX1.x, uvX4.y, 0, 0)).S * w; wsum += w; \
    w = w23.x       * w4.y; ret += tex2Dlod(source, float4(uvXC.x, uvX4.y, 0, 0)).S * w; wsum += w; \
    w = w4.x        * w4.y; ret += tex2Dlod(source, float4(uvX4.x, uvX4.y, 0, 0)).S * w; wsum += w; \
    w = w5.x        * w4.y; ret += tex2Dlod(source, float4(uvX5.x, uvX4.y, 0, 0)).S * w; wsum += w; \
    w = w1.x        * w5.y; ret += tex2Dlod(source, float4(uvX1.x, uvX5.y, 0, 0)).S * w; wsum += w; \
    w = w23.x       * w5.y; ret += tex2Dlod(source, float4(uvXC.x, uvX5.y, 0, 0)).S * w; wsum += w; \
    w = w4.x        * w5.y; ret += tex2Dlod(source, float4(uvX4.x, uvX5.y, 0, 0)).S * w; wsum += w; \
    return max(0, ret / max(wsum, 1e-8));

DEFINE_VARIANTS(sample_lanczos3_21tap_fast, (sampler source, float2 texcoord), SAMPLE_LANCZOS3_21TAP_FAST)

#define SAMPLE_LANCZOS3_25TAP(T, S) \
    int2 tex_size = tex2Dsize(source, 0); \
    float2 pixel_coord = texcoord * tex_size; \
    float2 nX = floor(pixel_coord - 0.5) + 0.5; \
    float2 fx = pixel_coord - nX; \
    float _a = 3.0; \
    float2 w0 = float2(lanczos_weight(fx.x + 2.0, _a), lanczos_weight(fx.y + 2.0, _a)); \
    float2 w1 = float2(lanczos_weight(fx.x + 1.0, _a), lanczos_weight(fx.y + 1.0, _a)); \
    float2 w2 = float2(lanczos_weight(fx.x, _a), lanczos_weight(fx.y, _a)); \
    float2 w3 = float2(lanczos_weight(fx.x - 1.0, _a), lanczos_weight(fx.y - 1.0, _a)); \
    float2 w4 = float2(lanczos_weight(fx.x - 2.0, _a), lanczos_weight(fx.y - 2.0, _a)); \
    float2 w5 = float2(lanczos_weight(fx.x - 3.0, _a), lanczos_weight(fx.y - 3.0, _a)); \
    float2 w23 = w2 + w3; \
    float2 uvX0 = (nX - 2.0) / tex_size; \
    float2 uvXC = (nX + w3 / w23) / tex_size; \
    float2 uvX5 = uvX0 + 5.0 / tex_size; \
    float2 uvX1 = (nX - 1.0) / tex_size; \
    float2 uvX4 = (nX + 2.0) / tex_size; \
    T ret = 0; \
    float wsum = 0.0; \
    float w; \
    w = w0.x        * w0.y; ret += tex2Dlod(source, float4(uvX0.x, uvX0.y, 0, 0)).S * w; wsum += w; \
    w = w1.x        * w0.y; ret += tex2Dlod(source, float4(uvX1.x, uvX0.y, 0, 0)).S * w; wsum += w; \
    w = w23.x       * w0.y; ret += tex2Dlod(source, float4(uvXC.x, uvX0.y, 0, 0)).S * w; wsum += w; \
    w = w4.x        * w0.y; ret += tex2Dlod(source, float4(uvX4.x, uvX0.y, 0, 0)).S * w; wsum += w; \
    w = w5.x        * w0.y; ret += tex2Dlod(source, float4(uvX5.x, uvX0.y, 0, 0)).S * w; wsum += w; \
    w = w0.x        * w1.y; ret += tex2Dlod(source, float4(uvX0.x, uvX1.y, 0, 0)).S * w; wsum += w; \
    w = w1.x        * w1.y; ret += tex2Dlod(source, float4(uvX1.x, uvX1.y, 0, 0)).S * w; wsum += w; \
    w = w23.x       * w1.y; ret += tex2Dlod(source, float4(uvXC.x, uvX1.y, 0, 0)).S * w; wsum += w; \
    w = w4.x        * w1.y; ret += tex2Dlod(source, float4(uvX4.x, uvX1.y, 0, 0)).S * w; wsum += w; \
    w = w5.x        * w1.y; ret += tex2Dlod(source, float4(uvX5.x, uvX1.y, 0, 0)).S * w; wsum += w; \
    w = w0.x        * w23.y; ret += tex2Dlod(source, float4(uvX0.x, uvXC.y, 0, 0)).S * w; wsum += w; \
    w = w1.x        * w23.y; ret += tex2Dlod(source, float4(uvX1.x, uvXC.y, 0, 0)).S * w; wsum += w; \
    w = w23.x       * w23.y; ret += tex2Dlod(source, float4(uvXC.x, uvXC.y, 0, 0)).S * w; wsum += w; \
    w = w4.x        * w23.y; ret += tex2Dlod(source, float4(uvX4.x, uvXC.y, 0, 0)).S * w; wsum += w; \
    w = w5.x        * w23.y; ret += tex2Dlod(source, float4(uvX5.x, uvXC.y, 0, 0)).S * w; wsum += w; \
    w = w0.x        * w4.y; ret += tex2Dlod(source, float4(uvX0.x, uvX4.y, 0, 0)).S * w; wsum += w; \
    w = w1.x        * w4.y; ret += tex2Dlod(source, float4(uvX1.x, uvX4.y, 0, 0)).S * w; wsum += w; \
    w = w23.x       * w4.y; ret += tex2Dlod(source, float4(uvXC.x, uvX4.y, 0, 0)).S * w; wsum += w; \
    w = w4.x        * w4.y; ret += tex2Dlod(source, float4(uvX4.x, uvX4.y, 0, 0)).S * w; wsum += w; \
    w = w5.x        * w4.y; ret += tex2Dlod(source, float4(uvX5.x, uvX4.y, 0, 0)).S * w; wsum += w; \
    w = w0.x        * w5.y; ret += tex2Dlod(source, float4(uvX0.x, uvX5.y, 0, 0)).S * w; wsum += w; \
    w = w1.x        * w5.y; ret += tex2Dlod(source, float4(uvX1.x, uvX5.y, 0, 0)).S * w; wsum += w; \
    w = w23.x       * w5.y; ret += tex2Dlod(source, float4(uvXC.x, uvX5.y, 0, 0)).S * w; wsum += w; \
    w = w4.x        * w5.y; ret += tex2Dlod(source, float4(uvX4.x, uvX5.y, 0, 0)).S * w; wsum += w; \
    w = w5.x        * w5.y; ret += tex2Dlod(source, float4(uvX5.x, uvX5.y, 0, 0)).S * w; wsum += w; \
    return max(0, ret / max(wsum, 1e-8));

DEFINE_VARIANTS(sample_lanczos3_25tap, (sampler source, float2 texcoord), SAMPLE_LANCZOS3_25TAP)

#define SAMPLE_LANCZOS4_37TAP_FAST(T, S) \
    int2 tex_size = tex2Dsize(source, 0); \
    float2 pixel_coord = texcoord * tex_size; \
    float2 nX = floor(pixel_coord - 0.5) + 0.5; \
    float2 fx = pixel_coord - nX; \
    float _a = 4.0; \
    float2 w0 = float2(lanczos_weight(fx.x + 3.0, _a), lanczos_weight(fx.y + 3.0, _a)); \
    float2 w1 = float2(lanczos_weight(fx.x + 2.0, _a), lanczos_weight(fx.y + 2.0, _a)); \
    float2 w2 = float2(lanczos_weight(fx.x + 1.0, _a), lanczos_weight(fx.y + 1.0, _a)); \
    float2 w3 = float2(lanczos_weight(fx.x, _a), lanczos_weight(fx.y, _a)); \
    float2 w4 = float2(lanczos_weight(fx.x - 1.0, _a), lanczos_weight(fx.y - 1.0, _a)); \
    float2 w5 = float2(lanczos_weight(fx.x - 2.0, _a), lanczos_weight(fx.y - 2.0, _a)); \
    float2 w6 = float2(lanczos_weight(fx.x - 3.0, _a), lanczos_weight(fx.y - 3.0, _a)); \
    float2 w7 = float2(lanczos_weight(fx.x - 4.0, _a), lanczos_weight(fx.y - 4.0, _a)); \
    float2 w34 = w3 + w4; \
    float2 uvX0 = (nX - 3.0) / tex_size; \
    float2 uvXC = (nX + w4 / w34) / tex_size; \
    float2 uvX7 = uvX0 + 7.0 / tex_size; \
    float2 uvX1 = (nX - 2.0) / tex_size; \
    float2 uvX2 = (nX - 1.0) / tex_size; \
    float2 uvX5 = (nX + 2.0) / tex_size; \
    float2 uvX6 = (nX + 3.0) / tex_size; \
    T ret = 0; \
    float wsum = 0.0; \
    float w; \
    w = w2.x        * w0.y; ret += tex2Dlod(source, float4(uvX2.x, uvX0.y, 0, 0)).S * w; wsum += w; \
    w = w34.x       * w0.y; ret += tex2Dlod(source, float4(uvXC.x, uvX0.y, 0, 0)).S * w; wsum += w; \
    w = w5.x        * w0.y; ret += tex2Dlod(source, float4(uvX5.x, uvX0.y, 0, 0)).S * w; wsum += w; \
    w = w1.x        * w1.y; ret += tex2Dlod(source, float4(uvX1.x, uvX1.y, 0, 0)).S * w; wsum += w; \
    w = w2.x        * w1.y; ret += tex2Dlod(source, float4(uvX2.x, uvX1.y, 0, 0)).S * w; wsum += w; \
    w = w34.x       * w1.y; ret += tex2Dlod(source, float4(uvXC.x, uvX1.y, 0, 0)).S * w; wsum += w; \
    w = w5.x        * w1.y; ret += tex2Dlod(source, float4(uvX5.x, uvX1.y, 0, 0)).S * w; wsum += w; \
    w = w6.x        * w1.y; ret += tex2Dlod(source, float4(uvX6.x, uvX1.y, 0, 0)).S * w; wsum += w; \
    w = w0.x        * w2.y; ret += tex2Dlod(source, float4(uvX0.x, uvX2.y, 0, 0)).S * w; wsum += w; \
    w = w1.x        * w2.y; ret += tex2Dlod(source, float4(uvX1.x, uvX2.y, 0, 0)).S * w; wsum += w; \
    w = w2.x        * w2.y; ret += tex2Dlod(source, float4(uvX2.x, uvX2.y, 0, 0)).S * w; wsum += w; \
    w = w34.x       * w2.y; ret += tex2Dlod(source, float4(uvXC.x, uvX2.y, 0, 0)).S * w; wsum += w; \
    w = w5.x        * w2.y; ret += tex2Dlod(source, float4(uvX5.x, uvX2.y, 0, 0)).S * w; wsum += w; \
    w = w6.x        * w2.y; ret += tex2Dlod(source, float4(uvX6.x, uvX2.y, 0, 0)).S * w; wsum += w; \
    w = w7.x        * w2.y; ret += tex2Dlod(source, float4(uvX7.x, uvX2.y, 0, 0)).S * w; wsum += w; \
    w = w0.x        * w34.y; ret += tex2Dlod(source, float4(uvX0.x, uvXC.y, 0, 0)).S * w; wsum += w; \
    w = w1.x        * w34.y; ret += tex2Dlod(source, float4(uvX1.x, uvXC.y, 0, 0)).S * w; wsum += w; \
    w = w2.x        * w34.y; ret += tex2Dlod(source, float4(uvX2.x, uvXC.y, 0, 0)).S * w; wsum += w; \
    w = w34.x       * w34.y; ret += tex2Dlod(source, float4(uvXC.x, uvXC.y, 0, 0)).S * w; wsum += w; \
    w = w5.x        * w34.y; ret += tex2Dlod(source, float4(uvX5.x, uvXC.y, 0, 0)).S * w; wsum += w; \
    w = w6.x        * w34.y; ret += tex2Dlod(source, float4(uvX6.x, uvXC.y, 0, 0)).S * w; wsum += w; \
    w = w7.x        * w34.y; ret += tex2Dlod(source, float4(uvX7.x, uvXC.y, 0, 0)).S * w; wsum += w; \
    w = w0.x        * w5.y; ret += tex2Dlod(source, float4(uvX0.x, uvX5.y, 0, 0)).S * w; wsum += w; \
    w = w1.x        * w5.y; ret += tex2Dlod(source, float4(uvX1.x, uvX5.y, 0, 0)).S * w; wsum += w; \
    w = w2.x        * w5.y; ret += tex2Dlod(source, float4(uvX2.x, uvX5.y, 0, 0)).S * w; wsum += w; \
    w = w34.x       * w5.y; ret += tex2Dlod(source, float4(uvXC.x, uvX5.y, 0, 0)).S * w; wsum += w; \
    w = w5.x        * w5.y; ret += tex2Dlod(source, float4(uvX5.x, uvX5.y, 0, 0)).S * w; wsum += w; \
    w = w6.x        * w5.y; ret += tex2Dlod(source, float4(uvX6.x, uvX5.y, 0, 0)).S * w; wsum += w; \
    w = w7.x        * w5.y; ret += tex2Dlod(source, float4(uvX7.x, uvX5.y, 0, 0)).S * w; wsum += w; \
    w = w1.x        * w6.y; ret += tex2Dlod(source, float4(uvX1.x, uvX6.y, 0, 0)).S * w; wsum += w; \
    w = w2.x        * w6.y; ret += tex2Dlod(source, float4(uvX2.x, uvX6.y, 0, 0)).S * w; wsum += w; \
    w = w34.x       * w6.y; ret += tex2Dlod(source, float4(uvXC.x, uvX6.y, 0, 0)).S * w; wsum += w; \
    w = w5.x        * w6.y; ret += tex2Dlod(source, float4(uvX5.x, uvX6.y, 0, 0)).S * w; wsum += w; \
    w = w6.x        * w6.y; ret += tex2Dlod(source, float4(uvX6.x, uvX6.y, 0, 0)).S * w; wsum += w; \
    w = w2.x        * w7.y; ret += tex2Dlod(source, float4(uvX2.x, uvX7.y, 0, 0)).S * w; wsum += w; \
    w = w34.x       * w7.y; ret += tex2Dlod(source, float4(uvXC.x, uvX7.y, 0, 0)).S * w; wsum += w; \
    w = w5.x        * w7.y; ret += tex2Dlod(source, float4(uvX5.x, uvX7.y, 0, 0)).S * w; wsum += w; \
    return max(0, ret / max(wsum, 1e-8));

DEFINE_VARIANTS(sample_lanczos4_37tap_fast, (sampler source, float2 texcoord), SAMPLE_LANCZOS4_37TAP_FAST)

#define SAMPLE_LANCZOS4_49TAP(T, S) \
    int2 tex_size = tex2Dsize(source, 0); \
    float2 pixel_coord = texcoord * tex_size; \
    float2 nX = floor(pixel_coord - 0.5) + 0.5; \
    float2 fx = pixel_coord - nX; \
    float _a = 4.0; \
    float2 w0 = float2(lanczos_weight(fx.x + 3.0, _a), lanczos_weight(fx.y + 3.0, _a)); \
    float2 w1 = float2(lanczos_weight(fx.x + 2.0, _a), lanczos_weight(fx.y + 2.0, _a)); \
    float2 w2 = float2(lanczos_weight(fx.x + 1.0, _a), lanczos_weight(fx.y + 1.0, _a)); \
    float2 w3 = float2(lanczos_weight(fx.x, _a), lanczos_weight(fx.y, _a)); \
    float2 w4 = float2(lanczos_weight(fx.x - 1.0, _a), lanczos_weight(fx.y - 1.0, _a)); \
    float2 w5 = float2(lanczos_weight(fx.x - 2.0, _a), lanczos_weight(fx.y - 2.0, _a)); \
    float2 w6 = float2(lanczos_weight(fx.x - 3.0, _a), lanczos_weight(fx.y - 3.0, _a)); \
    float2 w7 = float2(lanczos_weight(fx.x - 4.0, _a), lanczos_weight(fx.y - 4.0, _a)); \
    float2 w34 = w3 + w4; \
    float2 uvX0 = (nX - 3.0) / tex_size; \
    float2 uvXC = (nX + w4 / w34) / tex_size; \
    float2 uvX7 = uvX0 + 7.0 / tex_size; \
    float2 uvX1 = (nX - 2.0) / tex_size; \
    float2 uvX2 = (nX - 1.0) / tex_size; \
    float2 uvX5 = (nX + 2.0) / tex_size; \
    float2 uvX6 = (nX + 3.0) / tex_size; \
    T ret = 0; \
    float wsum = 0.0; \
    float w; \
    w = w0.x        * w0.y; ret += tex2Dlod(source, float4(uvX0.x, uvX0.y, 0, 0)).S * w; wsum += w; \
    w = w1.x        * w0.y; ret += tex2Dlod(source, float4(uvX1.x, uvX0.y, 0, 0)).S * w; wsum += w; \
    w = w2.x        * w0.y; ret += tex2Dlod(source, float4(uvX2.x, uvX0.y, 0, 0)).S * w; wsum += w; \
    w = w34.x       * w0.y; ret += tex2Dlod(source, float4(uvXC.x, uvX0.y, 0, 0)).S * w; wsum += w; \
    w = w5.x        * w0.y; ret += tex2Dlod(source, float4(uvX5.x, uvX0.y, 0, 0)).S * w; wsum += w; \
    w = w6.x        * w0.y; ret += tex2Dlod(source, float4(uvX6.x, uvX0.y, 0, 0)).S * w; wsum += w; \
    w = w7.x        * w0.y; ret += tex2Dlod(source, float4(uvX7.x, uvX0.y, 0, 0)).S * w; wsum += w; \
    w = w0.x        * w1.y; ret += tex2Dlod(source, float4(uvX0.x, uvX1.y, 0, 0)).S * w; wsum += w; \
    w = w1.x        * w1.y; ret += tex2Dlod(source, float4(uvX1.x, uvX1.y, 0, 0)).S * w; wsum += w; \
    w = w2.x        * w1.y; ret += tex2Dlod(source, float4(uvX2.x, uvX1.y, 0, 0)).S * w; wsum += w; \
    w = w34.x       * w1.y; ret += tex2Dlod(source, float4(uvXC.x, uvX1.y, 0, 0)).S * w; wsum += w; \
    w = w5.x        * w1.y; ret += tex2Dlod(source, float4(uvX5.x, uvX1.y, 0, 0)).S * w; wsum += w; \
    w = w6.x        * w1.y; ret += tex2Dlod(source, float4(uvX6.x, uvX1.y, 0, 0)).S * w; wsum += w; \
    w = w7.x        * w1.y; ret += tex2Dlod(source, float4(uvX7.x, uvX1.y, 0, 0)).S * w; wsum += w; \
    w = w0.x        * w2.y; ret += tex2Dlod(source, float4(uvX0.x, uvX2.y, 0, 0)).S * w; wsum += w; \
    w = w1.x        * w2.y; ret += tex2Dlod(source, float4(uvX1.x, uvX2.y, 0, 0)).S * w; wsum += w; \
    w = w2.x        * w2.y; ret += tex2Dlod(source, float4(uvX2.x, uvX2.y, 0, 0)).S * w; wsum += w; \
    w = w34.x       * w2.y; ret += tex2Dlod(source, float4(uvXC.x, uvX2.y, 0, 0)).S * w; wsum += w; \
    w = w5.x        * w2.y; ret += tex2Dlod(source, float4(uvX5.x, uvX2.y, 0, 0)).S * w; wsum += w; \
    w = w6.x        * w2.y; ret += tex2Dlod(source, float4(uvX6.x, uvX2.y, 0, 0)).S * w; wsum += w; \
    w = w7.x        * w2.y; ret += tex2Dlod(source, float4(uvX7.x, uvX2.y, 0, 0)).S * w; wsum += w; \
    w = w0.x        * w34.y; ret += tex2Dlod(source, float4(uvX0.x, uvXC.y, 0, 0)).S * w; wsum += w; \
    w = w1.x        * w34.y; ret += tex2Dlod(source, float4(uvX1.x, uvXC.y, 0, 0)).S * w; wsum += w; \
    w = w2.x        * w34.y; ret += tex2Dlod(source, float4(uvX2.x, uvXC.y, 0, 0)).S * w; wsum += w; \
    w = w34.x       * w34.y; ret += tex2Dlod(source, float4(uvXC.x, uvXC.y, 0, 0)).S * w; wsum += w; \
    w = w5.x        * w34.y; ret += tex2Dlod(source, float4(uvX5.x, uvXC.y, 0, 0)).S * w; wsum += w; \
    w = w6.x        * w34.y; ret += tex2Dlod(source, float4(uvX6.x, uvXC.y, 0, 0)).S * w; wsum += w; \
    w = w7.x        * w34.y; ret += tex2Dlod(source, float4(uvX7.x, uvXC.y, 0, 0)).S * w; wsum += w; \
    w = w0.x        * w5.y; ret += tex2Dlod(source, float4(uvX0.x, uvX5.y, 0, 0)).S * w; wsum += w; \
    w = w1.x        * w5.y; ret += tex2Dlod(source, float4(uvX1.x, uvX5.y, 0, 0)).S * w; wsum += w; \
    w = w2.x        * w5.y; ret += tex2Dlod(source, float4(uvX2.x, uvX5.y, 0, 0)).S * w; wsum += w; \
    w = w34.x       * w5.y; ret += tex2Dlod(source, float4(uvXC.x, uvX5.y, 0, 0)).S * w; wsum += w; \
    w = w5.x        * w5.y; ret += tex2Dlod(source, float4(uvX5.x, uvX5.y, 0, 0)).S * w; wsum += w; \
    w = w6.x        * w5.y; ret += tex2Dlod(source, float4(uvX6.x, uvX5.y, 0, 0)).S * w; wsum += w; \
    w = w7.x        * w5.y; ret += tex2Dlod(source, float4(uvX7.x, uvX5.y, 0, 0)).S * w; wsum += w; \
    w = w0.x        * w6.y; ret += tex2Dlod(source, float4(uvX0.x, uvX6.y, 0, 0)).S * w; wsum += w; \
    w = w1.x        * w6.y; ret += tex2Dlod(source, float4(uvX1.x, uvX6.y, 0, 0)).S * w; wsum += w; \
    w = w2.x        * w6.y; ret += tex2Dlod(source, float4(uvX2.x, uvX6.y, 0, 0)).S * w; wsum += w; \
    w = w34.x       * w6.y; ret += tex2Dlod(source, float4(uvXC.x, uvX6.y, 0, 0)).S * w; wsum += w; \
    w = w5.x        * w6.y; ret += tex2Dlod(source, float4(uvX5.x, uvX6.y, 0, 0)).S * w; wsum += w; \
    w = w6.x        * w6.y; ret += tex2Dlod(source, float4(uvX6.x, uvX6.y, 0, 0)).S * w; wsum += w; \
    w = w7.x        * w6.y; ret += tex2Dlod(source, float4(uvX7.x, uvX6.y, 0, 0)).S * w; wsum += w; \
    w = w0.x        * w7.y; ret += tex2Dlod(source, float4(uvX0.x, uvX7.y, 0, 0)).S * w; wsum += w; \
    w = w1.x        * w7.y; ret += tex2Dlod(source, float4(uvX1.x, uvX7.y, 0, 0)).S * w; wsum += w; \
    w = w2.x        * w7.y; ret += tex2Dlod(source, float4(uvX2.x, uvX7.y, 0, 0)).S * w; wsum += w; \
    w = w34.x       * w7.y; ret += tex2Dlod(source, float4(uvXC.x, uvX7.y, 0, 0)).S * w; wsum += w; \
    w = w5.x        * w7.y; ret += tex2Dlod(source, float4(uvX5.x, uvX7.y, 0, 0)).S * w; wsum += w; \
    w = w6.x        * w7.y; ret += tex2Dlod(source, float4(uvX6.x, uvX7.y, 0, 0)).S * w; wsum += w; \
    w = w7.x        * w7.y; ret += tex2Dlod(source, float4(uvX7.x, uvX7.y, 0, 0)).S * w; wsum += w; \
    return max(0, ret / max(wsum, 1e-8));

DEFINE_VARIANTS(sample_lanczos4_49tap, (sampler source, float2 texcoord), SAMPLE_LANCZOS4_49TAP)
DEFINE_VARIANTS(sample_lanczos2_9tap, (sampler source, float2 texcoord), SAMPLE_LANCZOS2_9TAP)

#define SAMPLE_LANCZOS2_NTAP(T, S) SAMPLE_LANCZOS2_9TAP(T, S)

#define SAMPLE_LANCZOS2(T, S) SAMPLE_LANCZOS2_NTAP(T, S)
#define SAMPLE_LANCZOS3(T, S) SAMPLE_LANCZOS3_25TAP(T, S)
#define SAMPLE_LANCZOS4(T, S) SAMPLE_LANCZOS4_49TAP(T, S)

DEFINE_VARIANTS(sample_lanczos2, (sampler source, float2 texcoord), SAMPLE_LANCZOS2)
DEFINE_VARIANTS(sample_lanczos3, (sampler source, float2 texcoord), SAMPLE_LANCZOS3)
DEFINE_VARIANTS(sample_lanczos4, (sampler source, float2 texcoord), SAMPLE_LANCZOS4)





/* SHADES_LICENSE_ATTRIBUTION The next 209 lines of code below were ported from, or are more than functionally equivalent to, FidelityFX FSR EASU by AMD and are licensed under MIT License (https://opensource.org/license/mit) only; the remainder of this file is not. */

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


