


/** 
 * - Temporal Filter Anti Aliasing | TFAA
 * - First published 2022 - Copyright, Jakob Wapenhensch
 * - https://creativecommons.org/licenses/by-nc/4.0/
 * - https://creativecommons.org/licenses/by-nc/4.0/legalcode
 */

 



/*=============================================================================
	Includes
=============================================================================*/

#include "ReShadeUI.fxh"
#include "ReShade.fxh"
#include "shades_util.fxh"


/*=============================================================================
	Preprocessor settings
=============================================================================*/


// Uniform variables to store frame time and frame count
uniform float frametime < source = "frametime"; >;
uniform int framecount < source = "framecount"; >;

// Constant to compute FPS; 48 frames are expected per 1000 milliseconds
static const float fpsConst = (1000.0 / 48.0);

/*=============================================================================
	UI Uniforms
=============================================================================*/

uniform float  UI_TEMPORAL_FILTER_STRENGTH <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0; ui_step = 0.01;
	ui_label = "Temporal Filter Strength";
	ui_category = "Temporal Filter";
	ui_tooltip = "";
> = 0.5;


uniform float  UI_POST_SHARPEN <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0; ui_step = 0.01;
	ui_label = "Adaptive Sharpening";
	ui_category = "Temporal Filter";
	ui_tooltip = "";
> = 0.5;



uniform int UI_DEBUG <
	ui_type = "combo";
    ui_label = "Show Debug View";
	ui_items = "None\0Final Weights\0Dissocclusion\0Local Contrast\0Speed\0Sharpening Mask\0";
	ui_tooltip = "";
    ui_category = "Debug";
> = 0;

// uniform float UI_CONTRAST_WEIGHT <
// 	ui_type = "slider";
//     ui_label = "Contrast Blend Weight";
//     ui_tooltip = "Weight of the contrast blending.";
//     ui_category = "Blending Weight Factors";
//     ui_min = 0;
//     ui_max = 1;
//     ui_step = 0.01;
// > = 0.5;

/*=============================================================================
	Textures & Samplers
=============================================================================*/

texture texDepthIn : DEPTH;
sampler smpDepthIn { Texture = texDepthIn; };

// Texture and sampler for the current frame's color
texture texInCur : COLOR;
sampler smpInCur { Texture = texInCur; AddressU = Clamp; AddressV = Clamp; MipFilter = Linear; MinFilter = Linear; MagFilter = Linear; };

// Backup texture for the current frame's color
texture texInCurBackup < pooled = true; > { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16F; };
sampler smpInCurBackup { Texture = texInCurBackup; AddressU = Clamp; AddressV = Clamp; MipFilter = Linear; MinFilter = Linear; MagFilter = Linear; };

// Textures to store Exponential frame Buffer
texture texExpColor < pooled = true; > { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16F; };
sampler smpExpColor { Texture = texExpColor; AddressU = Clamp; AddressV = Clamp; MipFilter = Linear; MinFilter = Linear; MagFilter = Linear; };

texture texExpColorBackup < pooled = true; > { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16F; };
sampler smpExpColorBackup { Texture = texExpColorBackup; AddressU = Clamp; AddressV = Clamp; MipFilter = Linear; MinFilter = Linear; MagFilter = Linear; };


// Backup textures from last frame
texture texDepthBackup < pooled = true; > { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = R16f; };
sampler smpDepthBackup { Texture = texDepthBackup; AddressU = Clamp; AddressV = Clamp; MipFilter = Point; MinFilter = Point; MagFilter = Point; };



/*=============================================================================
	Functions
=============================================================================*/

//Thanks Marty <3
float4 bicubic_5(sampler source, float2 texcoord)
{
	// Compute the texture size
    float2 texsize = tex2Dsize(source);

    // Compute the normalized relative position of the texel and the relative position of each sample
    float2 UV =  texcoord * texsize;
    float2 tc = floor(UV - 0.5) + 0.5;
    float2 f = UV - tc;

    // Compute the weights for each sample
    float2 f2 = f * f; 
    float2 f3 = f2 * f;
    float2 w0 = f2 - 0.5 * (f3 + f);
    float2 w1 = 1.5 * f3 - 2.5 * f2 + 1.0;
    float2 w3 = 0.5 * (f3 - f2);
    float2 w12 = 1.0 - w0 - w3;

    // Compute the sample positions and weights
    float4 ws[3];    
    ws[0].xy = w0;
    ws[1].xy = w12;
    ws[2].xy = w3;

    ws[0].zw = tc - 1.0;
    ws[1].zw = tc + 1.0 - w1 / w12;
    ws[2].zw = tc + 2.0;

    // Normalize the weights
    ws[0].zw /= texsize;
    ws[1].zw /= texsize;
    ws[2].zw /= texsize;

    // Compute the interpolated value
    float4 ret;
    ret  = tex2Dlod(source, float2(ws[1].z, ws[0].w), 0) * ws[1].x * ws[0].y;    
    ret += tex2Dlod(source, float2(ws[0].z, ws[1].w), 0) * ws[0].x * ws[1].y;    
    ret += tex2Dlod(source, float2(ws[1].z, ws[1].w), 0) * ws[1].x * ws[1].y;    
    ret += tex2Dlod(source, float2(ws[2].z, ws[1].w), 0) * ws[2].x * ws[1].y;    
    ret += tex2Dlod(source, float2(ws[1].z, ws[2].w), 0) * ws[1].x * ws[2].y;    
    float normfact = 1.0 / (1.0 - (f.x - f2.x)*(f.y - f2.y) * 0.25); 
    return max(0, ret * normfact);   
}

float4 bicubic_9(sampler2D source, float2 texcoord)
{
	// Calculate the size of the source texture
    float2 texSize = tex2Dsize(source);

    // Calculate the position to sample in the source texture
    float2 samplePos = texcoord * texSize;

    // Calculate the integer and fractional parts of the sample position
    float2 texPos1 = floor(samplePos - 0.5f) + 0.5f;
    float2 f = samplePos - texPos1;

    // Calculate the interpolation weights for the four cubic spline basis functions
    float2 w0 = f * (-0.5f + f * (1.0f - 0.5f * f));
    float2 w1 = 1.0f + f * f * (-2.5f + 1.5f * f);
    float2 w2 = f * (0.5f + f * (2.0f - 1.5f * f));
    float2 w3 = f * f * (-0.5f + 0.5f * f);

    // Calculate weights for two intermediate values (used for more efficient sampling)
    float2 w12 = w1 + w2;
    float2 offset12 = w2 / (w1 + w2);

    // Calculate the positions to sample for the eight texels involved in bicubic interpolation
    float2 texPos0 = texPos1 - 1;
    float2 texPos3 = texPos1 + 2;
    float2 texPos12 = texPos1 + offset12;

    // Normalize the texel positions to the [0, 1] range
    texPos0 /= texSize;
    texPos3 /= texSize;
    texPos12 /= texSize;

    // Initialize the result color to zero
    float4 result = 0.0f;

    // Perform bicubic interpolation by sampling the source texture with the calculated weights
    result += tex2Dlod(source, float2(texPos0.x, texPos0.y), 0) * w0.x * w0.y;
    result += tex2Dlod(source, float2(texPos12.x, texPos0.y), 0) * w12.x * w0.y;
    result += tex2Dlod(source, float2(texPos3.x, texPos0.y), 0) * w3.x * w0.y;

    result += tex2Dlod(source, float2(texPos0.x, texPos12.y), 0) * w0.x * w12.y;
    result += tex2Dlod(source, float2(texPos12.x, texPos12.y), 0) * w12.x * w12.y;
    result += tex2Dlod(source, float2(texPos3.x, texPos12.y), 0) * w3.x * w12.y;

    result += tex2Dlod(source, float2(texPos0.x, texPos3.y), 0) * w0.x * w3.y;
    result += tex2Dlod(source, float2(texPos12.x, texPos3.y), 0) * w12.x * w3.y;
    result += tex2Dlod(source, float2(texPos3.x, texPos3.y), 0) * w3.x * w3.y;

    return result;
}

float4 sampleHistory(sampler2D historySampler, float2 texcoord)
{
	return bicubic_5(historySampler, texcoord);
}

float getDepth(float2 texcoord)
{
	float depth = tex2Dlod(smpDepthIn, texcoord, 0).x;

	#if RESHADE_DEPTH_INPUT_IS_REVERSED
		depth = 1.0 - depth;
	#endif

	const float N = 1.0;
	depth /= RESHADE_DEPTH_LINEARIZATION_FAR_PLANE - depth * (RESHADE_DEPTH_LINEARIZATION_FAR_PLANE - N);


	return depth;
}



/*=============================================================================
	Passes
=============================================================================*/

float4 SaveCur(float4 position : SV_Position, float2 texcoord : TEXCOORD) : SV_Target0
{	
	float depthOnly = getDepth(texcoord);
	return float4(tex2Dlod(smpInCur, texcoord, 0).rgb, depthOnly);
}

float4 TemporalFilter(float4 position : SV_Position, float2 texcoord : TEXCOORD ) : SV_Target
{
	float4 sampleCur = tex2Dlod(smpInCurBackup, texcoord, 0);
	float4 cvtColorCur = float4(cvtRgb2whatever(sampleCur.rgb), sampleCur.a);

    static const float2 nOffsets[9] = { 
		float2(-0.7,-0.7), float2(0, 1), float2(0.7, 0.7), 
        float2(-1, 0),      float2(0, 0), float2(1, 0), 
        float2(-0.7, 0.7), float2(0, -1), float2(0.7, 0.7) 
	};
    
	float4 neigborhood[9];
	int closestDepthIndex = 4;
	float closestDepth = sampleCur.a;

	float4 minimumCvt = 2;
	float4 maximumCvt = -1;

	for (int i = 0; i < 9; i++)
	{
		neigborhood[i] = tex2Dlod(smpInCurBackup, texcoord + (nOffsets[i] * ReShade::PixelSize * 1), 0);
		float4 cvt = float4(cvtRgb2whatever(neigborhood[i].rgb), neigborhood[i].a);

        minimumCvt = min(minimumCvt, cvt);
        maximumCvt = max(maximumCvt, cvt);
	}


	float2 motion = Deferred::get_motion(texcoord + (nOffsets[closestDepthIndex] * ReShade::PixelSize));
	float2 lastSamplePos = texcoord + motion;
	float lastDepth = tex2Dlod(smpDepthBackup, lastSamplePos, 0).r;
	float4 sampleExp = saturate(sampleHistory(smpExpColorBackup, lastSamplePos));


	float fpsFix = frametime / fpsConst;
	float localContrast = saturate(pow(abs(maximumCvt.r - minimumCvt.r), 0.75) * 1);
	float speed = length(motion);
	float speedFactor = 1.0 - pow(saturate(length(motion) * 20.0), 0.5);



	float depthDelta = max(0, saturate(minimumCvt.a - lastDepth)) / sampleCur.a;
	float depthMask = saturate(1.0 - pow(depthDelta * 4, 4));


	float weight = lerp(0.50, 0.99, UI_TEMPORAL_FILTER_STRENGTH);

	weight = lerp(weight, weight * (0.6 + localContrast * 2), 0.5);

	weight *= speedFactor;

	weight *= depthMask;

	weight = clamp(weight, 0.0, 0.95);


	float4 sampleExpClamped = float4(cvtWhatever2Rgb(clamp(cvtRgb2whatever(sampleExp.rgb), minimumCvt.rgb, maximumCvt.rgb)), sampleExp.a);

	const static float correctionFactor = 1;
	float3 blendedColor = saturate(pow(lerp(pow(sampleCur.rgb, correctionFactor), pow(sampleExpClamped.rgb, correctionFactor), weight), rcp(correctionFactor)));


	float sharp = 0;

	switch(UI_DEBUG)
	{
		case 1:
			return weight;
		case 2:
			return depthMask;
		case 3:
			return localContrast;
		case 4:
			return speedFactor;
		case 5:
			sharp = saturate((0.01 + localContrast) * ( pow(speed, 0.15) ) * depthMask * 2);
			return sharp;
		default:
			sharp = saturate((0.01 + localContrast) * ( pow(speed, 0.15) ) * depthMask * 2);
			return float4(blendedColor, sharp);
	}


}

void SavePost(float4 position : SV_Position, float2 texcoord : TEXCOORD, out float4 lastExpOut : SV_Target0, out float depthOnly : SV_Target1)
{
	lastExpOut = tex2Dlod(smpExpColor, texcoord, 0);
	depthOnly = getDepth(texcoord);
}

float4 Out(float4 position : SV_Position, float2 texcoord : TEXCOORD ) : SV_Target
{
	float4 center = tex2Dlod(smpExpColor, texcoord, 0);
	float3 top = tex2Dlod(smpExpColor, texcoord + (float2(0, -1) * ReShade::PixelSize), 0).rgb;
	float3 bottom = tex2Dlod(smpExpColor, texcoord + (float2(0, 1) * ReShade::PixelSize), 0).rgb;
	float3 left = tex2Dlod(smpExpColor, texcoord + (float2(-1, 0) * ReShade::PixelSize), 0).rgb;
	float3 right = tex2Dlod(smpExpColor, texcoord + (float2(1, 0) * ReShade::PixelSize), 0).rgb;
	float3 topLeft = tex2Dlod(smpExpColor, texcoord + (float2(-0.7, -0.7) * ReShade::PixelSize), 0).rgb;
	float3 topRight = tex2Dlod(smpExpColor, texcoord + (float2(0.7, -0.7) * ReShade::PixelSize), 0).rgb;
	float3 bottomLeft = tex2Dlod(smpExpColor, texcoord + (float2(-0.7, 0.7) * ReShade::PixelSize), 0).rgb;
	float3 bottomRight = tex2Dlod(smpExpColor, texcoord + (float2(0.7, 0.7) * ReShade::PixelSize), 0).rgb;

	float3 maxCross = max(top, max(bottom, max(left, max(right, center.rgb))));
	float3 minCross = min(top, min(bottom, min(left, min(right, center.rgb))));
	float3 maxBox = max(maxCross, max(topLeft, max(topRight, max(bottomLeft, bottomRight))));
	float3 minBox = min(minCross, min(topLeft, min(topRight, min(bottomLeft, bottomRight))));
	
	float contrast = 1.0;
	float sharpAmount = saturate(UI_POST_SHARPEN * UI_TEMPORAL_FILTER_STRENGTH * center.a * 16);

	//calulate sharpening weights for current frame pixel, similar to sharpening weights calulation from AMD CAS
	float3 crossWeight = -rcp(rsqrt(saturate(min(minBox, 1.0 - maxBox) * rcp(maxBox))) * (-3.0 * contrast + 8.0));

	//get reciprocal of crossWeight scaled by the amount of pixels used for sharpening
	float3 rcpWeight = rcp(4.0 * crossWeight + 1.0);

	//get the summ of the neighbouring pixels
	float3 crossSumm = top + bottom + left + right;
 
	//combine local pixel with neighbouring pixels according to their weights
	float3 sharpened = lerp(center.rgb, saturate((crossSumm * crossWeight + center.rgb) * rcpWeight), sharpAmount);



	return float4(sharpened, 0);
}


/*=============================================================================
	Techniques
=============================================================================*/

technique TFAA
{
	pass PassSavePre
	{
		VertexShader = PostProcessVS;
		PixelShader = SaveCur;
		RenderTarget = texInCurBackup;	
	}

	pass PassTemporalFilter
	{
		VertexShader = PostProcessVS;
		PixelShader = TemporalFilter;
		RenderTarget = texExpColor;
	}

	pass PassSavePost
	{
		VertexShader = PostProcessVS;
		PixelShader = SavePost;
		RenderTarget0 = texExpColorBackup;
		RenderTarget1 = texDepthBackup;
	}

	pass PassShow
	{
		VertexShader = PostProcessVS;
		PixelShader = Out;
	}
}
