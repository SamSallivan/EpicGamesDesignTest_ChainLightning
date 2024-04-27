Shader "Hidden/LGame/StarActor/Gem/PreZ/Effect"
{
	Properties
	{
		[HDR]_Color("Color", Color) = (1.0 , 1.0 , 1.0 , 0)
		_MainTex("Albedo", 2D) = "white" {}
		_Glossiness("Smoothness", Range(0.0, 1.0)) = 0.5
		_BumpMap("Normal", 2D) = "bump" {}
		_BumpScale("Bump Scale",Range(0.0,1.0)) = 1.0
		_ShadowStrength("Self Shadow Strength" , Range(0,1)) = 1
		_SubSurface("SubSurface" ,Range(0,1)) = 1
		[HDR]_ReflectionColor("Reflection Color", Color) = (1.0 , 1.0 , 1.0 , 0)
		[NoScaleOffset]_ReflectionMatCap("Reflection MatCap", 2D) = "" {}
		_FresnelPower("Fresnel Power",Range(0.0,1.0)) = 0.5
		_DecalColor("Heart-Shaped Color", Color) = (1.0 , 1.0 , 1.0 , 1.0)
		_DecalMap("Heart-Shaped Map", 2D) = "black" {}
		_NoiseMap("Noise Map", 2D) = "black" {}
		_HighlightRange("Highlight Range",Range(0.0,1.0)) = 1.0
		_HighlightSpeed("Highlight Speed",Range(0.0,1.0)) = 1.0
		_DiamondMap("Diamand Map",2D) = "black"{}
		_GlintPower("Glint Power",Float) = 0.1
		_GlintSpeed("Glint Speed",Float) = 1.0
		_GlintStrength("Glint Strength",Range(0.0,16.0)) = 1.0
		[HDR]_WireframeColor("Wireframe Color", Color) = (1,1,1,1)
		_WireframeMap("Wireframe Map", 2D) = "black" {}
		_WireframeWidth("Wireframe Width", Range(0.0,1.0)) = 0.5
		_FlowSpeed("Flow Speed",Range(-1.0,1.0)) = 0.5
		_FlowScale("Flow Scale",Range(0.0,1.0)) = 0.5
		[HDR]_FlocculeColor("Floccule Color",  Color) = (1.0 , 1.0 , 1.0 , 0)
		_FlocculeMap("Floccule Map", 2D) = "" {}
		_InnerPower("Inner Power",Range(0.0,1.0)) = 0.5
		_Parallax("Parallax",Range(0.0,1.0)) = 0.5
		_Refraction("Refraction",Range(0.0,1.0)) = 1.0
		[Enum(Blend,0,Separate,1)] _ShineType("Shine Type", Float) = 0
		[Enum(UnityEngine.Rendering.BlendMode)] _DstFactor("DstFactor()", Float) = 10
		_OpalMap("Opal Map",2D) = "white"{}
		_OpalDepth("Opal Depth", Float) = 1.0
		_OpalFrequency("Opal Frequency", Float) = 1.0
		_IOR("Opal IOR", Range(0.0,1.0)) = 0.5
		_OpalStrength("Opal Strength",Range(0.0,16.0)) = 1.0
		_Level("Level", Range(0.0,1.0)) = 0.5
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
			CGPROGRAM
			#pragma vertex vert_preZ
			#pragma fragment frag_preZ
			#pragma shader_feature _WORLD_CLIP
			#pragma shader_feature _DISSOLVE
			#include "UnityCG.cginc"
			#include "Assets/CGInclude/LGameStarActorCG.cginc"	
			ENDCG
		}
		Pass
		{
			Name "FORWARD"
			Tags{ "LightMode" = "ForwardBase" }
			Blend SrcAlpha [_DstFactor]
			ZWrite Off
			CGPROGRAM
			#pragma target 3.0
			#pragma multi_compile_fwdbase nolightmap nodirlightmap nodynlightmap novertexlight noshadowmask  
			#pragma skip_variants LIGHTMAP_SHADOW_MIXING LIGHTPROBE_SH SPOT DIRECTIONAL_COOKIE POINT_COOKIE SHADOWS_CUBE
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile _ _HARD_SHADOW _SOFT_SHADOW
			#pragma multi_compile _ _FASTEST_QUALITY
			#pragma shader_feature _OPAL
			#pragma shader_feature _DECAL
			#pragma shader_feature _GLINT
			#pragma shader_feature _WIREFRAME
			#pragma shader_feature _FLOCCULE
			#pragma shader_feature _WORLD_CLIP
			#pragma shader_feature _DISSOLVE
			#pragma shader_feature _FLOW
			#include "UnityCG.cginc"
			#include "AutoLight.cginc"	
			#include "Lighting.cginc"	
			#include "Assets/CGInclude/LGameStarActorShadow.cginc"	
			#include "Assets/CGInclude/LGameStarActorGem.cginc"	
			ENDCG
		}
		Pass
		{
			Name "FORWARD_DELTA"
			Tags { "LightMode" = "ForwardAdd" }
			Blend SrcAlpha One
			ZWrite Off
			CGPROGRAM
			#pragma target 3.0
			#pragma multi_compile_fwdadd  
			#pragma skip_variants LIGHTMAP_SHADOW_MIXING SHADOWS_SCREEN LIGHTPROBE_SH SPOT DIRECTIONAL_COOKIE POINT_COOKIE SHADOWS_CUBE
			#pragma vertex vert_add
			#pragma fragment frag_add
			#pragma shader_feature _WORLD_CLIP
			#pragma shader_feature _DISSOLVE
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
			#pragma skip_variants SHADOWS_CUBE
			#pragma vertex Vert_Shadow
			#pragma fragment Frag_Shadow
			#pragma shader_feature _WORLD_CLIP
			#pragma shader_feature _DISSOLVE
			#include "Assets/CGInclude/LGameStarActorShadowCaster.cginc"			
			ENDCG
		}
	}
	CustomEditor "LGameSDK.AnimTool.LGameStarActorGemShaderGUI"
}
