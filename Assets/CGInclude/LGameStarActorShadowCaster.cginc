#ifndef LGAME_STARACTOR_SHADOWCASTER_INCLUDED
#define LGAME_STARACTOR_SHADOWCASTER_INCLUDED
#include "UnityCG.cginc"
#include "AutoLight.cginc"	
#include "Lighting.cginc"	
#include "LGameStarActorEffect.cginc"
#include "Assets/CGInclude/LGameCharacterDgs.cginc"
/*Shadow Pass*/
#ifndef _ENABLE_TRANSPARENT_SHADOW
	#undef _TRANSPARENT_SHADOW
#endif
#ifdef _TRANSPARENT_SHADOW
sampler3D _DitherMaskLOD;
sampler2D _MainTex;
float4 _MainTex_ST;
fixed4 _Color;
#endif
struct a2v_Shadow
{
	float4 vertex	: POSITION;
	float2 uv		: TEXCOORD0;
	half3 normal	: NORMAL;
#ifdef _USE_DIRECT_GPU_SKINNING
	half4 tangent	: TANGENT;
	float4 skinIndices : TEXCOORD2;
	float4 skinWeights : TEXCOORD3;
#endif
};
struct v2f_Shadow 
{
	V2F_SHADOW_CASTER;
#ifdef _TRANSPARENT_SHADOW
	float2 uv		:TEXCOORD2;
#endif
#ifdef _WORLD_CLIP
	half4 screenPos			: TEXCOORD3;
	half4 posWorld			: TEXCOORD4;
#endif
};
v2f_Shadow Vert_Shadow(a2v_Shadow v)
{
#if _USE_DIRECT_GPU_SKINNING
	float3 binormal;
	float3 normal;
	float4 tangent;
	DecompressTangentNormal(v.tangent, tangent, normal, binormal);
	v.vertex = CalculateGPUSkin(v.skinIndices, v.skinWeights, v.vertex, tangent, normal, binormal);
	v.uv.xy = DecompressUV(v.uv.xy, _uvBoundData);
	v.normal = normal;
#endif

	v2f_Shadow o;
	o.pos = UnityObjectToClipPos(v.vertex);
	TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
#ifdef _TRANSPARENT_SHADOW
	o.uv = TRANSFORM_TEX(v.uv, _MainTex);
#endif
	/*Effect*/
#ifdef _WORLD_CLIP
	o.screenPos = ComputeScreenPos(o.pos);
	o.posWorld = mul(unity_ObjectToWorld, v.vertex);
#endif
	return o;
}
float4 Frag_Shadow(
#ifdef _TRANSPARENT_SHADOW
	UNITY_POSITION(vpos),
#endif
	v2f_Shadow i) : SV_Target
{
#ifdef _WORLD_CLIP
		LGame_Effect_WorldClip(i.posWorld.xyz,i.screenPos);
#endif
#ifdef _TRANSPARENT_SHADOW
		half Alpha = tex2D(_MainTex, i.uv.xy).a * _Color.a;
		half AlphaRef = tex3D(_DitherMaskLOD, half3(vpos.xy * 0.25,Alpha * 0.9375)).a;
		clip(AlphaRef - 0.01);
#endif
		SHADOW_CASTER_FRAGMENT(i)
}
#endif