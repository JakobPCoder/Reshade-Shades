/*=============================================================================
    macros
    Shared preprocessor macros for Shades shaders.
    Copyright, Jakob Wapenhensch
    License: CC BY-NC 4.0 (https://creativecommons.org/licenses/by-nc/4.0/)
    https://creativecommons.org/licenses/by-nc/4.0/legalcode
=============================================================================*/
#pragma once
#define PYR_DIVISOR (2)
#define PYR_DIV_0 (1)
#define PYR_DIV_1 (PYR_DIVISOR)
#define PYR_DIV_2 (PYR_DIV_1 * PYR_DIVISOR)
#define PYR_DIV_3 (PYR_DIV_2 * PYR_DIVISOR)
#define PYR_DIV_4 (PYR_DIV_3 * PYR_DIVISOR)
#define PYR_DIV_5 (PYR_DIV_4 * PYR_DIVISOR)
#define PYR_DIV_6 (PYR_DIV_5 * PYR_DIVISOR)
#define PYR_DIV_7 (PYR_DIV_6 * PYR_DIVISOR)
#define PYR_DIV_8 (PYR_DIV_7 * PYR_DIVISOR)
#define PYR_DIV_9 (PYR_DIV_8 * PYR_DIVISOR)
#define PYR_DIV_10 (PYR_DIV_9 * PYR_DIVISOR)
#define PYR_W(lvl)    (BUFFER_WIDTH / PYR_DIV_##lvl)
#define PYR_H(lvl)    (BUFFER_HEIGHT / PYR_DIV_##lvl)
#define PYR_SIZE(lvl) int2(PYR_W(lvl), PYR_H(lvl))
#define FILTER_POINT  MinFilter = Point;  MagFilter = Point;  MipFilter = Point;
#define FILTER_LINEAR MinFilter = Linear; MagFilter = Linear; MipFilter = Linear;
#define DEFINE_RESOURCE(NAME, W, H, FMT, FILTER, POOL) \
    texture2D tex_##NAME < pooled = POOL; > { Width = W; Height = H; Format = FMT; }; \
    sampler2D smp_##NAME { Texture = tex_##NAME; AddressU = Clamp; AddressV = Clamp; FILTER };
#define DEFINE_RESOURCE_DUAL_SAMPLERS(NAME, W, H, FMT, POOL) \
    texture2D tex_##NAME < pooled = POOL; > { Width = W; Height = H; Format = FMT; }; \
    sampler2D smp_##NAME { Texture = tex_##NAME; AddressU = Clamp; AddressV = Clamp; FILTER_LINEAR }; \
    sampler2D smp_##NAME##_point { Texture = tex_##NAME; AddressU = Clamp; AddressV = Clamp; FILTER_POINT };
#define DEFINE_PYR_LEVEL(NAME, LVL, FMT, POOL) \
    DEFINE_RESOURCE_DUAL_SAMPLERS(NAME##_cur_##LVL, PYR_W(LVL), PYR_H(LVL), FMT, POOL) \
    DEFINE_RESOURCE_DUAL_SAMPLERS(NAME##_last_##LVL, PYR_W(LVL), PYR_H(LVL), FMT, POOL)
#define DEFINE_COLOR_RESOURCE(FILTER) \
    texture tex_color : COLOR; \
    sampler smp_color { Texture = tex_color; AddressU = Clamp; AddressV = Clamp; FILTER };
#define DEFINE_DEPTH_RESOURCE(FILTER) \
    texture tex_depth : DEPTH; \
    sampler smp_depth { Texture = tex_depth; AddressU = Clamp; AddressV = Clamp; FILTER };
#define DEFINE_VARIANTS(NAME, ARGS, BODY) \
    float4 NAME##_rgba ARGS { BODY(float4, rgba) } \
    float3 NAME##_rgb  ARGS { BODY(float3, rgb) }  \
    float2 NAME##_rg   ARGS { BODY(float2, rg) }   \
    float  NAME##_r    ARGS { BODY(float,  r) }    \
#define DEFINE_BASIC_PASS_FUNCTION(NAME, T, FN, CALL_ARGS) \
    T ps_##NAME(float4 position : SV_Position, float2 texcoord : TEXCOORD) : SV_Target \
    { return (T)(FN CALL_ARGS); }
#define DEFINE_BASIC_PASS_ENTRY(NAME, TARGET) \
    pass NAME \
    { \
        VertexShader = PostProcessVS; \
        PixelShader  = ps_##NAME; \
        RenderTarget = TARGET; \
    }
#define PS_IN float4 position : SV_Position, float2 texcoord : TEXCOORD
#define DEFINE_PASS_FUNCTION(NAME, FN, CALL_ARGS, STRUCT, SIGNATURE, UNPACK) \
    void ps_##NAME SIGNATURE \
    { \
        STRUCT r = FN CALL_ARGS; \
        UNPACK \
    }
#define DEFINE_PASS_ENTRY(NAME, RT_BLOCK) \
    pass NAME \
    { \
        VertexShader = PostProcessVS; \
        PixelShader  = ps_##NAME; \
        RT_BLOCK \
    }
