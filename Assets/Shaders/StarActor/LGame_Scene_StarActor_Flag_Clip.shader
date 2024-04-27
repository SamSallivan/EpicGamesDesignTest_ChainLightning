Shader "LGame/Scene/StarActor/Flag/Clip"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		[NoScaleOffset]_MaskTex("Mask", 2D) = "white" {}
		[NoScaleOffset]_MatCap("MatCap",2D) = "black"{}
		_DetailNormalMap("Detail Normal",2D) = "bump"{}
		_AmbientColor("Ambient",Color)=(0.5,0.5,0.5,0)
		_Wind("Wind",Vector) = (1,1,0,0)
		[Header(Fog)]
		_FogColor("Fog Color",Color) = (0,0,0,1)
		_FogStart("Fog Start",float) = 0
		_FogEnd("Fog End",float) = 300
		[HideInInspector]_BrightnessForScene("",Range(0,1)) = 1.0
	}
	SubShader
	{
		Tags { "RenderType"="AlphaTest" "Queue"="AlphaTest" }
		LOD 100
		Cull Off
		Pass
		{	
			Name "FORWARD"
			Tags { "LightMode" = "ForwardBase" }
			CGPROGRAM
			#pragma multi_compile_fwdbase nolightmap nodirlightmap nodynlightmap novertexlight noshadowmask  
			#pragma skip_variants LIGHTMAP_SHADOW_MIXING LIGHTPROBE_SH SPOT DIRECTIONAL_COOKIE POINT_COOKIE SHADOWS_CUBE
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile _ _FASTEST_QUALITY
			#include "UnityCG.cginc"
			struct appdata
			{
				float4 vertex	: POSITION;
				float2 uv		: TEXCOORD0;
				float2 uv1		: TEXCOORD1;
				float3 normal	: NORMAL;
				float4 tangent	: TANGENT;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct v2f
			{
				float4 uv		: TEXCOORD0;
				float4 vertex	: SV_POSITION;
				float3 wPos		: TEXCOORD1;
#ifndef _FASTEST_QUALITY
				half4 tangent	: TEXCOORD2;
				half3 lightDir	: TEXCOORD3;
				half3 viewDir	: TEXCOORD4;
#endif
			};
			sampler2D	_MainTex;
			sampler2D	_MaskTex;
			sampler2D	_DetailNormalMap;
			sampler2D	_MatCap;
			float4		_MainTex_ST;
			float4		_DetailNormalMap_ST;
			float4		_Wind;
			half		_FogStart;
			half		_FogEnd;
			half		_Alpha;
			half		_BrightnessForScene;
			fixed4		_AmbientColor;
			fixed4		_FogColor;
			fixed3 SimulateFog(float3 worldPos, fixed3 col)
			{
				half dist = length(half3(0, 0, 0) - worldPos);
				half fogFactor = (_FogEnd - dist) / (_FogEnd - _FogStart);
				fogFactor = saturate(fogFactor);
				fixed3 afterFog = lerp(_FogColor.rgb, col.rgb, fogFactor);
				return afterFog;
			}
			float3 FlagOffset(half3 pos, half2 uv, half3 wind)
			{
				float3 offsets;
				half temp = pos.x + pos.y + pos.z;
				half fx = uv.x*0.5;
				half fy = uv.x*uv.y*0.75;
				offsets.x = sin(_Time.y*wind.x + temp)*fx;
				offsets.y = sin(_Time.y*wind.y + temp)*fx - fy;
				offsets.z = sin(_Time.y*wind.z + temp)*fx;
				return offsets;
			}
			half3 FlagNormal(half3 pos, half2 uv, half3 wind)
			{
				half3 normal = half3(0.0, 0.0, 2.0);
				half temp = pos.x + pos.y + pos.z;
				half fx = uv.x * 0.5;
				half fy = uv.x * uv.y * 0.9;
				normal.x = sin(_Time.y * wind.x + temp) * fx;
				normal.y = sin(_Time.y * wind.y + temp) * fx - fy;
				return normalize(normal);
			}
			v2f vert (appdata v)
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID(v);
				o.wPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				o.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
				o.uv.zw = TRANSFORM_TEX(v.uv1, _DetailNormalMap);
				float3 wind = normalize(_Wind.xyz)*_Wind.w;
				o.wPos += FlagOffset(o.wPos, v.uv1, wind);
				o.vertex = mul(UNITY_MATRIX_VP, float4(o.wPos, 1.0f));
#ifndef _FASTEST_QUALITY
				o.tangent.xyz = UnityObjectToWorldNormal(v.tangent.xyz);
				o.tangent.w = v.tangent.w;
				o.lightDir = UnityWorldSpaceLightDir(o.wPos);
				o.viewDir = UnityWorldSpaceViewDir(o.wPos);
#endif
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				fixed4 color = tex2D(_MainTex, i.uv.xy);
				clip(color.a - 0.5);
#ifndef _FASTEST_QUALITY
				half3 wind = normalize(_Wind.xyz) * _Wind.w;
				half3 N = FlagNormal(i.wPos, i.uv, wind);
				half3 T = normalize(i.tangent.xyz);
				half3 B = cross(T, N) * i.tangent.w * unity_WorldTransformParams.w;

				half3 V = normalize(i.viewDir);
				half3 L = normalize(i.lightDir);
				half3 R = reflect(-V, N);

				R.z += 1.0;
				half m = 2.0 * sqrt(dot(R, R));
				half2 matcapUV = R.xy / m + 0.5;
				half3 matcap = tex2D(_MatCap, matcapUV).rgb;
				half mask = tex2D(_MaskTex, i.uv.xy).r;
				color.rgb += mask * matcap;

				half3 detailN = UnpackNormal(tex2D(_DetailNormalMap, i.uv.zw));
				detailN = normalize(detailN.r * T + detailN.g * B + detailN.b * N);
				half NoL = abs(dot(detailN, L));
				color.rgb *= lerp(_AmbientColor.rgb, 1.0, NoL);
#endif
				color.rgb = SimulateFog(i.wPos, color.rgb);
				color.rgb *= _BrightnessForScene;
				return fixed4(color.rgb,1.0);
			}
			ENDCG
		}
	}
}
