Shader "LGame/StarActor/Smooth Gem"
{
	Properties
	{
		[Header(Base)]
		[HDR]_Color("Color", Color) = (1.0 , 1.0 , 1.0 , 0)
		[NoScaleOffset]_BaseColorMatCap("Base Color MatCap", 2D) = "white" {}
		_BumpMap("Normal", 2D) = "bump" {}
		_BumpScale("Bump Scale",Range(0.0,1.0)) =1.0
		[Header(Reflection)]
		[HDR]_ReflectionColor("Reflection Color", Color) = (1.0 , 1.0 , 1.0 , 0)
		[NoScaleOffset]_ReflectionMatCap("Reflection MatCap", 2D) = "" {}
		_FresnelPower("Fresnel Power",Range(0.0,1.0)) = 0.5
		_HighlightRange("Highlight Range",Range(0.0,1.0)) = 1.0
		[Header(Glint)]
		_DiamondMap("Diamand Map",2D) = "black"{}
		_GlintPower("Glint Power",Float) = 0.1
		_GlintSpeed("Glint Speed",Float) = 1.0
		_GlintStrength("Glint Strength",Range(0.0,16.0)) = 1.0
		[Header(Floccule)]
		[HDR]_FlocculeColor("Floccule Color",  Color) = (1.0 , 1.0 , 1.0 , 0)
		_FlocculeMap("Floccule Map", 2D) = "" {}
		_InnerPower("Inner Power",Range(0.0,1.0)) = 0.5
		_Parallax("Parallax",Range(0.0,1.0)) = 0.5
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
			Blend SrcAlpha OneMinusSrcAlpha
		Name "FORWARD"
		Tags { "LightMode" = "ForwardBase" }
		CGPROGRAM
		#pragma target 3.0
		#pragma multi_compile_fwdbase nolightmap nodirlightmap nodynlightmap novertexlight noshadowmask  
		#pragma skip_variants LIGHTMAP_SHADOW_MIXING LIGHTPROBE_SH SPOT DIRECTIONAL_COOKIE POINT_COOKIE SHADOWS_CUBE
		#pragma vertex vert
		#pragma fragment frag
		#pragma multi_compile _ _HARD_SHADOW _SOFT_SHADOW
		#pragma multi_compile _ _FASTEST_QUALITY
		//#pragma multi_compile __ _USE_DIRECT_GPU_SKINNING
		#include "UnityCG.cginc"
		#include "AutoLight.cginc"	
		#include "Lighting.cginc"	
		#include "UnityStandardUtils.cginc"	
		#include "Assets/CGInclude/LGameStarActorShadow.cginc"	
		#include "Assets/CGInclude/LGameCharacterDgs.cginc"
		sampler2D _HeartShapedMap;
		sampler2D _WireframeMap;
		sampler2D _BumpMap;
		sampler2D _NoiseMap;
		sampler2D _BaseColorMatCap;
		sampler2D _ReflectionMatCap;
		sampler2D _FlocculeMap;
		sampler2D _DiamondMap;
		half _WireframeWidth;
		float _FlowSpeed;
		half _FlowScale;
		half _BumpScale;
		half _Parallax;
		half _InnerPower; 
		half _FresnelPower;
		half _GlintPower;
		float _GlintSpeed;
		half _GlintStrength;
		half _HighlightRange;
		half _HighlightSpeed;
		fixed4 _FlocculeColor;
		fixed4 _WireframeColor;
		fixed4 _ReflectionColor;
		fixed4 _HeartShapedColor;
		fixed4	_Color;
		float4 _HeartShapedMap_ST;
		float4 _DiamondMap_ST;
			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv0 : TEXCOORD0;
				float2 uv1 : TEXCOORD1;
				float3 normal:NORMAL;
				float4 tangent:TANGENT;
#ifdef _USE_DIRECT_GPU_SKINNING
				float4 skinIndices	: TEXCOORD2;
				float4 skinWeights	: TEXCOORD3;
#endif
			};
			struct v2f
			{
				float4 uv : TEXCOORD0;
				float4 pos : SV_POSITION;
				float3 viewDir:TEXCOORD1;
				float3 lightDir:TEXCOORD2;
				float3 tangentViewDir:TEXCOORD3;
				float4 tangentToWorld[3] : TEXCOORD4;
				LGAME_STARACTOR_SHADOW_COORDS(7)
			};
			v2f vert(appdata v)
			{
				v2f o;
#if _USE_DIRECT_GPU_SKINNING

				v.vertex = CalculateGPUSkin_L(v.skinIndices, v.skinWeights, v.vertex);
				v.uv0.xy = DecompressUV(v.uv0.xy, _uvBoundData);
#endif
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv.xy = v.uv0;
				o.uv.zw = TRANSFORM_TEX(v.uv0, _HeartShapedMap);
				float3 posWorld = mul(unity_ObjectToWorld, v.vertex).xyz;
				o.viewDir = UnityWorldSpaceViewDir(posWorld);
				o.lightDir = UnityWorldSpaceLightDir(posWorld);
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
				LGAME_STARACTOR_TRNASFER_SHADOW(o);
				return o;
			}
			half3 F_Schlick(const half3 f0, half VoH) {
				half f = pow(1.0 - VoH, 5.0);
				return f + f0 * (1.0 - f);
			}
			half DiamondGlinting(half3 V, half Diamond ,half VoR)
			{
				half Pattern = step(0.01,Diamond.r * 2.0);
				float Glint = pow(Pattern * frac(Diamond.r + abs(V.x)), _GlintPower * (frac(Diamond.r + _Time.y * _GlintSpeed)+ 0.5 + 0.5));
				Glint *= _GlintStrength;
				return Glint;
			}
			fixed4 frag(v2f i) : SV_Target
			{
				half3 wPos = half3(i.tangentToWorld[0].w ,i.tangentToWorld[1].w ,i.tangentToWorld[2].w);
				half3 V = normalize(i.viewDir);
				half3 L = normalize(i.lightDir);
				half3 TV = normalize(i.tangentViewDir);
				half3 H = normalize(L + V);
				half3 N = UnpackScaleNormal(tex2D(_BumpMap, i.uv), _BumpScale);
				N = normalize(i.tangentToWorld[0].xyz*N.r + i.tangentToWorld[1].xyz*N.g + i.tangentToWorld[2].xyz*N.b);
				half3 R = normalize(reflect(-V, N));
				half NoL = dot(N, L);
				half NoV = saturate(dot(N, V));
				half NoH = saturate(dot(N, H));
				half VoH = saturate(dot(V, H));
				half VoR = saturate(dot(V, R));
				LGAME_STARACTOR_LIGHT_ATTENUATION(atten, i, wPos, NoL);
				NoL = saturate(NoL);
				//Base Color
				half2 BaseColorUV;
				BaseColorUV.x = mul(unity_CameraToWorld[0], half4x1(N.xyz, 0.0)) * 0.48 + 0.5;
				BaseColorUV.y = mul(unity_CameraToWorld[1], half4x1(N.xyz, 0.0)) * 0.48 + 0.5;
				half3 BaseColor = tex2D(_BaseColorMatCap, BaseColorUV) * _Color;
				//Reflection Color
				half3 vN = mul(UNITY_MATRIX_V, half4(N, 0)).xyz;
				half3 vP = UnityWorldToViewPos(wPos);
				half3 vR = normalize(reflect(vP, vN));
				half m = 2.0 * sqrt(vR.x * vR.x + vR.y * vR.y + (vR.z + 1) * (vR.z + 1));
				half2 ReflectionUV = vR.xy / m + 0.5;
				half3 Reflection= tex2D(_ReflectionMatCap, ReflectionUV) * _ReflectionColor;
				//Glint
				half Diamond = tex2D(_DiamondMap, TRANSFORM_TEX(i.uv.xy, _DiamondMap) + ParallaxOffset(0.0, 1.0-NoV, TV));
				half Glint = DiamondGlinting(V, Diamond , VoR) * NoL * VoR * atten;
				//Wireframe
				half3 Wireframe = tex2D(_WireframeMap, i.uv);
				float3 Flow = smoothstep(abs(sin(_Time.y * _FlowSpeed + i.uv.x * _FlowScale * 16.0)), 1.0, Wireframe);
				Wireframe = pow(Wireframe, 1.0 / _WireframeWidth);
				Wireframe += Flow;
				Wireframe *= _WireframeColor;
				//Fresnel
				half Fresnel = pow(1.0 - NoV, 8.0 * _FresnelPower);
				//Floccule
				half3 Floccule = tex2D(_FlocculeMap, i.uv.xy + ParallaxOffset(0.025, _Parallax, TV));
				half3 Inner= pow(NoH, 8.0 * _InnerPower) * _FlocculeColor * Floccule;
				//Combine
				half3 Other= Wireframe + Inner;
				fixed3 Color =lerp(BaseColor, BaseColor * Reflection, Fresnel);
				Color += Other;
				Color += Glint * Reflection;
				Color += pow(NoH, 1.0 / _HighlightRange);
				half Alpha = saturate(_Color.a + Fresnel + Glint);
				return fixed4(Color, Alpha);
			}
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
}
