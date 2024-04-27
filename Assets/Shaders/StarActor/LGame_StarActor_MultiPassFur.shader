Shader "LGame/StarActor/MultiPassFur"
{
	Properties
	{
		_Color("Color", Color) = (1,1,1,1)
		_MainTex("Albedo", 2D) = "white" {}
		_MetallicGlossMap("Metallic", 2D) = "white" {}
		_Glossiness("Smoothness", Range(0.0, 1.0)) = 0.5
		_GlossMapScale("Smoothness Scale", Range(0.0, 1.0)) = 1.0
		_BumpScale("Scale", Float) = 1.0
		_BumpMap("Normal Map", 2D) = "bump" {}
		_SheenColor("Sheen Color",Color) = (0.04,0.04,0.04,1.0)
		_SubSurfaceColor("SubSurface Color" , Color) = (0.3,0,0,1)
		_AmbientCol("Ambient Color" , Color) = (0.3,0.3,0.3,0.3)
		[Enum(MatCap,0,CubeMap,1)] _ReflectionType("Reflection Type", Float) = 0
		[HDR]_ReflectionColor("Reflection Color", Color) = (0.5 , 0.5 , 0.5 , 0)
		_ReflectionCubeMap("Reflection CubeMap", Cube) = "" {}
		_ReflectionMatCap("Reflection MatCap", 2D) = "" {}
		[HDR]_RakingLightColor("Raking Light Color" , Color) = (0,0,0,1)
		[HDR]_RakingLightColor2("Raking Light Color2" , Color) = (0,0,0,1)
		_DirLight("Dir Light" , Vector) = (-1,0,0,0)
		_RakingLightSoftness("Raking Light Softness",Float) = 4.0
		_NoiseMap("Noise Map",2D) = "white"{}
		_FurLength("Fur Length", Range(0,0.2)) = 0.02
		_FurOcclusion("Fur Occlusion", Range(0,1.0)) = 1.0
		_NoiseFade("Noise Fade",Range(0,1.0)) = 1.0
		_Gravity("Gravity",Range(0,1.0)) = 0.0
		_Wind("Wind",Vector) = (1.0,0.0,0.0,0.0)
		_FurFlowMap("Flow map", 2D) = "bump"{}
		_FlowMapScale ("Flow map scale", float) = 1

		[Enum(UnityEngine.Rendering.CullMode)] 	_CullMode("Cull Mode", int) = 2
		[HideInInspector]_NoiseFadeLayer0("",Float) = 0.0
		[HideInInspector]_NoiseFadeLayer1("",Float) = 0.0
		[HideInInspector]_NoiseFadeLayer2("",Float) = 0.0
		[HideInInspector]_NoiseFadeLayer3("",Float) = 0.0
		[HideInInspector]_NoiseFadeLayer4("",Float) = 0.0
		[HideInInspector]_NoiseFadeLayer5("",Float) = 0.0
		[HideInInspector]_NoiseFadeLayer6("",Float) = 0.0
		[HideInInspector]_NoiseFadeLayer7("",Float) = 0.0
		[HideInInspector]_NoiseFadeLayer8("",Float) = 0.0
		[HideInInspector]_NoiseFadeLayer9("",Float) = 0.0
		[HideInInspector]_NoiseFadeLayer10("",Float) = 0.0

		[HideInInspector]_FurMultiplierLayer0("",Float) = 0.0
		[HideInInspector]_FurMultiplierLayer1("",Float) = 0.0
		[HideInInspector]_FurMultiplierLayer2("",Float) = 0.0
		[HideInInspector]_FurMultiplierLayer3("",Float) = 0.0
		[HideInInspector]_FurMultiplierLayer4("",Float) = 0.0
		[HideInInspector]_FurMultiplierLayer5("",Float) = 0.0
		[HideInInspector]_FurMultiplierLayer6("",Float) = 0.0
		[HideInInspector]_FurMultiplierLayer7("",Float) = 0.0
		[HideInInspector]_FurMultiplierLayer8("",Float) = 0.0
		[HideInInspector]_FurMultiplierLayer9("",Float) = 0.0
		[HideInInspector]_FurMultiplierLayer10("",Float) = 0.0

		[HideInInspector]_OcclusionLayer0("",Float) = 0.0
		[HideInInspector]_OcclusionLayer1("",Float) = 0.0
		[HideInInspector]_OcclusionLayer2("",Float) = 0.0
		[HideInInspector]_OcclusionLayer3("",Float) = 0.0
		[HideInInspector]_OcclusionLayer4("",Float) = 0.0
		[HideInInspector]_OcclusionLayer5("",Float) = 0.0
		[HideInInspector]_OcclusionLayer6("",Float) = 0.0
		[HideInInspector]_OcclusionLayer7("",Float) = 0.0
		[HideInInspector]_OcclusionLayer8("",Float) = 0.0
		[HideInInspector]_OcclusionLayer9("",Float) = 0.0
		[HideInInspector]_OcclusionLayer10("",Float) = 0.0
		
		_ZWrite ("Solid layer ZWrite", Int) = 1
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" "Queue" = "Transparent" "PerformanceChecks"="False" }
		LOD 300
		Stencil {
			Ref 16
			Comp always
			Pass replace
		}
		Pass{
			Blend SrcAlpha OneMinusSrcAlpha
			Zwrite [_ZWrite]
			Cull Off
			Name "FORWARD"
			Tags { "LightMode" = "ForwardBase" }
			CGPROGRAM
			#pragma target 3.0
			#pragma multi_compile_fwdbase nolightmap nodirlightmap nodynlightmap novertexlight noshadowmask  
			#pragma skip_variants LIGHTMAP_SHADOW_MIXING LIGHTPROBE_SH SPOT DIRECTIONAL_COOKIE POINT_COOKIE SHADOWS_CUBE
			#pragma shader_feature _METALLICGLOSSMAP						
			#pragma vertex vert_solid
			#pragma fragment frag_solid
			#include "Assets/CGInclude/FurPass.cginc"
			ENDCG
		}
		Pass{
			Blend SrcAlpha OneMinusSrcAlpha
			Zwrite Off
			Cull [_CullMode]
			Name "FORWARD"
			Tags { "LightMode" = "ForwardBase" }
			CGPROGRAM
			#pragma target 3.0
			#pragma multi_compile_fwdbase nolightmap nodirlightmap nodynlightmap novertexlight noshadowmask  
			#pragma skip_variants LIGHTMAP_SHADOW_MIXING LIGHTPROBE_SH SPOT DIRECTIONAL_COOKIE POINT_COOKIE SHADOWS_CUBE
			#pragma shader_feature _NORMALMAP
			#pragma shader_feature _METALLICGLOSSMAP						
			#pragma shader_feature _REFLECTION_CUBEMAP
			#pragma multi_compile _ _FASTEST_QUALITY _FLOWMAP
			#pragma vertex vert_fur
			#pragma fragment frag_fur
			#define _FUR_PASS_0
			#include "Assets/CGInclude/FurPass.cginc"
			ENDCG
		}
		Pass{
			Blend SrcAlpha OneMinusSrcAlpha
			Zwrite Off
			Cull [_CullMode]
			Name "FORWARD"
			Tags { "LightMode" = "ForwardBase" }
			CGPROGRAM
			#pragma target 3.0
			#pragma multi_compile_fwdbase nolightmap nodirlightmap nodynlightmap novertexlight noshadowmask  
			#pragma skip_variants LIGHTMAP_SHADOW_MIXING LIGHTPROBE_SH SPOT DIRECTIONAL_COOKIE POINT_COOKIE SHADOWS_CUBE
			#pragma shader_feature _NORMALMAP			
			#pragma shader_feature _METALLICGLOSSMAP							
			#pragma shader_feature _REFLECTION_CUBEMAP
			#pragma multi_compile _ _FASTEST_QUALITY _FLOWMAP
			#pragma vertex vert_fur
			#pragma fragment frag_fur
			#define _FUR_PASS_1
			#include "Assets/CGInclude/FurPass.cginc"
			ENDCG
		}
		Pass{
			Blend SrcAlpha OneMinusSrcAlpha
			Zwrite Off
			Cull [_CullMode]
			Name "FORWARD"
			Tags { "LightMode" = "ForwardBase" }
			CGPROGRAM
			#pragma target 3.0
			#pragma multi_compile_fwdbase nolightmap nodirlightmap nodynlightmap novertexlight noshadowmask  
			#pragma skip_variants LIGHTMAP_SHADOW_MIXING LIGHTPROBE_SH SPOT DIRECTIONAL_COOKIE POINT_COOKIE SHADOWS_CUBE
			#pragma shader_feature _NORMALMAP			
			#pragma shader_feature _METALLICGLOSSMAP						
			#pragma shader_feature _REFLECTION_CUBEMAP
			#pragma multi_compile _ _FASTEST_QUALITY _FLOWMAP
			#pragma vertex vert_fur
			#pragma fragment frag_fur
			#define _FUR_PASS_2
			#include "Assets/CGInclude/FurPass.cginc"
			ENDCG
		}
		Pass{
			Blend SrcAlpha OneMinusSrcAlpha
			Zwrite Off
			Cull [_CullMode]
			Name "FORWARD"
			Tags { "LightMode" = "ForwardBase" }
			CGPROGRAM
			#pragma target 3.0
			#pragma multi_compile_fwdbase nolightmap nodirlightmap nodynlightmap novertexlight noshadowmask  
			#pragma skip_variants LIGHTMAP_SHADOW_MIXING LIGHTPROBE_SH SPOT DIRECTIONAL_COOKIE POINT_COOKIE SHADOWS_CUBE
			#pragma shader_feature _NORMALMAP			
			#pragma shader_feature _METALLICGLOSSMAP						
			#pragma shader_feature _REFLECTION_CUBEMAP
			#pragma multi_compile _ _FASTEST_QUALITY _FLOWMAP
			#pragma vertex vert_fur
			#pragma fragment frag_fur
			#define _FUR_PASS_3
			#include "Assets/CGInclude/FurPass.cginc"
			ENDCG
		}
		Pass{
			Blend SrcAlpha OneMinusSrcAlpha
			Zwrite Off
			Cull [_CullMode]
			Name "FORWARD"
			Tags { "LightMode" = "ForwardBase" }
			CGPROGRAM
			#pragma target 3.0
			#pragma multi_compile_fwdbase nolightmap nodirlightmap nodynlightmap novertexlight noshadowmask  
			#pragma skip_variants LIGHTMAP_SHADOW_MIXING LIGHTPROBE_SH SPOT DIRECTIONAL_COOKIE POINT_COOKIE SHADOWS_CUBE
			#pragma shader_feature _NORMALMAP			
			#pragma shader_feature _METALLICGLOSSMAP						
			#pragma shader_feature _REFLECTION_CUBEMAP
			#pragma multi_compile _ _FASTEST_QUALITY _FLOWMAP
			#pragma vertex vert_fur
			#pragma fragment frag_fur
			#define _FUR_PASS_4
			#include "Assets/CGInclude/FurPass.cginc"
			ENDCG
		}
		Pass{
			Blend SrcAlpha OneMinusSrcAlpha
			Zwrite Off
			Cull [_CullMode]
			Name "FORWARD"
			Tags { "LightMode" = "ForwardBase" }
			CGPROGRAM
			#pragma target 3.0
			#pragma multi_compile_fwdbase nolightmap nodirlightmap nodynlightmap novertexlight noshadowmask  
			#pragma skip_variants LIGHTMAP_SHADOW_MIXING LIGHTPROBE_SH SPOT DIRECTIONAL_COOKIE POINT_COOKIE SHADOWS_CUBE
			#pragma shader_feature _NORMALMAP			
			#pragma shader_feature _METALLICGLOSSMAP						
			#pragma shader_feature _REFLECTION_CUBEMAP
			#pragma multi_compile _ _FASTEST_QUALITY _FLOWMAP
			#pragma vertex vert_fur
			#pragma fragment frag_fur
			#define _FUR_PASS_5
			#include "Assets/CGInclude/FurPass.cginc"
			ENDCG
		}
		Pass{
			Blend SrcAlpha OneMinusSrcAlpha
			Zwrite Off
			Cull [_CullMode]
			Name "FORWARD"
			Tags { "LightMode" = "ForwardBase" }
			CGPROGRAM
			#pragma target 3.0
			#pragma multi_compile_fwdbase nolightmap nodirlightmap nodynlightmap novertexlight noshadowmask  
			#pragma skip_variants LIGHTMAP_SHADOW_MIXING LIGHTPROBE_SH SPOT DIRECTIONAL_COOKIE POINT_COOKIE SHADOWS_CUBE
			#pragma shader_feature _NORMALMAP			
			#pragma shader_feature _METALLICGLOSSMAP						
			#pragma shader_feature _REFLECTION_CUBEMAP
			#pragma multi_compile _ _FASTEST_QUALITY _FLOWMAP
			#pragma vertex vert_fur
			#pragma fragment frag_fur
			#define _FUR_PASS_6
			#include "Assets/CGInclude/FurPass.cginc"
			ENDCG
		}
		Pass{
			Blend SrcAlpha OneMinusSrcAlpha
			Zwrite Off
			Cull [_CullMode]
			Name "FORWARD"
			Tags { "LightMode" = "ForwardBase" }
			CGPROGRAM
			#pragma target 3.0
			#pragma multi_compile_fwdbase nolightmap nodirlightmap nodynlightmap novertexlight noshadowmask  
			#pragma skip_variants LIGHTMAP_SHADOW_MIXING LIGHTPROBE_SH SPOT DIRECTIONAL_COOKIE POINT_COOKIE SHADOWS_CUBE
			#pragma shader_feature _NORMALMAP			
			#pragma shader_feature _METALLICGLOSSMAP						
			#pragma shader_feature _REFLECTION_CUBEMAP
			#pragma multi_compile _ _FASTEST_QUALITY _FLOWMAP
			#pragma vertex vert_fur
			#pragma fragment frag_fur
			#define _FUR_PASS_7
			#include "Assets/CGInclude/FurPass.cginc"
			ENDCG
		}
		Pass{
			Blend SrcAlpha OneMinusSrcAlpha
			Zwrite Off
			Cull [_CullMode]
			Name "FORWARD"
			Tags { "LightMode" = "ForwardBase" }
			CGPROGRAM
			#pragma target 3.0
			#pragma multi_compile_fwdbase nolightmap nodirlightmap nodynlightmap novertexlight noshadowmask  
			#pragma skip_variants LIGHTMAP_SHADOW_MIXING LIGHTPROBE_SH SPOT DIRECTIONAL_COOKIE POINT_COOKIE SHADOWS_CUBE
			#pragma shader_feature _NORMALMAP			
			#pragma shader_feature _METALLICGLOSSMAP						
			#pragma shader_feature _REFLECTION_CUBEMAP
			#pragma multi_compile _ _FASTEST_QUALITY _FLOWMAP
			#pragma vertex vert_fur
			#pragma fragment frag_fur
			#define _FUR_PASS_8
			#include "Assets/CGInclude/FurPass.cginc"
			ENDCG
		}
		Pass{
			Name "FORWARD"
			Tags { "LightMode" = "ForwardBase" }
			Blend SrcAlpha OneMinusSrcAlpha
			Zwrite Off
			Cull [_CullMode]
			CGPROGRAM
			#pragma target 3.0
			#pragma multi_compile_fwdbase nolightmap nodirlightmap nodynlightmap novertexlight noshadowmask  
			#pragma skip_variants LIGHTMAP_SHADOW_MIXING LIGHTPROBE_SH SPOT DIRECTIONAL_COOKIE POINT_COOKIE SHADOWS_CUBE
			#pragma shader_feature _NORMALMAP			
			#pragma shader_feature _METALLICGLOSSMAP						
			#pragma shader_feature _REFLECTION_CUBEMAP
			#pragma multi_compile _ _FASTEST_QUALITY _FLOWMAP
			#pragma vertex vert_fur
			#pragma fragment frag_fur
			#define _FUR_PASS_9
			#include "Assets/CGInclude/FurPass.cginc"
			ENDCG
		}
		Pass
		{
			Name "ShadowCaster"
			Tags { "LightMode" = "ShadowCaster" }
			ZTest LEqual
			Cull Back
			CGPROGRAM
			#pragma multi_compile_shadowcaster
			#pragma skip_variants SHADOWS_CUBE
			#pragma vertex vert_shadow
			#pragma fragment frag_shadow
			#include "Assets/CGInclude/FurPass.cginc"			
			ENDCG
		}
	}
	CustomEditor "LGameSDK.AnimTool.LGameStarActorMultiPassFurShaderGUI"
}
