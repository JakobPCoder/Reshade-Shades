

float4 tex2Dlod(sampler s, float2 uv, float mip)
{
    return tex2Dlod(s, float4(uv, 0, mip));
}

float3 cvtRgb2YCbCr(float3 rgb)
{
 	float y = 0.299 * rgb.r + 0.587 * rgb.g + 0.114 * rgb.b;
    float cb = (rgb.b - y) * 0.565;
    float cr = (rgb.r - y) * 0.713;

    return float3(y, cb, cr);
}

float3 cvtYCbCr2Rgb(float3 YCbCr)
{
    return float3(
        YCbCr.x + 1.403 * YCbCr.z,
        YCbCr.x - 0.344 * YCbCr.y - 0.714 * YCbCr.z,
        YCbCr.x + 1.770 * YCbCr.y
    );
}

float3 cvtRgb2whatever(float3 rgb)
{
	return cvtRgb2YCbCr(rgb);
    // return rgb;
}

float3 cvtWhatever2Rgb(float3 whatever)
{
	return cvtYCbCr2Rgb(whatever);
    // return whatever;
}


namespace Deferred 
{
    //motion vectors, RGBA16F, XY = delta uv, Z = confidence, W = depth because why not
    texture MotionVectorsTex        { Width = BUFFER_WIDTH;   Height = BUFFER_HEIGHT;   Format = RG16F;     };
    sampler sMotionVectorsTex       { Texture = MotionVectorsTex; };

    float2 get_motion(float2 uv)
    {
        return tex2Dlod(sMotionVectorsTex, uv, 0).xy;
    }
}

