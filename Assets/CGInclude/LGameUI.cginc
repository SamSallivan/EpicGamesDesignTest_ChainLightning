
#ifndef LGAME_UI_INCLUDED
#define LGAME_UI_INCLUDED

	inline float UnityGet2DClipping (in float2 position, in float4 clipRect)
	{
	    float2 inside = step(clipRect.xy, position.xy) * step(position.xy, clipRect.zw);
	    return inside.x * inside.y;
	}
	
	inline fixed4 LGameGetUIDiffuseColor(in float2 position, in sampler2D mainTexture, in sampler2D alphaTexture, fixed4 textureSampleAdd)
	{
	    return fixed4(tex2D(mainTexture, position).rgb + textureSampleAdd.rgb, tex2D(alphaTexture, position).r + textureSampleAdd.a);
	}

	inline float LGameGetSoft2DClipping (in float2 position, in float4 clipRect , in float4 borderBlend)
	{
		float2 inside = smoothstep(clipRect.xy, clipRect.xy + borderBlend.xy, position.xy) * smoothstep(clipRect.zw, clipRect.zw - borderBlend.zw, position.xy);
	    return inside.x * inside.y;
	}

	#define LGameTransFormUV(uv,name) (uv.xy - 0.5) * name##_ST.xy + name##_ST.zw + 0.5;

	float2 LGameRotateUV(float2 uv,half uvRotate)
	{
		float2 outUV;
		half rotate = uvRotate/57.296;
		half2 sc = half2(sin(rotate), cos(rotate));
		
		outUV = uv - half2(0.5, 0.5);
		outUV = float2(outUV.x * sc.y - outUV.y * sc.x, outUV.x * sc.x + outUV.y * sc.y);
		outUV = outUV + half2(0.5, 0.5);
		return outUV;
	}
#endif