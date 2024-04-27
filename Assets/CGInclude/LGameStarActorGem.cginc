#ifndef LGAME_STARACTOR_GEM_INCLUDED
#define LGAME_STARACTOR_GEM_INCLUDED
#include "Assets/CGInclude/LGameCharacterDgs.cginc"
#include "Assets/CGInclude/LGameStarActorEffect.cginc"
sampler2D _BumpMap;
sampler2D _StarActorTexture;
sampler2D _ReflectionMatCap;
sampler2D _MainTex;
half _Glossiness;
half _BumpScale;
half _Refraction;
half _SubSurface;
fixed4 _ReflectionColor;
fixed4 _Color;

struct appdata
{
	float4 vertex : POSITION;
	float2 uv0 : TEXCOORD0;
	float2 uv1 : TEXCOORD1;
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
	float4 uv : TEXCOORD0;
	float4 pos : SV_POSITION;
	float3 viewDir:TEXCOORD1;
	float3 lightDir:TEXCOORD2;
	float3 tangentViewDir:TEXCOORD3;
	float4 tangentToWorld[3] : TEXCOORD4;
	LGAME_STARACTOR_EFFECT_STRUCT(7)
	LGAME_STARACTOR_SHADOW_COORDS(8)
};
v2f vert(appdata v)
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
	o.pos = UnityObjectToClipPos(v.vertex);
	o.uv.xy = v.uv0;
	o.uv.zw = v.uv1;
	float3 posWorld = mul(unity_ObjectToWorld, v.vertex).xyz;
	o.viewDir = UnityWorldSpaceViewDir(posWorld);
	o.lightDir = UnityWorldSpaceLightDir(posWorld);
	float3 normalWorld = UnityObjectToWorldNormal(normal);
	float3 tangentWorld = UnityObjectToWorldDir(tangent.xyz);
	float3 binormalWorld = cross(normalWorld, tangentWorld) * tangent.w * unity_WorldTransformParams.w;
	o.tangentToWorld[0].xyz = tangentWorld;
	o.tangentToWorld[1].xyz = binormalWorld;
	o.tangentToWorld[2].xyz = normalWorld;
	o.tangentToWorld[0].w = posWorld.x;
	o.tangentToWorld[1].w = posWorld.y;
	o.tangentToWorld[2].w = posWorld.z;
	half3x3 objectToTangent = half3x3(
		v.tangent.xyz,
		cross(normal, tangent.xyz) * tangent.w,
		normal
		);
	o.tangentViewDir = mul(objectToTangent, ObjSpaceViewDir(v.vertex)).xyz;
	LGAME_STARACTOR_EFFECT_VERTEX(o)
	LGAME_STARACTOR_TRNASFER_SHADOW(o);
	return o;
}
half3 Specular_Shading(half3 BaseColor,half NdotH, half Roughness)
{
	half a2 = Roughness * Roughness;
	half d = (NdotH * a2 - NdotH) * NdotH + 1.0f;
	half3 Specular= UNITY_INV_PI * a2 / (d * d + 1e-7f);
	Specular *= BaseColor;
	Specular = Specular - 1e-4f;
	Specular = clamp(Specular, 0.0, 100.0);
	return Specular;
}
half3 Fresnel_Shading(half3 Reflection,half PerceptualRoughness,half Roughness,half NoV,out half Edge)
{
	half SurfaceReduction = (0.6 - 0.08 * PerceptualRoughness);
	SurfaceReduction = 1.0 - Roughness * PerceptualRoughness * SurfaceReduction;
	half GrazingTerm = saturate(_Glossiness + 0.08);
	Edge = SurfaceReduction * FresnelLerpFast(0.08, GrazingTerm, NoV);
	half3 Fresnel= Edge * Reflection;
	return Fresnel;
}
half3 Reflection_Shading(half3 N,half3 wPos)
{
	half3 vN = mul((half3x3)UNITY_MATRIX_V, N).xyz;
	half3 vP = UnityWorldToViewPos(wPos);
	half3 vR = normalize(reflect(vP, vN));
	half m = 2.0 * sqrt(vR.x * vR.x + vR.y * vR.y + (vR.z + 1) * (vR.z + 1));
	half2 ReflectionUV = vR.xy / m + 0.5;
	half3 Reflection = tex2D(_ReflectionMatCap, ReflectionUV) * _ReflectionColor;
	return Reflection;
}
half3 Diffuse_Shading(half3 N, half2 uv,half NoL,half atten)
{
	half3 BaseColor= tex2D(_MainTex, uv) * _Color;
	half3 Diffuse = BaseColor *_LightColor0.rgb;
	//Trick For Gem Scattering
	half SubSurfaceRatio = saturate((NoL + 0.5) / 2.25);
	NoL = saturate(NoL);
	half3 SubSurfaceConstant = saturate(BaseColor - NoL * atten);
	Diffuse = lerp(Diffuse * NoL * atten, Diffuse * SubSurfaceRatio + SubSurfaceConstant, _SubSurface);
	return Diffuse;
}

half3 F_Schlick(const half3 f0, half VoH) {
	half f = pow(1.0 - VoH, 5.0);
	return f + f0 * (1.0 - f);
}

#ifdef _WIREFRAME
sampler2D _WireframeMap;
fixed4 _WireframeColor;
half _WireframeWidth;
half _FlowSpeed;
half _FlowScale;
half3 WireFrame_Shading(half2 uv)
{
	half3 Wireframe = tex2D(_WireframeMap, uv);
	half3 Flow = smoothstep(abs(sin(_Time.y * _FlowSpeed + uv.x * _FlowScale * 16.0)), 1.0, Wireframe);
	Wireframe = pow(Wireframe, 1.0 / _WireframeWidth);
	Wireframe += Flow;
	Wireframe *= _WireframeColor;
	return Wireframe;
}
#endif
#ifdef _DECAL
sampler2D _DecalMap;
sampler2D _NoiseMap;
float4 _DecalMap_ST;
fixed4 _DecalColor;
half _HighlightRange;
half _HighlightSpeed;
half4 Decal_Shading(half2 uv,half NoH,half atten)
{
	float2  Decal_UV = TRANSFORM_TEX(uv, _DecalMap);
	half4 Decal = tex2D(_DecalMap, Decal_UV) * _DecalColor;
	half Noise = tex2D(_NoiseMap, uv + _Time.y *_HighlightSpeed);
	Decal.rgb += pow(NoH, 1.0 / _HighlightRange) * Noise * atten;
	return Decal;
}
#endif

#ifdef _FLOCCULE
sampler2D _FlocculeMap;
float4 _FlocculeMap_ST;
fixed4 _FlocculeColor;
half _Parallax;
half _InnerPower;
half3 Floccule_Shading(half2 uv,half3 TV,half NoH, half NoL)
{
	float2  Floccule_UV = TRANSFORM_TEX(uv, _FlocculeMap);
	half3 Floccule = tex2D(_FlocculeMap, Floccule_UV + ParallaxOffset(0.025, _Parallax, TV));
	Floccule *= pow(NoH, 8.0 * _InnerPower) * _FlocculeColor * NoL;
	return Floccule;
}
#endif
#ifdef _GLINT
sampler2D _DiamondMap;
float4 _DiamondMap_ST;
half _GlintPower;
half _GlintSpeed;
half _GlintStrength;
half DiamondGlinting(half3 V, half3 Diamond)
{
	half random = V.x + V.y + V.z + Diamond.r;
	half glint = frac(random) * Diamond.g;
	glint = pow(glint, _GlintPower)*Diamond.b;
	glint *= (frac(sin(_Time.y*_GlintSpeed)*0.25 + random)*0.5 + 0.5)*_GlintStrength;
	return glint;
}
half3 Glint_Shading(half2 uv, half3 TV,half3 V, half NoL,half NoV,half VoR,half3 Reflection,half atten)
{
	float2  Diamond_UV = TRANSFORM_TEX(uv, _DiamondMap);
	half3 Diamond = tex2D(_DiamondMap, Diamond_UV + ParallaxOffset(0.0,NoV, TV));
	half3 Glint = DiamondGlinting(V, Diamond) * Reflection * NoL * VoR * atten;
	return Glint;
}
#endif
#ifdef _OPAL
sampler2D _OpalMap;
float4 _OpalMap_ST;
half _IOR;
half _Level;
half _OpalStrength;
half _OpalDepth;
half _OpalFrequency;
half _ShineType;
half3 FilmIridescence_MonsterHunterWorld(half cos0)
{
	half tr = cos0 * _Level - _IOR;
	half3 n_color = (cos((tr * 35.0) * half3(0.71, 0.87, 1.0)) * -0.5) + 0.5;
	n_color = lerp(n_color, half3(0.5, 0.5, 0.5), tr);
	n_color *= n_color * _OpalStrength;
	return n_color;
}
half3 Opal_Shading(half3 TV,half2 uv ,half Temp,half SignFace,half3 Diffuse,out half3 Output)
{
	float2 Opal_UV = TRANSFORM_TEX(uv, _OpalMap);
	float2 Opal_Depth_UV = Opal_UV + ParallaxOffset(Temp, _OpalDepth, TV * SignFace);
	half Height = tex2D(_OpalMap, Opal_UV).b;
	half2 Data= tex2D(_OpalMap, Opal_Depth_UV).rg; //ID/Mask
	half3 Opal = FilmIridescence_MonsterHunterWorld(Data.r + Temp * _OpalFrequency) * Data.g;
	Opal = lerp(0.0.xxx, Opal, Height);
	Output = Diffuse * lerp(1.0, saturate(1.0 - Height * Data.g * _OpalStrength), _ShineType);
	return Opal;
}
#endif
fixed4 frag(v2f i) : SV_Target
{	//Effect
	//Evalution At Begin
	LGAME_STARACTOR_EFFECT_FRAGMENT_BEGIN(i)
	half3 wPos = half3(i.tangentToWorld[0].w ,i.tangentToWorld[1].w ,i.tangentToWorld[2].w);
	half3 V = normalize(i.viewDir);
	half3 L = Unity_SafeNormalize(i.lightDir);
	half3 TV = normalize(i.tangentViewDir);
	half3 H = Unity_SafeNormalize(L + V);
	half3 N = UnpackScaleNormal(tex2D(_BumpMap, i.uv), _BumpScale);
	N = normalize(i.tangentToWorld[0].xyz*N.r + i.tangentToWorld[1].xyz*N.g + i.tangentToWorld[2].xyz*N.b);
	half3 R = normalize(reflect(-V, N));
	half NoL = dot(N, L);
	half NoV = abs(dot(N, V));
	half NoH = abs(dot(N, H));
	half VoH = abs(dot(V, H));
	half VoR = abs(dot(V, R));
	//LGAME_STARACTOR_EFFECT_FRAGMENT_SETUP(i, null)
	LGAME_STARACTOR_LIGHT_ATTENUATION(atten, i, wPos, NoL);
	//Base Color
	half3 Diffuse = Diffuse_Shading(N,i.uv, NoL, atten);
	NoL = abs(NoL);
	half3 Reflection = Reflection_Shading(N, wPos);

#ifdef _DECAL
	half4 Decal = Decal_Shading(i.uv, NoH,atten);
#endif

#ifdef _GLINT
	half3 Glint = Glint_Shading(i.uv, TV, V, NoL, NoV, VoR, Reflection, atten);
#endif
#ifdef _WIREFRAME
	half3 Wireframe = WireFrame_Shading(i.uv);
#endif

#ifdef _FLOCCULE
	half3 Floccule = Floccule_Shading(i.uv, TV,NoH,NoL);
#endif

#ifdef _OPAL
	half3 TempN = normalize(i.tangentToWorld[2].xyz);
	half3 TempR = normalize(reflect(-V, TempN));
	half TempNoL = abs(dot(TempN, L));
	half TempVoR = abs(dot(TempN, TempR));
	half SignFace = sign(dot(TempN, V));
	half Temp = NoL * VoR;
	half3 Opal = Opal_Shading(TV,i.uv, Temp, SignFace, Diffuse, Diffuse);
#endif
	half PerceptualRoughness = 1.0 - _Glossiness;
	half Roughness = PerceptualRoughness * PerceptualRoughness;
	half3 Specular = Specular_Shading(Diffuse, NoH , Roughness);
	half Edge = 0.0;
	half3 Fresnel = Fresnel_Shading(Reflection, PerceptualRoughness, Roughness, NoV, Edge);
	//Combine
#ifdef _REFRACTION
	//Scene Color
	half4 ScreenUV = UNITY_PROJ_COORD(float4(i.ScreenPosition.xy + N.xy * _Refraction, i.ScreenPosition.zw));
	half3 SceneColor = tex2Dproj(_StarActorTexture, ScreenUV);
	fixed3 Color = lerp(SceneColor * Diffuse, Diffuse, saturate(_Color.a + Edge));
#else
	fixed3 Color = Diffuse;
#endif

	Color += Fresnel;

	Color += Specular;
#ifdef _GLINT
	Color += Glint;
#endif
#ifdef _OPAL
	Color += Opal;
#endif
#ifdef _WIREFRAME
	Color += Wireframe;
#endif
#ifdef _FLOCCULE
	Color += Floccule;
#endif
#ifdef _DECAL
	Color = lerp(Color, Decal.rgb, Decal.a);
#endif
	LGAME_STARACTOR_EFFECT_FRAGMENT_END(i,Color)
#ifdef _REFRACTION
	return fixed4(Color, 1.0);
#else
	return fixed4(Color, saturate(_Color.a + Edge));
#endif
}
#endif