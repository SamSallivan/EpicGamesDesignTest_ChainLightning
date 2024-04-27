#ifndef LGAME_STARACTOR_PBS_INCLUDED
#define LGAME_STARACTOR_PBS_INCLUDED
#include "LGameStarActorInput.cginc"
#include "LGameStarActorBRDF.cginc"
#include "LGameStarActorLighting.cginc"
//PBS
half4 LGAME_BRDF_PBS(LGameGI gi, BaseMaterialData base, float3 viewDir, half NoV, half NoL, half atten)
{
/*Vector*/
	float3 H = Unity_SafeNormalize(gi.direct.dir + viewDir);
/*Dot Product*/
#if !defined(_SUBSURFACE_SCATTERING) && !defined(_VELVET) && !defined(_CHIFFON)
	NoL = saturate(NoL);
#endif
#ifndef _HAIR
	float NoH = saturate(dot(base.normal, H));
	float LoH = saturate(dot(gi.direct.dir, H));
#endif
//Anisotropic Dot Product Do Not Need To Saturate/Clamp(0,1)
#if defined(_SILK)||defined(_ANISOTROPY)
	//return half4(base.specColor, base.opacity);
	float ToL = dot(base.tangent, gi.direct.dir);
	float BoL = dot(base.binormal, gi.direct.dir);
	float ToV = dot(base.tangent, viewDir);
	float BoV = dot(base.binormal, viewDir);
	float ToH = dot(base.tangent, H);
	float BoH = dot(base.binormal, H);
#endif

/*Diffuse Term*/
#if defined(_CHIFFON)
	NoL = abs(NoL);
	half3 subsurface = saturate(_SubSurfaceColor + NoL * (atten * 0.5 + 0.5));
	half3 diffuseTerm = gi.direct.color * subsurface;
#else
#ifdef _SUBSURFACE_SCATTERING
	//half3 subsurface = SubSurfaceColor(base.uv, atten, NoL);
	//return float4(subsurface, 1);
	half3 subsurface = SubSurfaceColor(NoL , atten, base.curvature);
	half3 diffuseTerm =  gi.direct.color * subsurface;
#elif defined(_SILK)
	/*Diffuse Fabric*/
	//half3 diffuseTerm = gi.direct.color * atten * NoL *lerp(1.0, 0.5, base.roughness);
	half3 diffuseTerm =  atten * NoL *(1.0 - 0.5 * base.roughness) * gi.direct.color;
#elif defined(_VELVET)
	half3 diffuseTerm = gi.direct.color * atten;
	//Energy Conservative Wrap Diffuse！！Filament
	diffuseTerm *= saturate((NoL + 0.5) / 2.25);
	NoL = saturate(NoL);
	diffuseTerm *= saturate(_SubSurfaceColor + NoL * atten);
//#elif defined(_EYE)
//	half3 diffuseTerm = gi.direct.color * atten * Diffuse_EYE(base.iris.xyz, base.caustic_normal, NoL, base.iris.w, gi.direct.dir);
#else 
	half3 diffuseTerm = gi.direct.color * atten * NoL;
#endif
#endif

/*Specular Term*/
#ifdef _HAIR
	float3 specularTerm = Kajiya_Kay_Specular_BxDF(H, base.normal, base.tangent, base.mask, base.shift);
#elif defined(_SILK)||defined(_ANISOTROPY)
	float3 specularTerm = Silk_Specular_BxDF(NoL, NoV, NoH, ToV, BoV, ToL, BoL, ToH, BoH, LoH, base.roughnessT, base.roughnessB, base.specColor);
#elif defined(_VELVET)
	float3 specularTerm = Velvet_Specular_BxDF(NoL, NoV, NoH, LoH, base.roughness, base.specColor);
#else
	float a2 = base.roughness * base.roughness;
	float d = (NoH * NoH * (a2 - 1.0f) + 1.0f) + 0.00001f;
	float3 specularTerm =  a2 / (max(0.1f, LoH * LoH) * (base.roughness + 0.5f) * (d * d)* 4.0f ) * base.specColor;
#endif
/*ClearCoat:Diffuse Term & Specular Term*/
#ifdef _CLEARCOAT
	half cc_NoH = saturate(dot(base.cc_normal, H));
	half cc_NoL = saturate(dot(base.cc_normal, gi.direct.dir));
	half3 cc_diffuseTerm = gi.direct.color * atten * cc_NoL;
	half3 Fcc;
	half3 cc_specularTerm = ClearCoat_Specular_BxDF(cc_NoH, LoH, _ClearCoat, base.cc_roughness, Fcc);
	half3 cc_atten = 1.0 - Fcc;
	diffuseTerm *= cc_atten;
	specularTerm *= cc_atten;
#endif
	/*Approximate Calculation*/
	specularTerm = specularTerm - 1e-4f;
	specularTerm = clamp(specularTerm, 0.0f, 100.0f);
/*Combine*/
	half surfaceReduction = (0.6 - 0.08 * base.perceptual_roughness);
	surfaceReduction = 1.0 - base.roughness * base.perceptual_roughness * surfaceReduction;
	half grazingTerm = saturate(base.smoothness + (1.0 - base.one_minus_reflectivity));
	half3 color = (base.diffColor + specularTerm) * diffuseTerm;
#ifdef _CLEARCOAT
	color += cc_diffuseTerm * cc_specularTerm;
#endif
#ifdef _GLINT
	color += gi.indirect.specular * base.glint;
#endif
	color += gi.indirect.diffuse * base.diffColor;
	color += surfaceReduction * gi.indirect.specular * FresnelLerpFast(base.specColor, grazingTerm, NoV);
//#ifdef _EYE_REFRACTION
//	color += lerp(color, gi.indirect.specular, saturate(base.refraction));
//#endif
	return half4(color, base.opacity);
}
half4 LGAME_BRDF_PBS_ADD(LGameDirectLight direct, BaseMaterialData base, half3 viewDir, half atten)
{
	half3 H = Unity_SafeNormalize(direct.dir + viewDir);
#if defined(_SUBSURFACE_SCATTERING)||defined(_VELVET)||defined(_CHIFFON)
	half NoL = dot(base.normal, direct.dir);
#else
	half NoL = saturate(dot(base.normal, direct.dir));
#endif

#if defined(_FILM_IRIDESCENCE) || defined(_SILK)||defined(_VELVET)
	half NoV = saturate(dot(base.normal, viewDir));
#endif
#ifndef _HAIR
	half NoH = saturate(dot(base.normal, H));
	half LoH = saturate(dot(direct.dir, H));
#endif
#if defined(_SILK)||defined(_ANISOTROPY)
	half ToL = dot(base.tangent, direct.dir);
	half BoL = dot(base.binormal, direct.dir);
	half ToV = dot(base.tangent, viewDir);
	half BoV = dot(base.binormal, viewDir);
	half ToH = dot(base.tangent, H);
	half BoH = dot(base.binormal, H);
#endif

/*Diffuse Term*/
#if defined(_CHIFFON)
	half3 diffuseTerm = direct.color * atten;
	//Energy Conservative Wrap Diffuse！！Filament
	diffuseTerm *= saturate((NoL + 0.5) / 2.25);
	NoL = abs(NoL);
	diffuseTerm *= saturate(_SubSurfaceColor + NoL * atten);
#else
#ifdef _SUBSURFACE_SCATTERING
	half3 subsurface = SubSurfaceColor(NoL, atten, base.curvature);
	half3 diffuseTerm = direct.color * subsurface;
#elif defined(_SILK)
	/*Diffuse Fabric*/
	half3 diffuseTerm = atten * NoL *(1.0 - 0.5 * base.roughness) * direct.color;
	//half3 diffuseTerm = direct.color * atten * NoL *lerp(1.0, 0.5, base.roughness);
#elif defined(_VELVET)
	half3 diffuseTerm = direct.color * atten;
	//Energy Conservative Wrap Diffuse！！Filament
	diffuseTerm *= saturate((NoL + 0.5) / 2.25);
	NoL = saturate(NoL);
	diffuseTerm *= saturate(_SubSurfaceColor + NoL * atten);
//#elif defined(_EYE)
//	half3 diffuseTerm = direct.color * atten * Diffuse_EYE(base.iris.xyz, base.caustic_normal, NoL, base.iris.w, direct.dir);
#else 
	half3 diffuseTerm = direct.color * atten * NoL;
#endif
#endif

#ifdef _HAIR
	half3 specularTerm = Kajiya_Kay_Specular_BxDF(H, base.normal, base.tangent, base.mask, base.shift);
#elif defined(_SILK)||defined(_ANISOTROPY)
	half3 specularTerm = Silk_Specular_BxDF(NoL, NoV, NoH, ToV, BoV, ToL, BoL, ToH, BoH, LoH, base.roughnessT, base.roughnessB, base.specColor);
#elif defined(_VELVET)
	half3 specularTerm = Velvet_Specular_BxDF(NoL, NoV, NoH, LoH, base.roughness, base.specColor);
#else
	float a2 = base.roughness * base.roughness;
	float d = NoH * NoH * (a2 - 1.f) + 1.00001f;
	half3 specularTerm = a2 / (max(0.1f, LoH * LoH) * (base.roughness + 0.5f) * (d * d) * 4.0)* base.specColor;
#endif

#ifdef _CLEARCOAT
	half cc_NoH = saturate(dot(base.cc_normal, H));
	half cc_NoL = saturate(dot(base.cc_normal, direct.dir));
	half3 cc_diffuseTerm = direct.color * atten * cc_NoL;
	half3 Fcc;
	half3 cc_specularTerm = ClearCoat_Specular_BxDF(cc_NoH, LoH, _ClearCoat, base.cc_roughness, Fcc);
	half3 cc_atten = 1.0 - Fcc;
	diffuseTerm *= cc_atten;
	specularTerm *= cc_atten;
#endif
	specularTerm = specularTerm - 1e-4f;
	specularTerm = clamp(specularTerm, 0.0, 100.0);
	half3 color = (base.diffColor + specularTerm)*diffuseTerm;
#ifdef _CLEARCOAT
	color += cc_diffuseTerm * cc_specularTerm;
#endif
	return half4(color, base.opacity);
}
#endif