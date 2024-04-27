#ifndef LGAME_STARACTOR_ICE_INCLUDED
#define LGAME_STARACTOR_ICE_INCLUDED
#include "UnityCG.cginc"
#include "AutoLight.cginc"	
#include "Lighting.cginc"	
#include "LGameStarActorShadow.cginc"
#include "LGameStarActorBRDF.cginc"
#include "LGameStarActorLighting.cginc"
#include "LGameStarActorEffect.cginc"
sampler2D _MainTex;
sampler2D _BumpMap;
sampler2D _IceDataMap;
sampler2D _IceCrackMap;
half _BumpScale;
half _NormalShift;
half _Distortion;
half _RefractionScale;
half _TransmissionPower;
half4	_MainTex_ST;
half4	_IceCrackMap_ST;
fixed4	_Color;
fixed4	_TransmissionColor;

#ifdef _METALLICGLOSSMAP
sampler2D	_MetallicGlossMap;
half        _GlossMapScale;
#else
half        _Metallic;
half        _Glossiness;
#endif

#ifdef _GRAB_PASS
sampler2D _StarActorTexture;
sampler2D _DetailNormalMap;
half _DetailNormalScale;
half4	_DetailNormalMap_ST;
#endif

struct a2v
{
	float4 vertex			: POSITION;
	float2 uv0				: TEXCOORD0;
	float2 uv1				: TEXCOORD1;
	half3 normal			: NORMAL;
	half4 tangent			: TANGENT;
	fixed4 color			: COLOR;
};
struct v2f
{
	float4 pos				: SV_POSITION;
	float4 uv				: TEXCOORD0;
	float3 viewDir          : TEXCOORD1;
	float4 tangentToWorld[3]	: TEXCOORD2;
	half3 tangentViewDir	: TEXCOORD5;
	half4 uv1				: TEXCOORD6;
	LGAME_STARACTOR_SHADOW_COORDS(7)
	LGAME_STARACTOR_EFFECT_STRUCT(8)
};
struct IceData
{
	half3 DiffColor;
	half3 SpecColor;
	float3 Normal;
	half3 Occlusion;
	half Smoothness;
	half Roughness;
	half PerceptualRoughness;
	half OneMinusReflectivity;
#if defined(UNITY_PASS_FORWARDBASE)
	half3 Crack;
#if defined(_GRAB_PASS) 
	half3 Background;
#endif
#ifdef _EMISSION
	half3 Emission;
#endif
#endif
	half Opacity;
	half Thickness;
};
half3 Transmission(half3 L, half3 V, half3 N, half3 ambient, half thickness) {
	half3 H = normalize(L + N * _NormalShift);
	half VoH = pow(saturate(dot(V, -H)) + saturate(dot(V, H)), _TransmissionPower);
	return (VoH + ambient) * thickness * _TransmissionColor.rgb;
}
half3 IceCrack(half3 tangentViewDir, half2 uv, half thickness, half mask, half3 Normal,half3 viewDir) {
	half OneMinusNoV = 1.0 - saturate(dot(Normal, viewDir));
	half temp = thickness * OneMinusNoV;
	half3 surface_crack = tex2D(_IceCrackMap, uv + ParallaxOffset(0.025, temp, tangentViewDir));
	half3 deep_crack = tex2D(_IceCrackMap, uv + ParallaxOffset(0.5, temp, tangentViewDir));
	half3 crack = (surface_crack + deep_crack) * mask;
	return crack;
}
void IceDataSetup(v2f i, out float3 viewDir, out half3 wPos, out IceData Ice)
{
	viewDir = normalize(i.viewDir.xyz);
	wPos = half3(i.tangentToWorld[0].w, i.tangentToWorld[1].w, i.tangentToWorld[2].w);
	float3 Normal = UnpackScaleNormal(tex2D(_BumpMap, i.uv.xy), _BumpScale);
	half3 iceData = tex2D(_IceDataMap, i.uv.xy).rgb;
	Ice.Thickness = iceData.r;
	Ice.Normal = normalize(i.tangentToWorld[0].xyz * Normal.r + i.tangentToWorld[1].xyz * Normal.g + i.tangentToWorld[2].xyz * Normal.b);

	half4 albedo = tex2D(_MainTex, TRANSFORM_TEX(i.uv.xy, _MainTex)) * _Color;
#ifdef UNITY_COLORSPACE_GAMMA
	albedo.rgb = GammaToLinearSpace(albedo.rgb);
#endif
	Ice.Opacity = albedo.a;
#ifdef _METALLICGLOSSMAP
	half3 Data = tex2D(_MetallicGlossMap, i.uv).rgb;
	Data.g *= _GlossMapScale;
	Ice.Smoothness = Data.g;
#else
	Ice.Smoothness = _Glossiness;
#endif
	Ice.PerceptualRoughness = 1.0 - Ice.Smoothness;
	Ice.Roughness = max(0.001, Ice.PerceptualRoughness * Ice.PerceptualRoughness);
	half4 _ColorSpaceDielectricSpec = half4(0.04, 0.04, 0.04, 1.0 - 0.04);
	Ice.OneMinusReflectivity = _ColorSpaceDielectricSpec.a;
	Ice.DiffColor = albedo.rgb;
	Ice.SpecColor = albedo.rgb;
#ifdef _OCCLUSION_UV1
	Ice.Occlusion = Occlusion(i.uv.zw);
#else
	Ice.Occlusion = Occlusion(i.uv.xy);
#endif

#if defined(UNITY_PASS_FORWARDBASE)
	//Scene Color
#if defined(_GRAB_PASS)
	half3 DetailNormal = UnpackScaleNormal(tex2D(_DetailNormalMap, i.uv1.zw), iceData.b * _DetailNormalScale);
	half3 FrostedNormal = BlendAngleCorrectedNormals(Normal, DetailNormal);
	FrostedNormal = normalize(i.tangentToWorld[0].xyz * FrostedNormal.r + i.tangentToWorld[1].xyz * FrostedNormal.g + i.tangentToWorld[2].xyz * FrostedNormal.b);
	half4 ScreenUV = UNITY_PROJ_COORD(float4(i.ScreenPosition.xy + FrostedNormal.xy * _Distortion, i.ScreenPosition.zw));
	Ice.Background = tex2Dproj(_StarActorTexture, ScreenUV);
#ifdef UNITY_COLORSPACE_GAMMA
	Ice.Background = GammaToLinearSpace(Ice.Background);
#endif
#endif
	half3 TangentViewDir = normalize(i.tangentViewDir.xyz);
	Ice.Crack = IceCrack(TangentViewDir, i.uv1.xy, iceData.r, iceData.g, Ice.Normal, viewDir);
#ifdef _EMISSION
	Ice.Emission = Emission(i.uv.xy);
#endif
#endif	
}

half4 LGAME_BRDF_PBS_ICE(LGameGI gi, IceData Ice, float3 viewDir, half NoV, half NoL, half atten)
{
	/*Vector*/
	float3 H = Unity_SafeNormalize(gi.direct.dir + viewDir);
	NoL = saturate(NoL);
	float NoH = saturate(dot(Ice.Normal, H));
	float LoH = saturate(dot(gi.direct.dir, H));

	half3 DiffuseTerm = gi.direct.color * atten * NoL;

	float a2 = Ice.Roughness * Ice.Roughness;
	float d = (NoH * NoH * (a2 - 1.f) + 1.0f) + 0.00001f;
	float3 SpecularTerm = a2 / (max(0.1f, LoH * LoH) * (Ice.Roughness + 0.5f) * (d * d) * 4.0f) * Ice.SpecColor;
	SpecularTerm = SpecularTerm - 1e-4f;
	SpecularTerm = clamp(SpecularTerm, 0.0f, 100.0f);

	half3 T = Transmission(gi.direct.dir, viewDir, Ice.Normal, gi.indirect.diffuse, Ice.Thickness);
	/*Combine*/
	half SurfaceReduction = (0.6 - 0.08 * Ice.PerceptualRoughness);
	SurfaceReduction = 1.0 - Ice.Roughness * Ice.PerceptualRoughness * SurfaceReduction;
	half GrazingTerm = saturate(Ice.Smoothness + (1.0 - Ice.OneMinusReflectivity));
	half3 Color = (Ice.DiffColor + SpecularTerm) * DiffuseTerm;
#ifdef UNITY_PASS_FORWARDBASE	
	Color += gi.indirect.diffuse * Ice.DiffColor;
	//half NoV = saturate(dot(Ice.Normal, viewDir));
	half3 ShiftN = normalize(Ice.Normal * _NormalShift + viewDir);
	half ShiftNoV = saturate(dot(ShiftN, viewDir));
	half Alpha = saturate(ShiftNoV + 1.0 - Ice.Thickness);
	Alpha = saturate((pow(Alpha, 4.0) - 0.5) * 2.5);
	Alpha = saturate(Alpha + Luminance(Ice.Crack));
	Alpha *= Ice.Opacity;
#if defined(_GRAB_PASS)
	Color = lerp(Ice.Background.rgb * Color, Color, Alpha);
#endif	
	Color += T * (1.0 - Alpha);
	Color += Ice.Crack * atten;
	Color += SurfaceReduction * gi.indirect.specular * FresnelLerpFast(Ice.SpecColor, GrazingTerm, NoV);
#endif	

#ifdef UNITY_PASS_FORWARDBASE	
#if defined(_PRE_Z)
	Alpha= saturate(Alpha + Luminance(Color));
	return half4(Color, Alpha);
#else	
	return half4(Color, 1.0);
#endif	
#else
#if defined(_PRE_Z)
	half Alpha = saturate(Ice.Opacity + Luminance(Color));
	return half4(Color, Alpha);
#else	
	return half4(Color, 1.0);
#endif	

#endif	
}
v2f Vert_Ice(a2v v)
{
	v2f o;
	UNITY_INITIALIZE_OUTPUT(v2f, o);
	float4 posWorld = mul(unity_ObjectToWorld, v.vertex);
	o.tangentToWorld[0].w = posWorld.x;
	o.tangentToWorld[1].w = posWorld.y;
	o.tangentToWorld[2].w = posWorld.z;
	o.pos = UnityObjectToClipPos(v.vertex);
	o.uv.xy = v.uv0;
	o.uv.zw = v.uv1;
	o.uv1 = TRANSFORM_TEX(v.uv0, _IceCrackMap).xyxy;
	o.viewDir = UnityWorldSpaceViewDir(posWorld);
	float3 normalWorld = UnityObjectToWorldNormal(v.normal);
	float3 tangentWorld = UnityObjectToWorldDir(v.tangent.xyz);
	half3 binormalWorld = cross(normalWorld, tangentWorld) * v.tangent.w * unity_WorldTransformParams.w;
	o.tangentToWorld[0].xyz = tangentWorld;
	o.tangentToWorld[1].xyz = binormalWorld;
	o.tangentToWorld[2].xyz = normalWorld;	
#ifdef UNITY_PASS_FORWARDBASE
	half3x3 objectToTangent = half3x3(
		v.tangent.xyz,
		cross(v.normal, v.tangent.xyz) * v.tangent.w,
		v.normal
		);
	o.tangentViewDir = mul(objectToTangent, ObjSpaceViewDir(v.vertex)).xyz;
#ifdef _GRAB_PASS
	o.uv1.zw = TRANSFORM_TEX(v.uv0, _DetailNormalMap);
#endif
#endif
	LGAME_STARACTOR_EFFECT_VERTEX(o)
	LGAME_STARACTOR_TRNASFER_SHADOW(o)
	return o;
}
fixed4 Frag_Ice(v2f i) : SV_Target
{
	//Effect
	//Evalution At Begin
	LGAME_STARACTOR_EFFECT_FRAGMENT_BEGIN(i)

	IceData Ice;
	half3 viewDir;
	half3 wPos;
	IceDataSetup(i, viewDir, wPos, Ice);
	//Evalution At Base Data Setup
	LGAME_STARACTOR_EFFECT_FRAGMENT_SETUP(i, Ice)
	LGameGI GI = FragmentGI(wPos, viewDir, Ice.Normal, Ice.Occlusion.r, Ice.PerceptualRoughness);
	half NoL = dot(Ice.Normal, GI.direct.dir);
	half NoV = saturate(dot(Ice.Normal, viewDir));
#ifdef UNITY_PASS_FORWARDBASE
	LGAME_STARACTOR_LIGHT_ATTENUATION(atten, i, wPos, NoL);
#else
	UNITY_LIGHT_ATTENUATION(atten, i, wPos)
#endif

	fixed4 Color = LGAME_BRDF_PBS_ICE(GI, Ice, viewDir, NoV, NoL, atten);
#ifdef UNITY_COLORSPACE_GAMMA
	Color.rgb = LinearToGammaSpace(Color.rgb);
#endif

#ifdef UNITY_PASS_FORWARDBASE
	Color.rgb += LGame_RakingLight(wPos, viewDir, Ice.Normal, NoV,atten, Ice.Occlusion.g);
#ifdef _EMISSION
	Color.rgb += Ice.Emission;
#endif
	LGAME_STARACTOR_EFFECT_FRAGMENT_END(i, Color)
#endif
	return Color;
}
#endif