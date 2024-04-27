Shader "LGame/StarActor/Pet/Default"
{
    Properties
    {
        _Color("Color", Color) = (1,1,1,1)
        _MainTex("Albedo", 2D) = "white" {}
        _Emission ("Emission Intensity", float) = 10
        _Metallic("Metallic", Range(0.0, 1.0)) = 0.0
        _MetallicGlossMap("Metallic", 2D) = "white" {}
        _Glossiness("Smoothness", Range(0.0, 1.0)) = 0.5
        _GlossMapScale("Smoothness Scale", Range(0.0, 1.0)) = 1.0
        _TintMask ("Tint Mask", 2D) = "black"{}
        _TintR ("Red Channel Tint", Color) = (1,0,0,1)
        _TintG ("Green Channel Tint", Color) = (0,1,0,1)
        _TintB ("Blue Channel Tint", Color) = (0,0,1,1)
        _GradientTex ("Tint Gradient", 2D) = "white"{}
        _UseTint ("Use Tint", Vector) = (1,1,1,1)
        [Toggle] _GlobalGradient ("Use Global Gradient", float) = 0
        _GradientOffset ("Gradient Offset", Vector) = (1,0,0,0)
        _BumpScale("Scale", Float) = 1.0
        _BumpMap("Normal Map", 2D) = "bump" {}
        _AmbientCol("Ambient Color" , Color) = (0.3,0.3,0.3,0.3)
        [HDR]_ReflectionColor("Reflection Color", Color) = (0.5 , 0.5 , 0.5 , 0)
        _ReflectionMatCap("Reflection MatCap", 2D) = "" {}
        _ShadowStrength("Self Shadow Strength" , Range(0,1)) = 1
		[HDR]_RakingLightColor("Raking Light Color" , Color) = (0,0,0,0)
		[HDR]_RakingLightColor2("Dual Raking Light Color" , Color) = (0,0,0,0)
		_DirLight("Dir Light" , Vector) = (-1,0,0,0)
		_BrightnessInOcclusion("Brightness In Occlusion" , Range(0,1)) = 0.5
		_BrightnessInShadow("Brightness In Shadow" , Range(0,1)) = 0.5
		_RakingLightSoftness("Raking Light Softness",Range(0.0,16.0)) = 4.0
    	
    	[Enum(UnityEngine.Rendering.BlendMode)] _BlendSrc ("Blend Src", Int) = 1
    	[Enum(UnityEngine.Rendering.BlendMode)] _BlendDest ("Blend Dest", Int) = 0
    	[HideInInspector] _BlendMode ("BlendMode", Int) = 1
    }
    SubShader
    {
        Tags { "RenderType"="AlphaTest" "Queue"="AlphaTest" }
        LOD 100

        Pass
        {
            Name "FORWARD"
            Tags { "LightMode" = "ForwardBase" }
        	Blend [_BlendSrc] [_BlendDest]
            CGPROGRAM
            #pragma target 3.0
            #pragma multi_compile_fwdbase nolightmap nodirlightmap nodynlightmap novertexlight noshadowmask  
            #pragma skip_variants LIGHTMAP_SHADOW_MIXING LIGHTPROBE_SH SPOT DIRECTIONAL_COOKIE POINT_COOKIE SHADOWS_CUBE
            #pragma multi_compile _ _HARD_SHADOW _SOFT_SHADOW
            #pragma shader_feature _METALLICGLOSSMAP
            #pragma shader_feature _EMISSION
            #pragma shader_feature _GLOBALGRADIENT_ON
            #define _PET
            #define _DUAL_RIMLIGHT
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
			Offset -1, -1
			ZTest LEqual
			CGPROGRAM
			#pragma target 3.0
			#pragma multi_compile_fwdadd  
			//#pragma multi_compile __ _USE_DIRECT_GPU_SKINNING
			#pragma skip_variants LIGHTMAP_SHADOW_MIXING SHADOWS_SCREEN LIGHTPROBE_SH SPOT DIRECTIONAL_COOKIE POINT_COOKIE SHADOWS_CUBE
			#pragma shader_feature _METALLICGLOSSMAP
			#pragma shader_feature _OCCLUSION_UV1
			#pragma shader_feature _SUBSURFACE_SCATTERING
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
			#pragma vertex Vert_Shadow
			#pragma fragment Frag_Shadow
			#include "Assets/CGInclude/LGameStarActorShadowCaster.cginc"				
			ENDCG
		}
    }
	CustomEditor "CustomShaderGUI.LGameStarActorPetShaderGUI"
}
