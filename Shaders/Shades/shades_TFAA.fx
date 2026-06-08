/*=============================================================================
    TFAA (2.0.2)
    Temporal Filter Anti-Aliasing Shader
    Copyright, Jakob Wapenhensch
    License: CC BY-NC-ND 4.0 (https://creativecommons.org/licenses/by-nc-nd/4.0/)
    https://creativecommons.org/licenses/by-nc-nd/4.0/legalcode
=============================================================================*/


#include "ReShadeUI.fxh"
#include "ReShade.fxh"
#include "shades_samplers.fxh"
#include "shades_helpers.fxh"


#ifndef TFAA_SAMPLING_METHOD
	#define TFAA_SAMPLING_METHOD 3
#endif

#ifndef TFAA_RECTIFY_COLOR_SPACE
	#define TFAA_RECTIFY_COLOR_SPACE 2
#endif

#ifndef TFAA_RECTIFY_OP
	#define TFAA_RECTIFY_OP 4
#endif

#ifndef TFAA_RECTIFY_SHAPE
	#define TFAA_RECTIFY_SHAPE 1
#endif

#ifndef TFAA_MOTION_SOURCE
	#define TFAA_MOTION_SOURCE 0
#endif

#ifndef UI_DEBUG
	#define UI_DEBUG 0
#endif

#if TFAA_RECTIFY_SHAPE == 3
	#define TFAA_KDOP_AXIS_LIMIT_BY_SHAPE 13
#elif TFAA_RECTIFY_SHAPE == 2
	#define TFAA_KDOP_AXIS_LIMIT_BY_SHAPE 9
#elif TFAA_RECTIFY_SHAPE == 1
	#define TFAA_KDOP_AXIS_LIMIT_BY_SHAPE 7
#else
	#define TFAA_KDOP_AXIS_LIMIT_BY_SHAPE 0
#endif

#if TFAA_RECTIFY_OP == 0
	#define TFAA_KDOP_AXIS_LIMIT 0
#else
	#define TFAA_KDOP_AXIS_LIMIT TFAA_KDOP_AXIS_LIMIT_BY_SHAPE
#endif

#if TFAA_KDOP_AXIS_LIMIT > 0
#define TFAA_NEED_KDOP_SLABS 1
#else
#define TFAA_NEED_KDOP_SLABS 0
#endif

#if TFAA_NEED_KDOP_SLABS
    #define TFAA_INV_SQRT3 0.57735027
    #define TFAA_INV_SQRT2 0.70710678

    struct KDOPSlabs
    {
#if TFAA_RECTIFY_SHAPE == 1 || TFAA_RECTIFY_SHAPE == 3
        float4 diagMin;
        float4 diagMax;
#endif
#if TFAA_RECTIFY_SHAPE == 2 || TFAA_RECTIFY_SHAPE == 3
        float4 edge1Min;
        float4 edge1Max;
        float2 edge2Min;
        float2 edge2Max;
#endif
    };
#endif


#if TFAA_RECTIFY_COLOR_SPACE == 0
	#define TFAA_RGB_TO_RECTIFY(rgb) (rgb)
	#define TFAA_RECTIFY_TO_RGB(c) (c)
#elif TFAA_RECTIFY_COLOR_SPACE == 2
	#define TFAA_RGB_TO_RECTIFY(rgb) rgb_to_ycocg_norm(rgb)
	#define TFAA_RECTIFY_TO_RGB(c) ycocg_norm_to_rgb(c)
#else
	#define TFAA_RGB_TO_RECTIFY(rgb) rgb_to_ycbcr_norm(rgb)
	#define TFAA_RECTIFY_TO_RGB(c) ycbcr_norm_to_rgb(c)
#endif


uniform float UI_TEMPORAL_FILTER_STRENGTH <
    ui_type    = "slider";
    ui_min     = 0.0;
    ui_max     = 1.0;
    ui_step    = 0.01;
    ui_label   = "Temporal Filter Strength";
    ui_category= "Temporal Filter";
    ui_tooltip = "Strength of the temporal filter.";
> = 0.5;

uniform float UI_ADAPTIVE_SHARPEN <
    ui_type    = "slider";
    ui_min     = 0.0;
    ui_max     = 1.0;
    ui_step    = 0.01;
    ui_label   = "Adaptive Sharpening";
    ui_category= "Temporal Filter";
    ui_tooltip = "Amount of adaptive sharpening applied to cancel out temporal blurring where necessary.";
> = 0.5;

uniform float UI_POST_SHARPEN <
    ui_type    = "slider";
    ui_min     = 0.0;
    ui_max     = 1.0;
    ui_step    = 0.01;
    ui_label   = "Post Sharpening";
    ui_category= "Temporal Filter";
    ui_tooltip = "Amount of post-sharpening applied to the whole image.";
> = 0.0;


#if UI_DEBUG

uniform bool UI_CLAMPING <
    ui_type    = "checkbox";
    ui_label   = "Enable Color Rectification";
    ui_tooltip = "When enabled, uses TFAA_RECTIFY_OP and TFAA_RECTIFY_SHAPE from the preprocessor. CLAMP (op 0) always uses AABB only; shape affects CLIP ops (1–4) only.";
    ui_category= "Debug";
> = true;

uniform bool UI_DEPTH_REJECTION <
    ui_type    = "checkbox";
    ui_label   = "Enable Depth Rejection";
    ui_tooltip = "Toggle depth rejection on and off";
    ui_category= "Debug";
> = true;

uniform int UI_DEBUG_MODE <
	ui_type = "combo";
    ui_label = "DEBUG MODE";
	ui_items = "None\0Weight\0Sharp\0Occlusion\0";
	ui_tooltip = "";
    ui_category = "Debug";
> = 0;

#endif



texture texInCur : COLOR;
sampler smpInCur {
    Texture   = texInCur;
    AddressU  = Clamp;
    AddressV  = Clamp;
    MipFilter = Linear;
    MinFilter = Linear;
    MagFilter = Linear;
};

texture texInCurBackup < pooled = true; > {
    Width   = BUFFER_WIDTH;
    Height  = BUFFER_HEIGHT;
    Format  = RGBA8;
};

sampler smpInCurBackup {
    Texture   = texInCurBackup;
    AddressU  = Clamp;
    AddressV  = Clamp;
    MipFilter = Linear;
    MinFilter = Linear;
    MagFilter = Linear;
};

texture texExpColor < pooled = true; > {
    Width   = BUFFER_WIDTH;
    Height  = BUFFER_HEIGHT;
    Format  = RGBA16F;
};

sampler smpExpColor {
    Texture   = texExpColor;
    AddressU  = Clamp;
    AddressV  = Clamp;
    MipFilter = Linear;
    MinFilter = Linear;
    MagFilter = Linear;
};

texture texExpColorBackup < pooled = true; > {
    Width   = BUFFER_WIDTH;
    Height  = BUFFER_HEIGHT;
    Format  = RGBA16F;
};

sampler smpExpColorBackup {
    Texture   = texExpColorBackup;
    AddressU  = Clamp;
    AddressV  = Clamp;
    MipFilter = Linear;
    MinFilter = Linear;
    MagFilter = Linear;
};

texture texDepthBackup < pooled = true; > {
    Width   = BUFFER_WIDTH;
    Height  = BUFFER_HEIGHT;
    Format  = R16f;
};

sampler smpDepthBackup {
    Texture   = texDepthBackup;
    AddressU  = Clamp;
    AddressV  = Clamp;
    MipFilter = Point;
    MinFilter = Point;
    MagFilter = Point;
};


float4 tex2Dlod(sampler s, float2 uv, float mip)
{
    return tex2Dlod(s, float4(uv, 0, mip));
}



float4 sampleHistory(sampler2D historySampler, float2 texcoord)
{
#if TFAA_SAMPLING_METHOD == 0
    return tex2Dlod(historySampler, texcoord, 0);
#elif TFAA_SAMPLING_METHOD == 1
    return sample_catmullrom_5tap_fast_rgba(historySampler, texcoord);
#elif TFAA_SAMPLING_METHOD == 2
    return sample_catmullrom_9tap_rgba(historySampler, texcoord);
#elif TFAA_SAMPLING_METHOD == 3
    return sample_lanczos2_5tap_fast_rgba(historySampler, texcoord);
#elif TFAA_SAMPLING_METHOD == 4
    return sample_lanczos2_9tap_rgba(historySampler, texcoord);
#elif TFAA_SAMPLING_METHOD == 5
    return sample_lanczos3_21tap_fast_rgba(historySampler, texcoord);
#elif TFAA_SAMPLING_METHOD == 6
    return sample_lanczos3_25tap_rgba(historySampler, texcoord);
#elif TFAA_SAMPLING_METHOD == 7
    return sample_lanczos4_37tap_fast_rgba(historySampler, texcoord);
#elif TFAA_SAMPLING_METHOD == 8
    return sample_lanczos4_49tap_rgba(historySampler, texcoord);
#elif TFAA_SAMPLING_METHOD == 9
    return sample_easu_same(historySampler, texcoord);
#else
    return sample_lanczos2_5tap_fast_rgba(historySampler, texcoord);
#endif
}

float3 ClipRayAABB(float3 history, float3 anchor, float3 bMin, float3 bMax)
{
    float3 dir = history - anchor;
    float3 edge = (dir > 0.0) ? (bMax - anchor) : (bMin - anchor);

    float3 dirSafe = (abs(dir) < 1e-7) ? 1.0 : dir;
    float3 t = (abs(dir) < 1e-7) ? 1.0 : saturate(edge / dirSafe);

    float clipRatio = min(t.x, min(t.y, t.z));
    return anchor + dir * clipRatio;
}

#if TFAA_NEED_KDOP_SLABS

#if TFAA_RECTIFY_SHAPE == 1 || TFAA_RECTIFY_SHAPE == 3
float4 ProjectDiag(float3 c)
{
    float x_plus_z = c.x + c.z;
    float x_minus_z = c.x - c.z;
    return float4(
        x_plus_z + c.y,
        x_plus_z - c.y,
        x_minus_z + c.y,
        x_minus_z - c.y
    ) * TFAA_INV_SQRT3;
}
#endif

#if TFAA_RECTIFY_SHAPE == 2 || TFAA_RECTIFY_SHAPE == 3
void ProjectEdge(float3 c, out float4 edge1, out float2 edge2)
{
    edge1 = float4(
        c.x + c.y,
        c.x - c.y,
        c.x + c.z,
        c.x - c.z
    ) * TFAA_INV_SQRT2;
    edge2 = float2(c.y + c.z, c.y - c.z) * TFAA_INV_SQRT2;
}
#endif

void InitKDOPSlabs(out KDOPSlabs slabs)
{
#if TFAA_RECTIFY_SHAPE == 1 || TFAA_RECTIFY_SHAPE == 3
    slabs.diagMin = 1e10;
    slabs.diagMax = -1e10;
#endif
#if TFAA_RECTIFY_SHAPE == 2 || TFAA_RECTIFY_SHAPE == 3
    slabs.edge1Min = 1e10;
    slabs.edge1Max = -1e10;
    slabs.edge2Min = 1e10;
    slabs.edge2Max = -1e10;
#endif
}

float3 ClipRayKDOP(float3 history, float3 anchor, float3 aabbMin, float3 aabbMax, KDOPSlabs slabs)
{
    float3 rayDir = history - anchor;
    float minT = 1.0;

    float3 edge = (rayDir > 0.0) ? (aabbMax - anchor) : (aabbMin - anchor);
    float3 dirSafe = (abs(rayDir) < 1e-7) ? 1.0 : rayDir;
    float3 t = (abs(rayDir) < 1e-7) ? 1.0 : saturate(edge / dirSafe);
    minT = min(minT, min(t.x, min(t.y, t.z)));

#if TFAA_RECTIFY_SHAPE == 1 || TFAA_RECTIFY_SHAPE == 3
    float4 diagDir = ProjectDiag(rayDir);
    float4 diagAnchor = ProjectDiag(anchor);
    float4 diagEdge = (diagDir > 0.0) ? (slabs.diagMax - diagAnchor) : (slabs.diagMin - diagAnchor);
    float4 diagDirSafe = (abs(diagDir) < 1e-7) ? 1.0 : diagDir;
    float4 diagT = (abs(diagDir) < 1e-7) ? 1.0 : saturate(diagEdge / diagDirSafe);
    minT = min(minT, min(min(diagT.x, diagT.y), min(diagT.z, diagT.w)));
#endif

#if TFAA_RECTIFY_SHAPE == 2 || TFAA_RECTIFY_SHAPE == 3
    float4 edge1Dir;
    float2 edge2Dir;
    ProjectEdge(rayDir, edge1Dir, edge2Dir);
    float4 edge1Anchor;
    float2 edge2Anchor;
    ProjectEdge(anchor, edge1Anchor, edge2Anchor);

    float4 edge1Edge = (edge1Dir > 0.0) ? (slabs.edge1Max - edge1Anchor) : (slabs.edge1Min - edge1Anchor);
    float4 edge1DirSafe = (abs(edge1Dir) < 1e-7) ? 1.0 : edge1Dir;
    float4 edge1T = (abs(edge1Dir) < 1e-7) ? 1.0 : saturate(edge1Edge / edge1DirSafe);
    minT = min(minT, min(min(edge1T.x, edge1T.y), min(edge1T.z, edge1T.w)));

    float2 edge2Edge = (edge2Dir > 0.0) ? (slabs.edge2Max - edge2Anchor) : (slabs.edge2Min - edge2Anchor);
    float2 edge2DirSafe = (abs(edge2Dir) < 1e-7) ? 1.0 : edge2Dir;
    float2 edge2T = (abs(edge2Dir) < 1e-7) ? 1.0 : saturate(edge2Edge / edge2DirSafe);
    minT = min(minT, min(edge2T.x, edge2T.y));
#endif

    return anchor + rayDir * minT;
}
#endif



#if TFAA_MOTION_SOURCE == 0
namespace Deferred
{
    texture MotionVectorsTex {
        Width  = BUFFER_WIDTH;
        Height = BUFFER_HEIGHT;
        Format = RG16F;
    };
    sampler sMotionVectorsTex {
        Texture = MotionVectorsTex;
    };

    float2 get_motion_launchpad(float2 uv)
    {
        return tex2Dlod(sMotionVectorsTex, uv, 0).xy;
    }
}
#endif

#if TFAA_MOTION_SOURCE == 1
namespace Kernel
{
    texture2D tFlow { Width = BUFFER_WIDTH / 8; Height = BUFFER_HEIGHT / 8; Format = RG16F; };
    sampler2D sFlow { Texture = tFlow; MagFilter = POINT; MinFilter = POINT; };

    float2 get_motion_lumenite(float2 uv)
    {
        return tex2Dlod(Kernel::sFlow, float4(uv, 0, 0)).xy;
    }
}
#endif

float2 get_motion(float2 uv)
{
#if TFAA_MOTION_SOURCE == 0
    return Deferred::get_motion_launchpad(uv);
#else
    return Kernel::get_motion_lumenite(uv);
#endif
}



float4 PassSaveCur(float4 position : SV_Position, float2 texcoord : TEXCOORD) : SV_Target0
{
    float depthOnly = ReShade::GetLinearizedDepth(texcoord);

    return float4(tex2Dlod(smpInCur, texcoord, 0).rgb, depthOnly);
}

float4 PassTemporalFilter(float4 position : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
    static const int samples = 9;

    static const float2 nOffsets[samples] = {
        float2(-1.0, -1.0), float2(0.0, -1.0), float2(1.0, -1.0),
        float2(-1.0,  0.0), float2(0.0,  0.0), float2(1.0,  0.0),
        float2(-1.0,  1.0), float2(0.0,  1.0), float2(1.0,  1.0)
    };

    float4 sampleCur = tex2Dlod(smpInCurBackup, texcoord, 0);
    float4 cvtColorCur = float4(TFAA_RGB_TO_RECTIFY(sampleCur.rgb), sampleCur.a);

    int closestDepthIndex = 4;

    float minNeighborDepth = 2;

    float3 minimumRectify = 1e10;
    float3 maximumRectify = -1e10;

#if TFAA_RECTIFY_OP == 2
    float3 neighborSum = 0;
#endif

#if TFAA_RECTIFY_OP == 1
    float3 cvtCache[samples];
#endif

#if TFAA_NEED_KDOP_SLABS
    KDOPSlabs slabs;
    InitKDOPSlabs(slabs);
#endif

    for (int i = 0; i < samples; i++)
    {
        float4 rgba = tex2Dlod(smpInCurBackup, texcoord + (nOffsets[i] * ReShade::PixelSize), 0);
        float3 cvtRgb = TFAA_RGB_TO_RECTIFY(rgba.rgb);

        if (rgba.a < minNeighborDepth)
            closestDepthIndex = i;
        minNeighborDepth = min(minNeighborDepth, rgba.a);

        minimumRectify = min(minimumRectify, cvtRgb);
        maximumRectify = max(maximumRectify, cvtRgb);

#if TFAA_RECTIFY_OP == 2
        neighborSum += cvtRgb;
#endif
#if TFAA_RECTIFY_OP == 1
        cvtCache[i] = cvtRgb;
#endif

#if TFAA_NEED_KDOP_SLABS
#if TFAA_RECTIFY_SHAPE == 1 || TFAA_RECTIFY_SHAPE == 3
        float4 diag = ProjectDiag(cvtRgb);
        slabs.diagMin = min(slabs.diagMin, diag);
        slabs.diagMax = max(slabs.diagMax, diag);
#endif
#if TFAA_RECTIFY_SHAPE == 2 || TFAA_RECTIFY_SHAPE == 3
        float4 edge1;
        float2 edge2;
        ProjectEdge(cvtRgb, edge1, edge2);
        slabs.edge1Min = min(slabs.edge1Min, edge1);
        slabs.edge1Max = max(slabs.edge1Max, edge1);
        slabs.edge2Min = min(slabs.edge2Min, edge2);
        slabs.edge2Max = max(slabs.edge2Max, edge2);
#endif
#endif
    }

    float2 motion = get_motion(texcoord + (nOffsets[closestDepthIndex] * ReShade::PixelSize));

    float2 lastSamplePos = texcoord + motion;

    float4 sampleExp = saturate(sampleHistory(smpExpColorBackup, lastSamplePos));
    float lastDepth = tex2Dlod(smpDepthBackup, lastSamplePos, 0).r;

    float3 sampleExpCvt = TFAA_RGB_TO_RECTIFY(sampleExp.rgb);

#if TFAA_RECTIFY_OP == 1
    float nearestDist = 1e10;
    float3 nearestAnchor = cvtColorCur.rgb;
    [unroll]
    for (int nc = 0; nc < samples; ++nc)
    {
        float d = length(cvtCache[nc] - sampleExpCvt);
        if (d < nearestDist)
        {
            nearestDist = d;
            nearestAnchor = cvtCache[nc];
        }
    }
#endif

    float localContrast = saturate(pow(length(maximumRectify - minimumRectify), 0.75));
    float speed         = length(motion);
    float speedFactor   = 1.0 - pow(saturate(speed * 10), 0.75);

    float depthDelta = saturate(minNeighborDepth - lastDepth);
    depthDelta = saturate(pow(depthDelta, 4) - 0.0000001);
    float depthMask =  saturate(1.0 - (depthDelta * 10000000));

#if UI_DEBUG
    if (!UI_DEPTH_REJECTION)
        depthMask = 1.0;
#endif

    float weight = lerp(0.5, 0.99, pow(UI_TEMPORAL_FILTER_STRENGTH, 0.5));
    weight = clamp(weight * speedFactor * saturate(localContrast + 0.75) * depthMask, 0.0, 0.99);

    float3 sampleExpClamped = sampleExp.rgb;

#if UI_DEBUG
    if (UI_CLAMPING)
#endif
    {
        float3 rectified;
        #if TFAA_RECTIFY_OP == 0
            rectified = clamp(sampleExpCvt, minimumRectify, maximumRectify);
        #else
            float3 rectifyAnchor;
            #if TFAA_RECTIFY_OP == 1
                rectifyAnchor = nearestAnchor;
            #elif TFAA_RECTIFY_OP == 2
                rectifyAnchor = neighborSum / float(samples);
            #elif TFAA_RECTIFY_OP == 3
                rectifyAnchor = (minimumRectify + maximumRectify) * 0.5;
            #else
                rectifyAnchor = cvtColorCur.rgb;
            #endif

            #if TFAA_NEED_KDOP_SLABS
                rectified = ClipRayKDOP(sampleExpCvt, rectifyAnchor, minimumRectify, maximumRectify, slabs);
            #else
                rectified = ClipRayAABB(sampleExpCvt, rectifyAnchor, minimumRectify, maximumRectify);
            #endif
        #endif
        sampleExpClamped = TFAA_RECTIFY_TO_RGB(rectified);
    }

    const static float correctionFactor = 2;

    float3 blendedColor = saturate(pow(lerp(pow(sampleCur.rgb, correctionFactor), pow(sampleExpClamped, correctionFactor), weight), (1.0 / correctionFactor)));

    float sharp = saturate(saturate(UI_TEMPORAL_FILTER_STRENGTH * pow(speed * 10, 0.5) * saturate(localContrast + 0.6) * depthMask) * 5);

    float3 return_value = blendedColor.rgb;

    #if UI_DEBUG
    switch (UI_DEBUG_MODE)
    {
        case 1:
            return_value = weight;
            break;
        case 2:
            return_value = sharp;
            break;
        case 3:
            return_value = depthMask;
            break;
        default:
            break;
    }
    #endif

    return float4(return_value, sharp);
}

void PassSavePost(float4 position : SV_Position, float2 texcoord : TEXCOORD, out float4 lastExpOut : SV_Target0, out float depthOnly : SV_Target1)
{
    lastExpOut = tex2Dlod(smpExpColor, texcoord, 0);

    depthOnly = ReShade::GetLinearizedDepth(texcoord);
}

float4 PassSharp(float4 position : SV_Position, float2 texcoord : TEXCOORD ) : SV_Target
{
    float4 center     = tex2Dlod(smpExpColor, texcoord, 0);
    float4 top        = tex2Dlod(smpExpColor, texcoord + (float2(0, -1) * ReShade::PixelSize), 0);
    float4 bottom     = tex2Dlod(smpExpColor, texcoord + (float2(0,  1) * ReShade::PixelSize), 0);
    float4 left       = tex2Dlod(smpExpColor, texcoord + (float2(-1, 0) * ReShade::PixelSize), 0);
    float4 right      = tex2Dlod(smpExpColor, texcoord + (float2(1,  0) * ReShade::PixelSize), 0);

    float4 maxBox = max(top, max(bottom, max(left, max(right, center))));
    float4 minBox = min(top, min(bottom, min(left, min(right, center))));

    float contrast = 0.7;
    float sharpAmount = saturate((maxBox.a * 20 * UI_ADAPTIVE_SHARPEN)) + (UI_POST_SHARPEN * 0.5);

    /* SHADES_LICENSE_ATTRIBUTION The next 4 lines of code below were ported from, or are more than functionally equivalent to, FidelityFX CAS by AMD and are licensed under MIT License (https://opensource.org/license/mit) only; the remainder of this file is not. */
    float4 crossWeight = -rcp(rsqrt(saturate(min(minBox, 1.0 - maxBox) * rcp(maxBox))) * (-3.0 * contrast + 8.0));
    float4 rcpWeight = rcp(4.0 * crossWeight + 1.0);
    float4 crossSumm = top + bottom + left + right;
    return lerp(center, saturate((crossSumm * crossWeight + center) * rcpWeight), sharpAmount);

}



technique TFAA
<
    ui_label = "TFAA";
    ui_tooltip =
		"- Temporal Filter Anti-Aliasing -\n"
		"Temporal component of TAA to use with (after) spatial anti-aliasing.\n"
		"Requires motion vectors (e.g. LAUNCHPAD.fx).\n"
		"Preprocessor defines (no runtime branching):\n"
		"\n"
		"                     Value  Samples                Description\n"
		"------------------------------------------------------------------------\n"
		"TFAA_SAMPLING_METHOD\n"
		"BILINEAR             0      1-tap                  Hardware bilinear tap\n"
		"CATMULLROM_5TAP      1      5-tap                  Catmull-Rom fast\n"
		"                                                   (corners omitted)\n"
		"CATMULLROM_9TAP      2      9-tap                  Catmull-Rom\n"
		"LANCZOS2_5TAP        3      5-tap                  Lanczos-2 fast\n"
		"                                                   (corners omitted)\n"
		"                                                   [default]\n"
		"LANCZOS2_9TAP        4      9-tap                  Lanczos-2 full\n"
		"                                                   optimized merge\n"
		"LANCZOS3_21TAP_FAST  5      21-tap                 Lanczos-3 fast\n"
		"                                                   (corners omitted)\n"
		"LANCZOS3_25TAP       6      25-tap                 Lanczos-3 full\n"
		"                                                   optimized merge\n"
		"LANCZOS4_37TAP_FAST  7      37-tap                 Lanczos-4 fast\n"
		"                                                   (corners omitted)\n"
		"LANCZOS4_49TAP       8      49-tap                 Lanczos-4 full\n"
		"                                                   optimized merge\n"
		"FSR EASU ()          9      12-tap                 AMD FidelityFX EASU\n"
		"                                                   Breaking change: if\n"
		"                                                   you previously set a\n"
		"                                                   custom\n"
		"                                                   TFAA_SAMPLING_METHOD,\n"
		"                                                   remap 1→3, 2→4, 3→6,\n"
		"                                                   4→8, 5→1, 6→2, 7→9.\n"
		"                                                   [default]\n"
		"\n"
		"TFAA_RECTIFY_COLOR_SPACE\n"
		"RGB                  0      R: G: B:               No color transform\n"
		"                                                   (identity); loosest\n"
		"                                                   rectification bounds.\n"
		"                                                   Most blurring and\n"
		"                                                   most color deviation\n"
		"                                                   artifacts. [default]\n"
		"YCbCr                1      Y: BT.601 Cb: Cr:      ITU-R BT.601 /\n"
		"                                                   JPEG-style full-range\n"
		"                                                   chroma scales (not\n"
		"                                                   broadcast\n"
		"                                                   limited-range\n"
		"                                                   packing). Chrominance\n"
		"                                                   more correlated\n"
		"                                                   across axes than\n"
		"                                                   YCoCg. Rectify path\n"
		"                                                   stores Cb/Cr with\n"
		"                                                   +0.5 offset so all\n"
		"                                                   axes are in [0,1].\n"
		"                                                   [default]\n"
		"YCoCg                2      Y: (R+2G+B)/4 Co: Cg:  Malvar & Sullivan\n"
		"                                                   (2003 YCoCg);\n"
		"                                                   orthogonal chroma,\n"
		"                                                   more decorrelated\n"
		"                                                   than YCbCr. Rectify\n"
		"                                                   path stores Co/Cg\n"
		"                                                   with +0.5 offset so\n"
		"                                                   all axes are in\n"
		"                                                   [0,1]. [default]\n"
		"\n"
		"TFAA_RECTIFY_OP\n"
		"CLAMP                0                             Clamp history to the\n"
		"                                                   AABB.\n"
		"                                                   (TFAA_RECTIFY_SHAPE\n"
		"                                                   is ignored).\n"
		"                                                   [default]\n"
		"CLIP_NEAREST         1                             Ray clip towards\n"
		"                                                   neighborhood sample\n"
		"                                                   closest to history in\n"
		"                                                   rectification space.\n"
		"                                                   [default]\n"
		"CLIP_MEAN            2                             Ray clip towards the\n"
		"                                                   nine-tap arithmetic\n"
		"                                                   average. [default]\n"
		"CLIP_CENTROID        3                             Ray clip towards the\n"
		"                                                   per-channel midpoint\n"
		"                                                   (min+max)/2.\n"
		"                                                   [default]\n"
		"CLIP_CURRENT         4                             Ray clip towards the\n"
		"                                                   current pixel.\n"
		"                                                   [default]\n"
		"\n"
		"TFAA_RECTIFY_SHAPE\n"
		"AABB                 0                             3-axis | 6-faces Box\n"
		"                                                   - classic\n"
		"                                                   axis-aligned box used\n"
		"                                                   for clipping/clamping\n"
		"                                                   in common industry\n"
		"                                                   TAA solutions.\n"
		"                                                   [default]\n"
		"14-DOP               1                             7-axis | 14 - faces |\n"
		"                                                   Box with cut corners.\n"
		"                                                   [default]\n"
		"18-DOP               2                             9-axis | 18 - faces |\n"
		"                                                   Box with cut edges.\n"
		"                                                   [default]\n"
		"26-DOP               3                             13-axis | 26 - faces\n"
		"                                                   | Box with cut\n"
		"                                                   corners and edges.\n"
		"                                                   [default]\n"
		"\n"
		"TFAA_MOTION_SOURCE\n"
		"LAUNCHPAD            0                             Uses\n"
		"                                                   MartysMods_LAUNCHPAD.\n"
		"                                                   [default]\n"
		"LUMENITE_KERNEL      1                             Uses\n"
		"                                                   lumenite_Kernel.fx\n"
		"UI_DEBUG\n"
		"off                  0                             Depth rejection and\n"
		"                                                   color rectification\n"
		"                                                   always on\n"
		"on                   1                             Debug UI (toggle\n"
		"                                                   rectification / depth\n"
		"                                                   rejection)\n";
>
{
    pass PassSavePre
    {
        VertexShader   = PostProcessVS;
        PixelShader    = PassSaveCur;
        RenderTarget   = texInCurBackup;
    }

    pass PassTemporalFilter
    {
        VertexShader   = PostProcessVS;
        PixelShader    = PassTemporalFilter;
        RenderTarget   = texExpColor;
    }

    pass PassSavePost
    {
        VertexShader   = PostProcessVS;
        PixelShader    = PassSavePost;
        RenderTarget0  = texExpColorBackup;
        RenderTarget1  = texDepthBackup;
    }

    pass PassShow
    {
        VertexShader   = PostProcessVS;
        PixelShader    = PassSharp;
    }
}