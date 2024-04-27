#ifndef LGAME_STARACTOR_INPUT_INCLUDED
#define LGAME_STARACTOR_INPUT_INCLUDED
#include "LGameStarActorLighting.cginc"
#include "LGameStarActorEffect.cginc"
#define LGAME_STARACTOR_BASE_MATERIAL_DATA_SETUP(i)\
	BaseMaterialData base;\
	half3 viewDir;\
	float3 wPos;\
	BaseMateiralDataSetup(i, viewDir, wPos, base);


sampler2D _MainTex;
sampler2D _BumpMap;
half	_BumpScale;
half4  _MainTex_ST;
fixed4	_Color;

#ifdef _GLINT
sampler2D _DiamondMap;
half4  _DiamondMap_ST;
half	_GlintStrength;
half	_GlintPower;
half    _GlintSpeed;
#endif

#if defined(_CHIFFON)
sampler2D _DetailMaskMap;
sampler2D _DetailNormalMap;
half4	_DetailNormalMap_ST;
half	_DetailNormalScale;
#endif

#if defined(_VELVET)||defined(_CHIFFON)
fixed3	_SheenColor;
#endif

#ifdef _METALLICGLOSSMAP
sampler2D   _MetallicGlossMap;
float        _GlossMapScale;
#else
#ifndef _SILK
half        _Metallic;
#endif
half        _Glossiness;
#endif

#ifdef _HAIR
#ifndef _SPHERE_MAPPING
sampler2D _TangentMap;
#endif
sampler2D _HairDataMap;
#endif

#if defined(_SILK)||defined(_ANISOTROPY)
half _Anisotropy;
#endif

#ifdef _CLEARCOAT
sampler2D	_ClearCoatNormalMap;
half		_ClearCoat;
half		_ClearCoatRoughness;
#endif

/*
#ifdef _EYE
sampler2D _EyeDataMap;
half3 _FrontDir;
half3 _RightDir;
#ifdef _EYE_REFRACTION
half _IOR;
half _Radius;
half _RefractionStrength;
sampler2D _IrisNormalMap;
sampler2D _IrisMap;
#endif
#endif
*/

#ifdef _PET
sampler2D _TintMask;
fixed4 _TintR;
fixed4 _TintG;
fixed4 _TintB;
sampler2D _GradientTex;
fixed2 _GradientOffset;
fixed4 _UseTint;
#ifndef _METALLICGLOSSMAP
sampler2D _MetallicGlossMap;
#endif
#endif

struct a2v_simplest
{
	float4 vertex			: POSITION;
};
struct a2v
{
	float4 vertex			: POSITION;
	half2 uv0				: TEXCOORD0;
	half2 uv1				: TEXCOORD1;
	float3 normal			: NORMAL;
	float4 tangent			: TANGENT;
	fixed4 color			: COLOR;
#ifdef _USE_DIRECT_GPU_SKINNING
	float4 skinIndices		: TEXCOORD2;
	float4 skinWeights		: TEXCOORD3;
#endif
};
struct v2f_preZ
{
	float4 pos				: SV_POSITION;
	float3 wPos				: TEXCOORD0;
	LGAME_STARACTOR_EFFECT_STRUCT(1)
};
struct v2f
{
	float4 pos				: SV_POSITION;
	half4 uv				: TEXCOORD0;
	float3 viewDir          : TEXCOORD1;
	float4 tangentToWorld[3]	: TEXCOORD2;
	LGAME_STARACTOR_SHADOW_COORDS(5)
	LGAME_STARACTOR_EFFECT_STRUCT(6)
#ifdef _HAIR
#ifdef _SPHERE_MAPPING
	half3 proxyTangent		: TEXCOORD7;
#endif
#elif defined(_CHIFFON)
	half4 detail_uv			: TEXCOORD7;
//#elif defined(_EYE)
//#ifdef _EYE_REFRACTION
//	half3 frontDir			: TEXCOORD7;
//#else
//	half3 irisNormal		: TEXCOORD8;
//#endif
#endif
};
struct BaseMaterialData
{
	half3 diffColor;
	half3 specColor;
	float3 normal;
	half3 occlusion;
	float smoothness;
	float roughness;
	half opacity;
	float perceptual_roughness;
	half one_minus_reflectivity;
#ifdef _EMISSION
	half3 emission;
#endif
#ifdef _SUBSURFACE_SCATTERING
	half curvature;
#endif
#if defined(_HAIR)||defined(_SILK)||defined(_ANISOTROPY)
	float3 tangent;
#endif
#ifdef _HAIR
	half shift;
	half mask;
#endif
#if defined(_SILK)||defined(_ANISOTROPY)
	float3 binormal;
	half roughnessT;
	half roughnessB;
#endif
#ifdef _CLEARCOAT
	half3 cc_normal;
	half cc_roughness;
	half cc_perceptual_roughness;
#endif
#ifdef _GLINT
	half3 glint;
#endif
//#ifdef _EYE
//	half4 iris;//xyz:normal w:mask
//	half3 caustic_normal;
//#ifdef _EYE_REFRACTION
//	half refraction; 
//#endif
//#endif
};

#ifdef _GLINT
half Glint(half3 viewDir, half3 diamond)
{
	half random = viewDir.x + viewDir.y + viewDir.z + diamond.r;
	half glint = frac(random) * diamond.g;
	glint = pow(glint, _GlintPower)*diamond.b;
	glint *= (frac(sin(_Time.y*_GlintSpeed)*0.25 + random)*0.5 + 0.5)*_GlintStrength;
	return glint;
}
#endif
/*
#ifdef _EYE
half2 EyeRefraction(half2 uv, half ior, half mask, half radius, half iris_depth, half strength, half3 viewDir, half3 normal, half3 frontNormalW,out half refraction)
{
	half heightW = iris_depth * saturate(1.0 - 18.4 * radius * radius);
	half w = ior * dot(normal, viewDir);
	half k = sqrt(1.0 + (w - ior) * (w + ior));
	half3 refractedW = (w - k) * normal - ior * viewDir;
	half cosAlpha = dot(frontNormalW, -refractedW);
	half dist = heightW / cosAlpha;
	half3 offsetW = dist * refractedW;
	half3 offsetL = mul(offsetW, (float3x3)unity_ObjectToWorld);
	half3 yAxis = cross( normalize(_FrontDir), normalize(_RightDir));
	half3x3 objectMatrix = half3x3(normalize(_RightDir), yAxis, normalize(_FrontDir));
	offsetL = mul(objectMatrix, offsetL);
	refraction = length(offsetL);
	uv += half2(mask, -mask) * offsetL * strength;
	return uv;
}
#endif
*/
void BaseMateiralDataSetup(v2f i, out float3 viewDir, out float3 wPos, out BaseMaterialData base)
{
	viewDir = Unity_SafeNormalize(i.viewDir.xyz);
	wPos = float3(i.tangentToWorld[0].w, i.tangentToWorld[1].w, i.tangentToWorld[2].w);
	float3 normal = UnpackScaleNormal(tex2D(_BumpMap, i.uv.xy), _BumpScale);

#ifdef _CHIFFON
	float3 detail_normal = UnpackScaleNormal(tex2D(_DetailNormalMap, i.detail_uv.xy), _DetailNormalScale);
	float detail_mask = tex2D(_DetailMaskMap, i.uv.xy).r;
	detail_normal = BlendAngleCorrectedNormals(normal, detail_normal);
	normal = lerp(normal,detail_normal,detail_mask);
#endif

	base.normal = normalize(i.tangentToWorld[0].xyz*normal.r + i.tangentToWorld[1].xyz*normal.g + i.tangentToWorld[2].xyz*normal.b);
/*
#ifdef _EYE
	half2 eyeData = tex2D(_EyeDataMap, i.uv.xy).rg;
	base.iris.w = eyeData.r;
#ifdef _EYE_REFRACTION
	half3 frontDir = normalize(i.frontDir);
	half3 iris_normal = UnpackNormal(tex2D(_IrisNormalMap, i.uv));
	base.iris.xyz = normalize(i.tangentToWorld[0].xyz*iris_normal.r + i.tangentToWorld[1].xyz*iris_normal.g + i.tangentToWorld[2].xyz*iris_normal.b);
	half2 refract_uv = EyeRefraction(TRANSFORM_TEX(i.uv.xy, _MainTex), _IOR, base.iris.w, _Radius, eyeData.g, _RefractionStrength, viewDir, base.normal, frontDir, base.refraction);
	half iris_distance = pow(length(refract_uv - 0.5) * 0.1116, 0.2767);
	base.caustic_normal = normalize(lerp(base.iris.xyz, -base.normal, base.iris.w * iris_distance));
#else
	base.iris.xyz = lerp(base.normal, normalize(i.irisNormal), base.iris.w);
	base.caustic_normal = normalize(lerp(base.iris.xyz, -base.normal.xyz, base.iris.w));
#endif
#endif
*/
	float2 albedoMotionUV = TRANSFORM_TEX(i.uv.xy, _MainTex);
	half4 albedo = tex2D(_MainTex, albedoMotionUV) * _Color;
#ifdef _PET
	fixed4 mask = tex2D(_TintMask, i.uv.xy);
	#if _GLOBALGRADIENT_ON
	fixed gradient = (wPos.y - unity_ObjectToWorld._m13 + _GradientOffset.y) * _GradientOffset.x;
	#else
	fixed gradient = (mask.a + _GradientOffset.y) * _GradientOffset.x;
	#endif
	fixed3 gradientColor = tex2D(_GradientTex, fixed2(gradient, 0));
#endif

//#ifdef _EYE_REFRACTION
//	half4 iris = tex2D(_IrisMap, saturate(refract_uv));
//	albedo = lerp(albedo,iris,eyeData.r);
//#endif

#ifdef UNITY_COLORSPACE_GAMMA
	albedo.rgb = GammaToLinearSpace(albedo.rgb);
	#ifdef _PET
	_TintR.rgb = GammaToLinearSpace(_TintR.rgb);
	_TintG.rgb = GammaToLinearSpace(_TintG.rgb);
	_TintB.rgb = GammaToLinearSpace(_TintB.rgb);
	gradientColor = GammaToLinearSpace(gradientColor);
	#endif
#endif

#ifdef _PET
    fixed maskR = mask.r * _UseTint.r;
    fixed maskG = mask.g * _UseTint.g;
    fixed maskB = mask.b * _UseTint.b;
    float gradientMask = saturate(step(.1, mask.a) * 1.111111f - 0.1 - mask.r - mask.g - mask.b);
    albedo.rgb = lerp(albedo.rgb, gradientColor, gradientMask * _UseTint.a);
    albedo.rgb = lerp(albedo.rgb, _TintR.rgb, maskR);
    albedo.rgb = lerp(albedo.rgb, _TintG.rgb, maskG);
    albedo.rgb = lerp(albedo.rgb, _TintB.rgb, maskB);
#endif

	base.opacity = albedo.a;
#ifdef _METALLICGLOSSMAP
	float3 data = tex2D(_MetallicGlossMap, lerp(i.uv.xy, albedoMotionUV, _MGSyncMotion)).rgb;
#ifdef _SUBSURFACE_SCATTERING
	data.gb *= float2(_GlossMapScale, _SubSurface);
#else
	data.g *= _GlossMapScale;
#endif
#ifndef _SILK
	float metallic = data.r;
#endif
	base.smoothness = data.g;
#ifdef _SUBSURFACE_SCATTERING
	base.curvature = data.b;
#endif
#else
#ifndef _SILK
	float metallic = _Metallic;
#endif
	base.smoothness = _Glossiness;
#ifdef _SUBSURFACE_SCATTERING
	base.curvature = _SubSurface;
#endif
#endif
	base.perceptual_roughness = 1.0f - base.smoothness;
	base.roughness = max(0.001f,base.perceptual_roughness * base.perceptual_roughness);
	//float4 _ColorSpaceDielectricSpec = float4(0.04, 0.04, 0.04, 1.0 - 0.04);

#if defined(_CHIFFON)||defined(_VELVET)
	base.one_minus_reflectivity = 0.96;
	base.diffColor = albedo.rgb;
	base.specColor = _SheenColor;
#else
#if defined(_SILK)
	base.one_minus_reflectivity = 0.96;
	base.diffColor = albedo.rgb;
	base.specColor = albedo.rgb;
#else
	base.one_minus_reflectivity = (1.0 - metallic) * 0.96;
	base.diffColor = albedo.rgb* base.one_minus_reflectivity;
	base.specColor = lerp(float3(0.04, 0.04, 0.04), albedo.rgb, metallic);
#endif
#endif

#if !defined(_SCENE) || !defined(_CHIFFON)
#ifdef _OCCLUSION_UV1
	base.occlusion = Occlusion(i.uv.zw);
#else
	base.occlusion = Occlusion(i.uv.xy);
#endif
#else
	base.occlusion = 1.0;
#endif

#ifdef _EMISSION
#ifdef _PET
	fixed emissionRaw = tex2D(_MetallicGlossMap, i.uv.xy).a;
	base.emission = albedo * lerp(0, _Emission, emissionRaw);
#else
	base.emission = Emission(i.uv.xy);
#endif
#endif

#ifdef _HAIR
#ifdef _SPHERE_MAPPING
	float3 proxyTangent = normalize(i.proxyTangent.xyz);
	base.tangent = proxyTangent;
#else
	float3 tangent = tex2D(_TangentMap, i.uv.xy) * 2.0f - 1.0f;
	base.tangent = normalize(i.tangentToWorld[0].xyz*tangent.r + i.tangentToWorld[1].xyz*tangent.g + i.tangentToWorld[2].xyz*tangent.b);
#endif
	half2 hair_data = tex2D(_HairDataMap, i.uv.xy).rg;
	base.shift = hair_data.r;
	base.mask = hair_data.g;
#endif
#if defined(_SILK)||defined(_ANISOTROPY)
	base.roughnessT = max(base.roughness  * (1.0 + _Anisotropy), 0.01f);
	base.roughnessB = max(base.roughness  * (1.0 - _Anisotropy), 0.01f);
	base.tangent = normalize(i.tangentToWorld[0].xyz);
	base.tangent = Orthonormalize(base.tangent,base.normal);
	base.binormal = cross(base.tangent, base.normal);
#endif

#ifdef _CLEARCOAT
	base.cc_perceptual_roughness = lerp(0.089, 0.6, _ClearCoatRoughness);
	base.cc_roughness = base.cc_perceptual_roughness * base.cc_perceptual_roughness;
	half3 cc_normal = UnpackNormal(tex2D(_ClearCoatNormalMap, i.uv));
	base.cc_normal = normalize(i.tangentToWorld[0].xyz*cc_normal.r + i.tangentToWorld[1].xyz*cc_normal.g + i.tangentToWorld[2].xyz*cc_normal.b);
	base.roughness = max(base.roughness, base.cc_roughness);
#endif

#ifdef _GLINT
	half3 diamond = tex2D(_DiamondMap, i.detail_uv.zw);
	base.glint = Glint(viewDir, diamond);
	base.opacity = saturate(base.opacity + base.glint);
#endif
}

#endif