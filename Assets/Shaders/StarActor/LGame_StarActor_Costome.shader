Shader "LGame/StarActor/Costome"
{
	Properties
	{
		_Color("Color", Color) = (1,1,1,1)
		_MainTex("Albedo", 2D) = "white" {}
		_Glossiness("Smoothness", Range(0.0, 1.0)) = 0.5
		_GlossMapScale("Smoothness Scale", Range(0.0, 1.0)) = 1.0
		_MetallicGlossMap("Metallic", 2D) = "white" {}
		_BumpMap("Normal Map", 2D) = "bump" {}
		_BumpScale("Normal Scale", Range(0.0,1.0)) = 1.0
		_OcclusionMap("Occlusion Map",2D) = "white"{}
		_OcclusionStrength("Occlusion Strength",Range(0,1)) = 1
		[Enum(uv0,0,uv1,1)] _OcclusionUVChannel("Occlusion texture UV", Float) = 0
		_DetailAlbedoMap("Detail Albedo Map",2D) = "white"{}
		_DetailNormalMap("Detail Normal Map",2D) = "bump"{}
		_DetailNormalScale("Detail Normal Scale", Range(0.0,1.0)) = 1.0
		_DetailDataMap("Detail Data Map",2D) = "black"{}
		_DetailGlossiness("Detail Smoothness", Range(0.0, 1.0)) = 0.5
		_DetailMetallic("Detail Metallic", Range(0.0, 1.0)) = 0.0
		_DetailOcclusion("Detail Occlusion", Range(0.0, 1.0)) = 0.0
		[HDR]_ReflectionColor("Reflection Color", Color) = (0.5,0.5,0.5)
		_ReflectionMatCap("Reflection Texture", 2D) = "black" {}
		_AmbientCol("Ambient Color" , Color) = (0.3,0.3,0.3,0.3)
		_ShadowStrength("Self Shadow Strength" , Range(0,1)) = 1		
		_Frequency("Frequency", Float) = 1.0
		_IOR("IOR", Range(0.0,1.0)) = 0.5
		_Strength("Strength",Range(0.0,2.0)) = 1.0
		_Thickness("Thickness", Range(0.0,1.0)) = 0.5

		_ClothFrequency("Cloth Frequency", Float) = 1.0
		_ClothIOR("Cloth IOR", Range(0.0,1.0)) = 0.5
		_ClothStrength("Cloth Strength",Range(0.0,2.0)) = 0.0
		_ClothThickness("Cloth Thickness", Range(0.0,1.0)) = 0.5

		_Anisotropy("Anisotropy", Range(-1.0, 1.0)) = 0.0
		_SheenColor("Sheen Color",Color) = (0.04,0.04,0.04,1.0)
		_SubSurfaceColor("Subsurface Color",Color) = (0,0,0,0)
	}
	CGINCLUDE
	#include "UnityCG.cginc"
	#include "AutoLight.cginc"	
	#include "Lighting.cginc"	
	#include "Assets/CGInclude/LGameStarActorPBS.cginc"
	#include "Assets/CGInclude/LGameStarActorLighting.cginc"
	sampler2D _DetailDataMap;
	sampler2D _DetailAlbedoMap;
	sampler2D _DetailNormalMap;
	half _IOR;
	half _Thickness;
	half _Strength;
	half _Frequency;
	half _ClothFrequency; 
	half _ClothIOR;
	half _ClothStrength;
	half _ClothThickness;
	half _DetailNormalScale;
	half _DetailGlossiness;
	half _DetailMetallic;
	half _DetailOcclusion;
	half _Anisotropy;
	fixed3	_SheenColor;
	fixed4	_SubSurfaceColor;
	float4  _DetailDataMap_ST;
	struct CostomeData
	{
		half3 DiffColor;
		half3 SpecColor;
		half3 Normal;
		half3 DetailNormal;
		half3 ViewDir;
		half3 Occlusion;
		half Smoothness;
		half Roughness;
		half PerceptualRoughness;
		half OneMinusReflectivity;
		half Diamond;
		half Mask;
		half RoughnessT;
		half RoughnessB;
		half3 Tangent;
		half3 Binormal;
		half4 Film;
	};
	struct v2f_Costome
	{
		half4 pos				: SV_POSITION;
		half4 uv				: TEXCOORD0;
		half4 detail_uv			: TEXCOORD1;
		half3 viewDir           : TEXCOORD2;
		half4 tangentToWorld[3]	: TEXCOORD3;
		LGAME_STARACTOR_SHADOW_COORDS(6)
	};

	half3 FilmIridescence_MonsterHunterWorld(half cos0,half thickness,half ior,half strength)
	{
		half tr = cos0 * thickness - ior;
		half3 n_color = (cos((tr * 35.0) * half3(0.71, 0.87, 1.0)) * -0.5) + 0.5;
		n_color = lerp(n_color, half3(0.5, 0.5, 0.5), tr);
		n_color *= n_color * strength;
		return n_color;
	}
	CostomeData CostomeDataSetup(v2f_Costome i)
	{
		CostomeData Costome;
		half4 Albedo = tex2D(_MainTex, i.uv.xy) * _Color;
		Albedo.rgb = GammaToLinearSpace(Albedo.rgb);
#ifdef _METALLICGLOSSMAP
		half2 MetallicGlossiness = tex2D(_MetallicGlossMap, i.uv.xy).rg;
		Costome.Smoothness = MetallicGlossiness.g * _GlossMapScale;
#else
		Costome.Smoothness = _Glossiness;
#endif

#ifdef _OCCLUSION_UV1
		Costome.Occlusion = Occlusion(i.uv.zw);
#else
		Costome.Occlusion = Occlusion(i.uv.xy);
#endif

		half4 Data = tex2D(_DetailDataMap, i.detail_uv.zw);

		Data.rgb = lerp(half3(0.0, 1.0, 0.0), Data.rgb, Costome.Occlusion.bbb * half3(1.0, _DetailOcclusion, 1.0));
		half4 _ColorSpaceDielectricSpec = half4(0.04, 0.04, 0.04, 1.0 - 0.04);
		half3 Normal = UnpackScaleNormal(tex2D(_BumpMap, i.uv.xy), _BumpScale);
		half3 DetailNormal = UnpackScaleNormal(tex2D(_DetailNormalMap, i.detail_uv.xy), _DetailNormalScale);
		half3 BlendNormal = BlendAngleCorrectedNormals(Normal, DetailNormal);
		Normal = lerp(Normal, BlendNormal, Costome.Occlusion.b);
		Costome.Normal = normalize(i.tangentToWorld[0].xyz * Normal.r + i.tangentToWorld[1].xyz * Normal.g + i.tangentToWorld[2].xyz * Normal.b);


		Costome.Diamond = Data.r;
		Costome.Occlusion.r *= Data.g;
		Costome.Mask = Data.b;
		half3 DetailAlbedo = tex2D(_DetailAlbedoMap, i.uv.xy);
		Costome.ViewDir = normalize(i.viewDir);
		Albedo.rgb = lerp(Albedo.rgb, DetailAlbedo.rgb, Data.r);

		half DetailGlossiness = max(Costome.Smoothness, _DetailGlossiness);
		Costome.Smoothness =lerp(Costome.Smoothness, DetailGlossiness, Data.r);

		Costome.PerceptualRoughness = 1.0 - Costome.Smoothness;
		Costome.Roughness = max(0.001, Costome.PerceptualRoughness * Costome.PerceptualRoughness);

		Costome.OneMinusReflectivity = (1.0 - _DetailMetallic) * _ColorSpaceDielectricSpec.a;
		Costome.OneMinusReflectivity = lerp(_ColorSpaceDielectricSpec.a, Costome.OneMinusReflectivity, Data.r);

		Costome.SpecColor = lerp(_ColorSpaceDielectricSpec.rgb, Albedo.rgb, _DetailMetallic);
		Costome.SpecColor = lerp(_SheenColor.rgb , Costome.SpecColor ,  Data.r);

		Costome.DiffColor = Albedo.rgb * Costome.OneMinusReflectivity;
		Costome.DiffColor = lerp(Albedo.rgb, Costome.DiffColor, Data.r);

		Costome.RoughnessT = max(Costome.Roughness  * (1.0 + _Anisotropy), 0.001f);
		Costome.RoughnessB = max(Costome.Roughness  * (1.0 - _Anisotropy), 0.001f);
		Costome.Tangent = normalize(i.tangentToWorld[0].xyz);
		Costome.Tangent = Orthonormalize(Costome.Tangent, Costome.Normal);
		Costome.Binormal = cross(Costome.Tangent, Costome.Normal);

		half4 TempValue0 = half4(_ClothFrequency, _ClothThickness, _ClothIOR, 1.0);
		half4 TempValue1 = half4(_Frequency, _Thickness, _IOR, _Strength);
		Costome.Film = lerp(TempValue0, TempValue1, Data.r);
		return Costome;
	}

	half4 LGAME_BRDF_PBS_COSTOME(LGameGI gi, CostomeData Costome, half NoL, half atten)
	{
		half3 H = normalize(gi.direct.dir + Costome.ViewDir);
		NoL = saturate(NoL);
		half NoV = saturate(dot(Costome.Normal, Costome.ViewDir));
		half NoH = saturate(dot(Costome.Normal, H));
		half LoH = saturate(dot(gi.direct.dir, H));
		half ToL = dot(Costome.Tangent, gi.direct.dir);
		half BoL = dot(Costome.Binormal, gi.direct.dir);
		half ToV = dot(Costome.Tangent, Costome.ViewDir);
		half BoV = dot(Costome.Binormal, Costome.ViewDir);
		half ToH = dot(Costome.Tangent, H);
		half BoH = dot(Costome.Binormal, H);

		half3 Subsurface = saturate(_SubSurfaceColor + NoL * (atten * 0.5 + 0.5));
		half3 DiffuseTerm_Cloth = gi.direct.color * Subsurface;
		half3 DiffuseTerm_Glint = gi.direct.color * atten * NoL;
		half3 DiffuseTerm = lerp(DiffuseTerm_Cloth, DiffuseTerm_Glint, Costome.Diamond);

		half3 SpecularTerm_Cloth = Silk_Specular_BxDF(NoL, NoV, NoH, ToV, BoV, ToL, BoL, ToH, BoH, LoH, Costome.RoughnessT, Costome.RoughnessB, Costome.SpecColor);

		float a2 = Costome.Roughness * Costome.Roughness;
		float d = (NoH * NoH * (a2 - 1.f) + 1.0f) + 0.00001f;
		half3 SpecularTerm_Glint = a2 / (max(0.1f, LoH * LoH) * (Costome.Roughness + 0.5f) * (d * d) * 4.0) * Costome.SpecColor;
		
		half3 SpecularTerm = lerp(SpecularTerm_Cloth, SpecularTerm_Glint, Costome.Diamond);
		half3 I = FilmIridescence_MonsterHunterWorld(NoV *  Costome.Film.r, Costome.Film.g, Costome.Film.b, Costome.Film.a);
		SpecularTerm *= lerp(I *_ClothStrength, 1.0.rrr, Costome.Mask);
		SpecularTerm = SpecularTerm - 1e-4f;
		SpecularTerm = clamp(SpecularTerm, 0.0, 100.0);

		half surfaceReduction = (0.6 - 0.08 * Costome.PerceptualRoughness);
		surfaceReduction = 1.0 - Costome.Roughness * Costome.PerceptualRoughness * surfaceReduction;
		half grazingTerm = saturate(Costome.Smoothness + 1.0 - Costome.OneMinusReflectivity);
		half3 color = (Costome.DiffColor + SpecularTerm) * DiffuseTerm
			+ I * Costome.Diamond * Costome.Occlusion.r
			+ gi.indirect.diffuse * Costome.DiffColor
			+ surfaceReduction * gi.indirect.specular * FresnelLerpFast(Costome.SpecColor, grazingTerm, NoV);
		return half4(color, 1.0);
	}
	half4 LGAME_BRDF_PBS_COSTOME_ADD(LGameDirectLight direct, CostomeData Costome,half atten)
	{
		half3 H = normalize(direct.dir + Costome.ViewDir);
		half NoL = saturate(dot(Costome.Normal, direct.dir));
		half NoH = saturate(dot(Costome.Normal, H));
		half LoH = saturate(dot(direct.dir, H));
		half3 diffuseTerm = direct.color * atten * NoL;
		float a2 = Costome.Roughness * Costome.Roughness;
		float d = NoH * NoH * (a2 - 1.f) + 1.00001f;
		half specularTerm = a2 / (max(0.1f, LoH * LoH) * (Costome.Roughness + 0.5f) * (d * d) * 4.0);
		half3 color = Costome.DiffColor * diffuseTerm
			+ specularTerm * diffuseTerm;
		return half4(color, 1.0);
	}
	ENDCG
	SubShader
	{
		Tags{ "RenderType" = "Opaque" "Queue" = "AlphaTest" "PerformanceChecks" = "False" }
		LOD 300
		Stencil {
			Ref 16
			Comp always
			Pass replace
		}
		Pass
		{
			Name "FORWARD"
			Tags{ "LightMode" = "ForwardBase" }
			ZWrite On
			CGPROGRAM
			#pragma multi_compile_fwdbase nolightmap nodirlightmap nodynlightmap novertexlight noshadowmask  
			#pragma skip_variants LIGHTMAP_SHADOW_MIXING LIGHTPROBE_SH SPOT DIRECTIONAL_COOKIE POINT_COOKIE SHADOWS_CUBE
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 3.0
			#pragma multi_compile _ _HARD_SHADOW _SOFT_SHADOW
			#pragma multi_compile _ _FASTEST_QUALITY
			#pragma shader_feature _METALLICGLOSSMAP						
			#pragma shader_feature _OCCLUSION_UV1	
			v2f_Costome vert(a2v v)
			{
				v2f_Costome o;
				UNITY_INITIALIZE_OUTPUT(v2f_Costome,o);
				float3 posWorld = mul(unity_ObjectToWorld, v.vertex).xyz;
				o.tangentToWorld[0].w = posWorld.x;
				o.tangentToWorld[1].w = posWorld.y;
				o.tangentToWorld[2].w = posWorld.z;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv.xy = TRANSFORM_TEX(v.uv0, _MainTex);
				o.uv.zw = v.uv1;
				o.detail_uv = TRANSFORM_TEX(v.uv0, _DetailDataMap).xyxy;
				o.viewDir = normalize(UnityWorldSpaceViewDir(posWorld));
				half3 normalWorld = UnityObjectToWorldNormal(v.normal);
				half3 tangentWorld = UnityObjectToWorldDir(v.tangent.xyz);
				half3 binormalWorld = cross(normalWorld, tangentWorld) * v.tangent.w * unity_WorldTransformParams.w;
				o.tangentToWorld[0].xyz = tangentWorld;
				o.tangentToWorld[1].xyz = binormalWorld;
				o.tangentToWorld[2].xyz = normalWorld;
				LGAME_STARACTOR_TRNASFER_SHADOW(o)
				return o;
			}
			fixed4 frag(v2f_Costome i) : SV_Target
			{
				CostomeData Costome = CostomeDataSetup(i);
				half3 wPos = half3(i.tangentToWorld[0].w, i.tangentToWorld[1].w, i.tangentToWorld[2].w);
				LGameGI gi = FragmentGI_Anisotropic(wPos, Costome.ViewDir,Costome.Normal, Costome.Tangent, Costome.Binormal, _Anisotropy, Costome.Occlusion.r, Costome.PerceptualRoughness);
				half NoL = dot(Costome.Normal, gi.direct.dir);
				LGAME_STARACTOR_LIGHT_ATTENUATION(atten, i, wPos, NoL);
				fixed4 col = LGAME_BRDF_PBS_COSTOME(gi, Costome, NoL, atten);
				col.rgb = LinearToGammaSpace(col.rgb);				
				return  col;
			}
		ENDCG
		}
		Pass
		{
			Name "FORWARD_DELTA"
			Tags{ "LightMode" = "ForwardAdd" }
			Blend One One
			ZWrite Off
			ZTest LEqual
			CGPROGRAM
			#pragma target 3.0
			#pragma multi_compile_fwdadd  
			#pragma skip_variants LIGHTMAP_SHADOW_MIXING SHADOWS_SCREEN LIGHTPROBE_SH SPOT DIRECTIONAL_COOKIE POINT_COOKIE SHADOWS_CUBE			
			#pragma vertex vertAdd
			#pragma fragment fragAdd
			#pragma shader_feature _METALLICGLOSSMAP
			#pragma shader_feature _OCCLUSION_UV1
			v2f_Costome vertAdd(a2v v)
			{
				v2f_Costome o;
				UNITY_INITIALIZE_OUTPUT(v2f_Costome,o);
				float3 posWorld = mul(unity_ObjectToWorld, v.vertex).xyz;
				o.tangentToWorld[0].w = posWorld.x;
				o.tangentToWorld[1].w = posWorld.y;
				o.tangentToWorld[2].w = posWorld.z;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv.xy = TRANSFORM_TEX(v.uv0, _MainTex);
				o.uv.zw = v.uv1;
				o.viewDir = normalize(UnityWorldSpaceViewDir(posWorld));
				half3 normalWorld = UnityObjectToWorldNormal(v.normal);
				half3 tangentWorld = UnityObjectToWorldDir(v.tangent.xyz);
				half3 binormalWorld = cross(normalWorld, tangentWorld) * v.tangent.w * unity_WorldTransformParams.w;
				o.tangentToWorld[0].xyz = tangentWorld;
				o.tangentToWorld[1].xyz = binormalWorld;
				o.tangentToWorld[2].xyz = normalWorld;
				return o;
			}
			half4 fragAdd(v2f_Costome i) : SV_Target
			{
				CostomeData Costome = CostomeDataSetup(i);
				half3 wPos = half3(i.tangentToWorld[0].w, i.tangentToWorld[1].w, i.tangentToWorld[2].w);
				UNITY_LIGHT_ATTENUATION(atten, i, wPos);
				LGameDirectLight direct = LGameDirectLighting(wPos);
				fixed4 col = LGAME_BRDF_PBS_COSTOME_ADD(direct, Costome,atten);
				col.rgb = LinearToGammaSpace(col.rgb);
				return col;
			}
			ENDCG
		}
		Pass
		{
			Name "ShadowCaster"
			Tags { "LightMode" = "ShadowCaster" }
			ZTest LEqual
			CGPROGRAM
			#pragma multi_compile_shadowcaster
			#pragma skip_variants SHADOWS_CUBE
			#pragma vertex Vert_Shadow
			#pragma fragment Frag_Shadow
			#include "Assets/CGInclude/LGameStarActorShadowCaster.cginc"				
			ENDCG
		}
	}	
	CustomEditor "LGameSDK.AnimTool.LGameStarActorCostomeShaderGUI"
}
