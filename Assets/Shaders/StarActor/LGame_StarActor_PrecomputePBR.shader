Shader "LGame/StarActor/PrecomputePBR"
{
    Properties
    {
		_Color("Color",Color)=(1,1,1,1)
        _MainTex ("Texture", 2D) = "white" {}
		_Metallic("Metallic", Range(0.0, 1.0)) = 0.0
		_MetallicGlossMap("Metallic", 2D) = "white" {}
		_Glossiness("Smoothness", Range(0.0, 1.0)) = 0.5
		_GlossMapScale("Smoothness Scale", Range(0.0, 1.0)) = 1.0
		_BumpScale("Scale", Float) = 1.0
		_BumpMap("Normal Map", 2D) = "bump" {}
		_OcclusionStrength("Strength", Range(0.0, 1.0)) = 1.0
		_OcclusionMap("Occlusion", 2D) = "white" {}
		[Enum(uv0,0,uv1,1)] _OcclusionUVChannel("Occlusion texture UV", Float) = 0
		_ShadowStrength("Self Shadow Strength" , Range(0,1)) = 1
		_ReflectionMap("Reflection Map", 2D) = "black" {}
		_FresnelMap("Fresnel Map", 2D) = "black" {}
		_SHMap("Spherical Harmonics Map",2D) = "black"{}
		_SkinMap("Skin Map", 2D) = "white" {}
		_Exposure("Exposure",Range(0.0,10.0))=0.970
		_Gamma("Gamma",Range(0.001,20.0)) = 0.8
		_Saturate("Saturate",Range(0.001,20.0)) = 1.4
    }
	CGINCLUDE
	#include "UnityCG.cginc"
	#include "AutoLight.cginc"	
	#include "Lighting.cginc"	
	#include "UnityStandardUtils.cginc"	
	#include "Assets/CGInclude/LGameStarActorShadow.cginc"	
		fixed4 _Color;
		float4 _MainTex_ST;
		sampler2D _MainTex;
		sampler2D _MetallicGlossMap;
		sampler2D _BumpMap;
		sampler2D _OcclusionMap;
		sampler2D _ReflectionMap;
		sampler2D _FresnelMap;
		sampler2D _SHMap;
		sampler2D _SkinMap;
		float _GlossMapScale;
		float _Glossiness;
		float _Metallic;
		float _BumpScale;
		float _OcclusionStrength;
		float _Exposure;
		float _Gamma;
		float _Saturate;
	float3 OcclusionMap(float2 uv)
	{
		float3 occlusion = tex2D(_OcclusionMap, uv).rgb;
		occlusion.r = LerpWhiteTo(occlusion.r, _OcclusionStrength);
		return occlusion;
	}
	float3 Overlay(float3 Blend, float3 Target)
	{
		return step(0.5, Target) * (1 - (1 - 2 * (Target - 0.5)) * (1 - Blend)) + step(Target, 0.5) * ((2 * Target) * Blend);
	}
	float2 MatCapUV(float3 N)
	{
		float2 MatCap;
		MatCap.x = mul(unity_WorldToCamera[0], half4x1(N.xyz, 0.0)) * 0.99 * 0.5f + 0.5f;
		MatCap.y = mul(unity_WorldToCamera[1], half4x1(N.xyz, 0.0)) * 0.99 * 0.5f + 0.5f;
		return MatCap;
	}
	//7x7 Atlas
	float2 MatCapLutTexcoord(float2 MatCap, float Roughness)
	{
		float2 uv = MatCap;
		uv.x = frac((floor(Roughness * 49) + MatCap.x) * 0.142857143f);
		uv.y = frac(((-floor(floor(Roughness * 49) / 7.0) + 6) + MatCap.y) * 0.142857143f);
		return uv;
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
			#pragma multi_compile _ _HARD_SHADOW _SOFT_SHADOW
			#pragma multi_compile _ _FASTEST_QUALITY
			#pragma shader_feature _EMISSION
			#pragma shader_feature _METALLICGLOSSMAP						
			#pragma shader_feature _OCCLUSION_UV1	
			#pragma shader_feature _SUBSURFACE_SCATTERING
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"
			#include "AutoLight.cginc"	
			#include "Lighting.cginc"	
			#include "UnityStandardUtils.cginc"	
			#include "Assets/CGInclude/LGameStarActorShadow.cginc"	
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv0 : TEXCOORD0;
				float2 uv1 : TEXCOORD1;
				float3 normal:NORMAL;
				float4 tangent:TANGENT;
            };

            struct v2f
            {
                float4 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
				float3 viewDir:TEXCOORD1;
				float3 lightDir:TEXCOORD2;
				float4 tangentToWorld[3]	: TEXCOORD3;
				LGAME_STARACTOR_SHADOW_COORDS(6)
            };
            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv.xy = TRANSFORM_TEX(v.uv0, _MainTex);
				o.uv.zw = v.uv1;
				float3 posWorld = mul(unity_ObjectToWorld, v.vertex).xyz;
				o.viewDir=UnityWorldSpaceViewDir(posWorld);
				o.lightDir=UnityWorldSpaceLightDir(posWorld);
				float3 normalWorld = UnityObjectToWorldNormal(v.normal);
				float3 tangentWorld = UnityObjectToWorldDir(v.tangent.xyz);
				float3 binormalWorld = cross(normalWorld, tangentWorld) * v.tangent.w * unity_WorldTransformParams.w;
				o.tangentToWorld[0].xyz = tangentWorld;
				o.tangentToWorld[1].xyz = binormalWorld;
				o.tangentToWorld[2].xyz = normalWorld;
				o.tangentToWorld[0].w = posWorld.x;
				o.tangentToWorld[1].w = posWorld.y;
				o.tangentToWorld[2].w = posWorld.z;
				LGAME_STARACTOR_TRNASFER_SHADOW(o);
                return o;
            }
            fixed4 frag (v2f i) : SV_Target
            {
				float3 V = normalize(i.viewDir);
				float3 L = normalize(i.lightDir);
				float3 H = normalize(L + V);

				float3 wPos = float3(i.tangentToWorld[0].w, i.tangentToWorld[1].w, i.tangentToWorld[2].w);
				float3 normal = UnpackScaleNormal(tex2D(_BumpMap, i.uv), _BumpScale);
				float3 N = normalize(i.tangentToWorld[0].xyz * normal.r + i.tangentToWorld[1].xyz * normal.g + i.tangentToWorld[2].xyz * normal.b);
				float VoH = saturate(dot(V, H));
				float NoL = dot(N, L);
				float2 MatCap = MatCapUV(N);

#ifdef _METALLICGLOSSMAP
				float3 data = tex2D(_MetallicGlossMap, i.uv).rgb;
				data.g *= _GlossMapScale;
				float Metallic = data.r;
				float Smoothness = data.g;
				float SkinMask = data.b;
#else
 				float Metallic = _Metallic;
 				float Smoothness = _Glossiness;
				float SkinMask = 0.0;
#endif

#ifdef _OCCLUSION_UV1
				float3 Occlusion = OcclusionMap(i.uv.zw);
#else
				float3 Occlusion = OcclusionMap(i.uv.xy);
#endif
				float Roughness = clamp(0.001,0.999,1.0 - Smoothness);

				float2 RoughnessTexcoord = MatCapLutTexcoord(MatCap, Roughness);
				float3 DF = tex2D(_ReflectionMap, RoughnessTexcoord);
				DF = GammaToLinearSpace(DF);
				float3 FR = tex2D(_FresnelMap, RoughnessTexcoord);
				FR = GammaToLinearSpace(FR);
				float3 SH = tex2D(_SHMap, RoughnessTexcoord);
				SH = GammaToLinearSpace(SH);

				float2 SkinTexcoord = MatCapLutTexcoord(MatCap, Occlusion.b);
				float3 Skin = tex2D(_SkinMap, SkinTexcoord);
				Skin = GammaToLinearSpace(Skin);
				
				float4 Albedo = tex2D(_MainTex, i.uv) * _Color;
				Albedo.rgb= GammaToLinearSpace(Albedo.rgb);
				float3 Diffuse = Albedo.rgb * UNITY_INV_PI * Occlusion.r;

				float3 DielectricSpecular = saturate((DF + FR) * Diffuse);
				Diffuse = Diffuse * SH;
				DielectricSpecular= saturate(DielectricSpecular + DF * FR + Diffuse);
				
				float3 MetalSpecular = saturate(DF * Albedo.rgb * 3.1830989 + FR);
				float3 Specular = saturate(lerp(DielectricSpecular, MetalSpecular, Metallic));

				LGAME_STARACTOR_LIGHT_ATTENUATION(atten, i, wPos ,NoL);
				float SkinArea = 0.75;
				float SkinIntensity = 2.0;
				float3 SkinColor = float3(1.0, 0.508, 0.237);
				SkinColor = LinearToGammaSpace(SkinColor);
				SkinArea = pow((1.0 - SH * atten),lerp(10.0, 1.0, SkinArea));
 
				Skin = (Skin * SkinArea * SkinIntensity * SkinColor + DielectricSpecular) * SkinMask;
				float luma = dot(Skin, float3(0.2126729, 0.7151522, 0.0721750));
 				Skin = luma.xxx + _Saturate * (Skin - luma.xxx);

				float3 Color = Diffuse *_LightColor0 + Specular + Skin;
				Color *= atten;
				Color = saturate(Overlay(NoL * 0.5 + 0.5,Color));


				Color = Color / ((Color + _Exposure) * _Gamma) * 2.0 ;
				Color = LinearToGammaSpace(Color);
				return fixed4(Color, 1.0);
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
			#pragma skip_variants LIGHTMAP_SHADOW_MIXING SHADOWS_SCREEN LIGHTPROBE_SH SPOT DIRECTIONAL_COOKIE POINT_COOKIE SHADOWS_CUBE
			#pragma shader_feature _METALLICGLOSSMAP
			#pragma shader_feature _OCCLUSION_UV1
			#pragma vertex vert
			#pragma fragment frag
			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv0 : TEXCOORD0;
				float2 uv1 : TEXCOORD1;
				float3 normal:NORMAL;
				float4 tangent:TANGENT;
			};

			struct v2f
			{
				float4 uv : TEXCOORD0;
				float4 pos : SV_POSITION;
				float3 viewDir:TEXCOORD1;
				float3 lightDir:TEXCOORD2;
				float4 tangentToWorld[3]	: TEXCOORD3;
				UNITY_SHADOW_COORDS(6)
			};			
			v2f vert(appdata v)
			{
				v2f o;
				UNITY_INITIALIZE_OUTPUT(v2f, o);
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv.xy = TRANSFORM_TEX(v.uv0, _MainTex);
				o.uv.zw = v.uv1;
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
				UNITY_TRANSFER_SHADOW(o, v.uv1);
				return o;
			}
			fixed4 frag(v2f i) : SV_Target
			{
				float3 V = normalize(i.viewDir);
				float3 L = normalize(i.lightDir);
				float3 H = normalize(L + V);

				float3 wPos = float3(i.tangentToWorld[0].w, i.tangentToWorld[1].w, i.tangentToWorld[2].w);
				float3 normal = UnpackScaleNormal(tex2D(_BumpMap, i.uv), _BumpScale);
				float3 N = normalize(i.tangentToWorld[0].xyz * normal.r + i.tangentToWorld[1].xyz * normal.g + i.tangentToWorld[2].xyz * normal.b);
				float VoH = saturate(dot(V, H));
				float NoL = dot(N, L);
				float2 MatCap = MatCapUV(N);

#ifdef _METALLICGLOSSMAP
				float3 data = tex2D(_MetallicGlossMap, i.uv).rgb;
				data.g *= _GlossMapScale;
				float Metallic = data.r;
				float Smoothness = data.g;
#else
				float Metallic = _Metallic;
				float Smoothness = _Glossiness;
#endif

#ifdef _OCCLUSION_UV1
				float3 Occlusion = OcclusionMap(i.uv.zw);
#else
				float3 Occlusion = OcclusionMap(i.uv.xy);
#endif
				float Roughness = clamp(0.001,0.999,1.0 - Smoothness);

				float2 RoughnessTexcoord = MatCapLutTexcoord(MatCap, Roughness);
				float3 DF = tex2D(_ReflectionMap, RoughnessTexcoord);
				DF = GammaToLinearSpace(DF);
				float3 FR = tex2D(_FresnelMap, RoughnessTexcoord);
				FR = GammaToLinearSpace(FR);

				float4 Albedo = tex2D(_MainTex, i.uv) * _Color;
				Albedo.rgb = GammaToLinearSpace(Albedo.rgb);
				float3 Diffuse = Albedo.rgb * UNITY_INV_PI * Occlusion.r;

				float3 DielectricSpecular = saturate((DF + FR) * Diffuse);
				DielectricSpecular = saturate(DielectricSpecular + DF * FR + Diffuse);

				float3 MetalSpecular = saturate(DF * Albedo.rgb * 3.1830989 + FR);
				float3 Specular = saturate(lerp(DielectricSpecular, MetalSpecular, Metallic));

				UNITY_LIGHT_ATTENUATION(atten, i, wPos);
				float3 Color = (Diffuse * _LightColor0 + Specular)* atten;
				Color = saturate(Overlay(NoL * 0.5 + 0.5,Color));

				Color = Color / ((Color + _Exposure) * _Gamma) * 2.0;
				Color = LinearToGammaSpace(Color);
				return fixed4(Color, 1.0);
			}
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
}
