#ifndef LGAME_PBR_INCLUDE
#define	LGAME_PBR_INCLUDE

#include "UnityLightingCommon.cginc"
#include "UnityGlobalIllumination.cginc"
//-------------------------------------------------------------------------------------

//注：BRDF入口点使用的平滑度和一减反射度来优化，主要用于适配DX9 SM2.0。 大多数数学都是在这些（1-x）值上完成的，而且可以节省几个ALU（算术逻辑单元？）
// Main Physically Based BRDF
// 衍生自迪斯尼工作，并基于Torrance-Sparrow 微表面模型
//
//   BRDF = kD / pi + kS * (D * V * F) / 4
//   I = BRDF * NdotL
//
// * NDF (depending on UNITY_BRDF_GGX):
//  a) Normalized BlinnPhong
//  b) GGX
// * Smith for Visiblity term
// * Schlick approximation for Fresnel

half4 LGame_BRDF3_Unity_PBS (half3 diffColor, half3 specColor, half oneMinusReflectivity, half smoothness,
	half3 normal, half3 viewDir,
	UnityLight light, UnityIndirect gi)
{
	half3 reflDir = reflect (viewDir, normal);

	half nl = saturate(dot(normal, light.dir));
	nl = nl* 0.5 + 0.5;//半兰伯特

	half nv = saturate(dot(normal, viewDir));

	// Vectorize Pow4 to save instructions
	half2 rlPow4AndFresnelTerm = Pow4 (half2(dot(reflDir, light.dir), 1-nv));  // use R.L instead of N.H to save couple of instructions
	half rlPow4 = rlPow4AndFresnelTerm.x; // power exponent must match kHorizontalWarpExp in NHxRoughness() function in GeneratedTextures.cpp
	half fresnelTerm = rlPow4AndFresnelTerm.y;

	half grazingTerm = saturate(smoothness + (1-oneMinusReflectivity));

	half3 color = BRDF3_Direct(diffColor, specColor, rlPow4, smoothness);
	color *= light.color * nl;
	color += BRDF3_Indirect(diffColor, specColor, gi, grazingTerm, fresnelTerm);

	return half4(color, 1);
}

// Based on Minimalist CookTorrance BRDF
// Implementation is slightly different from original derivation: http://www.thetenthplanet.de/archives/255
//
// * NDF (depending on UNITY_BRDF_GGX):
//  a) BlinnPhong
//  b) [Modified] GGX
// * Modified Kelemen and Szirmay-​Kalos for Visibility term
// * Fresnel approximated with 1/LdotH
half4 LGame_BRDF2_Unity_PBS (half3 diffColor, half3 specColor, half oneMinusReflectivity, half smoothness,
	half3 normal, half3 viewDir,
	UnityLight light, UnityIndirect gi)
{
	half3 halfDir = Unity_SafeNormalize (light.dir + viewDir);

	half nl = saturate(dot(normal, light.dir));
	half nh = saturate(dot(normal, halfDir));
	half nv = saturate(dot(normal, viewDir));
	half lh = saturate(dot(light.dir, halfDir));

	// Specular term
	half perceptualRoughness = SmoothnessToPerceptualRoughness (smoothness);
	half roughness = PerceptualRoughnessToRoughness(perceptualRoughness);

#if UNITY_BRDF_GGX

	// GGX Distribution multiplied by combined approximation of Visibility and Fresnel
	// See "Optimizing PBR for Mobile" from Siggraph 2015 moving mobile graphics course
	// https://community.arm.com/events/1155
	half a = roughness;
	half a2 = a*a;

	half d = nh * nh * (a2 - 1.h) + 1.00001h;
#ifdef UNITY_COLORSPACE_GAMMA
	// Tighter approximation for Gamma only rendering mode!
	// DVF = sqrt(DVF);
	// DVF = (a * sqrt(.25)) / (max(sqrt(0.1), lh)*sqrt(roughness + .5) * d);
	half specularTerm = a / (max(0.32h, lh) * (1.5h + roughness) * d);
#else
	half specularTerm = a2 / (max(0.1h, lh*lh) * (roughness + 0.5h) * (d * d) * 4);
#endif

	// on mobiles (where half actually means something) denominator have risk of overflow
	// clamp below was added specifically to "fix" that, but dx compiler (we convert bytecode to metal/gles)
	// sees that specularTerm have only non-negative terms, so it skips max(0,..) in clamp (leaving only min(100,...))
#if defined (SHADER_API_MOBILE)
	specularTerm = specularTerm - 1e-4h;
#endif

#else

	// Legacy
	half specularPower = PerceptualRoughnessToSpecPower(perceptualRoughness);
	// Modified with approximate Visibility function that takes roughness into account
	// Original ((n+1)*N.H^n) / (8*Pi * L.H^3) didn't take into account roughness 
	// and produced extremely bright specular at grazing angles

	half invV = lh * lh * smoothness + perceptualRoughness * perceptualRoughness; // approx ModifiedKelemenVisibilityTerm(lh, perceptualRoughness);
	half invF = lh;

	half specularTerm = ((specularPower + 1) * pow (nh, specularPower)) / (8 * invV * invF + 1e-4h);

#ifdef UNITY_COLORSPACE_GAMMA
	specularTerm = sqrt(max(1e-4h, specularTerm));
#endif

#endif

#if defined (SHADER_API_MOBILE)
	specularTerm = clamp(specularTerm, 0.0, 100.0);	// Prevent FP16 overflow on mobiles
#endif
#if defined(_SPECULARHIGHLIGHTS_OFF)
	specularTerm = 0.0;
#endif

	// surfaceReduction = Int D(NdotH) * NdotH * Id(NdotL>0) dH = 1/(realRoughness^2+1)

	// 1-0.28*x^3 as approximation for (1/(x^4+1))^(1/2.2) on the domain [0;1]
	// 1-x^3*(0.6-0.08*x)   approximation for 1/(x^4+1)
#ifdef UNITY_COLORSPACE_GAMMA
	half surfaceReduction = 0.28;
#else
	half surfaceReduction = (0.6-0.08*perceptualRoughness);
#endif

	surfaceReduction = 1.0 - roughness*perceptualRoughness*surfaceReduction;

	half grazingTerm = saturate(smoothness + (1-oneMinusReflectivity));
	half3 color =	(diffColor + specularTerm * specColor) * light.color * nl
					+ gi.diffuse * diffColor
					+ surfaceReduction * gi.specular * FresnelLerpFast (specColor, grazingTerm, nv);

	return half4(diffColor, 1);
}



// Default BRDF to use:
#if !defined (LGAME_UNITY_BRDF_PBS) // allow to explicitly override BRDF in custom shader
	// still add safe net for low shader models, otherwise we might end up with shaders failing to compile
	#if SHADER_TARGET < 30
		#define LGAME_UNITY_BRDF_PBS LGame_BRDF3_Unity_PBS
	#elif UNITY_PBS_USE_BRDF3
		#define LGAME_UNITY_BRDF_PBS LGame_BRDF3_Unity_PBS
	#elif UNITY_PBS_USE_BRDF2
		#define LGAME_UNITY_BRDF_PBS LGame_BRDF2_Unity_PBS
	#elif UNITY_PBS_USE_BRDF1
		#define LGAME_UNITY_BRDF_PBS LGame_BRDF1_Unity_PBS
	#elif defined(SHADER_TARGET_SURFACE_ANALYSIS)
		// we do preprocess pass during shader analysis and we dont actually care about brdf as we need only inputs/outputs
		#define LGAME_UNITY_BRDF_PBS LGame_BRDF1_Unity_PBS
	#else
		#error something broke in auto-choosing BRDF
	#endif
#endif

 #endif  