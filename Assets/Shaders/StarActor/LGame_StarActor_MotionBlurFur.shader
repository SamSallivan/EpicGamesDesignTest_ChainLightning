Shader "LGame/StarActor/MotionBlurFur"
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
		_FlowMap("Flow Map", 2D) = "black" {}
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
		Stencil {
			Ref 16
			Comp always
			Pass replace
		}
		Pass
		{
			Name "FlowMap"
			Tags
			{
				"LightMode" = "VertexLit"
			}
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"
			#include "AutoLight.cginc"	
			#include "Lighting.cginc"	
			struct appdata
			{
				half4 vertex : POSITION;
				half2 uv : TEXCOORD0;
				half3 normal : NORMAL;
				half4 tangent : TANGENT;
			};
			struct v2f_fur
			{
				half4 vertex	: SV_POSITION;
				half4 uv		: TEXCOORD0;
				half4 tangentToWorld[3]	: TEXCOORD1;
			};
			sampler2D _FlowMap;
			sampler2D _BumpMap;
			sampler2D _MainTex;
			float4 _MainTex_ST;
			float4 _FlowMap_ST;
			half _BumpScale;
			half3 Orthonormalize(half3 tangent, half3 normal)
			{
				return normalize(tangent - dot(tangent, normal)*normal);
			}
			v2f_fur vert(appdata v)
			{
				v2f_fur o;
				o.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
				o.uv.zw = TRANSFORM_TEX(v.uv, _FlowMap);
				half3 wPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				o.vertex = UnityObjectToClipPos(v.vertex);
				half3 normalWorld = UnityObjectToWorldNormal(v.normal);
				half3 tangentWorld = UnityObjectToWorldDir(v.tangent.xyz);
				half3 binormalWorld = cross(normalWorld, tangentWorld) * v.tangent.w * unity_WorldTransformParams.w;
				o.tangentToWorld[0].xyz = tangentWorld;
				o.tangentToWorld[1].xyz = binormalWorld;
				o.tangentToWorld[2].xyz = normalWorld;
				return o;
			}
			half4 frag(v2f_fur i) : SV_Target
			{
				half3 normal = UnpackScaleNormal(tex2D(_BumpMap, i.uv.xy), _BumpScale);
				normal = normalize(i.tangentToWorld[0].xyz*normal.r + i.tangentToWorld[1].xyz*normal.g + i.tangentToWorld[2].xyz*normal.b);
				half4 velocity = tex2D(_FlowMap, i.uv.zw) * 2.0 - 1.0;
				velocity.xyz = i.tangentToWorld[0].xyz * velocity.r + i.tangentToWorld[1].xyz * velocity.g + i.tangentToWorld[2].xyz * velocity.b;
				velocity.xyz = Orthonormalize(velocity.xyz, normal);
				velocity.xyz = mul(transpose((float3x3)unity_MatrixInvV), velocity.xyz);
				velocity = velocity * 0.5 + 0.5;
				velocity.xy *= velocity.a;
				return half4(velocity.xy, velocity.a,1.0);
			}
			ENDCG
		}
		Pass
		{
			Name "FORWARD"
			Tags{ "LightMode" = "ForwardBase" }
			Blend SrcAlpha OneMinusSrcAlpha
			ZWrite On
			Cull Back
			CGPROGRAM
			#pragma multi_compile_fwdbase nolightmap nodirlightmap nodynlightmap novertexlight noshadowmask  
			#pragma skip_variants LIGHTMAP_SHADOW_MIXING LIGHTPROBE_SH SPOT DIRECTIONAL_COOKIE POINT_COOKIE SHADOWS_CUBE
			#pragma vertex vert_base
			#pragma fragment frag_base
			#pragma target 3.0
			#pragma multi_compile _ _FASTEST_QUALITY
			#pragma multi_compile _ _HARD_SHADOW _SOFT_SHADOW
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
	CustomEditor "LGameStarActorMotionBlurFurShaderGUI"
}