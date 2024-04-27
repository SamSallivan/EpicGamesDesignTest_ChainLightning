Shader "Hidden/ShadowKawaseBlur" {
	Properties{
		_MainTex("Base (RGB)", 2D) = "" {}
	}

	CGINCLUDE

	#include "UnityCG.cginc"

	struct v2f {
		float4 pos : SV_POSITION;
		float2 uv : TEXCOORD0;
	};

	half _Offset;
	sampler2D _MainTex;
	float4 _MainTex_TexelSize;
	float4 _MainTex_ST;


	half4 KawaseBlur(sampler2D tex, float2 uv, float2 texelSize, half pixelOffset)
	{
		half4 o = 0;
		o += tex2D(tex, uv + float2(pixelOffset + 0.5, pixelOffset + 0.5) * texelSize);
		o += tex2D(tex, uv + float2(-pixelOffset - 0.5, pixelOffset + 0.5) * texelSize);
		o += tex2D(tex, uv + float2(-pixelOffset - 0.5, -pixelOffset - 0.5) * texelSize);
		o += tex2D(tex, uv + float2(pixelOffset + 0.5, -pixelOffset - 0.5) * texelSize);
		return o * 0.25;
	}

	v2f VertDefault(appdata_img v) 
	{
		v2f o;
		o.pos = UnityObjectToClipPos(v.vertex);
		o.uv.xy = v.texcoord.xy;
		return o;
	}

	half4 Frag(v2f i) : SV_Target
	{
		return KawaseBlur(_MainTex, i.uv.xy, _MainTex_TexelSize.xy, _Offset);
	}

	ENDCG

	Subshader
	{
		Cull Off ZWrite Off ZTest Always

		Pass
		{
			//ZTest Always
			//Cull Off
			//ZWrite Off
			Fog { Mode off }

			CGPROGRAM
			#pragma fragmentoption ARB_precision_hint_fastest
			#pragma vertex VertDefault
			#pragma fragment Frag
			ENDCG
		}
	}

	Fallback off
}