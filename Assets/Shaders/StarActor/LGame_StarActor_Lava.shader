Shader "LGame/StarActor/Lava"
{
	Properties
	{
		_Color("Color", Color) = (1,1,1,1)
		_MainTex("Albedo", 2D) = "white" {}
		_BumpScale("Scale", Range(0.0,1.0)) = 1.0
		_BumpMap("Normal Map", 2D) = "bump" {}
		[HDR]_EmissionColor("Emission Color", Color) = (0,0,0)
		_EmissionMap("Emission Map", 2D) = "white" {}
		_EmissionPower("Emission Power",Range(1.0,32.0)) = 1.0
		_EmissionRange("Emission Range",Range(0.0,1.0))=1.0
		_FresnelPower("Fresnel Power",Range(1.0,32.0)) = 16.0
		[HDR]_FresnelColor("Fresnel Color", Color) = (1,1,1,1)
		[HDR]_HeatColor("Heat Color" ,Color) = (0,0,0,0)
		_HeatMap("Heat Map", 2D) = "white" {}
		_DirtColor("Dirt Color" ,Color) = (0,0,0,0)
		_DirtMap("Dirt Map", 2D) = "black" {}
		_BreatheSpeed("Breathe Speed",Range(0.0,8.0))=1.0
		_Parallax("Parallax",Range(0.0,1.0)) = 0.25
		_Luminance("Luminance",Range(0.0,1.0)) = 0.25
	}
	CGINCLUDE
	#include "UnityCG.cginc"
	#include "AutoLight.cginc"	
	#include "Lighting.cginc"	
	fixed4 _Color;
	fixed4 _EmissionColor;
	fixed4 _FresnelColor;
	fixed4 _DirtColor;
	fixed4 _HeatColor;
	half _BumpScale;
	half _FresnelPower;
	half _EmissionPower;
	half _EmissionRange;
	float _BreatheSpeed;
	half _Parallax;
	half _Luminance;
	sampler2D _HeatMap;
	sampler2D _MainTex;
	sampler2D _BumpMap;
	sampler2D _DirtMap;	
	sampler2D _EmissionMap;
	float4 _EmissionMap_ST;
	float4 _DirtMap_ST;
	float4 _HeatMap_ST;
	float4 _MainTex_ST;
	struct appdata
	{
		float4 vertex : POSITION;
		float2 uv : TEXCOORD0;
		float3 normal:NORMAL;
		float4 tangent:TANGENT;
	};
	struct v2f
	{
		half4 pos				: SV_POSITION;
		half4 uv				: TEXCOORD0;
		half3 viewDir           : TEXCOORD1;
		half3 tangentViewDir	: TEXCOORD2;
		half4 tangentToWorld[3]	: TEXCOORD3;
	};
	v2f vert(appdata v)
	{
		v2f o;
		o.pos = UnityObjectToClipPos(v.vertex);
		o.uv.zw = v.uv.xy;
		o.uv.xy = TRANSFORM_TEX(v.uv.xy, _MainTex);
		float3 posWorld = mul(unity_ObjectToWorld, v.vertex).xyz;
		o.viewDir = UnityWorldSpaceViewDir(posWorld);
		float3 normalWorld = UnityObjectToWorldNormal(v.normal);
		float3 tangentWorld = UnityObjectToWorldDir(v.tangent.xyz);
		float3 binormalWorld = cross(normalWorld, tangentWorld) * v.tangent.w * unity_WorldTransformParams.w;
		o.tangentToWorld[0].xyz = tangentWorld;
		o.tangentToWorld[1].xyz = binormalWorld;
		o.tangentToWorld[2].xyz = normalWorld;
		o.tangentToWorld[0].w = posWorld.x;
		o.tangentToWorld[1].w = posWorld.y;
		o.tangentToWorld[2].w = posWorld.z;
		half3x3 objectToTangent = half3x3(
			v.tangent.xyz,
			cross(v.normal, v.tangent.xyz) * v.tangent.w,
			v.normal
			);
		o.tangentViewDir = mul(objectToTangent, ObjSpaceViewDir(v.vertex)).xyz;
		return o;
	}
	fixed4 frag(v2f i) : SV_Target
	{
		half3 wPos = half3(i.tangentToWorld[0].w ,i.tangentToWorld[1].w ,i.tangentToWorld[2].w);
		half3 V = normalize(i.viewDir);
		half3 TV = normalize(i.tangentViewDir);
		half3 N = UnpackScaleNormal(tex2D(_BumpMap, i.uv), _BumpScale);
		N = normalize(i.tangentToWorld[0].xyz * N.r + i.tangentToWorld[1].xyz * N.g + i.tangentToWorld[2].xyz * N.b);
		half NoV = saturate(dot(N, V));
		half3 Albedo = tex2D(_MainTex, i.uv.xy) * _Color;
		half3 Normal = UnpackScaleNormal(tex2D(_BumpMap, i.uv.xy), _BumpScale);
		Normal = normalize(i.tangentToWorld[0].xyz * Normal.r + i.tangentToWorld[1].xyz * Normal.g + i.tangentToWorld[2].xyz * Normal.b);
		half3 Diffuse = Albedo * saturate((NoV + 0.5) / 2.25) + saturate(Albedo - NoV);
		float Heat = tex2D(_HeatMap, TRANSFORM_TEX(i.uv.zw, _HeatMap))*(abs(sin(_Time.y * _BreatheSpeed))* (1.0-_Luminance) + _Luminance);
		half Dirt = 1.0 - tex2D(_DirtMap, TRANSFORM_TEX(i.uv.zw, _DirtMap)) * _DirtColor.a;
		half3 Fresnel= pow(1.0 - NoV, _FresnelPower) *_FresnelColor;
		half3 T = Heat * _HeatColor.rgb;
		half3 Emission= tex2D(_EmissionMap, TRANSFORM_TEX(i.uv.zw,_EmissionMap)+ ParallaxOffset(0.025, Heat * _Parallax, TV)) * _EmissionColor;
		Emission *= lerp(pow(NoV, _EmissionPower),1.0, _EmissionRange);
		fixed3 Color = Diffuse * Dirt + Fresnel +T * Dirt + Emission * Dirt + (1.0-Dirt)* _DirtColor;
		return fixed4(Color,1.0);
	}
	ENDCG
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
			#pragma multi_compile _ _FASTEST_QUALITY
			#pragma shader_feature _EMISSION				
			#pragma shader_feature _REFLECTION_CUBEMAP
			#pragma vertex vert
			#pragma fragment frag
			ENDCG
		}
		Pass
		{
			Name "ShadowCaster"
			Tags{ "LightMode" = "ShadowCaster" }
			ZWrite On
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
	CustomEditor "LGameSDK.AnimTool.LGameStarActorLavaShaderGUI"
}
