

/*=============================================================================
	Includes
=============================================================================*/

#include "ReShadeUI.fxh"
#include "ReShade.fxh"
#include "shades_util.fxh"



/*=============================================================================
	UI Uniforms
=============================================================================*/


/*=============================================================================
	Defines & Uniforms
=============================================================================*/

#define M_PI 3.1415926535
#define M_F_R2D (180.f / M_PI)
#define M_F_D2R (1.0 / M_F_R2D)

/*=============================================================================
	Textures & Samplers
=============================================================================*/

texture texDepthIn : DEPTH;
sampler smpDepthIn { Texture = texDepthIn; };


texture2D texInCur : COLOR;
sampler smpInCur { Texture = texInCur; AddressU = Clamp; AddressV = Clamp; MipFilter = Linear; MinFilter = Linear; MagFilter = Linear; };

texture texFeaturesACur < pooled = false; > { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; MipLevels = 8; Format = RGBA16F; };
sampler smpFeaturesACur { Texture = texFeaturesACur; AddressU = Clamp; AddressV = Clamp; MipFilter = Linear; MinFilter = Linear; MagFilter = Linear; };
texture texFeaturesBCur < pooled = false; > { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; MipLevels = 8; Format = RGBA16F; };
sampler smpFeaturesBCur { Texture = texFeaturesBCur; AddressU = Clamp; AddressV = Clamp; MipFilter = Linear; MinFilter = Linear; MagFilter = Linear; };

/*=============================================================================
	Functions
=============================================================================*/


float2x4 calculateFeatures(sampler c, float2 texcoord)
{
    static const float2 nOffsets[9] = { 
		float2(-0.7,-0.7), float2(0, 1), float2(0.7, 0.7), 
        float2(-1, 0),      float2(0, 0), float2(1, 0), 
        float2(-0.7, 0.7), float2(0, -1), float2(0.7, 0.7) 
	};
    
    static const float sobelKernelX[] = { -1, 0, 1, -2, 0, 2, -1, 0, 1 };
    static const float sobelKernelY[] = { -1, -2, -1, 0, 0, 0, 1, 2, 1 };

	float4 minimum = 1;
	float4 maximum = 0;
	float gradientX = 0;
    float gradientY = 0;

	float4 neigborhood[9];

	for (int i = 0; i < 9; i++)
	{
		neigborhood[i] = tex2Dlod(c, texcoord + (nOffsets[i] * ReShade::PixelSize * 1.25), 0);
		float4 cvt = float4(cvtRgb2whatever(neigborhood[i].rgb), neigborhood[i].a);
		gradientX += sobelKernelX[i] * cvt.r;
		gradientY += sobelKernelY[i] * cvt.r;

        minimum = min(minimum, cvt);
        maximum = max(maximum, cvt);
        float saturation = length(float2(cvt.g, cvt.b));
	}

    gradientX = (gradientX * 0.2) + 0.5;
    gradientY = (gradientY * 0.2) + 0.5;

    float3 center = cvtRgb2whatever(neigborhood[4].rgb);
    float contrast = saturate(length(maximum.r - minimum.r));
    float saturation = length(float2(center.g, center.b));

	return float2x4(float4(center.r, minimum.r, maximum.r, saturation), float4(contrast, gradientX, gradientY, 0));
}


/*=============================================================================
	Passes
=============================================================================*/

void PassA(float4 position : SV_Position, float2 texcoord : TEXCOORD, out float4 featuresA : SV_Target0, out float4 featuresB : SV_Target1)
{	
	float2x4 features = calculateFeatures(smpInCur, texcoord);
    featuresA = features[0];
    featuresB = features[1];
}

/*=============================================================================
	Techniques
=============================================================================*/

technique PREPASS
{

	pass A
	{
		VertexShader = PostProcessVS;
		PixelShader = PassA;
        RenderTarget0 = texFeaturesACur;
        RenderTarget1 = texFeaturesBCur;
	}
}
