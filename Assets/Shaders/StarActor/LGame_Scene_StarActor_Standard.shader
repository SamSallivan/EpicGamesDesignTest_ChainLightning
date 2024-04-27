Shader "LGame/Scene/StarActor/Standard"
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
		[HDR]_EmissionColor("Color", Color) = (0,0,0)
		_EmissionMap("Emission", 2D) = "white" {}
		_AmbientCol("Ambient Color" , Color) = (0.3,0.3,0.3,0.3)
		[Enum(MatCap,0,CubeMap,1)] _ReflectionType("Reflection Type", Float) = 0
		[HDR]_ReflectionColor("Reflection Color", Color) = (0.5 , 0.5 , 0.5 , 0)
		_ReflectionCubeMap("Reflection CubeMap", Cube) = "" {}
		_ReflectionMatCap("Reflection MatCap", 2D) = "" {}
		_ShadowStrength("Self Shadow Strength" , Range(0,1)) = 1
    }   
    SubShader
    {
        Tags { "Queue" = "Geometry" "RenderType" = "Opaque" }
        Pass
        {
			Stencil {
				Ref 0
				Comp always
				Pass replace
			}
            Name "FORWARD"
            Tags { "LightMode" = "ForwardBase" }          
            CGPROGRAM
			#pragma target 3.0
			#pragma multi_compile_fwdbase nolightmap nodirlightmap nodynlightmap novertexlight noshadowmask  
			#pragma skip_variants LIGHTMAP_SHADOW_MIXING
			#pragma skip_variants LIGHTPROBE_SH
			#pragma skip_variants SPOT
			#pragma skip_variants DIRECTIONAL_COOKIE
			#pragma skip_variants POINT_COOKIE
			#pragma multi_compile _ _FASTEST_QUALITY
			#pragma shader_feature _EMISSION
			#pragma shader_feature _METALLICGLOSSMAP						
			#pragma shader_feature _REFLECTION_CUBEMAP
			#pragma vertex vert_base
			#pragma fragment frag_base
			#define _SCENE
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
			#pragma skip_variants LIGHTMAP_SHADOW_MIXING
			#pragma skip_variants SHADOWS_SCREEN
			#pragma skip_variants LIGHTPROBE_SH
			#pragma skip_variants SPOT
			#pragma skip_variants DIRECTIONAL_COOKIE
			#pragma skip_variants POINT_COOKIE
			#pragma shader_feature _METALLICGLOSSMAP
			#pragma vertex vert_add
			#pragma fragment frag_add
			#define _SCENE
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
			#include "Assets/CGInclude/LGameStarActorShadowCaster.cginc"				
			ENDCG
		}
    }
	CustomEditor "LGameSDK.AnimTool.LGameSceneStarActorStandardShaderGUI"
}
