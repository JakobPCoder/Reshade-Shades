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




namespace EASU
{

void Con(
    out float4 con0, out float4 con1, out float4 con2, out float4 con3,
    float2 inputViewportInPixels,
    float2 inputSizeInPixels,
    float2 outputSizeInPixels
)
{
    con0 = float4(
        inputViewportInPixels / outputSizeInPixels,
        -0.5, -0.5
    );

    con1 = float4(1,  1,  1, -1) / inputSizeInPixels.xyxy;

    con2 = float4(-1, 2,  1,  2) / inputSizeInPixels.xyxy;
    con3 = float4( 0, 4,  0,  0) / inputSizeInPixels.xyxy;
}


void Tap(
    inout float3 aC, inout float aW,
    float2 off, float2 dir, float2 len,
    float lob, float clp,
    float3 c
)
{
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


void Set(
    inout float2 dir, inout float len,
    float w,
    float lA, float lB, float lC, float lD, float lE
)
{
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


float3 Filter(
    sampler2D samp,
    float2 ip,
    float4 con0, float4 con1, float4 con2, float4 con3
)
{
    float2 pp = ip * con0.xy + con0.zw;
    float2 fp = floor(pp);
    pp -= fp;

    float2 p0 = fp * con1.xy + con1.zw;
    float2 p1 = p0 + con2.xy;
    float2 p2 = p0 + con2.zw;
    float2 p3 = p0 + con3.xy;
    float4 off = float4(-0.5, 0.5, -0.5, 0.5) * con1.xxyy;


    float3 bC = tex2Dlod(samp, float4(p0 + off.xw, 0, 0)).rgb; float bL = bC.g + 0.5 * (bC.r + bC.b);
    float3 cC = tex2Dlod(samp, float4(p0 + off.yw, 0, 0)).rgb; float cL = cC.g + 0.5 * (cC.r + cC.b);
    float3 iC = tex2Dlod(samp, float4(p1 + off.xw, 0, 0)).rgb; float iL = iC.g + 0.5 * (iC.r + iC.b);
    float3 jC = tex2Dlod(samp, float4(p1 + off.yw, 0, 0)).rgb; float jL = jC.g + 0.5 * (jC.r + jC.b);
    float3 fC = tex2Dlod(samp, float4(p1 + off.yz, 0, 0)).rgb; float fL = fC.g + 0.5 * (fC.r + fC.b);
    float3 eC = tex2Dlod(samp, float4(p1 + off.xz, 0, 0)).rgb; float eL = eC.g + 0.5 * (eC.r + eC.b);
    float3 kC = tex2Dlod(samp, float4(p2 + off.xw, 0, 0)).rgb; float kL = kC.g + 0.5 * (kC.r + kC.b);
    float3 lC = tex2Dlod(samp, float4(p2 + off.yw, 0, 0)).rgb; float lL = lC.g + 0.5 * (lC.r + lC.b);
    float3 hC = tex2Dlod(samp, float4(p2 + off.yz, 0, 0)).rgb; float hL = hC.g + 0.5 * (hC.r + hC.b);
    float3 gC = tex2Dlod(samp, float4(p2 + off.xz, 0, 0)).rgb; float gL = gC.g + 0.5 * (gC.r + gC.b);
    float3 oC = tex2Dlod(samp, float4(p3 + off.yz, 0, 0)).rgb; float oL = oC.g + 0.5 * (oC.r + oC.b);
    float3 nC = tex2Dlod(samp, float4(p3 + off.xz, 0, 0)).rgb; float nL = nC.g + 0.5 * (nC.r + nC.b);

    float2 dir = 0;
    float  len = 0;
    Set(dir, len, (1.0 - pp.x) * (1.0 - pp.y), bL, eL, fL, gL, jL);
    Set(dir, len,        pp.x  * (1.0 - pp.y), cL, fL, gL, hL, kL);
    Set(dir, len, (1.0 - pp.x) *        pp.y,  fL, iL, jL, kL, nL);
    Set(dir, len,        pp.x  *        pp.y,   gL, jL, kL, lL, oL);

    float2 dir2 = dir * dir;
    float dirR  = dir2.x + dir2.y;
    bool   zro  = dirR < (1.0 / 32768.0);
    dirR   = rsqrt(dirR);
    dirR   = zro ? 1.0 : dirR;
    dir.x  = zro ? 1.0 : dir.x;
    dir   *= dirR;

    len = len * 0.5;
    len *= len;

    float stretch = dot(dir, dir) / max(abs(dir.x), abs(dir.y));
    float2 len2   = float2(1.0 + (stretch - 1.0) * len, 1.0 - 0.5 * len);
    float  lob    = 0.5 - 0.29 * len;
    float  clp    = 1.0 / lob;

    float3 min4 = min(min(fC, gC), min(jC, kC));
    float3 max4 = max(max(fC, gC), max(jC, kC));

    float3 aC = 0;
    float  aW = 0;
    Tap(aC, aW, float2( 0,-1) - pp, dir, len2, lob, clp, bC);
    Tap(aC, aW, float2( 1,-1) - pp, dir, len2, lob, clp, cC);
    Tap(aC, aW, float2(-1, 1) - pp, dir, len2, lob, clp, iC);
    Tap(aC, aW, float2( 0, 1) - pp, dir, len2, lob, clp, jC);
    Tap(aC, aW, float2( 0, 0) - pp, dir, len2, lob, clp, fC);
    Tap(aC, aW, float2(-1, 0) - pp, dir, len2, lob, clp, eC);
    Tap(aC, aW, float2( 1, 1) - pp, dir, len2, lob, clp, kC);
    Tap(aC, aW, float2( 2, 1) - pp, dir, len2, lob, clp, lC);
    Tap(aC, aW, float2( 2, 0) - pp, dir, len2, lob, clp, hC);
    Tap(aC, aW, float2( 1, 0) - pp, dir, len2, lob, clp, gC);
    Tap(aC, aW, float2( 1, 2) - pp, dir, len2, lob, clp, oC);
    Tap(aC, aW, float2( 0, 2) - pp, dir, len2, lob, clp, nC);

    return min(max4, max(min4, aC / aW));
}

}


float4 sample_fsr1_p(sampler2D s, float2 uv, int2 srcSize, int2 dstSize)
{
    float2 srcF = float2(srcSize);
    float2 dstF = float2(dstSize);

    float4 con0, con1, con2, con3;
    EASU::Con(con0, con1, con2, con3, srcF, srcF, dstF);

    float2 ip = uv * dstF;
    return float4(EASU::Filter(s, ip, con0, con1, con2, con3), 1.0);
}


float4 sample_fsr1(sampler2D s, float2 uv, int2 dstSize)
{
    return sample_fsr1_p(s, uv, tex2Dsize(s, 0), dstSize);
}
