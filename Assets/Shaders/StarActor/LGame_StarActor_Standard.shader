Shader "LGame/StarActor/Standard"
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
		_OcclusionStrength("Strength", Range(0.0, 1.0)) = 1.0
		_OcclusionMap("Occlusion", 2D) = "white" {}
		[Enum(uv0,0,uv1,1)] _OcclusionUVChannel("Occlusion texture UV", Float) = 0
		_SssLut("sssLut", 2D) = "white" {}
		_SubSurfaceColor("SubSurface Color" , Color) = (0.3,0,0,1)
		_SubSurface("SubSurface" ,Range(0,1)) = 1
		_AmbientCol("Ambient Color" , Color) = (0.3,0.3,0.3,0.3)
		[Enum(MatCap,0,CubeMap,1)] _ReflectionType("Reflection Type", Float) = 0
		[HDR]_ReflectionColor("Reflection Color", Color) = (0.5 , 0.5 , 0.5 , 0)
		_ReflectionCubeMap("Reflection CubeMap", Cube) = "" {}
		_ReflectionMatCap("Reflection MatCap", 2D) = "" {}
		_ShadowStrength("Self Shadow Strength" , Range(0,1)) = 1
		[HDR]_RakingLightColor("Raking Light Color" , Color) = (0,0,0,0)
		[HDR]_RakingLightColor2("Dual Raking Light Color" , Color) = (0,0,0,0)
		_DirLight("Dir Light" , Vector) = (-1,0,0,0)
		_BrightnessInOcclusion("Brightness In Occlusion" , Range(0,1)) = 0.5
		_BrightnessInShadow("Brightness In Shadow" , Range(0,1)) = 0.5
		_RakingLightSoftness("Raking Light Softness",Range(0.0,16.0)) = 4.0
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
	SubShader
	{
		Tags { "Queue" = "Transparent" "LightMode" = "ForwardBase" "IgnoreProjector" = "True" "RenderType" = "Transparent"}
		LOD 5
		Blend One One
		ZWrite[_ZWriteMode]
		ZTest[_ZTestMode]
		Cull[_CullMode]
		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment fragtest
			//#pragma multi_compile_instancing
			#include "Assets/CGInclude/LGameEffect.cginc" 
			half4 fragtest(v2f i) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID(i);
				fixed4 texColor = tex2D(_MainTex, i.uvMain.xy, float2(0, 0), float2(0, 0));
				return half4(0.15,0.06,0.03, texColor.a < 0.001);
			}
			ENDCG
		}
	}
	CustomEditor "LGameSDK.AnimTool.LGameStandardBetaShaderGUI"
}
