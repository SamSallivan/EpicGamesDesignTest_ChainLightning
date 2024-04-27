Shader "LGame/StarActor/Ice/PreZ"
{
	Properties
	{
		_Color("Color",Color) = (1,1,1,1)
		_MainTex("Main Texture", 2D) = "white" {}
		_Glossiness("Smoothness", Range(0.0, 1.0)) = 0.5
		_GlossMapScale("Smoothness Scale", Range(0.0, 1.0)) = 1.0
		_MetallicGlossMap("Metallic", 2D) = "white" {}
		_BumpMap("Normal Map", 2D) = "bump" {}
		_BumpScale("Normal Scale", Range(0.0,1.0)) = 1.0
		[HDR]_EmissionColor("Color", Color) = (0,0,0)
		_EmissionMap("Emission", 2D) = "white" {}
		_OcclusionMap("Occlusion Map",2D) = "white"{}
		_OcclusionStrength("Occlusion Strength",Range(0,1)) = 1
		[Enum(uv0,0,uv1,1)] _OcclusionUVChannel("Occlusion texture UV", Float) = 0
		[Enum(MatCap,0,CubeMap,1)] _ReflectionType("Reflection Type", Float) = 0
		[HDR]_ReflectionColor("Reflection Color", Color) = (0.5,0.5,0.5)
		_ReflectionMatCap("Reflection MatCap", 2D) = "" {}
		_ReflectionCubeMap("Reflection Texture", Cube) = "" {}
		_AmbientCol("Ambient Color" , Color) = (0.3,0.3,0.3,0.3)
		_ShadowStrength("Self Shadow Strength" , Range(0,1)) = 1
		[HDR]_RakingLightColor("Raking Light Color" , Color) = (0,0,0,0)
		_RakingLightSoftness("Raking Light Softness",Range(0.0,16.0)) = 4.0
		_BrightnessInOcclusion("Brightness In Occlusion" , Range(0,1)) = 0.5
		_BrightnessInShadow("Brightness In Shadow" , Range(0,1)) = 0.5
		_DirLight("Dir Light" , Vector) = (-1,0,0,0)
		[HDR]_TransmissionColor("Color" ,Color) = (0,0,0,0)
		_TransmissionPower("Power" , Range(0,16)) = 12
		_IceCrackMap("Ice Crack Map",2D) = "black"{}
		_IceDataMap("Thinness/Crack/Frosted",2D) = "white"{}
		_DetailNormalMap("Detail Normal Map",2D) = "bump"{}
		_DetailNormalScale("Detail Normal Scale", Range(0.0,1.0)) = 1.0
		_NormalShift("Normal Shift", Range(0.0,4.0)) = 1.0
	}
		SubShader
		{
			Tags { "RenderType" = "Opaque" "Queue" = "AlphaTest" "PerformanceChecks" = "False" }
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
				ZWrite Off
				Cull Back
				Blend SrcAlpha OneMinusSrcAlpha
				Name "FORWARD"
				Tags { "LightMode" = "ForwardBase" }
				CGPROGRAM
				#pragma multi_compile_fwdbase nolightmap nodirlightmap nodynlightmap novertexlight noshadowmask  
				#pragma skip_variants LIGHTMAP_SHADOW_MIXING LIGHTPROBE_SH SPOT DIRECTIONAL_COOKIE POINT_COOKIE SHADOWS_CUBE
				#pragma vertex Vert_Ice
				#pragma fragment Frag_Ice
				#pragma target 3.0
				#pragma multi_compile _ _FASTEST_QUALITY
				#pragma multi_compile _ _HARD_SHADOW _SOFT_SHADOW
				//#pragma multi_compile __ _USE_DIRECT_GPU_SKINNING
				#pragma shader_feature _EMISSION
				#pragma shader_feature _METALLICGLOSSMAP
				#pragma shader_feature _OCCLUSION_UV1
				#pragma shader_feature _REFLECTION_CUBEMAP	
				#define _PRE_Z
				#include "Assets/CGInclude/LGameStarActorIce.cginc"
				ENDCG
			}
			Pass
			{
				Name "FORWARD_DELTA"
				Tags{ "LightMode" = "ForwardAdd" }
				Blend SrcAlpha One
				ZWrite Off
				ZTest LEqual
				CGPROGRAM
				#pragma target 3.0
				#pragma multi_compile_fwdadd  
				//#pragma multi_compile __ _USE_DIRECT_GPU_SKINNING
				#pragma skip_variants LIGHTMAP_SHADOW_MIXING SHADOWS_SCREEN LIGHTPROBE_SH SPOT DIRECTIONAL_COOKIE POINT_COOKIE SHADOWS_CUBE			
				#pragma vertex Vert_Ice
				#pragma fragment Frag_Ice
				#pragma shader_feature _METALLICGLOSSMAP
				#pragma shader_feature _OCCLUSION_UV1
				#define _PRE_Z
				#include "Assets/CGInclude/LGameStarActorIce.cginc"
				ENDCG
			}
			Pass
			{
				Name "ShadowCaster"
				Tags{ "LightMode" = "ShadowCaster" }
				ZTest LEqual
				CGPROGRAM
				#pragma vertex Vert_Shadow
				#pragma fragment Frag_Shadow
				#pragma multi_compile_shadowcaster
				//#pragma multi_compile __ _USE_DIRECT_GPU_SKINNING
				#pragma skip_variants SHADOWS_CUBE
				#include "Assets/CGInclude/LGameStarActorShadowCaster.cginc"
				ENDCG
			}
		}	
		CustomEditor "LGameSDK.AnimTool.LGameStarActorIceShaderGUI"
}
