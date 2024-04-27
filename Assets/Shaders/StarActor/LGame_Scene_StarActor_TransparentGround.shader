Shader "LGame/Scene/StarActor/Transparent Ground"
{
    Properties
    {
		_MainTex("Base (RGBA)", 2D) = "white" {}
    	_Color ("Base Color", Color) = (1,1,1,1)
		[Header(Shadow)]
		_ShadowStrength("Self Shadow Strength" , Range(0,1)) = 1
    }   
		SubShader
		{
			Tags { "Queue" = "AlphaTest" "RenderType" = "AlphaTest" }
			LOD 100
			Cull Off
			Blend SrcAlpha OneMinusSrcAlpha
			Stencil {
				Ref 0
				Comp always
				Pass replace
			}
			Pass
			{
				Name "FORWARD"
				Tags { "LightMode" = "ForwardBase" }
				CGPROGRAM
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
					UNITY_SHADOW_COORDS(3)
				};
				sampler2D _MainTex;
				fixed4 _Color;
				half _ShadowStrength;
				float4 _MainTex_ST;
				v2f vert(appdata v)
				{
					v2f o;
					UNITY_SETUP_INSTANCE_ID(v);
					half3 posWorld = mul(unity_ObjectToWorld, v.vertex).xyz;
					o.pos = UnityObjectToClipPos(v.vertex);
					o.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
					o.uv.zw = v.uv1;
					#ifdef LIGHTMAP_ON
						o.lightmapUV = v.uv1 * unity_LightmapST.xy + unity_LightmapST.zw;;
					#endif
					o.posWorld = posWorld;
					UNITY_TRANSFER_SHADOW(o, v.uv1);
					return o;
				}
				fixed4 frag(v2f i) : SV_Target
				{
					fixed4 col = tex2D(_MainTex, i.uv.xy) * _Color;
					#ifdef LIGHTMAP_ON
						fixed4 light = UNITY_SAMPLE_TEX2D(unity_Lightmap, i.lightmapUV);
						light = fixed4(DecodeLightmap(light), 1);
						col *= light;
					#endif
					UNITY_LIGHT_ATTENUATION(atten, i, i.posWorld);
					atten = lerp(1.0, atten, _ShadowStrength);
					col.rgb *= atten;
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
				#pragma vertex vert
				#pragma fragment frag
				//#pragma multi_compile_instancing
				#pragma multi_compile_fwdadd
				#pragma skip_variants LIGHTMAP_SHADOW_MIXING LIGHTPROBE_SH SHADOWS_SCREEN SPOT DIRECTIONAL_COOKIE POINT_COOKIE
				#pragma target 3.0
				#include "UnityCG.cginc"
				#include "AutoLight.cginc"	
				#include "Lighting.cginc"	
				struct VertexInput
				{
					half4 vertex : POSITION;
					half3 normal : NORMAL;
					float2 uv:TEXCOORD0;
					float2 uv2:TEXCOORD2;
					UNITY_VERTEX_INPUT_INSTANCE_ID
				};
				struct VertexOutput
				{
					half4 vertex : SV_POSITION;
					half2 uv : TEXCOORD0;
					half3 normal:TEXCOORD1;
					LIGHTING_COORDS(2, 3)
				};
				sampler2D _MainTex;
				fixed4 _Color;
				float4 _MainTex_ST;
				VertexOutput vert(VertexInput v)
				{
					VertexOutput o;
					UNITY_SETUP_INSTANCE_ID(v);
					o.uv = TRANSFORM_TEX(v.uv, _MainTex);
					o.vertex = UnityObjectToClipPos(v.vertex);
					o.normal = UnityObjectToWorldNormal(v.normal);
					TRANSFER_VERTEX_TO_FRAGMENT(o)
					return o;
				}
				fixed4 frag(VertexOutput i) : SV_Target
				{
					fixed4 col = tex2D(_MainTex, i.uv) * _Color;
					col.rgb *= LIGHT_ATTENUATION(i) * _LightColor0.xyz;
					return fixed4(col.rgb * col.a,1.0);
				}
				ENDCG
			}
			Pass
			{
				Name "ShadowCaster"
				Tags{ "LightMode" = "ShadowCaster" }
				Fog{ Mode Off }
				ZWrite On ZTest Less Cull Off
				CGPROGRAM
				#pragma vertex vert_shadow
				#pragma fragment frag_shadow
				//#pragma multi_compile_instancing
				#pragma multi_compile_shadowcaster
				#pragma skip_variants SHADOWS_CUBE
				#include "UnityCG.cginc"
				struct a2v_shadow
				{
					half4 vertex : POSITION;
					half3 normal : NORMAL;
					half2 uv:TEXCOORD0;
				};
				struct v2f_shadow {
					V2F_SHADOW_CASTER;
				};
				v2f_shadow vert_shadow(a2v_shadow v)
				{
					v2f_shadow o;
					o.pos = UnityObjectToClipPos(v.vertex);
					TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
					return o;
				}
				float4 frag_shadow(v2f_shadow i) : SV_Target
				{
					SHADOW_CASTER_FRAGMENT(i)
				}
				ENDCG
			}
		}
}
