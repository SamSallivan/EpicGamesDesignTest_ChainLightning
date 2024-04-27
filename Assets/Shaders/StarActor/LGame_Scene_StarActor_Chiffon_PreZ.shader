Shader "LGame/Scene/StarActor/Chiffon(PreZ)"
{
	Properties
	{
		_Color("Color", Color) = (1,1,1,1)
		_MainTex("Albedo", 2D) = "white" {}
		_Glossiness("Smoothness", Range(0.0, 1.0)) = 0.5
		_GlossMapScale("Smoothness Scale", Range(0.0, 1.0)) = 1.0
		_Metallic("Metallic", Range(0.0, 1.0)) = 0.0
		_MetallicGlossMap("Metallic", 2D) = "white" {}
		_BumpMap("Normal Map", 2D) = "bump" {}
		_BumpScale("Normal Scale", Range(0.0,1.0)) = 1.0
		[Enum(MatCap,0,CubeMap,1)] _ReflectionType("Reflection Type", Float) = 0
		[HDR]_ReflectionColor("Reflection Color", Color) = (0.5,0.5,0.5)
		_ReflectionMatCap("Reflection Texture", 2D) = "black" {}
		_ReflectionCubeMap("Reflection Texture", Cube) = "" {}
		_AmbientCol("Ambient Color" , Color) = (0.3,0.3,0.3,0.3)
		_ShadowStrength("Self Shadow Strength" , Range(0,1)) = 1
		_DetailMaskMap("Detail Mask Map", 2D) = "white" {}
		_DetailNormalMap("Detail Normal Map",2D) = "bump"{}
		_DetailNormalScale("Detail Normal Scale", Range(0.0,1.0)) = 1.0
		_GlintStrength("Glint Strength",Range(0.0,16.0)) = 1.0
		_GlintPower("Glint Power",Float) = 16.0
		_GlintSpeed("Glint Speed",Float) = 1.0
		_DiamondMap("Diamand Map",2D) = "black"{}
		_Anisotropy("Anisotropy", Range(-1.0, 1.0)) = 0.0
		_SheenColor("Sheen Color",Color) = (0.04,0.04,0.04,1.0)
		_SubSurfaceColor("Subsurface Color",Color) = (0,0,0,0)
		[Enum(Standard,0,Silk,1,Velvet,2)] _SpecularMode("Specular Mode", Float) = 1
		[Enum(UnityEngine.Rendering.CullMode)] 	_CullMode("Cull Mode", int) = 2
		//Cull Front
		[HideInInspector][Enum(UnityEngine.Rendering.CullMode)]_ShadowCullMode("Shadow Cull Mode",int) = 1
		_FogColor("Fog Color",Color) = (0.0,0.0,0.0,1.0)
		_FogStart("Fog Start",Float) = 0.0
		_FogEnd("Fog End",Float) = 300.0
	}
	SubShader
	{
		Tags{ "Queue" = "AlphaTest" "RenderType" = "AlphaTest" }
		LOD 300
		Pass
		{
			Stencil {
				Ref 0
				Comp always
				Pass replace
			}
			ColorMask 0
			Cull Back
			ZWrite On
			Offset 1,1
		}
		Pass
		{
			Name "FORWARD"
			Tags{ "LightMode" = "ForwardBase" }
			Blend SrcAlpha OneMinusSrcAlpha
			ZWrite Off
			Cull[_CullMode]
			CGPROGRAM
			#pragma target 3.0
			#pragma multi_compile_fwdbase nodirlightmap nodynlightmap novertexlight noshadowmask  
			#pragma skip_variants LIGHTMAP_SHADOW_MIXING LIGHTPROBE_SH SPOT DIRECTIONAL_COOKIE POINT_COOKIE
			#pragma vertex vert
			#pragma fragment frag
			#pragma shader_feature _METALLICGLOSSMAP
			#pragma shader_feature _REFLECTION_CUBEMAP
			#pragma shader_feature _GLINT
			//Only For Specular Term
			#pragma shader_feature _ _VELVET _SILK 
			//Only For Diffuse Term
			#define _CHIFFON
			#define _NORMALMAP
			#include "Assets/CGInclude/LGameSceneStarActorCG.cginc"
			ENDCG
		}
		Pass
		{
			Name "FORWARD_DELTA"
			Tags{ "LightMode" = "ForwardAdd" }
			Blend SrcAlpha One
			ZWrite Off
			Cull[_CullMode]
			ZTest LEqual
			CGPROGRAM
			#pragma target 3.0
			#pragma multi_compile_fwdadd
			#pragma skip_variants LIGHTMAP_SHADOW_MIXING LIGHTPROBE_SH SHADOWS_SCREEN SPOT DIRECTIONAL_COOKIE POINT_COOKIE
			#pragma vertex vert_add
			#pragma fragment frag_add
			#pragma shader_feature _METALLICGLOSSMAP
			//Only For Specular Term
			#pragma shader_feature _ _VELVET _SILK 
			//Only For Diffuse Term
			#define _CHIFFON
			#define _NORMALMAP
			#include "Assets/CGInclude/LGameSceneStarActorCG.cginc"
			ENDCG
		}
		Pass
		{
			Name "ShadowCaster"
			Tags{ "LightMode" = "ShadowCaster" }
			ZWrite On
			ZTest LEqual
			Cull[_CullMode]
			CGPROGRAM
			//#pragma multi_compile __ _USE_DIRECT_GPU_SKINNING
			#pragma vertex Vert_Shadow
			#pragma fragment Frag_Shadow
			#pragma multi_compile_shadowcaster
			#pragma skip_variants SHADOWS_CUBE
			#pragma multi_compile _ _ENABLE_TRANSPARENT_SHADOW
			#pragma shader_feature _TRANSPARENT_SHADOW
			#include "Assets/CGInclude/LGameStarActorShadowCaster.cginc"
			ENDCG
		}
		Pass
		{
			Name "META"
			Tags { "LightMode" = "Meta" }
			Cull Off
			CGPROGRAM
			#pragma vertex vert_meta
			#pragma fragment frag_meta
			#pragma shader_feature _EMISSION
			#pragma shader_feature _METALLICGLOSSMAP
			#include "UnityCG.cginc"
			#include "UnityMetaPass.cginc"
			#include "UnityStandardUtils.cginc"
			#include "Assets/CGInclude/LGameStarActorUtils.cginc"
			struct a2v
			{
				float4 vertex			: POSITION;
				float2 uv0				: TEXCOORD0;
				float2 uv1				: TEXCOORD1;
				float2 uv2				: TEXCOORD2;
			};
			 struct v2f_meta
			 {
				 float2 uv       : TEXCOORD0;
				 float4 pos      : SV_POSITION;
			 };
			 fixed4 _Color;
			 float4  _MainTex_ST;
			 sampler2D _MainTex;
#ifdef _METALLICGLOSSMAP
			 sampler2D   _MetallicGlossMap;
			 half        _GlossMapScale;
#else
			 half        _Metallic;
			 half        _Glossiness;
#endif
			 v2f_meta vert_meta(a2v v)
			 {
				 v2f_meta o;
				 o.pos = UnityMetaVertexPosition(v.vertex, v.uv1.xy, v.uv2.xy, unity_LightmapST, unity_DynamicLightmapST);
				 o.uv.xy = TRANSFORM_TEX(v.uv0, _MainTex); // Always source from uv0
				 return o;
			 }
			 struct MetaData
			 {
				half3	DiffColor;
				half3	SpecColor;
				half	OneMinusReflectivity;
				half	Roughness;
			 };

			 half3 UnityLightmappingAlbedo(half3 diffuse, half3 specular, half roughness)
			 {
				 return diffuse + specular * roughness * 0.5;
			 }
			 inline MetaData MetaDataSetup(float4 i_tex)
			 {
				 MetaData Data = (MetaData)0;
				 half4 Albedo = tex2D(_MainTex, i_tex.xy) * _Color;
#ifdef UNITY_COLORSPACE_GAMMA
				 Albedo.rgb = GammaToLinearSpace(Albedo.rgb);
#endif

#ifdef _METALLICGLOSSMAP
				 half3 MG = tex2D(_MetallicGlossMap, i_tex.xy).rgb;
				 MG.g *= _GlossMapScale;
				 half Metallic = MG.r;
				 half Smoothness = MG.g;
#else
				 half Metallic = _Metallic;
				 half Smoothness = _Glossiness;
#endif
				 half PerceptualRoughness = 1.0 - Smoothness;
				 Data.Roughness = max(0.001, PerceptualRoughness * PerceptualRoughness);
				 half4 _ColorSpaceDielectricSpec = half4(0.04, 0.04, 0.04, 1.0 - 0.04);
				 Data.OneMinusReflectivity = (1.0 - Metallic) * _ColorSpaceDielectricSpec.a;
				 Data.DiffColor = Albedo.rgb * Data.OneMinusReflectivity;
				 Data.SpecColor = lerp(_ColorSpaceDielectricSpec.rgb, Albedo.rgb, Metallic);

				 return Data;
			 }
			 float4 frag_meta(v2f_meta i) : SV_Target
			 {
				 MetaData Data = MetaDataSetup(i.uv.xyxy);
				 UnityMetaInput o;
				 UNITY_INITIALIZE_OUTPUT(UnityMetaInput, o);
				 o.Albedo = UnityLightmappingAlbedo(Data.DiffColor, Data.SpecColor, Data.Roughness);
				 o.SpecularColor = Data.SpecColor;
				 o.Emission = Emission(i.uv.xy);
				 half4 Color = 0.0;
				 if (unity_MetaFragmentControl.x)
				 {
					 Color = half4(o.Albedo, 1.0);
					 // d3d9 shader compiler doesn't like NaNs and infinity.
					 unity_OneOverOutputBoost = saturate(unity_OneOverOutputBoost);
					 // Apply Albedo Boost from LightmapSettings.
					 Color.rgb = clamp(pow(Color.rgb, unity_OneOverOutputBoost), 0.0, unity_MaxOutputValue);
				 }
				 if (unity_MetaFragmentControl.y)
				 {
					 Color = half4(o.Emission, 1.0);
				 }
				 return Color;

			 }
			ENDCG
		}
	}
	CustomEditor "CustomShaderGUI.LGameSceneStarActorChiffonShaderGUI"
}