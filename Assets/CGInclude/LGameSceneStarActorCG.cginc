#ifndef LGAME_SCENE_STARACTOR_CG_INCLUDED
#define LGAME_SCENE_STARACTOR_CG_INCLUDED
#include "UnityCG.cginc"
#include "AutoLight.cginc"	
#include "Lighting.cginc"	
#include "Assets/CGInclude/LGameStarActorBRDF.cginc"
#include "Assets/CGInclude/LGameStarActorLighting.cginc"
#include "Assets/CGInclude/LGameStarActorUtils.cginc"
struct a2v
{
	float4 vertex			: POSITION;
	half2 uv0				: TEXCOORD0;
	half2 uv1				: TEXCOORD1;
#ifdef _DETAIL_MULX2
	half2 uv2				: TEXCOORD2;
	half2 uv3				: TEXCOORD3;
#endif
	half3 normal			: NORMAL;
#if defined(_NORMALMAP) || defined(_CHIFFON)
	half4 tangent			: TANGENT;
#endif
};
struct v2f
{
	float4 pos				: SV_POSITION;
	half4 uv0				: TEXCOORD0;
#ifdef _DETAIL_MULX2
	half4 uv1				: TEXCOORD1;
#endif
	half3 viewDir           : TEXCOORD2;
#if defined(_NORMALMAP) || defined(_CHIFFON)
	float4 tangentToWorld[3]	: TEXCOORD3;
#else	
	half3 posWorld			: TEXCOORD3;
	half3 normalWorld		: TEXCOORD4;
#endif
#ifdef _PLANAR_REFLECTION
	half4 screenPos			:TEXCOORD6;
#endif
	SHADOW_COORDS(7)
#ifdef _CHIFFON
	half4 detail_uv			: TEXCOORD8;
#endif
};
struct v2f_add
{
	float4 pos				: SV_POSITION;
	half4 uv0				: TEXCOORD0;
#ifdef _DETAIL_MULX2
	half4 uv1				: TEXCOORD1;
#endif
	half3 viewDir           : TEXCOORD2;
#if defined(_NORMALMAP) || defined(_CHIFFON)
	float4 tangentToWorld[3]	: TEXCOORD3;
#else	
	half3 posWorld			: TEXCOORD3;
	half3 normalWorld		: TEXCOORD4;
#endif
	UNITY_SHADOW_COORDS(6)
#ifdef _CHIFFON
	half4 detail_uv			: TEXCOORD7;
#endif
};
struct MaterialData
{
	half3 DiffColor;
	half3 SpecColor;
	float3 Normal;
#if defined(LIGHTMAP_ON)||defined(_LIGHTMAP_ON)
	half3 DiffColorBaked;
#endif
#ifdef _PLANAR_REFLECTION
	half3 Environment;
#endif
#ifdef _EMISSION
	half3 Emission;
#endif
	half Occlusion;
	float Smoothness;
	float Roughness;
	float PerceptualRoughness;
	half OneMinusReflectivity;
#if defined(_CHIFFON)
	half opacity;
    float3 detail_normal;
#endif
#if defined(_SILK)
	float3 tangent;
	float3 binormal;
	half roughnessT;
	half roughnessB;
#endif
#ifdef _GLINT
	half3 glint;
#endif
};
#ifdef _NORMALMAP
half		_BumpScale;
sampler2D	_BumpMap;
#endif

#ifdef _DETAIL_MULX2
float4  _DecalMap_ST;
float4  _DetailAlbedoMap_ST;
sampler2D _DecalMap;
sampler2D _DetailAlbedoMap;
#endif

#if defined(_CHIFFON)
sampler2D _DetailMaskMap;
sampler2D _DetailNormalMap;
half4	_DetailNormalMap_ST;
half	_DetailNormalScale;
fixed3	_SheenColor;
#endif

#ifdef _GLINT
sampler2D _DiamondMap;
half4  _DiamondMap_ST;
half	_GlintStrength;
half	_GlintPower;
half    _GlintSpeed;
#endif

#ifdef _SILK
half _Anisotropy;
#endif

float4  _MainTex_ST;
sampler2D _MainTex;
fixed4	_Color;

#ifdef _METALLICGLOSSMAP
sampler2D   _MetallicGlossMap;
float        _GlossMapScale;
#else
half        _Metallic;
half        _Glossiness;
#endif
#ifdef _PLANAR_REFLECTION
sampler2D	_Environment;
#endif
#if _LIGHTMAP_ON
sampler2D		_LightMap;
half			_LightMapIntensity;
#endif

half		_FogStart;
half		_FogEnd;
fixed4		_FogColor;
#ifdef _GLINT
half Glint(half3 viewDir, half3 diamond)
{
	half random = viewDir.x + viewDir.y + viewDir.z + diamond.r;
	float glint = frac(random) * diamond.g;
	glint = pow(glint, _GlintPower)*diamond.b;
	glint *= (frac(sin(_Time.y*_GlintSpeed)*0.25 + random)*0.5 + 0.5)*_GlintStrength;
	return glint;
}
#endif
half3 SimulateFog(float3 wPos, half3 color)
{
	half dist = length(half3(0.0, 0.0, 0.0) - wPos);
	half factor = saturate((_FogEnd - dist) / (_FogEnd - _FogStart));
	color = lerp(_FogColor.rgb, color.rgb, factor);
	return color;
}
void MateiralDataSetup(v2f i, out half3 viewDir, out half3 wPos, out MaterialData Data)
{
	viewDir = normalize(i.viewDir.xyz);
#ifdef _NORMALMAP
	wPos = float3(i.tangentToWorld[0].w, i.tangentToWorld[1].w, i.tangentToWorld[2].w);
	float3 Normal = UnpackScaleNormal(tex2D(_BumpMap, i.uv0.xy), _BumpScale);
#ifdef _CHIFFON
	float3 detail_normal = UnpackScaleNormal(tex2D(_DetailNormalMap, i.detail_uv.xy), _DetailNormalScale);
	float detail_mask = tex2D(_DetailMaskMap, i.uv0.xy).r;
	Data.detail_normal = BlendAngleCorrectedNormals(Normal, detail_normal);
	Data.Normal = lerp(Normal,detail_normal,detail_mask);
#endif
	Data.Normal = normalize(i.tangentToWorld[0].xyz * Normal.r + i.tangentToWorld[1].xyz * Normal.g + i.tangentToWorld[2].xyz * Normal.b);
#else 
	wPos = i.posWorld;
	Data.Normal = normalize(i.normalWorld);
#endif

	half4 Albedo = tex2D(_MainTex, i.uv0.xy) * _Color;
#if defined(_CHIFFON)
    Data.opacity = Albedo.a;
#endif
#ifdef UNITY_COLORSPACE_GAMMA
	Albedo.rgb = GammaToLinearSpace(Albedo.rgb);
#endif

#ifdef _DETAIL_MULX2
	half3 Detail = tex2D(_DetailAlbedoMap, i.uv1.zw);
	half4 Decal = tex2D(_DecalMap, i.uv1.xy);
#ifdef UNITY_COLORSPACE_GAMMA
	Detail.rgb = GammaToLinearSpace(Detail.rgb);
	Decal.rgb = GammaToLinearSpace(Decal.rgb);
#endif
	Albedo.rgb = lerp(Albedo.rgb, Decal.rgb, Decal.a);
	Albedo.rgb *= Detail.rgb;
#endif

#if defined(_SPECULARHIGHLIGHTS_OFF) && defined(_GLOSSYREFLECTIONS_OFF)
	Data.Smoothness = 0.0;
	Data.Roughness = 0.0;
	Data.PerceptualRoughness = 0.0;
	Data.OneMinusReflectivity = 0.0;
	Data.DiffColor = Albedo.rgb;
	Data.SpecColor = 0.0;
#else

#ifdef _METALLICGLOSSMAP
	float3 MG = tex2D(_MetallicGlossMap, i.uv0.xy).rgb;
	MG.g *= _GlossMapScale;
	half Metallic = MG.r;
	Data.Smoothness = MG.g;
#else
	half Metallic = _Metallic;
	Data.Smoothness = _Glossiness;
#endif
	Data.PerceptualRoughness = 1.0 - Data.Smoothness;
	Data.Roughness = max(0.001, Data.PerceptualRoughness * Data.PerceptualRoughness);
	half4 _ColorSpaceDielectricSpec = half4(0.04, 0.04, 0.04, 1.0 - 0.04);
#if defined(_CHIFFON)||defined(_VELVET)
	Data.OneMinusReflectivity = 0.96;
	Data.DiffColor = Albedo.rgb;
	Data.SpecColor = _SheenColor;
#else
	Data.OneMinusReflectivity = (1.0 - Metallic) * _ColorSpaceDielectricSpec.a;
	Data.DiffColor = Albedo.rgb * Data.OneMinusReflectivity;
	Data.SpecColor = lerp(_ColorSpaceDielectricSpec.rgb, Albedo.rgb, Metallic);
#endif
#endif

#ifdef LIGHTMAP_ON //Multiply
	half4 BakedLight = UNITY_SAMPLE_TEX2D(unity_Lightmap, i.uv0.zw);
	Data.DiffColorBaked = DecodeLightmap(BakedLight);
#ifdef UNITY_COLORSPACE_GAMMA
	Data.DiffColorBaked = GammaToLinearSpace(Data.DiffColorBaked);
#endif

#elif defined (_LIGHTMAP_ON) //ADD
	half4 BakedLight = tex2D(_LightMap, i.uv0.zw);
	Data.DiffColorBaked = (BakedLight * 2.0 - 1.0) * _LightMapIntensity;
#ifdef UNITY_COLORSPACE_GAMMA
	Data.DiffColorBaked = GammaToLinearSpace(Data.DiffColorBaked);
#endif
#endif
	Data.Occlusion = OcclusionR(i.uv0);

#ifdef _PLANAR_REFLECTION
	Data.Environment = tex2D(_Environment, i.screenPos.xy / i.screenPos.w)* _ReflectionColor;
#ifdef UNITY_COLORSPACE_GAMMA
	Data.Environment = GammaToLinearSpace(Data.Environment);
#endif
#endif

#ifdef _EMISSION
	Data.Emission = Emission(i.uv0.xy);
#endif

#ifdef _SILK
	Data.roughnessT = max(Data.Roughness  * (1.0 + _Anisotropy), 0.01f);
	Data.roughnessB = max(Data.Roughness  * (1.0 - _Anisotropy), 0.01f);
	Data.tangent = normalize(i.tangentToWorld[0].xyz);
	Data.tangent = Orthonormalize(Data.tangent,Data.normal);
	Data.binormal = cross(Data.tangent, Data.normal);
#endif

#ifdef _GLINT
	half3 diamond = tex2D(_DiamondMap, i.detail_uv.zw);
	Data.glint = Glint(viewDir, diamond);
	Data.opacity = saturate(Data.opacity + Data.glint);
#endif
}
v2f vert(a2v v)
{
	v2f o;
	UNITY_INITIALIZE_OUTPUT(v2f, o);
	float4 posWorld = mul(unity_ObjectToWorld, v.vertex);
	o.pos = UnityObjectToClipPos(v.vertex);
	o.uv0.xy = TRANSFORM_TEX(v.uv0, _MainTex).xy; //固有色以及法线粗糙度金属度
#ifdef LIGHTMAP_ON
	o.uv0.zw = v.uv1 * unity_LightmapST.xy + unity_LightmapST.zw; //光照贴图
#elif defined(_LIGHTMAP_ON)
	o.uv0.zw = v.uv1; //光照贴图
#endif
#ifdef _DETAIL_MULX2
	o.uv1.xy = TRANSFORM_TEX(v.uv2, _DecalMap).xy; //特殊喷涂及笔触叠加——通道
	o.uv1.zw = TRANSFORM_TEX(v.uv3, _DetailAlbedoMap).xy; //污渍及结合处的细节贴图——乘法				
#endif		
	o.viewDir = UnityWorldSpaceViewDir(posWorld) + v.uv1.xyy * 1e-4f;
#ifdef _NORMALMAP
	o.tangentToWorld[0].w = posWorld.x;
	o.tangentToWorld[1].w = posWorld.y;
	o.tangentToWorld[2].w = posWorld.z;
	float3 normalWorld = UnityObjectToWorldNormal(v.normal);
	float3 tangentWorld = UnityObjectToWorldDir(v.tangent.xyz);
	half3 binormalWorld = cross(normalWorld, tangentWorld) *  v.tangent.w * unity_WorldTransformParams.w;
	o.tangentToWorld[0].xyz = tangentWorld;
	o.tangentToWorld[1].xyz = binormalWorld;
	o.tangentToWorld[2].xyz = normalWorld;
#else
	o.posWorld = posWorld;
	o.normalWorld = UnityObjectToWorldNormal(v.normal);
#endif

#ifdef _PLANAR_REFLECTION
	o.screenPos = ComputeScreenPos(o.pos);
#endif
#if defined(_CHIFFON)
	o.detail_uv.xyzw = TRANSFORM_TEX(v.uv0, _DetailNormalMap).xyxy;
#ifdef _GLINT
	o.detail_uv.zw = TRANSFORM_TEX(v.uv0, _DiamondMap);
#endif
#endif
	TRANSFER_SHADOW(o);
	return o;
}
v2f_add vert_add(a2v v)
{
	v2f_add o;
	UNITY_INITIALIZE_OUTPUT(v2f_add, o);
	float4 posWorld = mul(unity_ObjectToWorld, v.vertex);
	o.pos = UnityObjectToClipPos(v.vertex);
	o.uv0.xy = TRANSFORM_TEX(v.uv0, _MainTex).xy; //固有色以及法线粗糙度金属度
#ifdef LIGHTMAP_ON
	o.uv0.zw = v.uv1 * unity_LightmapST.xy + unity_LightmapST.zw; //光照贴图
#elif defined(_LIGHTMAP_ON)
	o.uv0.zw = v.uv1; //光照贴图
#endif
#ifdef _DETAIL_MULX2
	o.uv1.xy = TRANSFORM_TEX(v.uv2, _DecalMap).xy; //特殊喷涂及笔触叠加——通道
	o.uv1.zw = TRANSFORM_TEX(v.uv3, _DetailAlbedoMap).xy; //污渍及结合处的细节贴图——乘法				
#endif		
	o.viewDir = UnityWorldSpaceViewDir(posWorld) + v.uv1.xyy * 1e-4f;
#ifdef _NORMALMAP
	o.tangentToWorld[0].w = posWorld.x;
	o.tangentToWorld[1].w = posWorld.y;
	o.tangentToWorld[2].w = posWorld.z;
	float3 normalWorld = UnityObjectToWorldNormal(v.normal);
	float3 tangentWorld = UnityObjectToWorldDir(v.tangent.xyz);
	half3 binormalWorld = cross(normalWorld, tangentWorld) *  v.tangent.w * unity_WorldTransformParams.w;
	o.tangentToWorld[0].xyz = tangentWorld;
	o.tangentToWorld[1].xyz = binormalWorld;
	o.tangentToWorld[2].xyz = normalWorld;
#else
	o.posWorld = posWorld;
	o.normalWorld = UnityObjectToWorldNormal(v.normal);
#endif

	UNITY_TRANSFER_SHADOW(o, v.uv1);
	return o;
}
//PBS
half4 LGAME_BRDF_PBS(LGameGI gi, MaterialData Data, half3 viewDir, half atten)
{
	/*Diffuse Term*/
#ifdef LIGHTMAP_ON
#ifdef _CHIFFON
    half illum = dot(Data.DiffColorBaked, unity_ColorSpaceLuminance);
    half3 DiffuseTerm = saturate(_SubSurfaceColor + illum) * Data.DiffColorBaked;
#else
	half3 DiffuseTerm = Data.DiffColorBaked * atten;
#endif
#elif defined (_LIGHTMAP_ON)
	half3 DiffuseTerm = atten;
#else
	half NoL = dot(Data.Normal, gi.direct.dir);
#if !defined(_CHIFFON) && !defined(_VELVET)
    NoL = saturate(NoL);
#endif

#if defined(_CHIFFON)
#if defined(_SILK)
	float ToL = dot(Data.tangent, gi.direct.dir);
	float BoL = dot(Data.binormal, gi.direct.dir);
	float ToV = dot(Data.tangent, viewDir);
	float BoV = dot(Data.binormal, viewDir);
	float ToH = dot(Data.tangent, H);
	float BoH = dot(Data.binormal, H);
#endif
	NoL = abs(NoL);
	half3 subsurface = saturate(_SubSurfaceColor + NoL * (atten * 0.5 + 0.5));
	half3 DiffuseTerm = gi.direct.color * subsurface;
#else
	half3 DiffuseTerm = gi.direct.color * atten * NoL;
#endif
#endif

#ifdef _SPECULARHIGHLIGHTS_OFF
	half3 SpecularTerm = 0.0;
#else
	half3 H = normalize(gi.direct.dir + viewDir);
	half NoH = saturate(dot(Data.Normal, H));
	half LoH = saturate(dot(gi.direct.dir, H));
	
#if defined(_SILK)
	float3 SpecularTerm = Silk_Specular_BxDF(NoL, saturate(dot(Data.Normal, viewDir)), NoH, ToV, BoV, ToL, BoL, ToH, BoH, LoH, Data.roughnessT, Data.roughnessB, Data.SpecColor);
#elif defined(_VELVET)
	float3 SpecularTerm = Velvet_Specular_BxDF(NoL, saturate(dot(Data.Normal, viewDir)), NoH, LoH, Data.Roughness, Data.SpecColor);
#else
	float a2 = Data.Roughness * Data.Roughness;
	float d = (NoH * NoH * (a2 - 1.f) + 1.0f) + 0.00001f;
	half3 SpecularTerm = a2 / (max(0.1f, LoH * LoH) * (Data.Roughness + 0.5f) * (d * d) * 4.0) * Data.SpecColor;
	/*Approximate Calculation*/
	SpecularTerm = SpecularTerm - 1e-4f;
	SpecularTerm = clamp(SpecularTerm, 0.0, 100.0);
#endif
#endif
	half3 Color = (Data.DiffColor + SpecularTerm) * DiffuseTerm;
#ifdef UNITY_PASS_FORWARDBASE
#ifdef _PLANAR_REFLECTION
#ifdef _REFLECTION_BLEND
	half3 IndirectSpecularCombined = lerp(Data.Environment, gi.indirect.specular, pow(Data.Roughness, 2.0));
#elif defined(_REFLECTION_PLANAR)
	half3 IndirectSpecularCombined = Data.Environment;
#else
	half3 IndirectSpecularCombined = gi.indirect.specular;
#endif
#else
	half3 IndirectSpecularCombined = gi.indirect.specular;
#endif
#ifdef _GLINT
	Data.glint *= pow(dot(Data.detail_normal, H), 8.0f);
	Data.glint = saturate(Data.glint);
	Color += gi.indirect.specular * Data.glint;
#endif
	Color += gi.indirect.diffuse * Data.DiffColor;
#ifdef _LIGHTMAP_ON
	Color += Data.DiffColorBaked;
#endif
#ifndef _GLOSSYREFLECTIONS_OFF
	half NoV = saturate(dot(Data.Normal, viewDir));
	half SurfaceReduction = (0.6 - 0.08 * Data.PerceptualRoughness);
	SurfaceReduction = 1.0 - Data.Roughness * Data.PerceptualRoughness * SurfaceReduction;
	half GrazingTerm = saturate(Data.Smoothness + (1.0 - Data.OneMinusReflectivity));
	Color += SurfaceReduction * IndirectSpecularCombined * FresnelLerpFast(Data.SpecColor, GrazingTerm, NoV);
#endif	
#ifdef _EMISSION
	Color.rgb += Data.Emission;
#endif
#endif//UNITY_PASS_FORWARDBASE
#if defined(_CHIFFON)
    return half4(Color, Data.opacity);
#else
	return half4(Color, 1.0);
#endif
}

LGameGI LGameSceneEnvironment(half3 wPos, half3 viewDir, MaterialData Data)
{
	LGameGI gi;
	gi.direct = LGameDirectLighting(wPos);
#ifdef UNITY_PASS_FORWARDBASE
	gi.indirect.diffuse = GammaToLinearSpace(_AmbientCol);
#if defined(_GLOSSYREFLECTIONS_OFF)
	gi.indirect.specular = 0.0;
#else	//Enable Reflection	
#ifdef _PLANAR_REFLECTION
	gi.indirect.specular = Data.Environment;
#ifdef _REFLECTION_BLEND
	gi.indirect.specular = IndirectSpecularCubeMap(viewDir, Data.Normal, Data.Occlusion.r, Data.PerceptualRoughness);
#elif defined(_REFLECTION_PLANAR)
	gi.indirect.specular = 0.0;
#else
	gi.indirect.specular = IndirectSpecular(wPos, viewDir, Data.Normal, Data.Occlusion.r, Data.PerceptualRoughness);
#endif
#else	//Disable _PLANAR_REFLECTION	
#if defined(_REFLECTION_BLEND) ||defined(_REFLECTION_PLANAR)
	gi.indirect.specular = IndirectSpecularCubeMap(viewDir, Data.Normal, Data.Occlusion.r, Data.PerceptualRoughness);
#else
	gi.indirect.specular = IndirectSpecular(wPos, viewDir, Data.Normal, Data.Occlusion.r, Data.PerceptualRoughness);
#endif		
#endif//_PLANAR_REFLECTION	
#endif//_GLOSSYREFLECTIONS_OFF
#else//UNITY_PASS_FORWARDBASE
	gi.indirect.diffuse = 0.0;
	gi.indirect.specular = 0.0;
#endif//UNITY_PASS_FORWARDBASE
	return gi;
}
fixed4 frag(v2f i) : SV_Target
{
	half3 viewDir;
	half3 wPos;
	MaterialData Data;
	MateiralDataSetup(i, viewDir, wPos, Data);
	half atten=SHADOW_ATTENUATION(i);
	atten=lerp(1.0,atten,_ShadowStrength);
	//GI Switch
#if defined(_SILK)
	LGameGI gi = FragmentGI_Anisotropic(wPos, viewDir, base.normal, Data.tangent, Data.binormal, _Anisotropy, Data.Occlusion, Data.PerceptualRoughness);
#else
	LGameGI gi = LGameSceneEnvironment(wPos, viewDir, Data);
#endif
	//PBS
	fixed4 col = LGAME_BRDF_PBS(gi, Data, viewDir, atten);
	//Shader Gamma Correction
	#ifdef UNITY_COLORSPACE_GAMMA
		col.rgb = LinearToGammaSpace(col.rgb);
	#endif
		col.rgb = SimulateFog(wPos, col.rgb);
	return col;
}
half4 LGAME_BRDF_PBS_CHIFFON_ADD(LGameDirectLight direct, half3 viewDir, MaterialData chiffon,half atten)
{
	half nl = saturate(dot(chiffon.Normal, direct.dir));
	half3 halfDir = normalize(direct.dir + viewDir);
	half lh = saturate(dot(direct.dir, halfDir));
	half nh = saturate(dot(chiffon.Normal, halfDir));
	half3 diffuseTerm = direct.color * atten * nl;
	float a2 = chiffon.Roughness * chiffon.Roughness;
	float d = nh * nh * (a2 - 1.f) + 1.00001f;
	half specularTerm = a2 / (max(0.1f, lh*lh) * (chiffon.Roughness + 0.5f) * (d * d) * 4);
	half3 color = chiffon.DiffColor * diffuseTerm
		+ specularTerm * diffuseTerm;
	return half4(color, 1.0);
}
fixed4 frag_add(v2f i) : SV_Target
{
	half3 viewDir;
	half3 wPos;
	MaterialData Data;
	MateiralDataSetup(i, viewDir, wPos, Data);
	UNITY_LIGHT_ATTENUATION(atten, i, wPos);
	//GI Switch
	LGameGI gi = LGameSceneEnvironment(wPos, viewDir, Data);
	//PBS
#ifdef _CHIFFON
	fixed4 col = LGAME_BRDF_PBS_CHIFFON_ADD(gi.direct, viewDir, Data, atten);
#else
	fixed4 col = LGAME_BRDF_PBS(gi, Data, viewDir, atten);
#endif
	//Shader Gamma Correction
	#ifdef UNITY_COLORSPACE_GAMMA
		col.rgb = LinearToGammaSpace(col.rgb);
	#endif
		col.rgb = SimulateFog(wPos, col.rgb);
	return col;
}
#endif