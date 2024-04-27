Shader "LGame/Scene/StarActor/Standard Advanced"
{
    Properties
    {
		_Color("Color", Color) = (1,1,1,1)
		_MainTex("Albedo", 2D) = "white" {}
		_Metallic("Metallic", Range(0.0, 1.0)) = 0.0
		_MetallicGlossMap("Metallic", 2D) = "white" {}
		_Glossiness("Smoothness", Range(0.0, 1.0)) = 0.5
		_GlossMapScale("Smoothness Scale", Range(0.0, 1.0)) = 1.0
		_BumpScale("Scale", Float) = 1.0
		_BumpMap("Normal Map", 2D) = "bump" {}
		_AmbientCol("Ambient Color" , Color) = (0.3,0.3,0.3,0.3)
		[Enum(MatCap,0,CubeMap,1,Planar,2,Blend,3)] _ReflectionType("Reflection Type", Float) = 0
		[HDR]_ReflectionColor("Reflection Color", Color) = (0.5 , 0.5 , 0.5 , 0)
		_ReflectionCubeMap("Reflection CubeMap", Cube) = "" {}
		_ReflectionMatCap("Reflection MatCap", 2D) = "" {}
		_Environment("Environment", 2D) = "" {}
		_ShadowStrength("Self Shadow Strength" , Range(0,1)) = 1
		_DecalMap("Decal Map", 2D) = "black" {}
		_DetailAlbedoMap("Detail Albedo Map",2D) = "black"{}
		_LightMap("LightMap", 2D) = "gray" {}
		_LightMapIntensity("LightMap Intensity",  Range(0,1)) = 1
		[HDR]_EmissionColor("Color", Color) = (0,0,0)
		_EmissionMap("Emission", 2D) = "white" {}
		_OcclusionStrength("Strength", Range(0.0, 1.0)) = 1.0
		_OcclusionMap("Occlusion", 2D) = "white" {}
		[Enum(uv0,0,uv1,1)] _OcclusionUVChannel("Occlusion texture UV", Float) = 0
		_FogColor("Fog Color",Color) = (0.0,0.0,0.0,1.0)
		_FogStart("Fog Start",Float) = 0.0
		_FogEnd("Fog End",Float) = 300.0
    }   
    SubShader
    {
        Tags { "Queue" = "Geometry" "RenderType" = "Opaque" }
		LOD 300
        Pass
        {		
            Name "FORWARD"
            Tags { "LightMode" = "ForwardBase" }          
            CGPROGRAM
			#pragma target 3.0
			#pragma multi_compile_fwdbase nodynlightmap novertexlight noshadowmask 
			#pragma skip_variants LIGHTMAP_SHADOW_MIXING LIGHTPROBE_SH SPOT DIRECTIONAL_COOKIE POINT_COOKIE
			#pragma multi_compile _ _FASTEST_QUALITY
			#pragma multi_compile _ _PLANAR_REFLECTION
			#pragma shader_feature _EMISSION
			#pragma shader_feature _NORMALMAP
			#pragma shader_feature _LIGHTMAP_ON
			#pragma shader_feature _OCCLUSION_UV1	
			#pragma shader_feature _METALLICGLOSSMAP	
			#pragma shader_feature _ _REFLECTION_CUBEMAP _REFLECTION_PLANAR _REFLECTION_BLEND
			#pragma shader_feature ___ _DETAIL_MULX2
			#pragma shader_feature _ _SPECULARHIGHLIGHTS_OFF
			#pragma shader_feature _ _GLOSSYREFLECTIONS_OFF
			#pragma vertex vert
			#pragma fragment frag
			#include "Assets/CGInclude/LGameSceneStarActorCG.cginc"		
			#ifdef _GLOSSYREFLECTIONS_OFF
				#undef _PLANAR_REFLECTION
			#endif			
         ENDCG          
        }
		Pass
		{
			Name "FORWARD_DELTA"
			Tags { "LightMode" = "ForwardAdd" }
			Blend SrcAlpha One
			ZWrite Off
			ZTest LEqual
			CGPROGRAM
			#pragma target 3.0
			#pragma multi_compile_fwdadd  
			#pragma skip_variants LIGHTMAP_SHADOW_MIXING SHADOWS_SCREEN LIGHTPROBE_SH DIRECTIONAL_COOKIE POINT_COOKIE
			#pragma shader_feature _NORMALMAP
			#pragma shader_feature _OCCLUSION_UV1
			#pragma shader_feature _METALLICGLOSSMAP
			#pragma shader_feature ___ _DETAIL_MULX2
			#pragma shader_feature _ _SPECULARHIGHLIGHTS_OFF
			#pragma shader_feature _ _GLOSSYREFLECTIONS_OFF
			#pragma vertex vert_add
			#pragma fragment frag_add 	
			#include "Assets/CGInclude/LGameSceneStarActorCG.cginc"			
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
	CustomEditor "LGameSDK.AnimTool.LGameSceneStarActorStandardAdvancedShaderGUI"
}
