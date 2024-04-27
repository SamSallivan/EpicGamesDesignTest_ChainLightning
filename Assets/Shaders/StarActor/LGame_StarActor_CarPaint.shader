Shader "LGame/StarActor/CarPaint"
{
	Properties
	{
		_Color											("Color", Color) = (1,1,1,1)
		_MainTex										("Albedo", 2D) = "white" {}
		_MetallicGlossMap								("MetallicGlossDecalAO", 2D) = "black" {}//R通道是金属度，G通道光滑度，B通道贴花蒙版,A通道遮蔽
		_Metallic										("Metallic", Range(0.0, 1.0)) = 0.0
		_Glossiness										("Smoothness", Range(0.0, 1.0)) = 0.0//默认取通道数值
		_GlossMapScale									("Smoothness Scale", Range(0.0, 1.0)) = 1.0
		_BumpMap										("Normal Map", 2D) = "bump" {}
		_BumpScale										("Scale", Float) = 1.0
		_OcclusionStrength								("OcclusionStrength", Range(0.0, 1.0)) = 1.0
		_AmbientCol										("Ambient Color" , Color) = (0.3,0.3,0.3,0.3)
		[Enum(MatCap,0,CubeMap,1)] _ReflectionType		("Reflection Type", Float) = 1
		[HDR]_ReflectionColor							("Reflection Color", Color) = (0.5 , 0.5 , 0.5 , 0)
		_ReflectionCubeMap								("Reflection CubeMap", Cube) = "" {}
		_ReflectionMatCap								("Reflection MatCap", 2D) = "" {}
		_ShadowStrength									("ShadowStrength",Range(0.0, 1.0))= 1.0
		//Decal
		_DecalRoughness									("DecalRoughness",Range(0.0, 1.0))= 1.0
		//ClearCoat
		_ClearCoat										("Clear Coat",Range(0.0,1.0)) = 1.0
		_ClearCoatRoughness								("Clear Coat Roughness",Range(0.0,1.0)) = 1.0
		_ClearCoatNormalMap								("Clear Coat Normal Map",2D) = "bump" {}
		_CCBumpScale									("ClearCoatNormalScale",Float) = 1.0
		//Ramp
		_Ramp											("Ramp",2D) = "white"{}
		_RampStrength									("RampStrength",Range(0.0,1.0))= 1.0
		_RampScale										("RampScale",Range(0.0,1.0))= 1.0
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
			Name "FORWARD"
			Tags { "LightMode" = "ForwardBase" }
			CGPROGRAM
			#pragma target 3.0
			#pragma multi_compile_fwdbase nodirlightmap nodynlightmap novertexlight noshadowmask  
			#pragma skip_variants LIGHTMAP_SHADOW_MIXING LIGHTPROBE_SH SPOT DIRECTIONAL_COOKIE POINT_COOKIE SHADOWS_CUBE
			#pragma multi_compile _ _HARD_SHADOW _SOFT_SHADOW
			#pragma multi_compile _ _FASTEST_QUALITY
			#pragma shader_feature _METALLICGLOSSMAP
			#pragma shader_feature _REFLECTION_CUBEMAP
			#pragma shader_feature _DECAL
			#pragma shader_feature _RAMPMAP
			#pragma vertex vert_carpaint
			#pragma fragment frag_carpaint
			//各种头文件
			#include "UnityCG.cginc"
			#include "AutoLight.cginc"	
			#include "Lighting.cginc"
			#include "Assets/CGInclude/LGameStarActorBRDF.cginc"
			#include "Assets/CGInclude/LGameStarActorLighting.cginc"
			#include "Assets/CGInclude/LGameStarActorShadow.cginc"
			#include "Assets/CGInclude/LGameCharacterDgs.cginc"
			//各种变量---------------------------------------------------------------------------------------
			fixed4				_Color;
			sampler2D			_MainTex;
			float4				_MainTex_ST;
			half				_Metallic;
			sampler2D			_MetallicGlossMap;
			half				_Glossiness;
			half				_GlossMapScale;
			half				_BumpScale;
			sampler2D			_BumpMap;
			float4				_BumpMap_ST;
			half				_ReflectionType;
			//ClearCoat
			half				_ClearCoat;
			half				_DecalRoughness;
			sampler2D			_Ramp;
			half				_RampStrength;
			half				_RampScale;
			half				_ClearCoatRoughness;
			sampler2D			_ClearCoatNormalMap;
			float4				_ClearCoatNormalMap_ST;
			half				_CCBumpScale;
			//变量结束-----------------------------------------------------------------------------------------
			struct a2v
			{
				float4 vertex			: POSITION;
				half2 uv0				: TEXCOORD0;
				half2 uv1				: TEXCOORD1;
				float3 normal			: NORMAL;
				float4 tangent			: TANGENT;
				fixed4 color			: COLOR;
			};
			struct v2f
			{
				float4 pos					: SV_POSITION;
				half4 uv					: TEXCOORD0;
				float3 viewDir				: TEXCOORD1;
				float4 tangentToWorld[3]	: TEXCOORD2;//这里用的是三个TEXCOORD。。。。
				LGAME_STARACTOR_SHADOW_COORDS(5)
			#ifdef LIGHTMAP_ON//添加lightmap
				float2 lightmapUV			:TEXCOORD6;
			#endif
			};
			v2f vert_carpaint(a2v v)
			{
				v2f o;
				float2 uv0 = v.uv0;
			#ifdef _USE_DIRECT_GPU_SKINNING
				float4 tangent;
				float3 binormal;
				float3 normal;
				DecompressTangentNormal(v.tangent, tangent, normal, binormal);
				float4 vec = CalculateGPUSkin(v.skinIndices, v.skinWeights, v.vertex, tangent, normal, binormal);
				uv0 = DecompressUV(v.uv0, _uvBoundData);
			#else
				float4 tangent = v.tangent;
				float3 normal = v.normal;
				float3 binormal = cross(normal, tangent.xyz) * tangent.w;
				float4 vec = v.vertex;
			#endif
				//初始值归0----------------------
				UNITY_INITIALIZE_OUTPUT(v2f, o);
			#ifdef LIGHTMAP_ON
					o.lightmapUV = v.uv1 * unity_LightmapST.xy + unity_LightmapST.zw;
			#endif
				//用tangentToWorld传世界空间位置
				float4 posWorld = mul(unity_ObjectToWorld,vec);
				o.tangentToWorld[0].w = posWorld.x;
				o.tangentToWorld[1].w = posWorld.y;
				o.tangentToWorld[2].w = posWorld.z;
				o.pos = UnityObjectToClipPos(vec);
				//传参-----------------------
				//写入UV
				o.uv.xy = uv0;
				o.uv.zw = v.uv1;
				o.viewDir =Unity_SafeNormalize(UnityWorldSpaceViewDir(posWorld));//需要归一化，如果不归一化会出错
				//各种构建TBN
				float3 normalWorld =UnityObjectToWorldNormal(normal);
				float3 tangentWorld = UnityObjectToWorldDir(tangent.xyz);
				float3 binormalWorld = UnityObjectToWorldDir(binormal) * unity_WorldTransformParams.w;
				o.tangentToWorld[0].xyz = tangentWorld;
				o.tangentToWorld[1].xyz = binormalWorld;
				o.tangentToWorld[2].xyz = normalWorld;
				//TBN构建完成
				LGAME_STARACTOR_TRNASFER_SHADOW(o)//自阴影宏
				return o;
			}
			half3 directSpecularCal(float roughness,float NoH,float LoH,half3 specColor)
			{
				float a2 = roughness * roughness;
				float d = (NoH * NoH * (a2 - 1.0f) + 1.0f) + 0.00001f;
				float3 specularTerm =  a2 / (max(0.1f, LoH * LoH) * (roughness + 0.5f) * (d * d)* 4.0f ) * specColor;//DGGX
				/*Approximate Calculation(近似计算，见unityURP相关文章)*/
				specularTerm = specularTerm - 1e-4f;
				specularTerm = clamp(specularTerm, 0.0f, 100.0f);
				return specularTerm;
			}
			fixed4 frag_carpaint(v2f i):SV_Target
			{
			//贴图采样(Cubemap和matcap以及Ramp都不在这里采)------------------------------------------
				float2 albedoMotionUV = TRANSFORM_TEX(i.uv.xy, _MainTex);
				float2 ccNormalUV = TRANSFORM_TEX(i.uv.xy,_ClearCoatNormalMap);
				half4 var_MainTex = tex2D(_MainTex,albedoMotionUV);
				float3 var_Normal = UnpackScaleNormal(tex2D(_BumpMap, albedoMotionUV), _BumpScale);
			#ifdef _METALLICGLOSSMAP
				half4 var_MetallicGlossMap = tex2D(_MetallicGlossMap,albedoMotionUV);
				half smoothness = _GlossMapScale*var_MetallicGlossMap.g;
				half metallic =var_MetallicGlossMap.r;
				float decalmask = var_MetallicGlossMap.b;
				half4 var_OcclusionMap = tex2D(_MetallicGlossMap,albedoMotionUV);//AO的UV采样这里设置为主法线的UV
				half occlusion = LerpWhiteTo(var_OcclusionMap.a, _OcclusionStrength);//这里L有R,G两类型AO，这里只取其一作为规范
			#else
				half smoothness = _Glossiness;
				half metallic =_Metallic;
				float decalmask = 0;
				half occlusion = 1.0;
			#endif
				half3 var_CCNormal = UnpackScaleNormal(tex2D(_ClearCoatNormalMap, ccNormalUV),_CCBumpScale);
			//基础数据计算------------------------------------------------------------------
				half clearcoatStrength = _ClearCoat;
				half perceptual_roughness = 1.0f - smoothness;
				half roughness = max(0.001f,perceptual_roughness * perceptual_roughness);//roughness 是 1.0f - smoothness 的平方
				half3 albedo = var_MainTex.rgb*_Color;
				half ccPerceptualRoughness = _ClearCoatRoughness;
				ccPerceptualRoughness = clamp(ccPerceptualRoughness,0.089,1.0);
				half ccRoughness = ccPerceptualRoughness*ccPerceptualRoughness;
				//roughness = max(roughness,ccRoughness);
			#ifdef UNITY_COLORSPACE_GAMMA
				albedo.rgb = GammaToLinearSpace(albedo.rgb);
			#endif
				//世界空间位置计算
				float3 simpleWorldNormal = i.tangentToWorld[2].xyz;
				float3 worldNormal = normalize(i.tangentToWorld[0].xyz*var_Normal.r + i.tangentToWorld[1].xyz*var_Normal.g + i.tangentToWorld[2].xyz*var_Normal.b);
				float3 ccworldNormal = normalize(i.tangentToWorld[0].xyz*var_CCNormal.r + i.tangentToWorld[1].xyz*var_CCNormal.g + i.tangentToWorld[2].xyz*var_CCNormal.b);
				float3 worldPos = float3(i.tangentToWorld[0].w, i.tangentToWorld[1].w, i.tangentToWorld[2].w);
				float3 worldLightDir = Unity_SafeNormalize(UnityWorldSpaceLightDir(worldPos.xyz));
				half3 lightCol = _LightColor0.rgb;
				half NoL = saturate(dot(worldNormal, worldLightDir));
				half NoV = saturate(dot(worldNormal, i.viewDir));
				//金属度相关处理
				half one_minus_reflectivity = (1.0 - metallic) * 0.96;
				half3 diffColor = albedo.rgb * one_minus_reflectivity;
				//这个specColor在其他地方被称为F0,因为传播介质不同，故与传统PBR相比应有所改变
				half3 specColor = lerp(float3(0.04, 0.04, 0.04), albedo.rgb, metallic);
			#ifdef _RAMPMAP
				float rampUV = _RampScale*(NoV);
				half3 var_Ramp = tex2D(_Ramp,float2(rampUV,0));
				//specColor = lerp(half3(1,1,1),var_Ramp,_RampStrength)*specColor;
				specColor = lerp(half3(1,1,1),var_Ramp,_RampStrength)*lerp(specColor,1,_RampStrength);
			#endif
				float3 ccNormal = normalize(i.tangentToWorld[0].xyz*var_CCNormal.r + i.tangentToWorld[1].xyz*var_CCNormal.g + i.tangentToWorld[2].xyz*var_CCNormal.b);
				//光照衰减相关系数，可以详细研究,现在先不管
				LGAME_STARACTOR_LIGHT_ATTENUATION(atten, i, worldPos, NoL);//自阴影宏
				float3 H = Unity_SafeNormalize(worldLightDir + i.viewDir);
				float NoH =saturate(dot(worldNormal, H));
				float LoH =saturate(dot(worldLightDir, H));
			//直接光漫反射,就是兰伯特
				half3 diffuseTerm = atten *lightCol *NoL;
			//直接光高光部分
				half3 specularTerm = directSpecularCal(roughness, NoH,LoH,specColor);
			//直接光清漆
				float ccNoH = saturate(dot(ccNormal, H));
				float ccNoL = saturate(dot(ccNormal,worldLightDir));
				float ccDiffuse =atten*ccNoL;
				float Dc = D_GGX(ccNoH,ccRoughness);
				float Vc = V_Kelemen(LoH);
				float Fc = F_Schlick(0.04,LoH)*clearcoatStrength;
				float Frc = ccDiffuse*(Dc*Vc)*Fc;//NOL作为蒙版
				fixed4 col =fixed4(1,1,1,1);
				diffuseTerm *=(1.0-Fc);
				specularTerm *=(1.0-Fc);
			#ifdef _RAMPMAP
				diffColor =lerp(diffColor,diffColor*var_Ramp,_RampStrength);
			#endif
				col.rgb = diffuseTerm*(diffColor+specularTerm)+Frc;
			//间接光漫反射
				half3 giDiffuse = half3(0,0,0);
			#ifdef _FASTEST_QUALITY
				giDiffuse = _AmbientCol;
			#else
				IndirectDiffuse(occlusion, worldNormal, giDiffuse);
				giDiffuse*=1.0-Fc;
			#endif
				col.rgb += giDiffuse*diffColor;
			//间接光清漆（只有高光，没漫反射）
				half3 giSpecular = half3(0,0,0);
			#ifndef _FASTEST_QUALITY
				half3 ccgiSpecular = half3(0,0,0);
				float3 ccNoV = saturate(dot(ccNormal, i.viewDir));
				half surfaceReduction = (0.6 - 0.08 * perceptual_roughness);
				surfaceReduction = 1.0 - roughness * perceptual_roughness * surfaceReduction;
				half grazingTerm = saturate(smoothness + (1.0 - one_minus_reflectivity));
				half3 ccsurfaceReduction = (0.6 - 0.08 * ccPerceptualRoughness);
				ccsurfaceReduction = 1.0 - ccRoughness * ccPerceptualRoughness * ccsurfaceReduction;
				IndirectSpecular(worldPos,i.viewDir, ccworldNormal,occlusion,ccPerceptualRoughness, ccgiSpecular);
				//F0代表从法线方向观察材质的反射率，而F90就是与法线垂直方向观察材质的反射率
				IndirectSpecular(worldPos,i.viewDir,worldNormal,occlusion,perceptual_roughness,giSpecular);
				giSpecular=Fc*ccgiSpecular+giSpecular*(1.0-Fc)*(1.0-Fc);
				giSpecular=surfaceReduction*giSpecular*FresnelLerpFast(specColor,grazingTerm,NoV);
			#endif
				col.rgb+=giSpecular;
			//间接光清漆合入(一点细节，衰减函数使用clearcoat相关的量，有了菲尼尔项就不用再重新计算,清漆不应受漫反射衰减影响)
				//ccgiSpecular = ccsurfaceReduction*Fc*ccgiSpecular;
				//col.rgb+=ccgiSpecular;
			//贴花计算
			#ifdef _DECAL
				float3 dNoL = saturate(dot(simpleWorldNormal, worldLightDir));
				float3 dNoH = saturate(dot(simpleWorldNormal, H));
				half3 decalCol = var_MainTex.rgb;
				half decalRoughness = max(0.1f,_DecalRoughness);
				half3 decalSpecularTerm = directSpecularCal(decalRoughness, dNoH,LoH,half3(0.04,0.04,0.04));
				half3 decalout =dNoL*lightCol*(decalCol+decalSpecularTerm);
				half3 dgiSpecular = half3(0,0,0);
				half3 dgiDiffuse = 0.04*decalCol;//添加间接光漫反射应对暗处没有颜色倾向的问题
				decalout += dgiDiffuse;
				//因为贴花面积较小，对IBL细节要求不高，ao设为1
			#ifndef _FASTEST_QUALITY
				half3 decalF = F_Schlick(0.04,LoH);//参照clearcoat间接GI，仅用F项节约计算
				IndirectSpecular(worldPos,i.viewDir,simpleWorldNormal,1,decalRoughness,dgiSpecular);
				decalout =lerp(decalout+decalF*dgiSpecular,decalout,decalRoughness);
			#endif
				col.rgb=lerp(col.rgb,decalout,decalmask);
			#endif
			#ifdef LIGHTMAP_ON//开启lightmap
					fixed4 light = UNITY_SAMPLE_TEX2D(unity_Lightmap, i.lightmapUV);
					light = fixed4(DecodeLightmap(light), 1.0);
					//col = NoL;
					col *= light;
			#endif
			#ifdef UNITY_COLORSPACE_GAMMA
				col.rgb = LinearToGammaSpace(col.rgb);//最后输出结果要有一个gamma矫正
			#endif
				return col;
			}
			ENDCG
		}
		//点光源
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
			#pragma shader_feature _DECAL
			#pragma shader_feature _RAMPMAP
			#pragma vertex vert_carpaintadd
			#pragma fragment frag_carpaintadd
			//各种头文件
			#include "UnityCG.cginc"
			#include "AutoLight.cginc"	
			#include "Lighting.cginc"
			#include "Assets/CGInclude/LGameStarActorBRDF.cginc"
			#include "Assets/CGInclude/LGameStarActorLighting.cginc"
			#include "Assets/CGInclude/LGameStarActorShadow.cginc"
			//各种变量---------------------------------------------------------------------------------------
			fixed4				_Color;
			sampler2D			_MainTex;
			float4				_MainTex_ST;
			half				_Metallic;
			sampler2D			_MetallicGlossMap;
			half				_Glossiness;
			half				_GlossMapScale;
			half				_BumpScale;
			sampler2D			_BumpMap;
			float4				_BumpMap_ST;
			half				_ReflectionType;
			//ClearCoat
			half				_ClearCoat;
			half				_DecalRoughness;
			sampler2D			_Ramp;
			half				_RampStrength;
			half				_RampScale;
			half				_ClearCoatRoughness;
			sampler2D			_ClearCoatNormalMap;
			float4				_ClearCoatNormalMap_ST;
			half				_CCBumpScale;
			//变量结束-----------------------------------------------------------------------------------------
			struct a2v
			{
				float4 vertex			: POSITION;
				half2 uv0				: TEXCOORD0;
				half2 uv1				: TEXCOORD1;
				float3 normal			: NORMAL;
				float4 tangent			: TANGENT;
				fixed4 color			: COLOR;
				//GPU_SKINNING待加入
			};
			struct v2f
			{
				float4 pos					: SV_POSITION;
				half4 uv					: TEXCOORD0;
				float3 viewDir				: TEXCOORD1;
				float4 tangentToWorld[3]	: TEXCOORD2;//这里用的是三个TEXCOORD。。。。
				LGAME_STARACTOR_SHADOW_COORDS(5)
			};
			v2f vert_carpaintadd(a2v v)
			{
				v2f o;
				//初始值归0----------------------
				UNITY_INITIALIZE_OUTPUT(v2f, o);
				float2 uv0 = v.uv0;
			#ifdef _USE_DIRECT_GPU_SKINNING
				float4 tangent;
				float3 binormal;
				float3 normal;
				DecompressTangentNormal(v.tangent, tangent, normal, binormal);
				float4 vec = CalculateGPUSkin(v.skinIndices, v.skinWeights, v.vertex, tangent, normal, binormal);
				uv0 = DecompressUV(v.uv0, _uvBoundData);
			#else
				float4 tangent = v.tangent;
				float3 normal = v.normal;
				float3 binormal = cross(normal, tangent.xyz) * tangent.w;
				float4 vec = v.vertex;
			#endif
				//用tangentToWorld传世界空间位置
				float4 posWorld = mul(unity_ObjectToWorld,vec);
				o.tangentToWorld[0].w = posWorld.x;
				o.tangentToWorld[1].w = posWorld.y;
				o.tangentToWorld[2].w = posWorld.z;
				o.pos = UnityObjectToClipPos(vec);
				//传参-----------------------
				//写入UV
				o.uv.xy = uv0;
				o.uv.zw = v.uv1;
				o.viewDir =Unity_SafeNormalize(UnityWorldSpaceViewDir(posWorld));//需要归一化，如果不归一化会出错
				//各种构建TBN
				float3 normalWorld =UnityObjectToWorldNormal(normal);
				float3 tangentWorld = UnityObjectToWorldDir(tangent.xyz);
				float3 binormalWorld = UnityObjectToWorldDir(binormal) * unity_WorldTransformParams.w;
				o.tangentToWorld[0].xyz = tangentWorld;
				o.tangentToWorld[1].xyz = binormalWorld;
				o.tangentToWorld[2].xyz = normalWorld;
				//TBN构建完成
				LGAME_STARACTOR_TRNASFER_SHADOW(o)//自阴影宏
				return o;
			}
			half3 directSpecularCal(float roughness,float NoH,float LoH,half3 specColor)
			{
				float a2 = roughness * roughness;
				float d = (NoH * NoH * (a2 - 1.0f) + 1.0f) + 0.00001f;
				float3 specularTerm =  a2 / (max(0.1f, LoH * LoH) * (roughness + 0.5f) * (d * d)* 4.0f ) * specColor;
				specularTerm = specularTerm - 1e-4f;
				specularTerm = clamp(specularTerm, 0.0f, 100.0f);
				return specularTerm;
			}
			fixed4 frag_carpaintadd(v2f i):SV_Target
			{
			//贴图采样(Cubemap和matcap以及Ramp都不在这里采)------------------------------------------
				float2 albedoMotionUV = TRANSFORM_TEX(i.uv.xy, _MainTex);
				float2 ccNormalUV = TRANSFORM_TEX(i.uv.xy,_ClearCoatNormalMap);
				half4 var_MainTex = tex2D(_MainTex,albedoMotionUV);
				float3 var_Normal = UnpackScaleNormal(tex2D(_BumpMap, albedoMotionUV), _BumpScale);
			#ifdef _METALLICGLOSSMAP
				half4 var_MetallicGlossMap = tex2D(_MetallicGlossMap,albedoMotionUV);
				half smoothness = _GlossMapScale*var_MetallicGlossMap.g;
				half metallic =var_MetallicGlossMap.r;
				float decalmask = var_MetallicGlossMap.b;
				half4 var_OcclusionMap = tex2D(_MetallicGlossMap,albedoMotionUV);//AO的UV采样这里设置为主法线的UV
				half occlusion = LerpWhiteTo(var_OcclusionMap.a, _OcclusionStrength);//这里L有R,G两类型AO，这里只取其一作为规范
			#else
				half smoothness = _Glossiness;
				half metallic =_Metallic;
				float decalmask = 0;
				half occlusion = 1.0;
			#endif
				half3 var_CCNormal = UnpackScaleNormal(tex2D(_ClearCoatNormalMap, ccNormalUV),_CCBumpScale);
			//基础数据计算------------------------------------------------------------------
				half clearcoatStrength = _ClearCoat;
				half perceptual_roughness = 1.0f - smoothness;
				half roughness = max(0.001f,perceptual_roughness * perceptual_roughness);//roughness 是 1.0f - smoothness 的平方
				half3 albedo = var_MainTex.rgb*_Color;
				half ccPerceptualRoughness = _ClearCoatRoughness;
				ccPerceptualRoughness = clamp(ccPerceptualRoughness,0.089,1.0);
				half ccRoughness = ccPerceptualRoughness*ccPerceptualRoughness;
			#ifdef UNITY_COLORSPACE_GAMMA
				albedo.rgb = GammaToLinearSpace(albedo.rgb);
			#endif
				//世界空间位置计算
				float3 simpleWorldNormal = i.tangentToWorld[2].xyz;
				float3 worldNormal = normalize(i.tangentToWorld[0].xyz*var_Normal.r + i.tangentToWorld[1].xyz*var_Normal.g + i.tangentToWorld[2].xyz*var_Normal.b);
				float3 ccworldNormal = normalize(i.tangentToWorld[0].xyz*var_CCNormal.r + i.tangentToWorld[1].xyz*var_CCNormal.g + i.tangentToWorld[2].xyz*var_CCNormal.b);
				float3 worldPos = float3(i.tangentToWorld[0].w, i.tangentToWorld[1].w, i.tangentToWorld[2].w);
				float3 worldLightDir = Unity_SafeNormalize(UnityWorldSpaceLightDir(worldPos.xyz));
				half3 lightCol = _LightColor0.rgb;
				half NoL = saturate(dot(worldNormal, worldLightDir));
				half NoV = saturate(dot(worldNormal, i.viewDir));
				//金属度相关处理
				half one_minus_reflectivity = (1.0 - metallic) * 0.96;
				half3 diffColor = albedo.rgb * one_minus_reflectivity;
				//这个specColor在其他地方被称为F0,因为传播介质不同，故与传统PBR相比应有所改变
				half3 specColor = lerp(float3(0.04, 0.04, 0.04), albedo.rgb, metallic);
			#ifdef _RAMPMAP
				float rampUV = _RampScale*(NoV);
				half3 var_Ramp = tex2D(_Ramp,float2(rampUV,0));
				//specColor = specColor*lerp(half3(1,1,1),var_Ramp,_RampStrength);
				specColor = lerp(half3(1,1,1),var_Ramp,_RampStrength)*lerp(specColor,1,_RampStrength);
			#endif
				float3 ccNormal = normalize(i.tangentToWorld[0].xyz*var_CCNormal.r + i.tangentToWorld[1].xyz*var_CCNormal.g + i.tangentToWorld[2].xyz*var_CCNormal.b);
				//光照衰减相关系数
				LGAME_STARACTOR_LIGHT_ATTENUATION(atten, i, worldPos, NoL);//自阴影宏
				float3 H = Unity_SafeNormalize(worldLightDir + i.viewDir);
				float NoH =saturate(dot(worldNormal, H));
				float LoH =saturate(dot(worldLightDir, H));
			//直接光漫反射
				half3 diffuseTerm = atten *lightCol *NoL;
			//直接光高光部分
				half3 specularTerm = directSpecularCal(roughness, NoH,LoH,specColor);
			//直接光清漆
				float ccNoH = saturate(dot(ccNormal, H));
				float ccNoL = saturate(dot(ccNormal,worldLightDir));
				float ccDiffuse =atten*ccNoL;
				float Dc = D_GGX(ccNoH,ccRoughness);
				float Vc = V_Kelemen(LoH);
				float Fc = F_Schlick(0.04,LoH)*clearcoatStrength;
				float Frc = ccDiffuse*(Dc*Vc)*Fc;//NOL作为蒙版
				fixed4 col =fixed4(1,1,1,1);
				diffuseTerm *=(1.0-Fc);
				specularTerm *=(1.0-Fc);
			#ifdef _RAMPMAP
				diffColor =lerp(diffColor,diffColor*var_Ramp,_RampStrength);
			#endif
				col.rgb = diffuseTerm*(diffColor+specularTerm)+Frc;
			//贴花计算
			#ifdef _DECAL
				float3 dNoL = saturate(dot(simpleWorldNormal, worldLightDir));
				float3 dNoH = saturate(dot(simpleWorldNormal, H));
				half3 decalCol = var_MainTex.rgb;
				half decalRoughness = max(0.1f,_DecalRoughness);
				half3 decalSpecularTerm = directSpecularCal(decalRoughness, dNoH,LoH,half3(0.04,0.04,0.04));
				half3 decalout = dNoL*lightCol*(decalCol+decalSpecularTerm);
				col.rgb=lerp(col.rgb,decalout,decalmask);
			#endif
			#ifdef UNITY_COLORSPACE_GAMMA
				col.rgb = LinearToGammaSpace(col.rgb);//最后输出结果要有一个gamma矫正
			#endif
				return col;
			}
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
	CustomEditor "LGameStarActorCarPaintShaderGUI"
}
