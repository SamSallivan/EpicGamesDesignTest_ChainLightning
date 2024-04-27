//丝绒材质
Shader "LGame/StarActor/Velvet"
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
		[Enum(MatCap,0,CubeMap,1)] _ReflectionType("Reflection Type", Float) = 0
		[HDR]_ReflectionColor("Reflection Color", Color) = (0.5,0.5,0.5)
		_ReflectionMatCap("Reflection Texture", 2D) = "black" {}
		_ReflectionCubeMap("Reflection Texture", Cube) = "" {}
		_AmbientCol("Ambient Color" , Color) = (0.3,0.3,0.3,0.3)
		_ShadowStrength("Self Shadow Strength" , Range(0,1)) = 1
		_SheenColor("Sheen Color",Color) = (0.04,0.04,0.04,1.0)
		_SubSurfaceColor("SubSurface Color",Color) = (0,0,0,0)
		[HDR]_RakingLightColor("Raking Light Color" , Color) = (0,0,0,0)
		_RakingLightSoftness("Raking Light Softness",Float) = 4.0
		_BrightnessInOcclusion("Brightness In Occlusion" , Range(0,1)) = 0.5
		_BrightnessInShadow("Brightness In Shadow" , Range(0,1)) = 0.5
		_DirLight("Dir Light" , Vector) = (-1,0,0,0)
	}
		SubShader
		{
			Tags{ "RenderType" = "Opaque" "Queue" = "AlphaTest" "PerformanceChecks" = "False" }
			LOD 300
			Pass
			{
				Stencil {
					Ref 16
					Comp always
					Pass replace
				}
				Name "FORWARD"
				Tags{ "LightMode" = "ForwardBase" }
				Blend SrcAlpha OneMinusSrcAlpha
				ZWrite On
				CGPROGRAM
				#pragma multi_compile_fwdbase nolightmap nodirlightmap nodynlightmap novertexlight noshadowmask  
				#pragma skip_variants LIGHTMAP_SHADOW_MIXING LIGHTPROBE_SH SPOT DIRECTIONAL_COOKIE POINT_COOKIE SHADOWS_CUBE
				#pragma vertex vert_base
				#pragma fragment frag_base
				#pragma target 3.0
				#pragma multi_compile _ _FASTEST_QUALITY
				#pragma multi_compile _ _HARD_SHADOW _SOFT_SHADOW
				//#pragma multi_compile __ _USE_DIRECT_GPU_SKINNING
				#pragma shader_feature _METALLICGLOSSMAP
				#pragma shader_feature _OCCLUSION_UV1
				#pragma shader_feature _REFLECTION_CUBEMAP
				#define _VELVET
				#include "Assets/CGInclude/LGameStarActorCG.cginc"
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
				//#pragma multi_compile __ _USE_DIRECT_GPU_SKINNING
				#pragma skip_variants LIGHTMAP_SHADOW_MIXING SHADOWS_SCREEN LIGHTPROBE_SH SPOT DIRECTIONAL_COOKIE POINT_COOKIE SHADOWS_CUBE
				#pragma vertex vert_add
				#pragma fragment frag_add
				#pragma shader_feature _METALLICGLOSSMAP
				#pragma shader_feature _OCCLUSION_UV1
				#define _VELVET
				#include "Assets/CGInclude/LGameStarActorCG.cginc"
				ENDCG
			}
			Pass
			{
				Name "ShadowCaster"
				Tags{ "LightMode" = "ShadowCaster" }
				ZWrite On 
				ZTest LEqual
				CGPROGRAM
				//#pragma multi_compile __ _USE_DIRECT_GPU_SKINNING
				#pragma multi_compile_shadowcaster
				#pragma skip_variants SHADOWS_CUBE
				#pragma vertex Vert_Shadow
				#pragma fragment Frag_Shadow
				#include "Assets/CGInclude/LGameStarActorShadowCaster.cginc"		
				ENDCG
			}
		}		
		CustomEditor "LGameSDK.AnimTool.LGameStarActorVelvetShaderGUI"
}