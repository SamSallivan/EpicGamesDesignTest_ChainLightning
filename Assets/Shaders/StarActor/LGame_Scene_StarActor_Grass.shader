Shader "LGame/Scene/StarActor/Grass"
{
	Properties
	{
		_Color("Color",Color) = (1.0,1.0,1.0,1.0)
		_RootColor("Root Color",Color)=(1.0,1.0,1.0,1.0)
		_TipColor("Tip Color",Color) = (1.0,1.0,1.0,1.0)
		_MainTex("Main Texture",2D) = "white"{}
		[Header(Wind)]
		_WindParams("Wind WaveStrength(X), WaveSpeed(Y)", Vector) = (0.3, 1.2, 0.0, 0.0)
		_WindRotation("Wind Rotation", Range(0, 6.28318530718)) = 0.0
		[Header(Fog)]
		_FogColor("Fog Color",Color) = (0.0,0.0,0.0,1.0)
		_FogStart("Fog Start",float) = 0.0
		_FogEnd("Fog End",float) = 300.0
		[Header(Shadow)]
		_ShadowStrength("Self Shadow Strength" , Range(0,1)) = 1.0
		[HideInInspector]_BrightnessForScene("",Range(0,1)) = 1.0
	}
	CGINCLUDE
		float4 _WindParams;
		fixed _WindRotation;
		fixed4 _Color;
		sampler2D _MainTex;
		float windStrength(float3 pos)
		{
			return pos.x + _Time.w * _WindParams.y 
				+ 5.0f * cos(0.01f * pos.z + _Time.y * _WindParams.y * 0.2f) 
				+ 4.0f * sin(0.05f * pos.z - _Time.y * _WindParams.y * 0.15f) 
				+ 4.0f * sin(0.2f * pos.z + _Time.y * _WindParams.y * 0.2f) 
				+ 2.0f * cos(0.6f * pos.z - _Time.y * _WindParams.y * 0.4f);
		}
		float2 wind(float3 pos)
		{
			float Strength = windStrength(pos);
			return _WindParams.x * sin(0.7f * Strength) * cos(0.15f * Strength);
		}
		float2 wind(float3 pos, float rotation)
		{
			float3 realPos = float3(
				pos.x * cos(rotation) - pos.z * sin(rotation), 
				pos.y, 
				pos.x * sin(rotation) + pos.z * cos(rotation)
				);
			float2 windValue = wind(realPos);
			return float2(windValue.x * cos(rotation) - windValue.y * sin(rotation), 
				windValue.x * sin(rotation) + windValue.y * cos(rotation));
		}
	ENDCG
	SubShader
	{
		Tags { "Queue" = "AlphaTest" "RenderType" = "AlphaTest" }
		LOD 300
		Cull Off
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
			#pragma vertex vert
			#pragma fragment frag
			//#pragma multi_compile_instancing
			#include "AutoLight.cginc"	
			#include "Lighting.cginc"	
			#include "UnityCG.cginc"
			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv:TEXCOORD0;
				float2 uv1:TEXCOORD1;
				float2 uv2:TEXCOORD2;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};
			struct v2f
			{
				float4 pos : SV_POSITION;
				float4 uv:TEXCOORD0;
				float3 posWorld:TEXCOORD1;
#ifdef LIGHTMAP_ON
				float2 lightmapUV:TEXCOORD2;
#endif
				SHADOW_COORDS(3)
			};
			half		_FogStart;
			half		_FogEnd;
			half		_ShadowStrength;
			half		_BrightnessForScene;
			fixed4		_RootColor;
			fixed4		_TipColor;
			fixed4		_FogColor;
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
			v2f vert (appdata v)
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID(v);
				float3 posWorld = mul(unity_ObjectToWorld, v.vertex).xyz;
				float2 windDir = wind(posWorld, _WindRotation);
				posWorld.xz += windDir.xy * v.uv2.y;
				posWorld.y -= length(windDir) *  v.uv2.y * 0.5f;
				o.pos = mul(UNITY_MATRIX_VP, float4(posWorld, 1.0f));
				o.uv.xy= v.uv;
				o.uv.zw = v.uv1;
				#ifdef LIGHTMAP_ON
					o.lightmapUV = v.uv1 * unity_LightmapST.xy + unity_LightmapST.zw;;
				#endif
				o.posWorld = posWorld;
				TRANSFER_SHADOW(o);
				return o;
			}	
			fixed4 frag (v2f i) : SV_Target
			{
				fixed4 col = tex2D(_MainTex, i.uv.xy)*lerp(_RootColor, _TipColor, i.uv.w)*_Color;
				clip(col.a - 0.5);
				#ifdef LIGHTMAP_ON
					fixed4 light = UNITY_SAMPLE_TEX2D(unity_Lightmap, i.lightmapUV);
					light = fixed4(DecodeLightmap(light), 1.0);
					col *= light;
				#endif
				col.rgb = SimulateFog(i.posWorld, col.rgb) + i.uv.zww * 0.0;
				half atten = SHADOW_ATTENUATION(i);
				atten = lerp(1.0, atten, _ShadowStrength);
				col.rgb *= atten;
				col.rgb *= _BrightnessForScene;
				return col;
			}
			ENDCG
		}
		Pass{
			Name "FORWARD_DELTA"
			Tags{ "LightMode" = "ForwardAdd" }
			Blend One One
			Zwrite Off
			CGPROGRAM
			#pragma target 3.0
			#pragma vertex vert
			#pragma fragment frag
			//#pragma multi_compile_instancing
			#pragma multi_compile_fwdadd
			#pragma skip_variants LIGHTMAP_SHADOW_MIXING LIGHTPROBE_SH SHADOWS_SCREEN SPOT DIRECTIONAL_COOKIE POINT_COOKIE
			#include "UnityCG.cginc"
			#include "AutoLight.cginc"	
			#include "Lighting.cginc"	
			struct VertexInput
			{
				float4 vertex : POSITION;
				float2 uv:TEXCOORD0;
				float2 uv2:TEXCOORD2;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};
			struct VertexOutput
			{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
				float3 posWorld : TEXCOORD1;
				UNITY_SHADOW_COORDS(2)
			};
			half		_BrightnessForScene;
			VertexOutput vert(VertexInput v)
			{
				VertexOutput o;
				UNITY_SETUP_INSTANCE_ID(v);
				o.uv = v.uv;
				o.posWorld = mul(unity_ObjectToWorld, v.vertex).xyz;
				float2 windDir = wind(o.posWorld, _WindRotation);
				o.posWorld.xz += windDir.xy * v.uv2.y;
				o.posWorld.y -= length(windDir) *  v.uv2.y * 0.5f;
				o.vertex = mul(UNITY_MATRIX_VP, float4(o.posWorld, 1.0f));
				UNITY_TRANSFER_SHADOW(o, v.uv2);
				return o;
			}
			fixed4 frag(VertexOutput i) : SV_Target
			{ 
				fixed4 col = tex2D(_MainTex, i.uv)*_Color;
				clip(col.a - 0.5);
				UNITY_LIGHT_ATTENUATION(atten, i, i.posWorld);
				fixed3 attenColor = atten * _LightColor0.xyz;
				col.rgb *= attenColor.rgb;
				col.rgb *= _BrightnessForScene;
				return fixed4(col.rgb,1.0);
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
			struct appdata
			{
				float4 vertex : POSITION;
				half3 normal : NORMAL;
				float2 uv:TEXCOORD0;
				float2 uv2:TEXCOORD2;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};
			struct v2f_shadow
			{
				float4 vertex : SV_POSITION;
				float2 uv:TEXCOORD0;
			};
			v2f_shadow vert_shadow(appdata v)
			{
				v2f_shadow o;
				UNITY_SETUP_INSTANCE_ID(v);
				o.uv = v.uv;
				float3 wPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				float2 windDir = wind(wPos, _WindRotation);
				wPos.xz += windDir.xy * v.uv2.y;
				wPos.y -= length(windDir) *  v.uv2.y * 0.5f;
				o.vertex = mul(UNITY_MATRIX_VP, float4(wPos, 1.0f));
				return o;
			}
			float4 frag_shadow(v2f_shadow i) : COLOR
			{
				fixed4 col = tex2D(_MainTex, i.uv)*_Color;;
				clip(col.a - 0.5);
				SHADOW_CASTER_FRAGMENT(i)
			}
			ENDCG
		}
	}
}
