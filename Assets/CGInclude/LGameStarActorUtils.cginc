#ifndef LGAME_STARACTOR_UTILS_INCLUDED
// Upgrade NOTE: excluded shader from OpenGL ES 2.0 because it uses non-square matrices
#pragma exclude_renderers gles
#define LGAME_STARACTOR_UTILS_INCLUDED

#ifndef _CHIFFON
	#undef _GLINT
#endif
#ifdef _FASTEST_QUALITY
	#undef _SUBSURFACE_SCATTERING
#endif

sampler2D _OcclusionMap;
half	_OcclusionStrength;
half	_BrightnessInOcclusion;

#if defined(_SUBSURFACE_SCATTERING)|| defined(_VELVET)||defined(_CHIFFON)
fixed4	_SubSurfaceColor;
#endif

#ifdef _SUBSURFACE_SCATTERING
half		_SubSurface;
sampler2D	_SssLut;
#endif

#ifdef _EMISSION
#ifdef _PET
fixed _Emission;
#else
sampler2D _EmissionMap;
fixed4 _EmissionColor;
#endif
#endif
/*--------------------------------------------------------*/
/*------------------* EMISSION TERM *---------------------*/
/*--------------------------------------------------------*/
half3 Emission(half2 uv)
{
#if defined(_EMISSION) && !defined(_PET)
	half3 emission = tex2D(_EmissionMap, uv).rgb * _EmissionColor.rgb;
	#ifdef UNITY_COLORSPACE_GAMMA
		emission = GammaToLinearSpace(emission);
	#endif
	return emission;
#else
	return 0;
#endif
}
/*--------------------------------------------------------*/
/*------------------* OCCLUSION TERM *--------------------*/
/*--------------------------------------------------------*/
half3 Occlusion(half2 uv)
{
	half3 occlusion = tex2D(_OcclusionMap, uv).rgb;
	occlusion.r = LerpWhiteTo(occlusion.r, _OcclusionStrength);
	occlusion.g = LerpWhiteTo(occlusion.g, _BrightnessInOcclusion);
	return occlusion;
}
half3 Occlusion(half4 uv)
{
#ifdef _OCCLUSION_UV1
	return Occlusion(uv.zw);
#else
	return Occlusion(uv.xy);
#endif
}
half OcclusionR(half2 uv)
{
	half occlusion = tex2D(_OcclusionMap, uv).r;
	occlusion.r = LerpWhiteTo(occlusion.r, _OcclusionStrength);
	return occlusion;
}
half OcclusionR(half4 uv)
{
#ifdef _OCCLUSION_UV1
	return OcclusionR(uv.zw);
#else
	return OcclusionR(uv.xy);
#endif
}
half2 OcclusionRG(half2 uv)
{
	half2 occlusion = tex2D(_OcclusionMap, uv).rg;
	occlusion.r = LerpWhiteTo(occlusion.r, _OcclusionStrength);
	occlusion.g = LerpWhiteTo(occlusion.g, _BrightnessInOcclusion);
	return occlusion;
}
half2 OcclusionRG(half4 uv)
{
#ifdef _OCCLUSION_UV1
	return OcclusionRG(uv.zw);
#else
	return OcclusionRG(uv.xy);
#endif
}
/*--------------------------------------------------------*/
/*-----------------* SUBSURFACE TERM *--------------------*/
/*--------------------------------------------------------*/
half3 SubSurfaceColor(half NoL, half atten, half curvature)
{
	half3 subSurfaceColor = half3(0.0, 0.0, 0.0);
#ifdef _SUBSURFACE_SCATTERING
	if (curvature > 0.02)
	{
		half sssAtten = atten * 0.5 + 0.5;
		half3 sssDiffuse = (tex2D(_SssLut, half2((NoL*0.5 + 0.5) * sssAtten, curvature)).rgb) * atten;
		subSurfaceColor = sssDiffuse;
	}
	else
	{
		subSurfaceColor = saturate(NoL) * atten;
	}
#endif
	return subSurfaceColor;
}
/*--------------------------------------------------------*/
/*--------------------* OTHER TERM *----------------------*/
/*--------------------------------------------------------*/
float3 Orthonormalize(float3 tangent, float3 normal)
{
    return normalize(tangent - dot(tangent, normal) * normal);
}

float3 BlendAngleCorrectedNormals(float3 baseNormal, float3 additionNormal)
{
    baseNormal += float3(0, 0, 1);
    additionNormal *= float3(-1, -1, 1);
    return baseNormal * dot(baseNormal, additionNormal) - baseNormal.b * additionNormal;
}
#endif