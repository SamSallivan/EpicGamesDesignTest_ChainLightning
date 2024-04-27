Shader "LGame/Scene/StarActor/Standard Advanced (Outline)"
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
		_AmbientCol("Ambient Color" , Color) = (0.3,0.3,0.3,0.3)
		[Enum(MatCap,0,CubeMap,1,Planar,2,Blend,3)] _ReflectionType("Reflection Type", Float) = 0
		[HDR]_ReflectionColor("Reflection Color", Color) = (0.5 , 0.5 , 0.5 , 0)
		_ReflectionCubeMap("Reflection CubeMap", Cube) = "" {}
		_ReflectionMatCap("Reflection MatCap", 2D) = "" {}
		_Environment("Environment", 2D) = "" {}
		_ShadowStrength("Self Shadow Strength" , Range(0,1)) = 1
		_DecalMap("Decal Map", 2D) = "black" {}
		_DetailAlbedoMap("Detail Albedo Map",2D) = "black"{}
		[HDR]_OutlineColor("Outline Color", Color) = (0.0 , 0.0 , 0.0 , 0.0)
		_OutlineWidth("Outline Width", Range(0.0, 1.0)) = 0.5
		_HollowWidth("Hollow Width", Range(0.0, 1.0)) = 0.5
		_ViewDeformation("Hollow Width", Range(0.0, 1.0)) = 0.0
		_LightMap("LightMap", 2D) = "gray" {}
		_LightMapIntensity("LightMap Intensity",  Range(0,1)) = 1
		[HDR]_EmissionColor("Color", Color) = (0,0,0)
		_EmissionMap("Emission", 2D) = "white" {}
		_OcclusionStrength("Strength", Range(0.0, 1.0)) = 1.0
		_OcclusionMap("Occlusion", 2D) = "white" {}
		[Enum(uv0,0,uv1,1)] _OcclusionUVChannel("Occlusion texture UV", Float) = 0
		_FogColor("Fog Color",Color) = (0.0,0.0,0.0,1.0)
		_FogStart("Fog Start",Float) = 0.0
		_FogEnd("Fog End",Float) = 300.0
    }   
    SubShader
    {
        Tags { "Queue" = "Geometry" "RenderType" = "Opaque" }
		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"
			struct appdata
			{
				float4 vertex	: POSITION;
				half3 normal	: NORMAL;
			};
			struct v2f
			{
				float4	vertex  : SV_POSITION;
				half	NoV : TEXCOORD1;
			};
			fixed4 _OutlineColor;
			half _OutlineWidth;
			half _HollowWidth;
			half _ViewDeformation;
			v2f vert(appdata v)
			{
				v2f o;
				half3 wPos = mul(unity_ObjectToWorld, v.vertex);
				half3 viewDir = normalize(UnityWorldSpaceViewDir(wPos));
				half3 normalWorld = UnityObjectToWorldNormal(v.normal);
				v.vertex.xyz *= 1.0 - viewDir * _ViewDeformation;
				v.vertex.xyz += v.normal * _OutlineWidth;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.NoV = saturate(dot(normalWorld, viewDir));
				return o;
			}
			fixed4 frag(v2f i) : SV_Target
			{
				half hollow = step(i.NoV,_HollowWidth);
				clip(hollow - 0.5);
				return hollow * _OutlineColor;
			}
			ENDCG
		}
		UsePass "LGame/Scene/StarActor/Standard Advanced/FORWARD"
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
		UsePass "LGame/Scene/StarActor/Standard Advanced/META"
    }
	CustomEditor "LGameSDK.AnimTool.LGameSceneStarActorStandardAdvancedShaderGUI"
}
