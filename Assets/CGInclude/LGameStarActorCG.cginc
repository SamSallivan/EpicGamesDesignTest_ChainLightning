#ifndef LGAME_STARACTOR_CG_INCLUDED
#define LGAME_STARACTOR_CG_INCLUDED
#include "UnityCG.cginc"
#include "AutoLight.cginc"	
#include "Lighting.cginc"	
#include "Assets/CGInclude/LGameStarActorPBS.cginc"	
#include "Assets/CGInclude/LGameStarActorEffect.cginc"	
#include "Assets/CGInclude/LGameCharacterDgs.cginc"
//Forword Base Pass
//Vertex Shader
v2f vert_base(a2v v)
{
	v2f o;
	float2 uv0 = v.uv0;
#ifdef _USE_DIRECT_GPU_SKINNING
	float4 tangent;
	float3 binormal;
	float3 normal;
	DecompressTangentNormal(v.tangent, tangent, normal, binormal);
	float4 vec = CalculateGPUSkin(v.skinIndices, v.skinWeights, v.vertex, tangent, normal, binormal);
	uv0 = DecompressUV(v.uv0, _uvBoundData);
#else
	float4 tangent = v.tangent;
	float3 normal = v.normal;
	float3 binormal = cross(normal, tangent.xyz) * tangent.w;
	float4 vec = v.vertex;
#endif
	
	UNITY_INITIALIZE_OUTPUT(v2f, o);
	float4 posWorld = mul(unity_ObjectToWorld, vec);
	o.tangentToWorld[0].w = posWorld.x;
	o.tangentToWorld[1].w = posWorld.y;
	o.tangentToWorld[2].w = posWorld.z;
	o.pos = UnityObjectToClipPos(vec);
	o.uv.xy = uv0;
	o.uv.zw = v.uv1;
	o.viewDir = UnityWorldSpaceViewDir(posWorld) + v.color.xyz * 0.00001;
	float3 normalWorld = UnityObjectToWorldNormal(normal);
	float3 tangentWorld = UnityObjectToWorldDir(tangent.xyz);
	float3 binormalWorld = UnityObjectToWorldDir(binormal) * unity_WorldTransformParams.w;
	o.tangentToWorld[0].xyz = tangentWorld;
	o.tangentToWorld[1].xyz = binormalWorld;
	o.tangentToWorld[2].xyz = normalWorld;
//Hair Trick
//Sphere Mapping From Houdini
#ifdef _HAIR
#ifdef _SPHERE_MAPPING
	o.proxyTangent = UnityObjectToWorldNormal(v.color.xyz*2.0 - 1.0);
#endif
//Detail Normal UV
#elif defined(_CHIFFON)
	o.detail_uv.xyzw = TRANSFORM_TEX(uv0, _DetailNormalMap).xyxy;
#ifdef _GLINT
	o.detail_uv.zw = TRANSFORM_TEX(uv0, _DiamondMap);
#endif
//Eye Trick
//Using For Front Direction
//#elif defined(_EYE)
//#ifdef _EYE_REFRACTION
//	o.frontDir = UnityObjectToWorldNormal(normalize(_FrontDir));
//#else
//	v.normal.z = -v.normal.z;
//	v.normal = -v.normal;
//	o.irisNormal = UnityObjectToWorldNormal(v.normal);
//#endif
#endif
/*Effect*/
	LGAME_STARACTOR_EFFECT_VERTEX(o)
	LGAME_STARACTOR_TRNASFER_SHADOW(o)
	return o;
}

//Forword Base Pass
//Fragment Shader
fixed4 frag_base(v2f i) : SV_Target
{
	//Effect
	//Evalution At Begin
	LGAME_STARACTOR_EFFECT_FRAGMENT_BEGIN(i)
	LGAME_STARACTOR_BASE_MATERIAL_DATA_SETUP(i)
	//Evalution At Base Data Setup
	LGAME_STARACTOR_EFFECT_FRAGMENT_SETUP(i,base)

//GI Switch
//Silk & Chiffon : Anisotropic GI
#if defined(_SILK)
	LGameGI gi = FragmentGI_Anisotropic(wPos, viewDir, base.normal, base.tangent, base.binormal, _Anisotropy, base.occlusion.r, base.perceptual_roughness);
//ClearCoat : 2 Layer
#elif defined(_CLEARCOAT)
	half cc_NoV = saturate(dot(base.cc_normal, viewDir));
	half fcc = F_Schlick(0.04, cc_NoV) * _ClearCoat;
	LGameGI gi = FragmentGI_ClearCoat(wPos,viewDir,base.normal, base.occlusion.r, base.perceptual_roughness,fcc,base.cc_normal,base.cc_perceptual_roughness);
//Base
#else
	LGameGI gi = FragmentGI(wPos, viewDir, base.normal, base.occlusion.r, base.perceptual_roughness);
#endif
//PBS
	half NoL = dot(base.normal, gi.direct.dir);
	half NoV = saturate(dot(base.normal, viewDir));
	LGAME_STARACTOR_LIGHT_ATTENUATION(atten, i, wPos, NoL);
	#ifdef _PET
	base.occlusion *= tex2D(_MetallicGlossMap, i.uv.xy).b;
	#endif
	fixed4 col = LGAME_BRDF_PBS(gi, base, viewDir, NoV, NoL, atten);

//Shader Gamma Correction
#ifdef UNITY_COLORSPACE_GAMMA
    col.rgb = LinearToGammaSpace(col.rgb);
#endif

//Emission
#ifdef _EMISSION
    col.rgb+= base.emission;
#endif

//Art Effect
//Character Raking Light
#ifndef _SCENE
    half3 RakingLight = LGame_RakingLight(wPos, viewDir, base.normal,NoV,atten, base.occlusion.g);
    col.rgb += RakingLight;
#endif

#ifdef _PET
    col.a = base.opacity;
#endif
	LGAME_STARACTOR_EFFECT_FRAGMENT_END(i,col)
	return col;
}
//Forword Add Pass
//Vertex Shader
v2f vert_add(a2v v)
{
	v2f o;
	UNITY_INITIALIZE_OUTPUT(v2f, o);
	float2 uv0 = v.uv0;
#ifdef _USE_DIRECT_GPU_SKINNING
	float4 tangent;
	float3 binormal;
	float3 normal;
	DecompressTangentNormal(v.tangent, tangent, normal, binormal);
	float4 vec = CalculateGPUSkin(v.skinIndices, v.skinWeights, v.vertex, tangent, normal, binormal);
	uv0 = DecompressUV(v.uv0, _uvBoundData);
#else
	float4 tangent = v.tangent;
	float3 normal = v.normal;
	float3 binormal = cross(normal, tangent.xyz) * tangent.w;
	float4 vec = v.vertex;
#endif
	
	float4 posWorld = mul(unity_ObjectToWorld, vec);
	o.pos = UnityObjectToClipPos(vec);
	o.uv = uv0.xyxy;
	o.viewDir = UnityWorldSpaceViewDir(posWorld);
	float3 normalWorld = UnityObjectToWorldNormal(normal);
	float3 tangentWorld = UnityObjectToWorldDir(tangent.xyz);
	half3 binormalWorld = UnityObjectToWorldDir(binormal) * unity_WorldTransformParams.w;
	o.tangentToWorld[0].xyz = tangentWorld;
	o.tangentToWorld[1].xyz = binormalWorld;
	o.tangentToWorld[2].xyz = normalWorld;
	o.tangentToWorld[0].w = posWorld.x;
	o.tangentToWorld[1].w = posWorld.y;
	o.tangentToWorld[2].w = posWorld.z;
#ifdef _SPHERE_MAPPING
	o.proxyTangent = UnityObjectToWorldNormal(v.color.xyz*2.0 - 1.0);
//#elif defined(_EYE)
//#ifdef _EYE_REFRACTION
//	half3 originVertex = mul(unity_ObjectToWorld, half4(0, 0, 0, 1));
//	half3 frontVertex = mul(unity_ObjectToWorld, half4(0, 0, -1, 1));
//	o.frontDir = normalize(frontVertex - originVertex);
//#else
//	normal.z = -normal.z;
//	normal = -normal;
//	o.irisNormal = UnityObjectToWorldNormal(normal);
//#endif
#endif
/*Effect*/
	LGAME_STARACTOR_EFFECT_VERTEX(o)
	UNITY_TRANSFER_SHADOW(o, v.uv1);
	return o;
}
//Forword Add Pass
//Fragment Shader
half4 frag_add(v2f i) : SV_Target
{
	LGAME_STARACTOR_EFFECT_FRAGMENT_BEGIN(i)
	LGAME_STARACTOR_BASE_MATERIAL_DATA_SETUP(i)
	LGAME_STARACTOR_EFFECT_FRAGMENT_SETUP(i,base)
	UNITY_LIGHT_ATTENUATION(atten, i, wPos);
	LGameDirectLight direct = LGameDirectLighting(wPos);
	fixed4 col = LGAME_BRDF_PBS_ADD(direct,base,viewDir, atten);
	//gamma空间下才需要做矫正
	#ifdef UNITY_COLORSPACE_GAMMA
	col.rgb = LinearToGammaSpace(col.rgb);
	#endif
	return col;
}
//PreZ Pass With Effect
v2f_preZ vert_preZ(a2v_simplest v)
{
	v2f_preZ o;
	o.pos = UnityObjectToClipPos(v.vertex);
	o.wPos = mul(unity_ObjectToWorld, v.vertex).xyz;
	LGAME_STARACTOR_EFFECT_VERTEX(o)
	return o;
}
fixed4 frag_preZ(v2f_preZ i) : SV_Target
{
	LGAME_STARACTOR_WORLD_CLIP(i.wPos, i.ScreenPosition)
	return 0;
}
#endif