Shader "LGame/StarActor/Chiffon/PreZ (Blend)"
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
		[HDR]_RakingLightColor("Raking Light Color" , Color) = (0,0,0,0)
		[HDR]_RakingLightColor2("Dual Raking Light Color" , Color) = (0,0,0,0)
		_RakingLightSoftness("Raking Light Softness",Float) = 4.0
		_BrightnessInOcclusion("Brightness In Occlusion" , Range(0,1)) = 0.5
		_BrightnessInShadow("Brightness In Shadow" , Range(0,1)) = 0.5
		_DirLight("Dir Light" , Vector) = (-1,0,0,0)
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
	}
	SubShader
	{
		Tags{ "RenderType" = "UniqueShadow" "Queue" = "AlphaTest" "PerformanceChecks" = "False" }
		LOD 300
		Pass
		{
			Stencil {
				Ref 16
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
			#pragma multi_compile_fwdbase nolightmap nodirlightmap nodynlightmap novertexlight noshadowmask  
			#pragma skip_variants LIGHTPROBE_SH SPOT DIRECTIONAL_COOKIE LIGHTMAP_SHADOW_MIXING POINT_COOKIE
			#pragma vertex vert_base
			#pragma fragment frag_base
			#pragma target 3.0
			#pragma multi_compile _ _FASTEST_QUALITY
			#pragma multi_compile _ _HARD_SHADOW _SOFT_SHADOW
			//#pragma multi_compile __ _USE_DIRECT_GPU_SKINNING
			#pragma shader_feature _METALLICGLOSSMAP
			#pragma shader_feature _REFLECTION_CUBEMAP
			#pragma shader_feature _DUAL_RIMLIGHT
			#pragma shader_feature _GLINT
			//Only For Specular Term
			#pragma shader_feature _ _VELVET _SILK 
			//Only For Diffuse Term
			#define _CHIFFON 
			#include "Assets/CGInclude/LGameStarActorCG.cginc"
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
			#pragma multi_compile_fwdadd nolightmap nodirlightmap nodynlightmap novertexlight noshadowmask  
			//#pragma multi_compile __ _USE_DIRECT_GPU_SKINNING
			#pragma skip_variants LIGHTMAP_SHADOW_MIXING SHADOWS_SCREEN LIGHTPROBE_SH SPOT DIRECTIONAL_COOKIE POINT_COOKIE SHADOWS_CUBE
			#pragma vertex vert_add
			#pragma fragment frag_add
			#pragma shader_feature _METALLICGLOSSMAP
			//Only For Specular Term
			#pragma shader_feature _ _VELVET _SILK 
			//Only For Diffuse Term
			#define _CHIFFON 
			#include "Assets/CGInclude/LGameStarActorCG.cginc"
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
	}
	CustomEditor "LGameSDK.AnimTool.LGameStarActorChiffonShaderGUI"
}
