#include "UnityUI.cginc"

#ifndef LGAME_UI_INCLUDED
#define LGAME_UI_INCLUDED

	inline float2 smoothstepEx(in float2 a, in float2 b, in float2 x ,in float2 alpha)
	{
		float2 t = saturate((x - a) / (b - a));
		t = t * t * (3.0 - 2.0 * t);
		t = lerp(alpha,float2(1,1), t);

		return t;
	}

	inline float LGameGetSoft2DClippingEx(in float2 position, in float4 clipRect, in float4 borderBlend,in float4 borderBlendAlpha)
	{
		float2 inside = smoothstepEx(clipRect.xy, clipRect.xy + borderBlend.xy, position.xy, borderBlendAlpha.xy)
			* smoothstepEx(clipRect.zw, clipRect.zw - borderBlend.zw, position.xy, borderBlendAlpha.zw);
		float2 clippingSide = UnityGet2DClipping(position, clipRect);
		inside *= clippingSide;

		return inside.x * inside.y;
	}

	float3 RGB2HSV(float3 c)
	{
		float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
		float4 p = lerp(float4(c.bg, K.wz), float4(c.gb, K.xy), step(c.b, c.g));
		float4 q = lerp(float4(p.xyw, c.r), float4(c.r, p.yzx), step(p.x, c.r));

		float d = q.x - min(q.w, q.y);
		float e = 1.0e-10;
		return float3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
	}

	float3 HSV2RGB(float3 c)
	{
		float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
		float3 p = abs(frac(c.xxx + K.xyz) * 6.0 - K.www);
		return c.z * lerp(K.xxx, saturate(p - K.xxx), c.y);
	}
	float2 UnpackUV(float uv)
	{
		float2 output;
		output.x = floor(uv / 4096);
		output.y = uv - 4096 * output.x;

		return output * 0.001953125;
	}
#endif