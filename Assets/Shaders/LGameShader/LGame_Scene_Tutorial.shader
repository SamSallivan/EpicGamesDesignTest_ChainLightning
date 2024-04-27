Shader "LGame/Scene/Tutorial"
{
	Properties
	{
		_MainTex("Texture", 2D) = "white" {}
		_LightMap("LightMap", 2D) = "gray" {}
		_LightMapIntensity("LightMap Intensity",  Range(0,1)) = 1
		_AmbientCol("Ambient Color" , Color) = (0,0,0,0)
		_NoiseMap("Noise Map",2D) = "white"{}
		_FlowMap("Flow Map",2D) = "black"{}
		_DistortionMap("Distortion Map",2D) = "black"{}
		[Enum(MODEL,0,WORLD,1)]_EffectUVType("Effect UV Type",Float) = 0.0
		_FlowScale("Flow Value", Range(0, 2)) = 0
		[HDR]_Color("Color",Color) = (1.0,1.0,1.0,1.0)
		[HDR]_DissolveColor("Dissolve Color",Color) = (1.0,1.0,1.0,1.0)
		_RimColor("Rim Color",Color) = (1.0,1.0,1.0,1.0)
		_RimPower("Rim Power",Range(0.0,16.0)) = 4.0
		_AlphaClip("Alpha Clip",Range(0.0,1.0)) = 0.5
		_GradientWidth("Gradient Width",Range(0.0,1.0)) = 0.25
		_DissolveWidth("Dissolve Width",Range(0.0,1.0)) = 0.1
		_Scale("Scale",Float) = 0.01
	}
		CGINCLUDE
			float3 _Pivot;
		half _EffectUVType;
		float _Offset;
		float _Scale;
		float _AlphaClip;
		float _GradientWidth;
		float _DissolveWidth;
		sampler2D _NoiseMap;
		sampler2D _MainTex;
		float4 _NoiseMap_ST;
		float4 _MainTex_ST;
		ENDCG
			SubShader
		{
			Tags { "RenderType" = "AlphaTest" "Queue" = "AlphaTest" }
			LOD 100
			Pass
			{
				Tags{ "LightMode" = "ForwardBase" }
				Zwrite On
				Cull Back
				CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag
				#pragma multi_compile __ _SOFTSHADOW_ON
				#include "UnityCG.cginc" 

				struct appdata
				{
					float4 vertex : POSITION;
					float2 uv : TEXCOORD0;
					float2 uv1 : TEXCOORD1;
					float3 normal:NORMAL;
				};

				struct v2f
				{
					float4 vertex : SV_POSITION;
					float4 uv : TEXCOORD0;
					fixed4 color : COLOR;
					float4 screenPos:TEXCOORD1;
					float3 wPos:TEXCOORD2;
					half3 viewDir:TEXCOORD3;
					half3 wNormal:TEXCOORD4;
					float4 effect:TEXCOORD5;
#if _SOFTSHADOW_ON
					half4 srcPos	: TEXCOORD6;
#endif
				};
				sampler2D	_DistortionMap;
				sampler2D	_FlowMap;
				sampler2D	_LightMap;
				float4		_FlowMap_ST;
				float4		_DistortionMap_ST;
				fixed4		_Color;
				fixed4		_DissolveColor;
				fixed4		_RimColor;
				fixed4		_AmbientCol;
				half		_RimPower;
				half		_FlowScale;
				half		_Brightness;
				half		_LightMapIntensity;

#if _SOFTSHADOW_ON
				fixed4 _SoftShadowColor;
				sampler2D _Temp1;
#endif
				v2f vert(appdata v)
				{
					v2f o;
					o.vertex = UnityObjectToClipPos(v.vertex);
					o.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
					o.uv.zw = v.uv1;
					o.screenPos = ComputeScreenPos(o.vertex);
					o.wPos = mul(unity_ObjectToWorld, v.vertex).xyz;
					float2 base_uv = lerp(v.uv, o.wPos.xz, _EffectUVType);
					o.effect.xy = base_uv * _FlowMap_ST.xy + frac(_FlowMap_ST.zw * _Time.x);
					o.effect.zw = base_uv * _DistortionMap_ST.xy + frac(_DistortionMap_ST.zw * _Time.x);
					o.wNormal = UnityObjectToWorldNormal(v.normal);
					o.viewDir = UnityWorldSpaceViewDir(o.wPos);
					o.color = saturate(o.wPos.y * 2);
#if _SOFTSHADOW_ON
					o.srcPos = ComputeScreenPos(o.vertex);
#endif

					return o;
				}

				fixed4 frag(v2f i) : SV_Target
				{
					half3 V = normalize(i.viewDir);
					half3 N = normalize(i.wNormal);
					half NoV = saturate(dot(N, V));
					half fresnel = pow(1.0 - NoV, _RimPower);

					float temp = length(i.wPos - _Pivot)*_Scale;
					temp = 1.0 - smoothstep(_Offset - _GradientWidth, _Offset, temp);
					fixed4 col = tex2D(_MainTex, i.uv.xy);

					fixed3 lightMap = tex2D(_LightMap, i.uv.zw);
					col.rgb += (lightMap * 2.0 - 1.0) * _LightMapIntensity;
					col.rgb *= 1.0 + _AmbientCol;

					col.rgb *= 1.0 + _Brightness;
					clip(col.a - 0.5);
					float2 screen_uv = i.screenPos.xy / i.screenPos.w;
					float2 flow_uv = i.effect.xy;
					float2 distortion_uv = i.effect.zw;
					float distortion = tex2D(_DistortionMap, frac(distortion_uv)).r * _FlowScale;
					fixed3 flow = tex2D(_FlowMap, frac(flow_uv + distortion));
					half noise = tex2D(_NoiseMap, frac(screen_uv*_NoiseMap_ST.xy + _NoiseMap_ST.zw)).r;
					half alpha = (1.0 - saturate(temp + noise * temp));

					fixed3 result = fresnel * _RimColor + lerp(col.rgb, flow.rgb * _Color.rgb, _Color.a);
					half gradient = smoothstep(_AlphaClip, _AlphaClip + _DissolveWidth, alpha);
					fixed3 blend = lerp(col.rgb, _DissolveColor.rgb, gradient);
					result = lerp(blend.rgb, result.rgb, gradient);
					result = lerp(result, col.rgb, temp);
					half shadow;
#if _SOFTSHADOW_ON
					half shadowMask = float3(1, 1, 1) - i.color.rrr;
					shadow = tex2D(_Temp1, i.srcPos.xy / i.srcPos.w).b * shadowMask;
					col.rgb = lerp(col.rgb, _SoftShadowColor.rgb, shadow);
#endif
					return fixed4(col.rgb,1.0);
				}
				ENDCG
			}
			Pass
			{
				Name "FORWARD ADD"
				Tags{ "LightMode" = "ForwardAdd" }
				ZWrite Off
				Blend One One
				CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag	
				#pragma multi_compile_fwdadd
				#pragma target 3.0
				#include "UnityCG.cginc"
				#include "AutoLight.cginc"	
				#include "Lighting.cginc"	
				struct appdata
				{
					float4 vertex	: POSITION;
					float2 uv		: TEXCOORD0;
				};
				struct v2f
				{
					float4 vertex	: SV_POSITION;
					float2 uv		: TEXCOORD0;
					float4 screenPos:TEXCOORD1;
					float3 wPos		:TEXCOORD2;
				};
				fixed4 _Color;
				v2f vert(appdata v)
				{
					v2f o;
					o.vertex = UnityObjectToClipPos(v.vertex);
					o.uv = TRANSFORM_TEX(v.uv, _MainTex);
					o.screenPos = ComputeScreenPos(o.vertex);
					o.wPos = mul(unity_ObjectToWorld, v.vertex).xyz;
					return o;
				}
				fixed4 frag(v2f i) : SV_Target
				{
					float temp = length(i.wPos - _Pivot) * _Scale;
					temp = 1.0 - smoothstep(_Offset - _GradientWidth, _Offset, temp);
					fixed4 col = tex2D(_MainTex, i.uv.xy);
					clip(col.a - 0.5);
					float2 screen_uv = i.screenPos.xy / i.screenPos.w;
					half noise = tex2D(_NoiseMap, frac(screen_uv * _NoiseMap_ST.xy + _NoiseMap_ST.zw));
					half alpha = (1.0 - saturate(temp + noise * temp));
					half gradient = smoothstep(_AlphaClip, _AlphaClip + _DissolveWidth, alpha);
					UNITY_LIGHT_ATTENUATION(atten,i,i.wPos);
					fixed3 attenColor = atten * _LightColor0.xyz;
					return fixed4(attenColor * gradient, 1.0);
				}
				ENDCG
			}
		}
}
