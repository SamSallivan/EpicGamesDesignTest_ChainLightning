Shader "Hidden/VerticalFog"
{
	Properties
	{
		_MainTex("Texture", 2D) = "white" {}
	}
	CGINCLUDE
	#include "UnityCG.cginc"
	struct appdata
	{
		float4 vertex : POSITION;
		float2 uv : TEXCOORD0;
	};
	struct v2f
	{
		float2 uv : TEXCOORD0;
		float4 vertex : SV_POSITION;
	};
	v2f vert(appdata v)
	{
		v2f o;
		o.vertex = UnityObjectToClipPos(v.vertex);
		o.uv = v.uv;
		return o;
	}
	sampler2D _MainTex;
	sampler2D _ParticleTexture;
	sampler2D _CameraDepthTexture;
	sampler2D _ColorTexture;
	half _FogTop;
	half _FogBottom;
	half _HeightDensity;
	half _DistanceDensity;
	half _ParticleDensity;
	half _BlendLocation;
	half _AspectRatio;
	half _Transmission;
	half _Distribution;
	half2 _DensityRange;
	float2 _FlowSpeed;
	float2 _TextureSpaceSunPosition;
	fixed4 _SingleColor;
	fixed4 _GradientColor[3];
	float4 _MainTex_ST;
	float4 ComputeWorldSpacePosFromDepthAndInvProjMat(float Depth , float2 UV)
	{
		float4 clipPos = float4(UV, Depth, 1.0);
		clipPos.xyz = 2.0 * clipPos.xyz - 1.0;
		float4 camPos = mul(unity_CameraInvProjection, clipPos);
		camPos.xyz /= camPos.w;
		camPos.z *= -1.0;
		float4 wPos = mul(unity_CameraToWorld, half4(camPos.xyz, 1.0));
		return wPos;
	}
	#define MOD3 float3(443.8975,397.2973, 491.1871)
	float Hash12(float2 Position)
	{
		float3 P3 = frac(float3(Position.xyx) * MOD3);
		P3 += dot(P3, P3.yzx + 19.19);
		return frac((P3.x + P3.y) * P3.z);
	}
	float DitherClip(float2 Position,float Alpha)
	{
		float its = lerp(0.0f, 1.0f / 32.0f, Alpha);
		Position += frac(_Time.y * _FlowSpeed);
		float Rand = Hash12(Position) + Hash12(Position + 0.59374) - 0.5;
		float Dither = its + Rand / 255.0;
		Dither = floor(Dither * 255.0) / 255.0;
		Dither *= 32.0;
		return saturate(Dither);
	}
	half3 VerticalFog(float3 wPos, half3 Color , half2 UV, float Depth,half2 temp)
	{
		float Linear_01_Depth = Linear01Depth(Depth);
		float Linear_Eye_Depth = LinearEyeDepth(Depth);
		half HeightFactor = (_FogTop - wPos.y) / (_FogTop - _FogBottom);
		half DistanceFactor = exp2(-(_DistanceDensity * Linear_Eye_Depth));
		half Linear = saturate((wPos.y - _FogBottom) / (_FogTop - _FogBottom) + DistanceFactor);
#if defined(_ENABLE_SUN)
		half Temp = saturate(length(UV - _TextureSpaceSunPosition));
		Temp= (1.0 - Temp) * _Transmission;
		Temp = pow(Temp, _Distribution) * Linear_01_Depth;
		Linear = saturate(Linear + Temp);
#endif

#if defined(_DITHER)
		float Dither = DitherClip(UV, Linear);
		Dither = lerp(1.0, Dither, Linear_01_Depth * _ParticleDensity);
		Linear = saturate(Linear * Dither);
#endif
		half4 FogColor;
#if defined(_COLOR)
		FogColor = _SingleColor;
#elif defined(_GRADIENT) 
		FogColor = lerp(_GradientColor[0], _GradientColor[1], clamp(Linear , 0.0 , _BlendLocation) / _BlendLocation);
		half OneMinusBlendLocation = 1.0 - _BlendLocation;
		FogColor = lerp(FogColor, _GradientColor[2], (clamp(Linear , _BlendLocation, 1.0)- _BlendLocation )/ OneMinusBlendLocation);
#elif defined(_TEXTURE) 
		FogColor = tex2D(_ColorTexture, half2(Linear, 0.5));
#endif
		HeightFactor = saturate(HeightFactor * _HeightDensity);
		HeightFactor = clamp(HeightFactor, _DensityRange.x, _DensityRange.y);
#if defined(UNITY_COLORSPACE_GAMMA)
		HeightFactor = LinearToGammaSpace(HeightFactor);
#endif
		half3 Fog = lerp(Color.rgb, FogColor.rgb, HeightFactor);
		Fog = lerp(Fog.rgb, Color.rgb, DistanceFactor);
		return Fog;
	}
	ENDCG
		SubShader
	{
		Cull Off ZWrite Off ZTest Always
		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag	
			#pragma multi_compile _COLOR _GRADIENT _TEXTURE
			#pragma multi_compile _ _ENABLE_SUN			
			#pragma multi_compile _ _DITHER
			half4 frag(v2f i) : SV_Target
			{ 
				float Depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv);
				float ReversedDepth = Depth;
#if defined(UNITY_REVERSED_Z)
				ReversedDepth = 1.0 - Depth;
#endif
				half4 wPos = ComputeWorldSpacePosFromDepthAndInvProjMat(ReversedDepth,i.uv);
				half3 Color = tex2D(_MainTex, i.uv);
				half2 UV = i.uv;
				UV.y *= _AspectRatio;
				half3 Fog = VerticalFog(wPos.xyz, Color, UV, Depth, i.uv);
				return half4(Fog, 1.0);
			}
			ENDCG
		}
	}
}
