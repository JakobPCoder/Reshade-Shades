/*=============================================================================
    helpers
    Shader helper utilities and color space conversions for Shades shaders.
    Copyright, Jakob Wapenhensch
    License: CC BY-NC 4.0 (https://creativecommons.org/licenses/by-nc/4.0/)
    https://creativecommons.org/licenses/by-nc/4.0/legalcode
=============================================================================*/

#include "macros.fxh"

#define COPY(T, S) \
    return tex2Dlod(source, float4(texcoord, 0, 0)).S;

DEFINE_VARIANTS(copy, (sampler source, float2 texcoord), COPY)



float3 rgb_to_ycbcr(float3 rgb)
{
    float y  = dot(rgb, float3(0.299, 0.587, 0.114));
    float cb = (rgb.b - y) * 0.565;
    float cr = (rgb.r - y) * 0.713;
    return float3(y, cb, cr);
}

float3 ycbcr_to_rgb(float3 ycbcr)
{
    return float3(
        ycbcr.x + 1.403 * ycbcr.z,
        ycbcr.x - 0.344 * ycbcr.y - 0.714 * ycbcr.z,
        ycbcr.x + 1.770 * ycbcr.y
    );
}

float3 rgb_to_ycbcr_norm(float3 rgb)
{
    float3 ycc = rgb_to_ycbcr(rgb);
    return float3(ycc.x, ycc.y + 0.5, ycc.z + 0.5);
}

float3 ycbcr_norm_to_rgb(float3 ycbcr_norm)
{
    return ycbcr_to_rgb(float3(ycbcr_norm.x, ycbcr_norm.y - 0.5, ycbcr_norm.z - 0.5));
}



float3 rgb_to_ycocg(float3 rgb)
{
    float y  = dot(rgb, float3(0.25, 0.5, 0.25));
    float co = dot(rgb, float3(0.5, 0.0, -0.5));
    float cg = dot(rgb, float3(-0.25, 0.5, -0.25));
    return float3(y, co, cg);
}

float3 ycocg_to_rgb(float3 ycocg)
{
    return float3(
        ycocg.x + ycocg.y - ycocg.z,
        ycocg.x + ycocg.z,
        ycocg.x - ycocg.y - ycocg.z
    );
}

float3 rgb_to_ycocg_norm(float3 rgb)
{
    float3 ycc = rgb_to_ycocg(rgb);
    return float3(ycc.x, ycc.y + 0.5, ycc.z + 0.5);
}

float3 ycocg_norm_to_rgb(float3 ycocg_norm)
{
    return ycocg_to_rgb(float3(ycocg_norm.x, ycocg_norm.y - 0.5, ycocg_norm.z - 0.5));
}


/* SHADES_LICENSE_ATTRIBUTION The next 39 lines of code below were ported from, or are more than functionally equivalent to, FidelityFX FSR RCAS by AMD and are licensed under MIT License (https://opensource.org/license/mit) only; the remainder of this file is not. */

#define FSR_RCAS_LIMIT (0.25 - (1.0 / 16.0))

float4 sample_rcas(sampler2D s, float2 uv, float sharpness)
{
    float2 texel = rcp(float2(tex2Dsize(s, 0)));

    float3 b = tex2Dlod(s, float4(uv + float2( 0,-1)*texel, 0,0)).rgb;
    float3 d = tex2Dlod(s, float4(uv + float2(-1, 0)*texel, 0,0)).rgb;
    float3 e = tex2Dlod(s, float4(uv,                        0,0)).rgb;
    float3 f = tex2Dlod(s, float4(uv + float2( 1, 0)*texel, 0,0)).rgb;
    float3 h = tex2Dlod(s, float4(uv + float2( 0, 1)*texel, 0,0)).rgb;

    float bL = b.g + 0.5*(b.r+b.b);
    float dL = d.g + 0.5*(d.r+d.b);
    float eL = e.g + 0.5*(e.r+e.b);
    float fL = f.g + 0.5*(f.r+f.b);
    float hL = h.g + 0.5*(h.r+h.b);

    float nz = 0.25*(bL+dL+fL+hL) - eL;
    nz = clamp(
        abs(nz) / (max(max(bL,dL),max(eL,max(fL,hL))) - min(min(bL,dL),min(eL,min(fL,hL)))),
        0.0, 1.0
    );
    nz = 1.0 - 0.5*nz;

    float3 mn4 = min(b, min(f, h));
    float3 mx4 = max(b, max(f, h));

    float2 peakC   = float2(1.0, -4.0);
    float3 hitMin  = mn4 / (4.0 * mx4);
    float3 hitMax  = (peakC.x - mx4) / (4.0 * mn4 + peakC.y);
    float3 lobeRGB = max(-hitMin, hitMax);
    float  lobe    = max(-FSR_RCAS_LIMIT, min(max(lobeRGB.r, max(lobeRGB.g, lobeRGB.b)), 0.0))
                     * exp2(-sharpness);

    lobe *= nz;

    return float4((lobe*(b+d+f+h) + e) / (4.0*lobe + 1.0), 1.0);
}



