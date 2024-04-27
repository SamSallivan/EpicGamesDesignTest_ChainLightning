Shader "LGame/Scene/StarActor/LightMap"
{
	Properties
	{
		_Color("Color",Color) = (1.0,1.0,1.0,1.0)
		_MainTex("Base (RGB)", 2D) = "white" { }
		[Header(Fog)]
		_FogColor("Fog Color",Color) = (0.0,0.0,0.0,1.0)
		_FogStart("Fog Start",float) = 0.0
		_FogEnd("Fog End",float) = 300.0
		[Header(Shadow)]
		_ShadowStrength("Self Shadow Strength" , Range(0,1)) = 1.0
		[HideInInspector]_BrightnessForScene("",Range(0,1))=1.0
		[Header(Custom Lightmap)]
		[Toggle] _CustomLightmap ("Enable Custom Lightmap", float) = 0
		_LightMapCustom ("LightMap", 2D) = "gray" {}
		_LightMapIntensity("LightMap Intensity",  Range(0,1)) = 1
	}

	SubShader
	{
		Tags { "Queue" = "Geometry" "RenderType" = "Opaque" }
		LOD 100
		Pass
		{	
			Stencil 
			{
				Ref 0
				Comp always
				Pass replace
			}
			Name "FORWARD"
			Tags { "LightMode" = "ForwardBase" }
			CGPROGRAM
			#pragma target 3.0
			#pragma multi_compile_fwdbase nodirlightmap nodynlightmap novertexlight noshadowmask  
			#pragma skip_variants LIGHTMAP_SHADOW_MIXING LIGHTPROBE_SH SPOT DIRECTIONAL_COOKIE POINT_COOKIE
			#pragma shader_feature _CUSTOMLIGHTMAP_ON
			#pragma vertex vert
			#pragma fragment frag
			//#pragma multi_compile_instancing
			#include "UnityCG.cginc"
			#include "AutoLight.cginc"	
			#include "Lighting.cginc"
			struct a2v
			{
					float4 vertex: POSITION;
					float2 uv: TEXCOORD0;
					float2 uv1: TEXCOORD1;
					UNITY_VERTEX_INPUT_INSTANCE_ID
				};
				struct v2f
				{
					float4 pos: SV_POSITION;
					float4 uv: TEXCOORD0;
					float3 posWorld :TEXCOORD1;
			#if defined(LIGHTMAP_ON) || defined(_CUSTOMLIGHTMAP_ON)
				#if defined(LIGHTMAP_ON) && defined(_CUSTOMLIGHTMAP_ON)
					float4 lightmapUV: TEXCOORD2;
				#else
					float2 lightmapUV: TEXCOORD2;
				#endif
			#endif
					SHADOW_COORDS(3)
				};
				sampler2D	_MainTex;
				half4		_MainTex_ST;
				half		_FogStart;
				half		_FogEnd;
				half		_ShadowStrength;
				half		_BrightnessForScene;
				fixed4		_FogColor;
				fixed4		_Color;

		#if defined(_CUSTOMLIGHTMAP_ON)
				sampler2D _LightMapCustom;
				half4 _LightMapCustom_ST;
				fixed _LightMapIntensity;
			#ifdef LIGHTMAP_ON
				#define CUSTOMLIGHTMAPUV lightmapUV.zw
			#else
				#define CUSTOMLIGHTMAPUV lightmapUV.xy
			#endif
		#endif
			
				fixed3 SimulateFog(float3 worldPos, fixed3 col)
				{
					//half dist = length(_WorldSpaceCameraPos.xyz - worldPos);  
					//修改运动相机的fog改变 2018.9.3-jaffhan
					half dist = length(half3(0.0, 0.0, 0.0) - worldPos);
					half fogFactor = (_FogEnd - dist) / (_FogEnd - _FogStart);
					fogFactor = saturate(fogFactor);
					fixed3 afterFog = lerp(_FogColor.rgb, col.rgb, fogFactor);
					return afterFog;
				}
				// vertex shader
				v2f vert(a2v v)
				{
					v2f o;
					UNITY_SETUP_INSTANCE_ID(v);
					o.pos = UnityObjectToClipPos(v.vertex);
					o.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
					o.uv.zw = v.uv1;
	#ifdef LIGHTMAP_ON
					o.lightmapUV.xy = v.uv1 * unity_LightmapST.xy + unity_LightmapST.zw;
	#endif
	#ifdef _CUSTOMLIGHTMAP_ON
					o.CUSTOMLIGHTMAPUV = TRANSFORM_TEX(v.uv, _LightMapCustom);
	#endif
					o.posWorld = mul(unity_ObjectToWorld, v.vertex).xyz;
					TRANSFER_SHADOW(o);
					return o;
				}
				// fragment shader
				fixed4 frag(v2f i) : SV_Target
				{
					fixed4 col = tex2D(_MainTex, i.uv.xy)*_Color;
					#ifdef LIGHTMAP_ON
						fixed4 light = UNITY_SAMPLE_TEX2D(unity_Lightmap, i.lightmapUV.xy);
						light = fixed4(DecodeLightmap(light), 1.0);
						col.rgb *= light;
					#endif
					#ifdef _CUSTOMLIGHTMAP_ON
						fixed4 customLightmap = tex2D(_LightMapCustom, i.CUSTOMLIGHTMAPUV);
						col.rgb = col.rgb + (customLightmap * 2.0 - 1.0) * customLightmap.a * _LightMapIntensity;
					#endif
						col.rgb = SimulateFog(i.posWorld, col.rgb) + i.uv.zww * 0.0f;
						half atten = SHADOW_ATTENUATION(i);
						atten = lerp(1.0, atten, _ShadowStrength);
						col.rgb *= atten;
						col.rgb *= _BrightnessForScene;
					return fixed4(col.rgb, 1.0);
				}
				ENDCG

			}
			Pass
			{
				Name "FORWARD_DELTA"
				Tags { "LightMode" = "ForwardAdd" }
				Blend One One
				ZWrite Off
				CGPROGRAM
				#pragma target 3.0
				#pragma vertex vert
				#pragma fragment frag
				#pragma multi_compile_fwdadd  
				#pragma skip_variants LIGHTMAP_SHADOW_MIXING SHADOWS_SCREEN LIGHTPROBE_SH SPOT DIRECTIONAL_COOKIE POINT_COOKIE SHADOWS_CUBE
				//#pragma multi_compile_instancing
				#include "UnityCG.cginc"
				#include "AutoLight.cginc"	
				#include "Lighting.cginc"
				struct a2v
				{
					float4 vertex: POSITION;
					float2 uv: TEXCOORD0;
					UNITY_VERTEX_INPUT_INSTANCE_ID
				};
				struct v2f
				{
					float4 pos: SV_POSITION;
					float2 uv: TEXCOORD0;
					float3 posWorld :TEXCOORD1;
					UNITY_SHADOW_COORDS(3)
				};
				sampler2D	_MainTex;
				half4		_MainTex_ST;
				half		_BrightnessForScene;
				fixed4		_Color;
				// vertex shader
				v2f vert(a2v v)
				{
					v2f o;
					UNITY_SETUP_INSTANCE_ID(v);
					o.pos = UnityObjectToClipPos(v.vertex);
					o.uv = TRANSFORM_TEX(v.uv, _MainTex);
					o.posWorld = mul(unity_ObjectToWorld, v.vertex).xyz;
					UNITY_TRANSFER_SHADOW(o, v.uv1);
					return o;
				}
				// fragment shader
				fixed4 frag(v2f i) : SV_Target
				{
					fixed4 col = tex2D(_MainTex, i.uv)*_Color;
					UNITY_LIGHT_ATTENUATION(atten, i, i.posWorld);
					col.rgb *= atten * _LightColor0.xyz;
					col.rgb *= _BrightnessForScene;
					return fixed4(col.rgb, 1.0);
				}
			ENDCG

		}
		Pass
		{
			Name "ShadowCaster"
			Tags{ "LightMode" = "ShadowCaster" }
			CGPROGRAM
			#pragma target 3.0
			#pragma vertex vert_shadow
			#pragma fragment frag_shadow
			//#pragma multi_compile_instancing
			#pragma multi_compile_shadowcaster
			#pragma skip_variants SHADOWS_CUBE
			#include "UnityCG.cginc"
			struct v2f_shadow
			{
				V2F_SHADOW_CASTER;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};
			v2f_shadow vert_shadow(appdata_base v)
			{
				v2f_shadow o;
				UNITY_SETUP_INSTANCE_ID(v);
				TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
				return o;
			}
			float4 frag_shadow(v2f_shadow i) : COLOR
			{
				SHADOW_CASTER_FRAGMENT(i)
			}
			ENDCG
		}
	}
	CustomEditor "CustomShaderGUI.LGameSceneStarActorLightmapShaderGUI"
}
