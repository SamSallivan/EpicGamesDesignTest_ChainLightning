Shader "Hidden/MotionBlurFur" {
	Properties {
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_MotionTex ("Motion (RGB)", 2D) = "white" {}
	}
	CGINCLUDE
	#pragma fragmentoption ARB_precision_hint_fastest
	#pragma exclude_renderers flash
	#include "UnityCG.cginc"
	sampler2D _MotionTex;
	sampler2D _MainTex;
	float4 _MainTex_ST;
	half4 _BLUR_STEP;
	float4 _MainTex_TexelSize;
	float4 _MotionTex_TexelSize;
	struct v2f
	{
		float4 pos : SV_POSITION;
		float4 uv : TEXCOORD0;
	};
	v2f vert(appdata_img v)
	{
		v2f o = (v2f)0;
		o.pos = UnityObjectToClipPos(v.vertex);
		o.uv.xy = v.texcoord.xy;
		o.uv.zw = v.texcoord.xy;
#if UNITY_UV_STARTS_AT_TOP
		if (_MainTex_TexelSize.y < 0)
			o.uv.w = 1 - o.uv.w;
#endif
		return o;
	}
	float ig_noise(float2 screenPos)
	{
		const float3 magic = float3(0.06711056, 0.00583715, 52.9829189);
		return frac(magic.z * frac(dot(screenPos, magic.xy)));
	}
	half4 frag(v2f i) : SV_Target
	{
		half4 motion = tex2D(_MotionTex, i.uv.xy);
		half4 color = tex2D(_MainTex, i.uv.zw);
		half4 accum = half4(color.xyz, 1.0);
		motion.xy = motion.xy * 2.0 - 1.0;
		half2 dir_step0 = _BLUR_STEP.xy * motion.xy;
		half2 dir_step1 = dir_step0 * 0.5;
		dir_step0 *= ig_noise((i.uv.xy - dir_step0) * _MainTex_TexelSize.zw + 0.0) + 0.5;
		dir_step1 *= ig_noise((i.uv.xy - dir_step1) * _MainTex_TexelSize.zw + 1.0) + 0.5;
		half4 sample_color0 = tex2D(_MainTex, i.uv.zw - dir_step0);
		half4 sample_color1 = tex2D(_MainTex, i.uv.zw - dir_step1);
		half4 sample_color2 = tex2D(_MainTex, i.uv.zw + dir_step1);
		half4 sample_color3 = tex2D(_MainTex, i.uv.zw + dir_step0);
		half2 motion_dir0 = _MotionTex_TexelSize.xy * half2(1000.0, 1000.0) * dir_step0;
		half2 motion_dir1 = _MotionTex_TexelSize.xy * half2(-1000.0, 1000.0) * dir_step0;
		half sample_mag = motion.z;
		sample_mag+=tex2D(_MotionTex, i.uv.xy + motion_dir0).z;
		sample_mag += tex2D(_MotionTex, i.uv.xy - motion_dir0).z;
		sample_mag += tex2D(_MotionTex, i.uv.xy + motion_dir1).z;
		sample_mag += tex2D(_MotionTex, i.uv.xy - motion_dir1).z;
		//sample_mag *= ig_noise(sample_mag.xx* _MainTex_TexelSize.zw);
		sample_mag = saturate(sample_mag);
		half4 sample_color = accum;
		sample_color += half4(sample_color0.xyz, 1.0);
		sample_color += half4(sample_color1.xyz, 1.0);
		sample_color += half4(sample_color2.xyz, 1.0);
		sample_color += half4(sample_color3.xyz, 1.0);
		sample_color = sample_color / 5.0;
		sample_color = lerp(accum,sample_color,sample_mag);
		return sample_color;
	}
	ENDCG
	SubShader {
		ZTest Always Cull Off ZWrite Off Fog { Mode off }
		Pass {
			Name "Fur"
			CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag
				#pragma target 3.0
				#pragma exclude_renderers d3d11_9x
			ENDCG
		}
	}
	Fallback Off
}
