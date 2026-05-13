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
    float y  = 0.299 * rgb.r + 0.587 * rgb.g + 0.114 * rgb.b;
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
