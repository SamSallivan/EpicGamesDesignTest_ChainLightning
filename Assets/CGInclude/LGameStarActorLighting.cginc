#ifndef LGAME_STARACTOR_LIGHTING_INCLUDED
#define LGAME_STARACTOR_LIGHTING_INCLUDED
#include "LGameStarActorUtils.cginc"
#include "LGameStarActorShadow.cginc"
fixed3	_RakingLightColor;
#ifdef _DUAL_RIMLIGHT
fixed3 _RakingLightColor2;
#endif
fixed4	_AmbientCol;
fixed4	_ReflectionColor;

half	_BrightnessInShadow;
half	_RakingLightSoftness;
half3	_DirLight;
half4	_ReflectionCubeMap_HDR;
sampler2D _ReflectionMatCap;
sampler2D _AmbientColorTexture;
samplerCUBE _ReflectionCubeMap;
struct LGameDirectLight
{
	half3 color;
	float3 dir;
};
struct LGameIndirectLight
{
	half3 diffuse;
	half3 specular;
};
struct LGameGI
{
	LGameDirectLight direct;
	LGameIndirectLight indirect;
};
LGameDirectLight LGameDirectLighting(half3 wPos)
{
	LGameDirectLight direct;
	direct.color = _LightColor0.rgb;
	direct.dir = Unity_SafeNormalize(UnityWorldSpaceLightDir(wPos));
	return direct;
}
void IndirectDiffuse(half occlusion, half2 uv,half3 normal, out half3 color)
{
	//SH Lighting本身就是线性的
//#if UNITY_SHOULD_SAMPLE_SH
//	half3 ambient_contrib = SHEvalLinearL0L1(half4(normal, 1.0));
//	ambient_contrib += SHEvalLinearL2(half4(normal, 1.0));
//	color = max(half3(0, 0, 0), ambient_contrib);
//#else
#ifndef _REFLECTION_CUBEMAP
	color = tex2D(_AmbientColorTexture, uv);
	color = GammaToLinearSpace(color);
	color *= _AmbientCol;// GammaToLinearSpace(_AmbientCol);
#else
	color = texCUBElod(_ReflectionCubeMap, half4(normal, 5.0)) * _AmbientCol;
	color = GammaToLinearSpace(color);
#endif
	//#endif
	color *= occlusion;
}
void IndirectDiffuse(half occlusion, half3 normal, out half3 color)
{
	//SH Lighting本身就是线性的
//#if UNITY_SHOULD_SAMPLE_SH
//	half3 ambient_contrib = SHEvalLinearL0L1(half4(normal, 1.0));
//	ambient_contrib += SHEvalLinearL2(half4(normal, 1.0));
//	color = max(half3(0, 0, 0), ambient_contrib);
//#else
#ifndef _REFLECTION_CUBEMAP
	color = _AmbientCol;// GammaToLinearSpace(_AmbientCol);
#else
	color = texCUBElod(_ReflectionCubeMap, half4(normal, 5.0)) * _AmbientCol;
	color = GammaToLinearSpace(color);
#endif
//#endif
	color *= occlusion;
}

void MatCapUV(half3 wPos, half3 normal, out half2 uv)
{
#ifndef _REFLECTION_CUBEMAP
	half3 vNormal = mul((half3x3)UNITY_MATRIX_V, normal).xyz;
	half3 vPos = UnityWorldToViewPos(wPos);
	half3 r = normalize(reflect(vPos, vNormal));
	r.z += 1.0;
	half m = 2.0 * sqrt(dot(r,r));
	//half m = 2.0 * sqrt(r.x * r.x + r.y * r.y + (r.z + 1) * (r.z + 1));
	uv = r.xy / m + 0.5;
#else
	uv = 0.0;
#endif
}

half3 IndirectSpecularMatCap(half3 wPos, half3 normal, half occlusion, half perceptual_roughness)
{
	//half mip_roughness = perceptual_roughness * (1.7 - 0.7 * perceptual_roughness);
	//half mip = mip_roughness * 6.0;
	half mip = perceptual_roughness * (10.2 - 4.2 * perceptual_roughness);
	half2 matcapuv;
	MatCapUV(wPos, normal, matcapuv);
	half3 color = tex2Dlod(_ReflectionMatCap, half4(matcapuv, 0, mip)) * _ReflectionColor;
#ifdef UNITY_COLORSPACE_GAMMA
	color = GammaToLinearSpace(color);
#endif
	color *= occlusion;
	return color;
}
half3 IndirectSpecularCubeMap(half3 viewDir, half3 normal, half occlusion, half perceptual_roughness)
{
	//half mip_roughness = perceptual_roughness * (1.7 - 0.7 * perceptual_roughness);
	//half mip = mip_roughness * 6.0;
	half mip = perceptual_roughness * (10.2 - 4.2 * perceptual_roughness);
	half3 r = normalize(reflect(-viewDir, normal));
	half4 ldr = texCUBElod(_ReflectionCubeMap, half4(r, mip));
	half3 color = DecodeHDR(ldr, _ReflectionCubeMap_HDR) * _ReflectionColor;
#ifdef UNITY_COLORSPACE_GAMMA
	color = GammaToLinearSpace(color);
#endif
	color *= occlusion;
	return color;
}
//For Scene
half3 IndirectSpecular(half3 wPos, half3 viewDir, half3 normal, half occlusion, half perceptual_roughness)
{
	half3 color;
#ifndef _REFLECTION_CUBEMAP
	color = IndirectSpecularMatCap(wPos, normal, occlusion, perceptual_roughness);
#else
	color = IndirectSpecularCubeMap(viewDir, normal, occlusion, perceptual_roughness);
#endif
	return color;
}
//For Character
void IndirectSpecular(half3 wPos, half3 viewDir, half3 normal, half occlusion,half perceptual_roughness, out half3 color)
{
#ifndef _REFLECTION_CUBEMAP
	color = IndirectSpecularMatCap(wPos, normal, occlusion, perceptual_roughness);
#else
	color = IndirectSpecularCubeMap(viewDir, normal, occlusion, perceptual_roughness);
#endif
}


LGameGI FragmentGI_ClearCoat(half3 wPos, half3 viewDir, half3 normal, half occlusion, half perceptual_roughness, half fcc, half3 cc_normal, half cc_perceptual_roughness)
{
	LGameGI gi;
	gi.direct = LGameDirectLighting(wPos);
#ifdef _FASTEST_QUALITY
	gi.indirect.diffuse = _AmbientCol;
	gi.indirect.specular = 0.0;
#else//_FASTEST_QUALITY

	half one_minus_fcc = 1.0 - fcc;
	IndirectDiffuse(occlusion, normal, gi.indirect.diffuse);
	gi.indirect.diffuse *= one_minus_fcc;

	IndirectSpecular(wPos, viewDir, normal, occlusion, perceptual_roughness, gi.indirect.specular);
	gi.indirect.specular *= one_minus_fcc * one_minus_fcc;

	half3 cc_specular = 0.0;
	IndirectSpecular(wPos, viewDir, cc_normal, occlusion, cc_perceptual_roughness, cc_specular);
	gi.indirect.specular += cc_specular * fcc;

#endif//_FASTEST_QUALITY
	return gi;
}

LGameGI FragmentGI(half3 wPos, half3 viewDir, half3 normal, half occlusion, half perceptual_roughness)
{
	LGameGI gi;
	gi.direct = LGameDirectLighting(wPos);
#ifdef UNITY_PASS_FORWARDBASE
#ifdef	_FASTEST_QUALITY
	gi.indirect.diffuse = _AmbientCol;
	gi.indirect.specular = 0.0;
#else//_FASTEST_QUALITY

	IndirectDiffuse(occlusion, normal, gi.indirect.diffuse);
	IndirectSpecular(wPos, viewDir, normal, occlusion, perceptual_roughness, gi.indirect.specular);

#endif//_FASTEST_QUALITY
#endif//UNITY_PASS_FORWARDBASE
	return gi;
}
LGameGI FragmentGI(half2 uv,half3 wPos, half3 viewDir, half3 normal, half occlusion, half perceptual_roughness)
{
	LGameGI gi;
	gi.direct = LGameDirectLighting(wPos);
#ifdef UNITY_PASS_FORWARDBASE
#ifdef	_FASTEST_QUALITY
	gi.indirect.diffuse = _AmbientCol;
	gi.indirect.specular = 0.0;
#else//_FASTEST_QUALITY

	IndirectDiffuse(occlusion, uv,normal, gi.indirect.diffuse);
	IndirectSpecular(wPos, viewDir, normal, occlusion, perceptual_roughness, gi.indirect.specular);

#endif//_FASTEST_QUALITY
#endif//UNITY_PASS_FORWARDBASE

	return gi;
}
LGameGI FragmentGI_Anisotropic(half3 wPos, half3 viewDir, half3 normal, half3 tangent, half3 bitangent, half anisotropy, half occlusion, half perceptual_roughness)
{
	LGameGI gi;
	gi.direct = LGameDirectLighting(wPos);
#ifdef	_FASTEST_QUALITY
	gi.indirect.diffuse = _AmbientCol;
	gi.indirect.specular = 0.0;
#else//_FASTEST_QUALITY

	half3 anisotropicTangent = cross(bitangent, viewDir);
	half3 anisotropicNormal0 = cross(anisotropicTangent, bitangent);
	half3 bentNormal0 = normalize(lerp(normal, anisotropicNormal0, saturate(anisotropy)));

	half3 anisotropicBitangent = cross(tangent, viewDir);
	half3 anisotropicNormal1 = cross(anisotropicBitangent, tangent);
	half3 bentNormal1 = normalize(lerp(normal, anisotropicNormal1, saturate(-anisotropy)));

	half3 bentNormal = lerp(bentNormal1, bentNormal0, anisotropy * 0.5 + 0.5);

	IndirectDiffuse(occlusion, bentNormal, gi.indirect.diffuse);
	IndirectSpecular(wPos, viewDir, bentNormal, occlusion, perceptual_roughness, gi.indirect.specular);

#endif//_FASTEST_QUALITY
	return gi;
}
//Raking Light
half3 LGame_RakingLight(half3 wPos, half3 viewDir, half3 normal, half NoV,half atten, half occlusion)
{
#ifdef _FASTEST_QUALITY
	return half3(0, 0, 0);
#else
	half rim = pow(saturate(1.0 - NoV), max(1.0f, _RakingLightSoftness));
	atten = lerp(1.0, atten, _BrightnessInShadow) * occlusion;
	
	half3 Raking = _RakingLightColor * atten * rim;
#ifdef _DUAL_RIMLIGHT
	half3 Raking2 = _RakingLightColor2 * atten * rim;
#endif
	
	half light = saturate(dot(normal, normalize(_DirLight.xyz)));
	Raking *= light;
#ifdef _DUAL_RIMLIGHT
	half3 dualRimDirection = -1 * normalize(_DirLight.xyz);
	Raking2 *= saturate(dot(normal, dualRimDirection));
	return Raking + Raking2;
#endif
	return Raking;
#endif
}
#endif