
#ifndef LGAME_CONSOLE_CG_INCLUDE  
#define LGAME_CONSOLE_CG_INCLUDE

//@todo:  Should we wrap these vars in a define?
sampler2D   _SpecTex;
samplerCUBE _SpecCube;
half        _SpecRoughness;
half        _SpecContrast;
float       _SpecBoost;
float       _SpecSubtract;

// Add normal to appdata_uv2 for reflection calculations
struct appdata_uv2_n
{
	float4 vertex : POSITION;
	float3 normal : NORMAL;
	half2 texcoord : TEXCOORD0;
	half4 uv2: TEXCOORD1;
	UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct appdata_uv3_gpu_n
{
	float4 vertex : POSITION;
	float3 normal : NORMAL;
	half2 texcoord : TEXCOORD0;
	half4 uv2: TEXCOORD1;
	half4 uv3: TEXCOORD2;
	UNITY_VERTEX_INPUT_INSTANCE_ID
};

// We are expecting our _SpecCube to have a dimension of 256 to maintain consistency in the look of our faux roughness lod biasing
#define SPEC_CUBE_MAP_DIMENSION		256

// This is a cheap, artist controllable faux specular reflection implemented as a pretty simple cubemap lookup
float3 GetSpecularCubeReflection(half2 uv, float3 viewDir, float3 worldNormal)
{
	fixed4 specMap = tex2D(_SpecTex, uv);

	float3 reflectedDir = normalize(reflect(-viewDir, worldNormal));

	const half numCubeMips = log2(SPEC_CUBE_MAP_DIMENSION);
	half  mipLevel = numCubeMips * _SpecRoughness;
	half4 reflection = texCUBElod(_SpecCube, float4(reflectedDir, mipLevel));
	half4 reflectionBiased = pow(reflection, _SpecContrast) - _SpecSubtract;
	half4 reflectionMasked = reflectionBiased * specMap;

	return reflectionMasked * _SpecBoost;
}

inline float3 TransformFromDualQuat_Normal(half2x4 dualQuat, float3 n)
{
	return n + 2.0 * cross(dualQuat[0].xyz, cross(dualQuat[0].xyz, n) + dualQuat[0].w*n);
}

// This is a bit of a workaround for the fact that Unity doesn't appear to support modifying the ScreenSpaceShadowMask texture *directly*
// Use LGAME_SHADOW_ATTENUATION instead of the built in SHADOW_ATTENUATION macro to enable a single point of switching between using Unity's built in shadow map directly vs. our custom screen blurred version
#define LGAME_ENABLE_SCREEN_SPACE_SHADOW_BLUR	1

#if LGAME_ENABLE_SCREEN_SPACE_SHADOW_BLUR

	#if defined(SHADOWS_SCREEN)
		sampler2D _ScreenSpaceShadowMaskBlurred;
		#define LGAME_SHADOW_ATTENUATION(a)	UNITY_SAMPLE_SCREEN_SHADOW(_ScreenSpaceShadowMaskBlurred, a._ShadowCoord)
	#else
		#define LGAME_SHADOW_ATTENUATION(a) 1.0
	#endif

#else

	#define LGAME_SHADOW_ATTENUATION(a)	SHADOW_ATTENUATION(a)

#endif

#endif // LGAME_CONSOLE_CG_INCLUDE 