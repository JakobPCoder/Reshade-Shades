/*=============================================================================
    TFAA (1.1.2)
    Temporal Filter Anti-Aliasing Shader
    First published 2022 - Copyright, Jakob Wapenhensch
    License: CC BY-NC 4.0 (https://creativecommons.org/licenses/by-nc/4.0/)
    https://creativecommons.org/licenses/by-nc/4.0/legalcode
=============================================================================*/



#include "ReShadeUI.fxh"
#include "ReShade.fxh"
#include "samplers.fxh"
#include "helpers.fxh"


#ifndef UI_DEBUG
	#define UI_DEBUG 0
#endif



#ifndef TFAA_SAMPLING_METHOD
	#define TFAA_SAMPLING_METHOD 1
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

#if TFAA_KDOP_AXIS_LIMIT == 13
    static const float3 TFAA_KDOP_AXES[TFAA_KDOP_AXIS_LIMIT] = {
        float3(1, 0, 0), float3(0, 1, 0), float3(0, 0, 1),
        float3(1, 1, 1) * TFAA_INV_SQRT3, float3(1, -1, 1) * TFAA_INV_SQRT3,
        float3(1, 1, -1) * TFAA_INV_SQRT3, float3(1, -1, -1) * TFAA_INV_SQRT3,
        float3(1, 1, 0) * TFAA_INV_SQRT2, float3(1, -1, 0) * TFAA_INV_SQRT2,
        float3(1, 0, 1) * TFAA_INV_SQRT2, float3(1, 0, -1) * TFAA_INV_SQRT2,
        float3(0, 1, 1) * TFAA_INV_SQRT2, float3(0, 1, -1) * TFAA_INV_SQRT2
    };
#elif TFAA_KDOP_AXIS_LIMIT == 7
    static const float3 TFAA_KDOP_AXES[TFAA_KDOP_AXIS_LIMIT] = {
        float3(1, 0, 0), float3(0, 1, 0), float3(0, 0, 1),
        float3(1, 1, 1) * TFAA_INV_SQRT3, float3(1, -1, 1) * TFAA_INV_SQRT3,
        float3(1, 1, -1) * TFAA_INV_SQRT3, float3(1, -1, -1) * TFAA_INV_SQRT3
    };
#elif TFAA_KDOP_AXIS_LIMIT == 9
    static const float3 TFAA_KDOP_AXES[TFAA_KDOP_AXIS_LIMIT] = {
        float3(1, 0, 0), float3(0, 1, 0), float3(0, 0, 1),
        float3(1, 1, 0) * TFAA_INV_SQRT2, float3(1, -1, 0) * TFAA_INV_SQRT2,
        float3(1, 0, 1) * TFAA_INV_SQRT2, float3(1, 0, -1) * TFAA_INV_SQRT2,
        float3(0, 1, 1) * TFAA_INV_SQRT2, float3(0, 1, -1) * TFAA_INV_SQRT2
    };
#endif
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
    ui_tooltip = "";
> = 0.5;

uniform float UI_ADAPTIVE_SHARPEN <
    ui_type    = "slider";
    ui_min     = 0.0;
    ui_max     = 1.0;
    ui_step    = 0.01;
    ui_label   = "Adaptive Sharpening";
    ui_category= "Temporal Filter";
    ui_tooltip = "";
> = 0.5;

uniform float UI_POST_SHARPEN <
    ui_type    = "slider";
    ui_min     = 0.0;
    ui_max     = 1.0;
    ui_step    = 0.01;
    ui_label   = "Post Sharpening";
    ui_category= "Temporal Filter";
    ui_tooltip = "";
> = 0.5;


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
    return sample_catmullrom_rgba(historySampler, texcoord);
#elif TFAA_SAMPLING_METHOD == 2
    return sample_lanczos2_basic_rgba(historySampler, texcoord);
#elif TFAA_SAMPLING_METHOD == 3
    return sample_lanczos3_basic_rgba(historySampler, texcoord);
#elif TFAA_SAMPLING_METHOD == 4
    return sample_lanczos4_basic_rgba(historySampler, texcoord);
#elif TFAA_SAMPLING_METHOD == 5
    return sample_easu_same(historySampler, texcoord);
#else
    return sample_catmullrom_rgba(historySampler, texcoord);
#endif
}

float3 ClipRayAABB(float3 history, float3 anchor, float3 bMin, float3 bMax)
{
    float3 dir = history - anchor;
    float3 edge = (dir > 0.0) ? (bMax - anchor) : (bMin - anchor);
    float3 t = saturate(edge / (dir + 1e-7));
    float clipRatio = min(t.x, min(t.y, t.z));
    return anchor + dir * clipRatio;
}

#if TFAA_NEED_KDOP_SLABS
float3 ClipRayKDOP(float3 history, float3 anchor, float minE[TFAA_KDOP_AXIS_LIMIT], float maxE[TFAA_KDOP_AXIS_LIMIT])
{
	float3 rayDir = history - anchor;
	float minT = 1.0;

	[unroll]
	for (int a = 0; a < TFAA_KDOP_AXIS_LIMIT; ++a)
	{
		float originProj = dot(anchor, TFAA_KDOP_AXES[a]);
		float dirProj = dot(rayDir, TFAA_KDOP_AXES[a]);

		if (abs(dirProj) > 1e-7)
		{
			float t = (dirProj > 0.0)
				? (maxE[a] - originProj) / dirProj
				: (minE[a] - originProj) / dirProj;
			minT = min(minT, max(0.0, t));
		}
	}

	return anchor + rayDir * minT;
}
#endif


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

    float2 get_motion(float2 uv)
    {
        return tex2Dlod(sMotionVectorsTex, uv, 0).xy;
    }
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
		float2(-1.0,-1.0), float2(0, -1),  float2(1.0, -1.0),
        float2(-1, 0),     float2(0, 0),  float2(1, 0),
        float2(-0.7, 0.7), float2(0, 1), float2(0.7, 0.7)
	};

    float4 sampleCur = tex2Dlod(smpInCurBackup, texcoord, 0);
    float4 cvtColorCur = float4(TFAA_RGB_TO_RECTIFY(sampleCur.rgb), sampleCur.a);

    int closestDepthIndex = 4;

    float minNeighborDepth = 2;

#if !TFAA_NEED_KDOP_SLABS
    float3 minimumRectify = 2;
    float3 maximumRectify = -1;
#endif

#if TFAA_RECTIFY_OP == 2
    float3 neighborSum = 0;
#endif

#if TFAA_RECTIFY_OP == 1
    float3 cvtCache[samples];
#endif

#if TFAA_NEED_KDOP_SLABS
    float kdopMin[TFAA_KDOP_AXIS_LIMIT];
    float kdopMax[TFAA_KDOP_AXIS_LIMIT];
    [unroll]
    for (int kd = 0; kd < TFAA_KDOP_AXIS_LIMIT; ++kd)
    {
        kdopMin[kd] = 1e10;
        kdopMax[kd] = -1e10;
    }
#endif

    for (int i = 0; i < samples; i++)
    {
        float4 rgba = tex2Dlod(smpInCurBackup, texcoord + (nOffsets[i] * ReShade::PixelSize), 0);
        float3 cvtRgb = TFAA_RGB_TO_RECTIFY(rgba.rgb);

        if (rgba.a < minNeighborDepth)
            closestDepthIndex = i;
        minNeighborDepth = min(minNeighborDepth, rgba.a);

#if !TFAA_NEED_KDOP_SLABS
        minimumRectify = min(minimumRectify, cvtRgb);
        maximumRectify = max(maximumRectify, cvtRgb);
#endif

#if TFAA_RECTIFY_OP == 2
        neighborSum += cvtRgb;
#endif
#if TFAA_RECTIFY_OP == 1
        cvtCache[i] = cvtRgb;
#endif

#if TFAA_NEED_KDOP_SLABS
        [unroll]
        for (int a = 0; a < TFAA_KDOP_AXIS_LIMIT; ++a)
        {
            float p = dot(cvtRgb, TFAA_KDOP_AXES[a]);
            kdopMin[a] = min(kdopMin[a], p);
            kdopMax[a] = max(kdopMax[a], p);
        }
#endif
    }

#if TFAA_NEED_KDOP_SLABS
    float3 minimumRectify = float3(kdopMin[0], kdopMin[1], kdopMin[2]);
    float3 maximumRectify = float3(kdopMax[0], kdopMax[1], kdopMax[2]);
#endif

    float2 motion = Deferred::get_motion(texcoord + (nOffsets[closestDepthIndex] * ReShade::PixelSize));

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
            if TFAA_RECTIFY_OP == 1
                float3 rectifyAnchor = nearestAnchor;
            #elif TFAA_RECTIFY_OP == 2
                float3 rectifyAnchor = neighborSum / float(samples);
            #elif TFAA_RECTIFY_OP == 3
                float3 rectifyAnchor = (minimumRectify + maximumRectify) * 0.5;
            #else
                float3 rectifyAnchor = cvtColorCur.rgb;
            #endif

            #if TFAA_NEED_KDOP_SLABS
                rectified = ClipRayKDOP(sampleExpCvt, rectifyAnchor, kdopMin, kdopMax);
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
		"Temporal component of TAA to use with (after) spatial anti-aliasing techniques.\n"
		"Requires motion vectors (e.g. LAUNCHPAD.fx).\n\n"
		"---\n"
        "TFAA_SAMPLING_METHOD - filter used when sampling reprojected history (LINEAR history sampler).\n"
		"  0: bilinear - (1 tap) tex2Dlod\n"
		"  1: Catmull-Rom - (5 taps) sample_catmullrom_rgba [default]\n"
		"  2: Lanczos-2 - (16 taps) sample_lanczos2_basic_rgba \n"
		"  3: Lanczos-3 - (36 taps) sample_lanczos3_basic_rgba \n"
		"  4: Lanczos-4 - (64 taps) sample_lanczos4_basic_rgba \n"
		"  5: FSR EASU - (12 taps) sample_easu_same \n"
        "---\n"
        "TFAA_RECTIFY_COLOR_SPACE - Color space in which the history is rectified.\n"
		"  0: RGB (identity; loosest bounds)\n"
		"  1: YCbCr norm\n"
		"  2: YCoCg norm[default]\n"
		"---\n"
        "TFAA_RECTIFY_OP - rectification applied to historical color (0→4: generally stabler/softer clipping → sharper)\n"
		"  0: CLAMP - always AABB in rectify space (per-channel min/max of the 3x3 neighborhood). TFAA_RECTIFY_SHAPE is ignored.\n"
		"  1: CLIP_NEAREST - ray from neighbor sample closest to history in rectify space\n"
		"  2: CLIP_MEAN - ray from nine-tap arithmetic mean in rectify space\n"
		"  3: CLIP_CENTROID - ray from per-channel AABB midpoint (min+max)/2 in rectify space\n"
		"  4: CLIP_CURRENT - ray from current pixel (center 3x3 tap) [default]\n"
		"---\n"
		"TFAA_RECTIFY_SHAPE - k-DOP hull for CLIP ops (1-4) only; no effect when TFAA_RECTIFY_OP is 0 (CLAMP).\n"
		"  0: AABB - axis-aligned bounds (principal axes only)\n"
		"  1: 14-DOP - seven axes box+corners [default]\n"
		"  2: 18-DOP - nine axes box+edges\n"
		"  3: 26-DOP - thirteen axes box+edges+corners\n"
        "---\n"

		"UI_DEBUG\n"
		"  0: No optional temporal toggles or debug UI; depth rejection and color clamping are enabled.\n"
		"  1: Enables debug UI.\n\n"
		"---\n";
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