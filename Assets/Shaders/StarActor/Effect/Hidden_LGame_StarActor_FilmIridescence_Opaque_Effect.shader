Shader "Hidden/LGame/StarActor/Film Iridescence/Opaque/Effect"
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
		_OcclusionMap("Occlusion Map",2D) = "white"{}
		_OcclusionStrength("Occlusion Strength",Range(0,1)) = 1
		[Enum(uv0,0,uv1,1)] _OcclusionUVChannel("Occlusion texture UV", Float) = 0
		[Enum(MatCap,0,CubeMap,1)] _ReflectionType("Reflection Type", Float) = 0
		[HDR]_ReflectionColor("Reflection Color", Color) = (0.5 , 0.5 , 0.5 , 0)
		_ReflectionMatCap("Reflection Texture", 2D) = "black" {}
		_ReflectionCubeMap("Reflection Texture", Cube) = "" {}
		_AmbientCol("Ambient Color" , Color) = (0.5,0.5,0.5,0.5)
		_ShadowStrength("Self Shadow Strength" , Range(0,1)) = 1
		_FilmThickness("Film Thickness", Range(0,1)) = 1
		_RampMap("Ramp Map",2D) = "black"{}
		_FilmIOR("Film IOR",Range(0,1)) = 1
		_FilmStrengthMap("Iridescence Strength",2D) = "white"{}
		[HDR]_RakingLightColor("Raking Light Color" , Color) = (0,0,0,0)
		[HDR]_RakingLightColor2("Dual Raking Light Color" , Color) = (0,0,0,0)
		_RakingLightSoftness("Raking Light Softness",Range(0.0,16.0)) = 4.0
		_BrightnessInOcclusion("Brightness In Occlusion" , Range(0,1)) = 0.5
		_BrightnessInShadow("Brightness In Shadow" , Range(0,1)) = 0.5
		_DirLight("Dir Light" , Vector) = (-1,0,0,0)
		[Enum(MonsterHunterWorld,0,Ramp,1)] _FilmMode("Film Mode", Float) = 0
		[Enum(Standard,0,Anisotropy,1)] _SpecularMode("Specular Mode", Float) = 0
		[Enum(UnityEngine.Rendering.CullMode)] _CullMode("Cull Mode", int) = 2
		_Anisotropy("Anisotropy", Range(-1.0, 1.0)) = 0.0
		_FilmStrength("Film Strength", Range(0.0, 4.0)) = 1.0
		_FilmSpread("Film Spread", Range(1.0, 5.0)) = 1.0
		_SssLut("sssLut", 2D) = "white" {}
		_SubSurfaceColor("SubSurface Color" , Color) = (0.3,0,0,1)
		_SubSurface("SubSurface" ,Range(0,1)) = 1
		[HDR]_EmissionColor("Color", Color) = (0,0,0)
		_EmissionMap("Emission", 2D) = "white" {}

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
	}
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
				Cull[_CullMode]
				CGPROGRAM
				#pragma multi_compile_fwdbase nolightmap nodirlightmap nodynlightmap novertexlight noshadowmask  
				#pragma skip_variants LIGHTMAP_SHADOW_MIXING LIGHTPROBE_SH SPOT DIRECTIONAL_COOKIE POINT_COOKIE SHADOWS_CUBE
				#pragma vertex Vert_Film
				#pragma fragment Frag_Film
				#pragma target 3.0
				#pragma multi_compile _ _HARD_SHADOW _SOFT_SHADOW
				//#pragma multi_compile __ _USE_DIRECT_GPU_SKINNING
				#pragma multi_compile _ _FASTEST_QUALITY
				#pragma shader_feature _METALLICGLOSSMAP
				#pragma shader_feature _OCCLUSION_UV1
				#pragma shader_feature _REFLECTION_CUBEMAP
				#pragma shader_feature _RAMPMAP
				#pragma shader_feature _ANISOTROPY
				#pragma shader_feature _EMISSION
				#pragma shader_feature _SUBSURFACE_SCATTERING
				#pragma shader_feature _DUAL_RIMLIGHT
				#pragma shader_feature _WORLD_CLIP
				#pragma shader_feature _DISSOLVE
				#pragma shader_feature _FLOW
				#include "Assets/CGInclude/LGameStarActorFilm.cginc"
			ENDCG
			}
		Pass
		{
			Name "FORWARD_DELTA"
			Tags{ "LightMode" = "ForwardAdd" }
			Blend SrcAlpha One
			ZWrite Off
			Cull[_CullMode]
			CGPROGRAM
			#pragma target 3.0
			#pragma multi_compile_fwdadd  
			#pragma skip_variants LIGHTMAP_SHADOW_MIXING SHADOWS_SCREEN LIGHTPROBE_SH SPOT DIRECTIONAL_COOKIE POINT_COOKIE SHADOWS_CUBE		
			#pragma vertex Vert_Film
			#pragma fragment Frag_Film
			#pragma shader_feature _METALLICGLOSSMAP
			#pragma shader_feature _OCCLUSION_UV1
			#pragma shader_feature _RAMPMAP
			#pragma shader_feature _ANISOTROPY
			#pragma shader_feature _SUBSURFACE_SCATTERING
			//#pragma multi_compile __ _USE_DIRECT_GPU_SKINNING
			#pragma shader_feature _WORLD_CLIP
			#pragma shader_feature _DISSOLVE
			#include "Assets/CGInclude/LGameStarActorFilm.cginc"
			ENDCG
		}
		Pass
			{
				Name "ShadowCaster"
				Tags{ "LightMode" = "ShadowCaster" }
				Cull[_CullMode]
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
		CustomEditor "LGameSDK.AnimTool.LGameStarActorFilmIridescenceShaderGUI"
}
