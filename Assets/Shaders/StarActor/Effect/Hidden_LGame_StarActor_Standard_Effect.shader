Shader "Hidden/LGame/StarActor/Standard/Effect"
{
	Properties
	{
		//Base
		[HideInInspector]_Color("Color", Color) = (1,1,1,1)
		[HideInInspector]_MainTex("Albedo", 2D) = "white" {}
		[HideInInspector]_Metallic("Metallic", Range(0.0, 1.0)) = 0.0
		[HideInInspector]_MetallicGlossMap("Metallic", 2D) = "white" {}
		[HideInInspector]_Glossiness("Smoothness", Range(0.0, 1.0)) = 0.5
		[HideInInspector]_GlossMapScale("Smoothness Scale", Range(0.0, 1.0)) = 1.0
		[HideInInspector]_BumpScale("Scale", Float) = 1.0
		[HideInInspector]_BumpMap("Normal Map", 2D) = "bump" {}
		[HideInInspector][HDR]_EmissionColor("Color", Color) = (0,0,0)
		[HideInInspector]_EmissionMap("Emission", 2D) = "white" {}
		[HideInInspector]_OcclusionStrength("Strength", Range(0.0, 1.0)) = 1.0
		[HideInInspector]_OcclusionMap("Occlusion", 2D) = "white" {}
		[HideInInspector][Enum(uv0,0,uv1,1)]_OcclusionUVChannel("Occlusion texture UV", Float) = 0
		[HideInInspector]_SssLut("sssLut", 2D) = "white" {}
		[HideInInspector]_SubSurfaceColor("SubSurface Color" , Color) = (0.3,0,0,1)
		[HideInInspector]_SubSurface("SubSurface" ,Range(0,1)) = 1
		[HideInInspector]_AmbientCol("Ambient Color" , Color) = (0.3,0.3,0.3,0.3)
		[HideInInspector][Enum(MatCap,0,CubeMap,1)] _ReflectionType("Reflection Type", Float) = 0
		[HideInInspector][HDR]_ReflectionColor("Reflection Color", Color) = (0.5 , 0.5 , 0.5 , 0)
		[HideInInspector]_ReflectionCubeMap("Reflection CubeMap", Cube) = "" {}
		[HideInInspector]_ReflectionMatCap("Reflection MatCap", 2D) = "" {}
		[HideInInspector]_ShadowStrength("Self Shadow Strength" , Range(0,1)) = 1
		[HideInInspector][HDR]_RakingLightColor("Raking Light Color" , Color) = (0,0,0,0)
		[HideInInspector][HDR]_RakingLightColor2("Dual Raking Light Color" , Color) = (0,0,0,0)
		[HideInInspector]_DirLight("Dir Light" , Vector) = (-1,0,0,0)
		[HideInInspector]_BrightnessInOcclusion("Brightness In Occlusion" , Range(0,1)) = 0.5
		[HideInInspector]_BrightnessInShadow("Brightness In Shadow" , Range(0,1)) = 0.5
		[HideInInspector]_RakingLightSoftness("Raking Light Softness",Float) = 4.0
		//Effect
		_DissolveMap("Dissolve Map",2D) = "black"{}
		_Dissolve("Dissolve",Range(0,1)) = 1.0
		_WorldOrigin("World Origin",Vector) = (0,0,0,0)
		_WorldTerminal("World Terminal",Vector) = (0,0,0,0)
		[Enum(Forward,0,Backward,1)]_WorldDirection("World Direction",Float) = 0
		_WorldClip("World Clip", Float) = 0.0
		_DissolveClip("Dissolve Clip",Range(0,1)) = 0.0
		[Enum(uv0,0,uv1,1)]_DissolveUVChannel("Dissolve UV Channel",Float) = 0
		//Flow
		_FlowMap("Dissolve Map",2D) = "black"{}
		_MaskTex("Mask Texture",2D) = "white"{}
		[HDR]_FlowColor("Color", Color) = (0,0,0)
		_FlowSpeedX("Flow Speed X",Range(-1,1)) = 0.0
		_FlowSpeedY("Flow Speed Y",Range(-1,1)) = 0.0
		_CenterRotation("Center Rotation",Range(0,1.0)) = 0.0
		[Enum(uv0,0,uv1,1,screen,2)]_FlowUVChannel("Flow UV Channel",Float) = 0
		//UV
		[SimpleToggle]_MGSyncMotion("MG Sync Motion",Float) = 0
	}
	//High Quality
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
			Name "FORWARD"
			Tags { "LightMode" = "ForwardBase" }
			CGPROGRAM
			#pragma target 3.0
			#pragma multi_compile_fwdbase nolightmap nodirlightmap nodynlightmap novertexlight noshadowmask  
			#pragma skip_variants LIGHTMAP_SHADOW_MIXING LIGHTPROBE_SH SPOT DIRECTIONAL_COOKIE POINT_COOKIE SHADOWS_CUBE
			#pragma multi_compile _ _HARD_SHADOW _SOFT_SHADOW
			#pragma multi_compile _ _FASTEST_QUALITY
			//#pragma multi_compile __ _USE_DIRECT_GPU_SKINNING
			#pragma shader_feature _EMISSION
			#pragma shader_feature _METALLICGLOSSMAP						
			#pragma shader_feature _OCCLUSION_UV1	
			#pragma shader_feature _REFLECTION_CUBEMAP
			#pragma shader_feature _SUBSURFACE_SCATTERING
			#pragma shader_feature _DUAL_RIMLIGHT
			#pragma shader_feature _WORLD_CLIP
			#pragma shader_feature _DISSOLVE
			#pragma shader_feature _FLOW
			#pragma vertex vert_base
			#pragma fragment frag_base
			#include "Assets/CGInclude/LGameStarActorCG.cginc"	
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
			//#pragma multi_compile __ _USE_DIRECT_GPU_SKINNING
			#pragma skip_variants LIGHTMAP_SHADOW_MIXING SHADOWS_SCREEN LIGHTPROBE_SH SPOT DIRECTIONAL_COOKIE POINT_COOKIE SHADOWS_CUBE
			#pragma shader_feature _METALLICGLOSSMAP
			#pragma shader_feature _OCCLUSION_UV1
			#pragma shader_feature _SUBSURFACE_SCATTERING
			#pragma shader_feature _WORLD_CLIP
			#pragma shader_feature _DISSOLVE
			#pragma vertex vert_add
			#pragma fragment frag_add
			#include "Assets/CGInclude/LGameStarActorCG.cginc"
			ENDCG
		}
		Pass
		{
			Name "ShadowCaster"
			Tags { "LightMode" = "ShadowCaster" }
			ZTest LEqual
			CGPROGRAM
			#pragma multi_compile_shadowcaster
			//#pragma multi_compile __ _USE_DIRECT_GPU_SKINNING
			#pragma skip_variants SHADOWS_CUBE
			#pragma shader_feature _WORLD_CLIP
			#pragma shader_feature _DISSOLVE
			#pragma vertex Vert_Shadow
			#pragma fragment Frag_Shadow
			#include "Assets/CGInclude/LGameStarActorShadowCaster.cginc"	
			ENDCG
		}
	}
	CustomEditor "LGameSDK.AnimTool.LGameStarActorEffectShaderGUI"
}
