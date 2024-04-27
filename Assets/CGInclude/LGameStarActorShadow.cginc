#ifndef LGAME_STARACTOR_SHADOW_INCLUDED
#define LGAME_STARACTOR_SHADOW_INCLUDED
UNITY_DECLARE_SHADOWMAP(u_UniqueShadowTexture);
float4 u_LightShadowData;
#if defined(_SOFT_SHADOW)
	static half2 poisson[32] = {
		half2(0.02971195f, 0.8905211f),
		half2(0.2495298f, 0.732075f),
		half2(-0.3469206f, 0.6437836f),
		half2(-0.01878909f, 0.4827394f),
		half2(-0.2725213f, 0.896188f),
		half2(-0.6814336f, 0.6480481f),
		half2(0.4152045f, 0.2794172f),
		half2(0.1310554f, 0.2675925f),
		half2(0.5344744f, 0.5624411f),
		half2(0.8385689f, 0.5137348f),
		half2(0.6045052f, 0.08393857f),
		half2(0.4643163f, 0.8684642f),
		half2(0.335507f, -0.110113f),
		half2(0.03007669f, -0.0007075319f),
		half2(0.8077537f, 0.2551664f),
		half2(-0.1521498f, 0.2429521f),
		half2(-0.2997617f, 0.0234927f),
		half2(0.2587779f, -0.4226915f),
		half2(-0.01448214f, -0.2720358f),
		half2(-0.3937779f, -0.228529f),
		half2(-0.7833176f, 0.1737299f),
		half2(-0.4447537f, 0.2582748f),
		half2(-0.9030743f, 0.406874f),
		half2(-0.729588f, -0.2115215f),
		half2(-0.5383645f, -0.6681151f),
		half2(-0.07709587f, -0.5395499f),
		half2(-0.3402214f, -0.4782109f),
		half2(-0.5580465f, 0.01399586f),
		half2(-0.105644f, -0.9191031f),
		half2(-0.8343651f, -0.4750755f),
		half2(-0.9959937f, -0.0540134f),
		half2(0.1747736f, -0.936202f),
	};
uniform half2 u_UniqueShadowFilterWidth;
float SampleUniqueD3D9OGL(const half4 coords, half NoL)
{
	float shadow = 0.f;
	half4 uv = coords;
	for (int i = 0; i < 32; i++)
	{
		uv.xy = coords.xy + poisson[i] * u_UniqueShadowFilterWidth;
#ifdef SHADOWS_NATIVE
		shadow += UNITY_SAMPLE_SHADOW(u_UniqueShadowTexture, uv.xyz);
#else
		shadow += SAMPLE_DEPTH_TEXTURE_PROJ(u_UniqueShadowTexture, UNITY_PROJ_COORD(uv.xyz)) < (uv.z / uv.w) ? 0.0f : 1.0f;
#endif
	}
	return shadow / 32.0f;
}
#elif defined(_HARD_SHADOW)
static half2 pattern[4] = {
		half2(0.0, 0.0),
		half2(1.0, 0.0),
		half2(1.0, 1.0),
		half2(0.0, 1.0)
};
uniform half2 u_UniqueShadowFilterWidth;
//PCF1x1处理硬阴影问题
float SampleUniqueD3D9OGL(half4 coords,half NoL)
{
	float shadow = 0.f;
	float mask = 1.0f;
	half4 uv = coords;
#ifdef SHADOWS_NATIVE //仅在支持原生阴影贴图采样的设备生效
	float nolVal = smoothstep(0.0, u_LightShadowData.w, saturate(NoL + 0.2));//NoL处理边缘，作范围fade
	float aveVal = 0.f;//均值
	for (int i = 0; i < 4; i++)
	{
		uv.xy = coords.xy + pattern[i] * u_UniqueShadowFilterWidth * 0.5;
		shadow = UNITY_SAMPLE_SHADOW(u_UniqueShadowTexture, uv.xyz);
		aveVal += shadow;
	}
	aveVal *= 0.25f;
	//阴影混合算法
	shadow = smoothstep(u_LightShadowData.z,1.0f , saturate(aveVal));
	shadow *= nolVal;
#else
	shadow = SAMPLE_DEPTH_TEXTURE_PROJ(u_UniqueShadowTexture, UNITY_PROJ_COORD(uv.xyz)) < (uv.z / uv.w) ? 0.0f : 1.0f;
	shadow *= step(0.0f, NoL);
#endif
	return shadow;
}
#endif
/*
 * 之所以计算阴影Fade的原因是：
 * 1.部分场景存在阴影距离超出范围变黑的Bug，存在于LightMap开启的状态下，目前原因未知
 * 2.低配机型下，阴影Combine的效果并不好，为了解决高精度阴影的切割问题
 *
 * 用于场景
 * 使用Unity的阴影参数
 */
half LGameShadowFade_DepthDist(half3 wPos, half atten)
{
	float zDist = dot(_WorldSpaceCameraPos - wPos, UNITY_MATRIX_V[2].xyz);
	float fade = saturate(zDist * _LightShadowData.z + _LightShadowData.w);
	return lerp(atten, 1.0, fade);
}
/*
 * 用于角色
 * 使用自定义的阴影参数
 * 算法魔改以适应角色的半径距离
 * 增加距离镜头过劲的阴影透明表现 用于优化硬阴影下镜头特写阴影瑕疵问题
 */
float3 u_ShadowFadeCenter;
half _ShadowStrength;
half LGameShadowFade_SphereDist(half3 wPos, half atten)
{
	half centerDist = length(wPos - u_ShadowFadeCenter.xyz);
	half fade= saturate(pow(centerDist * u_LightShadowData.x,6.0));
#ifdef _HARD_SHADOW
	half zDist = dot(_WorldSpaceCameraPos - wPos, UNITY_MATRIX_V[2].xyz);
	atten=lerp(1.0,atten, smoothstep(0.0, u_LightShadowData.y, zDist));
#endif
	return lerp(atten, 1.0, fade);
}
#define UNIQUE_SHADOW_SAMPLE(i,NoL) SampleUniqueD3D9OGL(i._ShadowCoord,NoL)
uniform float4x4 u_UniqueShadowMatrix;
#define UNIQUE_SHADOW_INTERP(i)				half4 _ShadowCoord	: TEXCOORD##i;
#define UNIQUE_SHADOW_TRANSFER(o)			o._ShadowCoord = mul(u_UniqueShadowMatrix, float4(posWorld.xyz, 1.f));
#define UNIQUE_SHADOW_ATTENUATION(i,NoL)		UNIQUE_SHADOW_SAMPLE(i,NoL)
//Forward Base
#if defined(_SOFT_SHADOW)||defined(_HARD_SHADOW) 
//Vertex 2 Fragment Struct
//Compiler机制处理
#define LGAME_STARACTOR_SHADOW_COORDS(i)\
	UNIQUE_SHADOW_INTERP(i) 
//Vertex
#define LGAME_STARACTOR_TRNASFER_SHADOW(o) \
	UNIQUE_SHADOW_TRANSFER(o);
//Fragment
#define LGAME_STARACTOR_LIGHT_ATTENUATION(atten,i,wPos,NoL) \
	half atten = UNIQUE_SHADOW_ATTENUATION(i,NoL); \
	half3 bound = step(0.0f, i._ShadowCoord) * step(i._ShadowCoord, 1.0f); \
	half strength = bound.x * bound.y * bound.z * _ShadowStrength; \
	atten = lerp(1.0,atten, strength); \
	atten = LGameShadowFade_SphereDist(wPos, atten);
#else//_SOFT_SHADOW||_HARD_SHADOW
//Forward Base
#ifdef UNITY_PASS_FORWARDBASE
#define LGAME_STARACTOR_SHADOW_COORDS(i)\
 		UNITY_SHADOW_COORDS(i)
#define LGAME_STARACTOR_TRNASFER_SHADOW(o) \
		UNITY_TRANSFER_SHADOW(o,no_use);
#define LGAME_STARACTOR_LIGHT_ATTENUATION(atten,i,wPos,no_use) \
		UNITY_LIGHT_ATTENUATION(atten,i, wPos) \
		atten = lerp(1.0, atten, _ShadowStrength); 
// Forward Add
#elif defined(UNITY_PASS_FORWARDADD)
#define LGAME_STARACTOR_SHADOW_COORDS(i)\
 		UNITY_SHADOW_COORDS(i)
#define LGAME_STARACTOR_TRNASFER_SHADOW(o) \
		UNITY_TRANSFER_SHADOW(o,no_use);
#define LGAME_STARACTOR_LIGHT_ATTENUATION(atten,i,wPos,no_use) \
		UNITY_LIGHT_ATTENUATION(atten,i, wPos)
//Fall back
#else
#define LGAME_STARACTOR_SHADOW_COORDS(i)
#define LGAME_STARACTOR_TRNASFER_SHADOW(o) 
#define LGAME_STARACTOR_LIGHT_ATTENUATION(atten,i,wPos,no_use) \
	half atten = 1.0;
#endif//Pass
#endif//_SOFT_SHADOW||_HARD_SHADOW

#endif//LGAME_STARACTOR_SHADOW_INCLUDED