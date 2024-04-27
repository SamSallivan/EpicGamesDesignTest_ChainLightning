#ifndef LGAME_STARACTOR_FILM_INCLUDED
#define LGAME_STARACTOR_FILM_INCLUDED
#include "UnityCG.cginc"
#include "AutoLight.cginc"	
#include "Lighting.cginc"	
#include "LGameStarActorShadow.cginc"
#include "LGameStarActorBRDF.cginc"
#include "LGameStarActorLighting.cginc"
#include "LGameStarActorEffect.cginc"
#include "Assets/CGInclude/LGameCharacterDgs.cginc"
sampler2D _RampMap;
sampler2D _MainTex;
sampler2D _BumpMap;
sampler2D _FilmStrengthMap;

half	_FilmIOR;
half	_BumpScale;
half	_RimStrength;
half	_FilmStrength;
half	_FilmThickness;
half4	_MainTex_ST;
fixed4	_Color;
float4 _RampMap_TexelSize;

#ifdef _METALLICGLOSSMAP
sampler2D	_MetallicGlossMap;
half        _GlossMapScale;
#else
half        _Metallic;
half        _Glossiness;
#endif

#ifdef _ANISOTROPY
half _Anisotropy;
half _FilmSpread;
#endif
struct a2v
{
	float4 vertex			: POSITION;
	float2 uv0				: TEXCOORD0;
	float2 uv1				: TEXCOORD1;
//	half3 normal			: NORMAL;
//	half4 tangent			: TANGENT;
	fixed4 color : COLOR;

#ifdef _USE_DIRECT_GPU_SKINNING
	half4 tangent	: TANGENT;
	float4 skinIndices : TEXCOORD2;
	float4 skinWeights : TEXCOORD3;
#else
	float3 normal	: NORMAL;
	half4 tangent	: TANGENT;
#endif

};
struct v2f
{
	float4 pos				: SV_POSITION;
	float4 uv				: TEXCOORD0;
	half3 viewDir           : TEXCOORD1;
	float4 tangentToWorld[3]	: TEXCOORD2;
	LGAME_STARACTOR_SHADOW_COORDS(5)
	LGAME_STARACTOR_EFFECT_STRUCT(6)
};
struct FilmData
{
	half3 DiffColor;
	half3 SpecColor;
	half3 Normal;
	half3 Occlusion;
	half Smoothness;
	half Roughness;
	half Opacity;
	half PerceptualRoughness;
	half OneMinusReflectivity;
	half Strength;
#ifdef _ANISOTROPY
	half3 Tangent;
	half3 Binormal;
	half RoughnessT;
	half RoughnessB;
#endif
#if defined(_SUBSURFACE_SCATTERING)
	half Curvature;
#endif
#ifdef _EMISSION
	half3 Emission;
#endif
};

half3 Anisotropic_Specular_BxDF(half NoL, half NoV, half NoH, half ToV, half BoV, half ToL, half BoL, half ToH, half BoH, half LoH, half roughnessT, half roughnessB, half3 specColor) {
	half D = D_Anisotropic(ToH, BoH, NoH, roughnessT, roughnessB);
	half V = V_SmithGGXCorrelated_Anisotropic(roughnessT, roughnessB, ToV, BoV, ToL, BoL, NoV, NoL);
	half3 F = F_Schlick(specColor, LoH);
	return(D * V) * F;
}
void FilmDataSetup(v2f i, out half3 viewDir, out float3 wPos, out FilmData Film)
{
	viewDir = normalize(i.viewDir.xyz);
	wPos = float3(i.tangentToWorld[0].w, i.tangentToWorld[1].w, i.tangentToWorld[2].w);
	half3 Normal = UnpackScaleNormal(tex2D(_BumpMap, i.uv.xy), _BumpScale);
	Film.Normal = normalize(i.tangentToWorld[0].xyz * Normal.r + i.tangentToWorld[1].xyz * Normal.g + i.tangentToWorld[2].xyz * Normal.b);
	half4 Albedo = tex2D(_MainTex, TRANSFORM_TEX(i.uv.xy, _MainTex)) * _Color;
#ifdef UNITY_COLORSPACE_GAMMA
	Albedo.rgb = GammaToLinearSpace(Albedo.rgb);
#endif
	Film.Opacity = Albedo.a;
#ifdef _METALLICGLOSSMAP
	half3 Data = tex2D(_MetallicGlossMap, i.uv).rgb;
#ifdef _SUBSURFACE_SCATTERING
	Data.gb *= half2(_GlossMapScale, _SubSurface);
#else
	Data.g *= _GlossMapScale;
#endif
	half Metallic = Data.r;
	Film.Smoothness = Data.g;

#ifdef _SUBSURFACE_SCATTERING
	Film.Curvature = Data.b;
#endif
#else
	half Metallic = _Metallic;
	Film.Smoothness = _Glossiness;
#ifdef _SUBSURFACE_SCATTERING
	Film.Curvature = _SubSurface;
#endif
#endif
	Film.PerceptualRoughness = 1.0 - Film.Smoothness;
	Film.Roughness = max(0.001, Film.PerceptualRoughness * Film.PerceptualRoughness);
	half4 _ColorSpaceDielectricSpec = half4(0.04, 0.04, 0.04, 1.0 - 0.04);
	Film.OneMinusReflectivity = (1.0 - Metallic) * _ColorSpaceDielectricSpec.a;
	Film.DiffColor = Albedo.rgb * Film.OneMinusReflectivity;
	Film.SpecColor = lerp(_ColorSpaceDielectricSpec.rgb, Albedo.rgb, Metallic);
#ifdef _OCCLUSION_UV1
	Film.Occlusion = Occlusion(i.uv.zw);
#else
	Film.Occlusion = Occlusion(i.uv.xy);
#endif
	Film.Strength = tex2D(_FilmStrengthMap, i.uv).r;
#ifdef _ANISOTROPY
	Film.RoughnessT = max(Film.Roughness  * (1.0 + _Anisotropy), 0.01f);
	Film.RoughnessB = max(Film.Roughness  * (1.0 - _Anisotropy), 0.01f);
	Film.Tangent = normalize(i.tangentToWorld[0].xyz);
	Film.Tangent = Orthonormalize(Film.Tangent, Film.Normal);
	Film.Binormal = cross(Film.Tangent, Film.Normal);
#endif

#ifdef _EMISSION
	Film.Emission = Emission(i.uv.xy);
#endif
}
half3  FilmIridescence_Ramp(half cos0, half thickness, half IOR)
{
	half2 texcoord = clamp(half2(IOR, cos0 * thickness), _RampMap_TexelSize.xy * 0.5, 1.0 - _RampMap_TexelSize.xy * 0.5);
	half3 n_color = tex2D(_RampMap, texcoord);
	return n_color;
}
half3  FilmIridescence_MonsterHunterWorld(half cos0, half thickness, half IOR)
{
	half tr = cos0 * thickness - IOR;
	half3 n_color = (cos((tr * 35.0) * half3(0.71, 0.87, 1.0)) * -0.5) + 0.5;
	n_color = lerp(n_color, half3(0.5, 0.5, 0.5), tr);
	n_color *= n_color * 2.0f;
	return n_color;
}
half3  FilmIridescence(half cos0, half thickness, half IOR)
{
	half3 n_color;
#ifdef _RAMPMAP
	n_color = FilmIridescence_Ramp(cos0, thickness, IOR);
#else
	n_color = FilmIridescence_MonsterHunterWorld(cos0, thickness, IOR);
#endif
	return 	n_color * _FilmStrength;
}
half4 LGAME_BRDF_PBS_FILM(LGameGI gi, FilmData Film, half3 viewDir, half NoV, half NoL, half atten)
{
	half3 H = normalize(gi.direct.dir + viewDir);
#ifndef _SUBSURFACE_SCATTERING
	NoL = saturate(NoL);
#endif
	half NoH = saturate(dot(Film.Normal, H));
	half LoH = saturate(dot(gi.direct.dir, H));
#ifdef _ANISOTROPY
	half ToL = dot(Film.Tangent, gi.direct.dir);
	half BoL = dot(Film.Binormal, gi.direct.dir);
	half ToV = dot(Film.Tangent, viewDir);
	half BoV = dot(Film.Binormal, viewDir);
	half ToH = dot(Film.Tangent, H);
	half BoH = dot(Film.Binormal, H);
#endif


#ifdef _SUBSURFACE_SCATTERING
	half3 Subsurface = SubSurfaceColor(NoL, atten, Film.Curvature);
	half3 DiffuseTerm = gi.direct.color * Subsurface;
#else
	half3 DiffuseTerm = gi.direct.color * atten * NoL;
#endif

#ifdef _ANISOTROPY
	half3 SpecularTerm = Anisotropic_Specular_BxDF(NoL, NoV, NoH, ToV, BoV, ToL, BoL, ToH, BoH, LoH, Film.RoughnessT, Film.RoughnessB, Film.SpecColor);
#else
	float a2 = Film.Roughness * Film.Roughness;
	float d = (NoH * NoH * (a2 - 1.f) + 1.0f) + 0.00001f;
	half3 SpecularTerm = a2 / (max(0.1f, LoH * LoH) * (Film.Roughness + 0.5f) * (d * d) * 4.0) * Film.SpecColor;
#endif

#ifdef _ANISOTROPY
	half cos0 = lerp(BoV, ToV, _Anisotropy);
	cos0 = abs(cos0);
	half3 I = FilmIridescence(cos0, _FilmThickness, _FilmIOR);
	SpecularTerm = lerp(SpecularTerm, pow(SpecularTerm, 1.0 / _FilmSpread) * I, Film.Strength);
#else
	half3 I = FilmIridescence(NoV, _FilmThickness, _FilmIOR);
	SpecularTerm *= lerp(1.0.rrr, I , Film.Strength);
#endif
	SpecularTerm = SpecularTerm - 1e-4f;
	SpecularTerm = clamp(SpecularTerm, 0.0, 100.0);
	half SurfaceReduction = (0.6 - 0.08 * Film.PerceptualRoughness);
	SurfaceReduction = 1.0 - Film.Roughness * Film.PerceptualRoughness * SurfaceReduction;
	half GrazingTerm = saturate(Film.Smoothness + (1.0 - Film.OneMinusReflectivity));
	//Optimized
	half Temp = Pow4(1.0 - NoV);
	half Fresnel = lerp(Film.SpecColor, GrazingTerm, Temp);
	half3 Color = (Film.DiffColor + SpecularTerm) * DiffuseTerm;
#ifdef UNITY_PASS_FORWARDBASE
	Color += gi.indirect.diffuse * Film.DiffColor;
	Color += SurfaceReduction * gi.indirect.specular * Fresnel;
#endif
#ifdef	_TRANSPARENT
	Film.Opacity = lerp(Film.Opacity, 1.0, Temp * _RimStrength);
#else
	Film.Opacity = 1.0;
#endif
	return half4(Color, Film.Opacity);
}
v2f Vert_Film(a2v v)
{
	float3 normal;
	float4 tangent;
#if _USE_DIRECT_GPU_SKINNING
	float3 binormal;
	DecompressTangentNormal(v.tangent, tangent, normal, binormal);
	v.vertex = CalculateGPUSkin(v.skinIndices, v.skinWeights, v.vertex, tangent, normal, binormal);
	v.uv0.xy = DecompressUV(v.uv0.xy, _uvBoundData);
#else
	normal = v.normal;
	tangent = v.tangent;
#endif
	v2f o;
	UNITY_INITIALIZE_OUTPUT(v2f, o);
	float4 posWorld = mul(unity_ObjectToWorld, v.vertex);
	o.tangentToWorld[0].w = posWorld.x;
	o.tangentToWorld[1].w = posWorld.y;
	o.tangentToWorld[2].w = posWorld.z;
	o.pos = UnityObjectToClipPos(v.vertex);
	o.uv.xy = v.uv0;
	o.uv.zw = v.uv1;
	o.viewDir = UnityWorldSpaceViewDir(posWorld);
	float3 normalWorld = UnityObjectToWorldNormal(normal);
	float3 tangentWorld = UnityObjectToWorldDir(tangent.xyz);
	half3 binormalWorld = cross(normalWorld, tangentWorld) * tangent.w * unity_WorldTransformParams.w;
	o.tangentToWorld[0].xyz = tangentWorld;
	o.tangentToWorld[1].xyz = binormalWorld;
	o.tangentToWorld[2].xyz = normalWorld;
	/*Effect*/
	LGAME_STARACTOR_EFFECT_VERTEX(o)
	LGAME_STARACTOR_TRNASFER_SHADOW(o)
	return o;
}
fixed4 Frag_Film(v2f i) : SV_Target
{
	//Effect
	//Evalution At Begin
	LGAME_STARACTOR_EFFECT_FRAGMENT_BEGIN(i)
	FilmData Film;
	half3 viewDir;
	float3 wPos;
	FilmDataSetup(i, viewDir, wPos, Film);
	//Evalution At Base Data Setup
	LGAME_STARACTOR_EFFECT_FRAGMENT_SETUP(i, Film)
#if _ANISOTROPY
	LGameGI GI = FragmentGI_Anisotropic(wPos, viewDir, Film.Normal, Film.Tangent, Film.Binormal, _Anisotropy, Film.Occlusion.r, Film.PerceptualRoughness);
#else
	LGameGI GI = FragmentGI(wPos, viewDir, Film.Normal, Film.Occlusion.r, Film.PerceptualRoughness);
#endif
	half NoL = dot(Film.Normal, GI.direct.dir);
	half NoV = saturate(dot(Film.Normal, viewDir));
#ifdef UNITY_PASS_FORWARDBASE
	LGAME_STARACTOR_LIGHT_ATTENUATION(atten, i, wPos, NoL);
#else
	UNITY_LIGHT_ATTENUATION(atten, i, wPos)
#endif
	fixed4 Color = LGAME_BRDF_PBS_FILM(GI, Film, viewDir, NoV, NoL, atten);
#ifdef UNITY_COLORSPACE_GAMMA
	Color.rgb = LinearToGammaSpace(Color.rgb);
#endif
#ifdef UNITY_PASS_FORWARDBASE
	Color.rgb += LGame_RakingLight(wPos, viewDir, Film.Normal, NoV,atten, Film.Occlusion.g);
#ifdef _EMISSION
	Color.rgb += Film.Emission;
#endif
	LGAME_STARACTOR_EFFECT_FRAGMENT_END(i, Color)
#endif
	return Color;
}
#endif