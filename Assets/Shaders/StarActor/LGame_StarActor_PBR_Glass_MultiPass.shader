Shader "LGame/StarActor/PBR_Glass_MultiPass"
{
	Properties
	{
		_Color("Color", Color) = (1,1,1,1)
		_MainTex("Albedo", 2D) = "white" {}

		_Metallic("Metallic", Range(0.0, 1.0)) = 0.0
		_MetallicGlossMap("Metallic", 2D) = "white" {}
		_Glossiness("Smoothness", Range(0.0, 1.0)) = 0.5
		_GlossMapScale("Smoothness Scale", Range(0.0, 1.0)) = 1.0

		_BumpMap("Normal Map", 2D) = "bump" {}
		_BumpScale("Scale", Float) = 1.0
		
		_ReflectionColor("Reflection Color", Color) = (0.5 , 0.5 , 0.5 , 0)
		_ReflectionMapScale ("CubeMap Scale", Range(0.0, 8.0)) = 1.0
		_ReflectionMatCap ("Reflection MatCap", 2D) = "" {}

		[hdr]_EmissionColor("Color", Color) = (0,0,0)						    
		_EmissionMap("Emission", 2D) = "white" {}			

	}
		SubShader
		{
			Tags {"Queue" = "Transparent" "RenderType" = "Opaque" }
			LOD 100

			Pass
			{
				ColorMask 0
			  ZWrite On
			}
			Pass
			{
				Tags { "LightMode" = "ForwardBase" }
				Blend One OneMinusSrcAlpha
				ZWrite Off

				CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag

				#include "UnityCG.cginc"
				#include "AutoLight.cginc"	
				#include "Lighting.cginc"
				#include "Assets/CGInclude/LGameCharacterDgs.cginc"

				#pragma shader_feature _METALLICGLOSSMAP
				#pragma shader_feature _EMISSION
				//#pragma multi_compile __ _USE_DIRECT_GPU_SKINNING

				struct appdata
				{
					float4 vertex	: POSITION;
					half2 uv		: TEXCOORD0;
#ifdef _USE_DIRECT_GPU_SKINNING
					half4 tangent	: TANGENT;
					float4 skinIndices : TEXCOORD2;
					float4 skinWeights : TEXCOORD3;
#else
					float3 normal	: NORMAL;
					half4 tangent	: TANGENT;
#endif
				};

				struct v2f
				{
					float4 pos				: SV_POSITION;
					float2 uv				: TEXCOORD0;
					half4 tangentToWorld[3]	: TEXCOORD1;    // [3x3:tangentToWorld | 1x3:worldPos]
				};

				fixed4		_Color;
				
				sampler2D	_MainTex;
				sampler2D	_BumpMap;
				half		_BumpScale;

				half		_Metallic;
				sampler2D	_MetallicGlossMap;
				half		_Glossiness;
				half		_GlossMapScale;

				fixed4		_ReflectionColor;
				half		_ReflectionMapScale;
				sampler2D	_ReflectionMatCap;

				sampler2D	_EmissionMap;
				half4		_EmissionColor;	

				v2f vert(appdata v)
				{

					float3 normal;
					float4 tangent;
#if _USE_DIRECT_GPU_SKINNING
					float3 binormal;
					DecompressTangentNormal(v.tangent, tangent, normal, binormal);
					v.vertex = CalculateGPUSkin(v.skinIndices, v.skinWeights, v.vertex, tangent, normal, binormal);
					v.uv.xy = DecompressUV(v.uv.xy, _uvBoundData);
#else
					normal = v.normal;
					tangent = v.tangent;
#endif


					v2f o;
					o.pos = UnityObjectToClipPos(v.vertex);
					o.uv = v.uv;

					//世界空间顶点坐标
					float4 posWorld = mul(unity_ObjectToWorld, v.vertex);
					o.tangentToWorld[0].w = posWorld.x;
					o.tangentToWorld[1].w = posWorld.y;
					o.tangentToWorld[2].w = posWorld.z;

					//切线转世界空间的矩阵
					float3 normalWorld = UnityObjectToWorldNormal(normal);
					float3 tangentWorld = UnityObjectToWorldDir(tangent.xyz);
					half3 binormalWorld = cross(normalWorld, tangentWorld) * tangent.w * unity_WorldTransformParams.w;
					o.tangentToWorld[0].xyz = tangentWorld;
					o.tangentToWorld[1].xyz = binormalWorld;
					o.tangentToWorld[2].xyz = normalWorld;

					return o;
				}


				half3 Emission(float2 uv)
				{
				#ifndef _EMISSION
					return 0;
				#else
					half3 emission = tex2D(_EmissionMap, uv).rgb * _EmissionColor.rgb; 
					return emission;
				#endif
				}
				fixed4 frag(v2f i) : SV_Target
				{
					
					half3 worldPos = half3(i.tangentToWorld[0].w , i.tangentToWorld[1].w , i.tangentToWorld[2].w);
					half3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));
					half3 worldLightDir = _WorldSpaceLightPos0.xyz;
					half3 halfDir = normalize(worldViewDir + worldLightDir);

					//World Space NormalDir
					//float3x3 TBN = float3x3(i.tangentToWorld[0].xyz , i.tangentToWorld[1].xyz , i.tangentToWorld[2].xyz);
					//half3 worldNormal = mul(TBN , UnpackScaleNormal(tex2D(_BumpMap, i.uv) , _BumpScale));
					
					half3 tangent = i.tangentToWorld[0].xyz;
					half3 binormal = i.tangentToWorld[1].xyz;
					half3 normal = i.tangentToWorld[2].xyz;
					half3 normalTangent = UnpackScaleNormal(tex2D (_BumpMap, i.uv.xy), _BumpScale) ;
					half3 worldNormal = normalize(tangent * normalTangent.x + binormal * normalTangent.y + normal * normalTangent.z);

					fixed4 texCol = (tex2D(_MainTex, i.uv));
					texCol.rgb =  (texCol.rgb);
					texCol *= _Color; 
					#ifdef _METALLICGLOSSMAP
						half3 metallicGloss = tex2D(_MetallicGlossMap, i.uv).rgb;
						half metallic =	metallicGloss.x;
						half smoothness = metallicGloss.y * _GlossMapScale;
						texCol.a *= metallicGloss.z;
					#else
						half metallic = _Metallic;
						half smoothness = _Glossiness;
					#endif

					half nh = saturate(dot(worldNormal, halfDir));
					half lh = saturate(dot(worldLightDir, halfDir));
					half nv = abs(dot(worldNormal, worldViewDir));
	
					// Specular term
					half perceptualRoughness = 1 - smoothness;
					half roughness = perceptualRoughness * perceptualRoughness;
					half a = roughness;
					half a2 = a * a;
					half d = nh * nh * (a2 - 1.h) + 1.00001h;
					half specularTerm = a / (max(0.32h, lh) * (1.5h + roughness) * d);

					half3 specColor = lerp(0.22.rrr, texCol.rgb, _Metallic);


					// Reflection
					perceptualRoughness = perceptualRoughness * (1.7 - 0.7*perceptualRoughness);
					half mip = perceptualRoughness * 6;

					half3 viewNormal = mul(UNITY_MATRIX_V , half4(worldNormal,0)).xyz;
					half3 viewPos = UnityWorldToViewPos(worldPos);
					float3 r = normalize(reflect(viewPos, viewNormal));
					float m = 2.0 * sqrt(r.x * r.x + r.y * r.y + (r.z + 1) * (r.z + 1));
					half2 matcapUV = r.xy/m + 0.5;
					fixed4 ReflectionMatcapCol = tex2Dlod(_ReflectionMatCap , half4(matcapUV, 0, mip)) ;
					ReflectionMatcapCol *= _ReflectionMapScale * _ReflectionColor;
					half oneMinusReflectivity = (1 - _Metallic) * 0.78;
					half3 diffColor = texCol.rgb * oneMinusReflectivity ;
		
					half surfaceReduction = (0.6 - 0.08*perceptualRoughness);
					half grazingTerm = saturate(smoothness + (1 - oneMinusReflectivity));

					half fresnel = Pow4(1 - nv);					
					half alpha = lerp(texCol.a , ReflectionMatcapCol.a, fresnel) ;

					half3 col = diffColor + specularTerm * specColor +  Emission(i.uv) +
								ReflectionMatcapCol * lerp(  specColor, grazingTerm.rrr, fresnel); 

					return half4( col , alpha);
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
		CustomEditor "LGameSDK.AnimTool.LGameStarActorPBRGlassShaderGUI"
}
