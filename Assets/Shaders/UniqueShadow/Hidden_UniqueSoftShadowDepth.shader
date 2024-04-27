Shader "Hidden/Unique Soft Shadow Depth"
{
	Properties
	{
		//Transparent
		_Color("Color", Color) = (1,1,1,1)
		_MainTex("Main Texture",2D) = "white"{}
		//Effect
		_DissolveMap("Dissolve Map",2D) = "black"{}
		_Dissolve("Dissolve",Range(0,1)) = 1.0
		_WorldOrigin("World Origin",Vector) = (0,0,0,0)
		_WorldTerminal("World Terminal",Vector) = (0,0,0,0)
		[Enum(Forward,0,Backward,1)]_WorldDirection("World Direction",Float) = 0
		_WorldClip("World Clip", Float) = 0.0
		_DissolveClip("Dissolve Clip",Range(0,1)) = 0.0
		[Enum(uv0,0,uv1,1)]_DissolveUVChannel("Dissolve UV Channel",Float) = 0
		//Cull Front
		[HideInInspector][Enum(UnityEngine.Rendering.CullMode)]_ShadowCullMode("Shadow Cull Mode",int) = 1
	}
	CGINCLUDE
	#include "UnityCG.cginc"
	#include "Assets/CGInclude/LGameStarActorEffect.cginc"	
#ifndef _ENABLE_TRANSPARENT_SHADOW
	#undef _TRANSPARENT_SHADOW
#endif
	struct a2v
	{
		float4	vertex			:POSITION;
		float3 normal			:NORMAL;
		float2 uv0				:TEXCOORD0;
		float2 uv1				:TEXCOORD1;
		half3 color				:COLOR;
	};

	struct v2f
	{
		float4	pos				:SV_POSITION;
		float4 uv				:TEXCOORD0;

		half3 color				:TEXCOORD1;
		/*Effect*/
#ifdef _WORLD_CLIP
		half4 screenPos			:TEXCOORD2;
		half4 posWorld			:TEXCOORD3;
#endif
	};
	float4 u_LightShadowBias;
#ifdef _TRANSPARENT_SHADOW
	sampler2D _MainTex;
	sampler3D _DitherMaskLOD;
	float4 _MainTex_ST;
	fixed4 _Color;
#endif
	v2f vert(a2v v) 
	{
		v2f o;
		o.uv.xy = v.uv0;
		o.uv.zw = v.uv1;
		float4 wPos = mul(unity_ObjectToWorld, v.vertex);
/*
 *用于特效裁剪的世界位置和屏幕位置不应该受到偏移影响
 */
#ifdef _WORLD_CLIP
		float4 cPos= mul(UNITY_MATRIX_VP, wPos);
		o.screenPos = ComputeScreenPos(cPos);
		o.posWorld = wPos;
#endif
		//Normal Bias
		if (u_LightShadowBias.z != 0.0f)
		{
			float3 wNormal = UnityObjectToWorldNormal(v.normal);
			float3 wLight = normalize(UnityWorldSpaceLightDir(wPos.xyz));
			float shadowCos = dot(wNormal, wLight);
			float shadowSine = sqrt(1.0f - shadowCos * shadowCos);
			float normalBias = u_LightShadowBias.z * shadowSine;
			wPos.xyz -= wNormal * normalBias;
		}
		o.pos = mul(UNITY_MATRIX_VP, wPos);
		// Depth Bias
#if defined(UNITY_REVERSED_Z)
		// We use max/min instead of clamp to ensure proper handling of the rare case
		// where both numerator and denominator are zero and the fraction becomes NaN.
		// UNITY_NEAR_CLIP_VALUE是NDC空间z的最小值
		// o.pos.w * UNITY_NEAR_CLIP_VALUE即在当前位置经过透视矩阵计算后的当前位置的z最小值
		// clamped代表的是光源背面（近似）的点的z值
		o.pos.z += max(-1.0f, min(u_LightShadowBias.x / o.pos.w, 0.0f));
		// 值域保护
		float clamped = min(o.pos.z, o.pos.w * UNITY_NEAR_CLIP_VALUE);
#else
		o.pos.z += saturate(u_LightShadowBias.x / o.pos.w);
		float clamped = max(o.pos.z, o.pos.w * UNITY_NEAR_CLIP_VALUE);
#endif
		// u_LightShadowBias.y对于平行光为1.0
		// 简化计算
		o.pos.z = lerp(o.pos.z, clamped, u_LightShadowBias.y);
		o.pos.z = clamped;
		/*
		 * 此方案未考虑齐次坐标系透视除法
		 * 此方案未考虑值域保护
#if defined(UNITY_REVERSED_Z)
		o.pos.z += u_LightShadowBias.x;
#else
		o.pos.z -= u_LightShadowBias.x;
#endif
		*/
		o.color = v.color.rgb;
		return o;
	}
	float4 frag(
#ifdef _TRANSPARENT_SHADOW
		UNITY_POSITION(vpos),
#endif
	v2f i) : SV_Target
	{
/*
 *特效裁剪
 */
#ifdef _DISSOLVE
		LGame_Effect_Dissolve(i.uv);
#endif
#ifdef _WORLD_CLIP
		LGame_Effect_WorldClip(i.posWorld.xyz,i.screenPos);
#endif
/*
 *顶点色Mask裁剪
 */
		clip(i.color.r - 0.5);
/*
 *半透明阴影Dither裁剪
 */
#ifdef _TRANSPARENT_SHADOW
		half alpha = tex2D(_MainTex, TRANSFORM_TEX(i.uv.xy, _MainTex)).a * _Color.a;
		half alphaRef = tex3D(_DitherMaskLOD, float3(vpos.xy * 0.25,alpha * 0.9375)).a;
		clip(alphaRef - 0.01);
#endif
		return 0.0f;
	}
	ENDCG
	SubShader
	{
		Tags{ "LightMode" = "ForwardBase" "RenderType" = "Opaque" }
		Cull Front
		ColorMask 0
		Pass{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile __ _WORLD_CLIP
			#pragma multi_compile __ _DISSOLVE
			ENDCG
		}
	}
	SubShader
	{
		Tags{ "LightMode" = "ForwardBase" "RenderType" = "UniqueShadow" }
		// SetReplacementShader()疑似有bug，_ShadowCullMode不会被bind到Cull State，下面这行永远为Cull Off @kittyjdhe 2023-9-15
		Cull [_ShadowCullMode]
		ColorMask 0
		Pass{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile __ _TRANSPARENT_SHADOW
			#pragma multi_compile __ _ENABLE_TRANSPARENT_SHADOW
			#pragma multi_compile __ _WORLD_CLIP
			#pragma multi_compile __ _DISSOLVE
			ENDCG
		}
	}
	// 对栅格状自阴影问题，强制Cull Front增大阴影精度容错 @kittyjdhe 2023-9-15
	SubShader
	{
		Tags { "LightMode"="ForwardBase" "RenderType"="UniqueShadowFrontCull" }
		Cull Front
		ColorMask 0
		Pass 
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile __ _TRANSPARENT_SHADOW
			#pragma multi_compile __ _ENABLE_TRANSPARENT_SHADOW
			#pragma multi_compile __ _WORLD_CLIP
			#pragma multi_compile __ _DISSOLVE
			ENDCG
		}
	}
}
