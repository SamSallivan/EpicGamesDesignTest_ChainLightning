#pragma target 3.0
// #pragma exclude_renderers d3d11
#define _DUAL_RIMLIGHT
#include "UnityCG.cginc"
#include "AutoLight.cginc"	
#include "Lighting.cginc"	
#include "Assets/CGInclude/LGameStarActorLighting.cginc"	
#include "Assets/CGInclude/LGameStarActorBRDF.cginc"	

sampler2D _MainTex;
sampler2D _NoiseMap;
fixed3	_SubSurfaceColor;
fixed3	_SheenColor;
fixed4	_Color;
half4  _MainTex_ST;
float4 _NoiseMap_ST;
half _FurLength; 
half _FurOcclusion;
half _NoiseFade;
half _Gravity;
half4 _Wind;
#ifdef _METALLICGLOSSMAP
sampler2D   _MetallicGlossMap;
half        _GlossMapScale;
#else
half        _Glossiness;
#endif
#ifdef _NORMALMAP
sampler2D _BumpMap;
half _BumpScale;
#endif
//half _NoiseFadeLayer0;
half _NoiseFadeLayer1;
half _NoiseFadeLayer2;
half _NoiseFadeLayer3;
half _NoiseFadeLayer4;
half _NoiseFadeLayer5;
half _NoiseFadeLayer6;
half _NoiseFadeLayer7;
half _NoiseFadeLayer8;
half _NoiseFadeLayer9;
half _NoiseFadeLayer10;

#ifdef _FLOWMAP
sampler2D _FurFlowMap;
fixed _FlowMapScale;
#endif

//half _FurMultiplierLayer0;
half _FurMultiplierLayer1;
half _FurMultiplierLayer2;
half _FurMultiplierLayer3;
half _FurMultiplierLayer4;
half _FurMultiplierLayer5;
half _FurMultiplierLayer6;
half _FurMultiplierLayer7;
half _FurMultiplierLayer8;
half _FurMultiplierLayer9;
half _FurMultiplierLayer10;

half _OcclusionLayer0;
half _OcclusionLayer1;
half _OcclusionLayer2;
half _OcclusionLayer3;
half _OcclusionLayer4;
half _OcclusionLayer5;
half _OcclusionLayer6;
half _OcclusionLayer7;
half _OcclusionLayer8;
half _OcclusionLayer9;
half _OcclusionLayer10;

struct a2v
{
	float4 vertex			: POSITION;
	half2 uv0				: TEXCOORD0;
	half3 normal			: NORMAL;
	half4 tangent			: TANGENT;
};

struct v2f
{
	float4 pos				: SV_POSITION;
	half4 uv				: TEXCOORD0;
	half3 viewDir           : TEXCOORD1;
#ifdef _NORMALMAP
	half4 tangentToWorld[3]	: TEXCOORD2;
#else
	half3 wPos				: TEXCOORD2;
	half3 normalWorld       : TEXCOORD3;
#endif
};
v2f vert_shell(a2v v)
{
	v2f o;
	o.uv.xy = TRANSFORM_TEX(v.uv0, _MainTex);
	o.uv.zw = TRANSFORM_TEX(v.uv0, _NoiseMap);
	o.pos = UnityObjectToClipPos(v.vertex);
	half3 posWorld = mul(unity_ObjectToWorld, v.vertex).xyz;
	o.viewDir = UnityWorldSpaceViewDir(posWorld);
#ifdef _NORMALMAP
	float3 normalWorld = UnityObjectToWorldNormal(v.normal);
	float3 tangentWorld = UnityObjectToWorldDir(v.tangent.xyz);
	half3 binormalWorld = cross(normalWorld, tangentWorld) * v.tangent.w * unity_WorldTransformParams.w;
	o.tangentToWorld[0].xyz = tangentWorld;
	o.tangentToWorld[1].xyz = binormalWorld;
	o.tangentToWorld[2].xyz = normalWorld;
	o.tangentToWorld[0].w = posWorld.x;
	o.tangentToWorld[1].w = posWorld.y;
	o.tangentToWorld[2].w = posWorld.z;
#else
	o.wPos = posWorld;
	o.normalWorld = UnityObjectToWorldNormal(v.normal);
#endif
	return o;
}

float3 ComputeFurNormal(a2v v)
{
	half3 localGravityDir = UnityWorldToObjectDir(half3(0.0, -1.0, 0.0));
#ifdef _FASTEST_QUALITY
	return Unity_SafeNormalize(v.normal + localGravityDir * _Gravity);
#endif

	half3 localWind = UnityWorldToObjectDir(_Wind.xyz);
	localWind = localWind * abs(sin(_Time.y * _Wind.w)) * length(_Wind.xyz);
#ifdef _FLOWMAP
	float3 normalTS = UnpackScaleNormal(tex2Dlod(_FurFlowMap, float4(v.uv0, 0, 0)), _FlowMapScale);
	float3 normalOS = normalize(v.normal);
	float3 tangentOS = normalize(v.tangent.xyz);
	float3 bitangentOS = normalize(cross(normalOS, tangentOS) * v.tangent.w * unity_WorldTransformParams.w);
	float3 offsetNormal = tangentOS * normalTS.x + bitangentOS * normalTS.y + normalOS * normalTS.z;
	return Unity_SafeNormalize(offsetNormal + localGravityDir *_Gravity + localWind);
#else
	return Unity_SafeNormalize(v.normal + localGravityDir *_Gravity + localWind);
#endif

}

v2f vert_fur(a2v v)
{
	v2f o;
	o.uv.xy = TRANSFORM_TEX(v.uv0, _MainTex);
	o.uv.zw = TRANSFORM_TEX(v.uv0, _NoiseMap);
	half Mask = tex2Dlod(_OcclusionMap,float4(v.uv0,0,0)).b;
	Mask *= tex2Dlod(_MainTex, float4(v.uv0, 0, 0)).a;
	half FurMultiplier = _FurLength;
#ifdef _FUR_PASS_0
	FurMultiplier *= _FurMultiplierLayer1;
#elif defined(_FUR_PASS_1)
	FurMultiplier *= _FurMultiplierLayer2;
#elif defined(_FUR_PASS_2)
	FurMultiplier *= _FurMultiplierLayer3;
#elif defined(_FUR_PASS_3)
	FurMultiplier *= _FurMultiplierLayer4;
#elif defined(_FUR_PASS_4)
	FurMultiplier *= _FurMultiplierLayer5;
#elif defined(_FUR_PASS_5)
	FurMultiplier *= _FurMultiplierLayer6;
#elif defined(_FUR_PASS_6)
	FurMultiplier *= _FurMultiplierLayer7;
#elif defined(_FUR_PASS_7)
	FurMultiplier *= _FurMultiplierLayer8;
#elif defined(_FUR_PASS_8)
	FurMultiplier *= _FurMultiplierLayer9;
#elif defined(_FUR_PASS_9)
	FurMultiplier *= _FurMultiplierLayer10;
#endif

	v.vertex.xyz += ComputeFurNormal(v) * FurMultiplier * Mask;
// 	half3 localGravityDir = UnityWorldToObjectDir(half3(0.0, -1.0, 0.0));
// #ifndef	_FASTEST_QUALITY
// 	half3 localWind = UnityWorldToObjectDir(_Wind.xyz);
// 	localWind = localWind * abs(sin(_Time.y * _Wind.w)) * length(_Wind.xyz);
// 	#if defined(_NORMALMAP) && defined(_FLOWMAP)
// 	float3 normalTS = UnpackScaleNormal(tex2Dlod(_FurFlowMap, float4(v.uv0, 0, 0)), _FlowMapScale);
// 	float3 normalOS = normalize(v.normal);
// 	float3 tangentOS = normalize(v.tangent.xyz);
// 	float3 bitangentOS = normalize(cross(normalOS, tangentOS) * v.tangent.w * unity_WorldTransformParams.w);
// 	float3 offsetNormal = tangentOS * normalTS.x + bitangentOS * normalTS.y + normalOS * normalTS.z;
// 	v.vertex.xyz += Unity_SafeNormalize(offsetNormal + localGravityDir *_Gravity + localWind) * FurMultiplier * Mask;
// 	#else
// 	v.vertex.xyz += Unity_SafeNormalize(v.normal + localGravityDir *_Gravity + localWind) * FurMultiplier * Mask;
// 	#endif
// #else
// 	v.vertex.xyz += Unity_SafeNormalize(v.normal + localGravityDir * _Gravity) * FurMultiplier * Mask;
// #endif
	half3 posWorld = mul(unity_ObjectToWorld, v.vertex).xyz;
	o.pos = mul(UNITY_MATRIX_VP, half4(posWorld,1.0));
	o.viewDir = UnityWorldSpaceViewDir(posWorld);
#ifdef _NORMALMAP
	float3 normalWorld = UnityObjectToWorldNormal(v.normal);
	float3 tangentWorld = UnityObjectToWorldDir(v.tangent.xyz);
	half3 binormalWorld = cross(normalWorld, tangentWorld) * v.tangent.w * unity_WorldTransformParams.w;
	o.tangentToWorld[0].xyz = tangentWorld;
	o.tangentToWorld[1].xyz = binormalWorld;
	o.tangentToWorld[2].xyz = normalWorld;
	o.tangentToWorld[0].w = posWorld.x;
	o.tangentToWorld[1].w = posWorld.y;
	o.tangentToWorld[2].w = posWorld.z;
#else
	o.wPos = posWorld;
	o.normalWorld = UnityObjectToWorldNormal(v.normal);
#endif
	return o;
}
fixed4 frag_fur(v2f i) : SV_Target
{
	half3 viewDir = normalize(i.viewDir.xyz);
#ifdef _NORMALMAP
	half3 wPos = half3(i.tangentToWorld[0].w, i.tangentToWorld[1].w, i.tangentToWorld[2].w);
	half3 Normal = UnpackScaleNormal(tex2D(_BumpMap, i.uv.xy), _BumpScale);
	Normal = normalize(i.tangentToWorld[0].xyz*Normal.r + i.tangentToWorld[1].xyz*Normal.g + i.tangentToWorld[2].xyz*Normal.b);
#else
	half3 wPos =  i.wPos;
	half3 Normal = normalize(i.normalWorld);
#endif
	half4 Albedo = tex2D(_MainTex, i.uv.xy); // * _Color;
	Albedo.rgb *= _Color.rgb;
	half mask = Albedo.a;
#ifdef UNITY_COLORSPACE_GAMMA
	Albedo.rgb = GammaToLinearSpace(Albedo.rgb);
#endif
#ifdef _METALLICGLOSSMAP
	half Smoothness = tex2D(_MetallicGlossMap, i.uv).g * _GlossMapScale;
#else
	half Smoothness = _Glossiness;
#endif
	half PerceptualRoughness = 1.0 - Smoothness;
	half Roughness = max(0.001, PerceptualRoughness * PerceptualRoughness);
	half4 _ColorSpaceDielectricSpec = half4(0.04, 0.04, 0.04, 1.0 - 0.04);
	half OneMinusReflectivity = _ColorSpaceDielectricSpec.a;
	half3 DiffColor = Albedo.rgb;
	half3 SpecColor = _SheenColor.rgb;
	half NoiseFade = _NoiseFade;
	half AmbientOcclusion = 1.0;
#ifdef _FUR_PASS_0
	AmbientOcclusion *= _OcclusionLayer1;
	NoiseFade *= _NoiseFadeLayer1;
#elif defined(_FUR_PASS_1)
	AmbientOcclusion *= _OcclusionLayer2;
	NoiseFade *= _NoiseFadeLayer2;
#elif defined(_FUR_PASS_2)
	AmbientOcclusion *= _OcclusionLayer3;
	NoiseFade *= _NoiseFadeLayer3;
#elif defined(_FUR_PASS_3)
	AmbientOcclusion *= _OcclusionLayer4;
	NoiseFade *= _NoiseFadeLayer4;
#elif defined(_FUR_PASS_4)
	AmbientOcclusion *= _OcclusionLayer5;
	NoiseFade *= _NoiseFadeLayer5;
#elif defined(_FUR_PASS_5)
	AmbientOcclusion *= _OcclusionLayer6;
	NoiseFade *= _NoiseFadeLayer6;
#elif defined(_FUR_PASS_6)
	AmbientOcclusion *= _OcclusionLayer7;
	NoiseFade *= _NoiseFadeLayer7;
#elif defined(_FUR_PASS_7)
	AmbientOcclusion *= _OcclusionLayer8;
	NoiseFade *= _NoiseFadeLayer8;
#elif defined(_FUR_PASS_8)
	AmbientOcclusion *= _OcclusionLayer9;
	NoiseFade *= _NoiseFadeLayer9;
#elif defined(_FUR_PASS_9)
	AmbientOcclusion *= _OcclusionLayer10;
	NoiseFade *= _NoiseFadeLayer10;
#endif
	AmbientOcclusion = lerp(1.0.xxx, AmbientOcclusion, _FurOcclusion);
	LGameGI gi = FragmentGI(wPos, viewDir, Normal, AmbientOcclusion, PerceptualRoughness);
	half3 H = normalize(gi.direct.dir + viewDir);
	half NoV = saturate(dot(Normal, viewDir));
	half NoL = dot(Normal, gi.direct.dir);
	half NoH = saturate(dot(Normal, H));
	half LoH = saturate(dot(gi.direct.dir, H));
	half3 DiffuseTerm = gi.direct.color * AmbientOcclusion * saturate((NoL + 0.5) / 2.25);
	NoL = saturate(NoL);
	DiffuseTerm *= saturate(_SubSurfaceColor + NoL * AmbientOcclusion);
	half3 SpecularTerm = Velvet_Specular_BxDF(NoL, NoV, NoH, LoH, Roughness, SpecColor);
	SpecularTerm = SpecularTerm - 1e-4f;
	SpecularTerm = clamp(SpecularTerm, 0.0, 100.0);
	half3 Color = (DiffColor + SpecularTerm) * DiffuseTerm;
	Color += gi.indirect.diffuse * DiffColor;

#ifndef	_FASTEST_QUALITY
	half SurfaceReduction = (0.6 - 0.08 * PerceptualRoughness);
	SurfaceReduction = 1.0 - Roughness * PerceptualRoughness * SurfaceReduction;
	half GrazingTerm = saturate(Smoothness + (1.0 - OneMinusReflectivity));
	Color += SurfaceReduction * gi.indirect.specular * FresnelLerpFast(SpecColor, GrazingTerm, NoV);
#endif

#ifdef UNITY_COLORSPACE_GAMMA
	Color.rgb = LinearToGammaSpace(Color.rgb);
#endif
	Color.rgb += LGame_RakingLight(wPos, viewDir, Normal, NoV,1.0,1.0);
	//Alpha
	half Noise = tex2D(_NoiseMap, frac(i.uv.zw)).r;
	NoiseFade = clamp(1.0 - NoiseFade, 0.01, 0.99);
	Noise = pow(Noise, 1.0 / NoiseFade);
	return  fixed4(Color.rgb, Noise * mask);
}
/*
 * 
 */
struct v2f_solid
{
	half4 pos				: SV_POSITION;
	half4 uv				: TEXCOORD0;
	half3 wNormal			: TEXCOORD1;
	half3 lightDir			: TEXCOORD2;
};
v2f_solid vert_solid(a2v v)
{
	v2f_solid o;
	o.uv.xy = TRANSFORM_TEX(v.uv0, _MainTex);
	o.pos = UnityObjectToClipPos(v.vertex);
	o.wNormal= UnityObjectToWorldNormal(v.normal);
	half3 posWorld = mul(unity_ObjectToWorld, v.vertex).xyz;
	o.lightDir = UnityWorldSpaceLightDir(posWorld);
	return o;
}
fixed4 frag_solid(v2f_solid i) : SV_Target
{
	half3 Normal = normalize(i.wNormal);
	half3 LightDir = normalize(i.lightDir);
	half4 Albedo = tex2D(_MainTex, i.uv.xy) * _Color;
#ifdef UNITY_COLORSPACE_GAMMA
	Albedo.rgb = GammaToLinearSpace(Albedo.rgb);
#endif
	half3 DiffColor = Albedo.rgb;
	half AmbientOcclusion = _OcclusionLayer0;
	AmbientOcclusion = lerp(1.0, AmbientOcclusion, _FurOcclusion);
	half NoL = dot(Normal, LightDir);
	half3 DiffuseTerm = _LightColor0 * AmbientOcclusion * saturate((NoL + 0.5) / 2.25);
	NoL = saturate(NoL);
	DiffuseTerm *= saturate(_SubSurfaceColor + NoL * AmbientOcclusion);
	half3 Color = DiffColor * DiffuseTerm + _AmbientCol.rgb * DiffColor;
#ifdef UNITY_COLORSPACE_GAMMA
	Color.rgb = LinearToGammaSpace(Color.rgb);
#endif
	return  fixed4(Color.rgb, _Color.a);
}
/*
 *
 */
struct a2v_overlay
{
	half4 vertex			: POSITION;
	half2 uv0				: TEXCOORD0;
	half2 uv1				: TEXCOORD1;
	half3 normal			: NORMAL;
	half4 tangent			: TANGENT;
};
struct v2f_overlay
{
	half4 pos				: SV_POSITION;
	half3 wPos				: TEXCOORD0;
	LGAME_STARACTOR_SHADOW_COORDS(1)
};
v2f_overlay vert_overlay(a2v_overlay v)
{
	v2f_overlay o;
	o.pos = UnityObjectToClipPos(v.vertex);
	half3 posWorld = mul(unity_ObjectToWorld, v.vertex).xyz;
	o.wPos = posWorld;
	LGAME_STARACTOR_TRNASFER_SHADOW(o)
	return o;
}
fixed4 frag_overlay(v2f_overlay i) : SV_Target
{
	LGAME_STARACTOR_LIGHT_ATTENUATION(atten, i, i.wPos, 1.0);
	half3 Color = atten * saturate(_SubSurfaceColor * 0.667 + atten) ;
	return fixed4(Color,1.0);
}

struct a2v_shadow
{
	half4 vertex : POSITION;
	half3 normal : NORMAL;
};
struct v2f_shadow {
	V2F_SHADOW_CASTER;
};
v2f_shadow vert_shadow(a2v_shadow v)
{
	v2f_shadow o;
	o.pos = UnityObjectToClipPos(v.vertex);
	TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
	return o;
}
float4 frag_shadow(v2f_shadow i) : SV_Target
{
	SHADOW_CASTER_FRAGMENT(i)
}