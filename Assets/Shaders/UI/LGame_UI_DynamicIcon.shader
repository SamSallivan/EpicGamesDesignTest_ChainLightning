Shader "LGame/UI/DynamicIcon" {
	Properties {
		_Cutoff ("Shadow alpha cutoff", Range(0,1)) = 0.1
		[NoScaleOffset] _MainTex ("Main Texture", 2D) = "black" {}
		[HideInInspector][Enum(UnityEngine.Rendering.BlendMode)] 		_SrcFactor("SrcFactor()", Float) = 1
		[HideInInspector][Enum(UnityEngine.Rendering.BlendMode)] 		_DstFactor("DstFactor()", Float) = 10
		[HideInInspector][Enum(UnityEngine.Rendering.BlendMode)] 		_SrcAlphaFactor("SrcAlphaFactor()", Float) = 1
		[HideInInspector][Enum(UnityEngine.Rendering.BlendMode)] 		_DstAlphaFactor("DstAlphaFactor()", Float) = 10
	}
	SubShader {
		Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" }
		Fog { Mode Off }
		Cull Off
		ZWrite Off
		Blend[_SrcFactor][_DstFactor],[_SrcAlphaFactor][_DstAlphaFactor]
		Lighting Off
		//Pass {
		//	Fog { Mode Off }
		//	Tags { "LightMode" = "ForwardBase" }
		//	ColorMaterial AmbientAndDiffuse
		//	SetTexture [_MainTex] {
		//		Combine texture * primary
		//	}
		//}
		Pass {
			Fog { Mode Off }
			Tags { "LightMode" = "ForwardBase" }
			ColorMaterial AmbientAndDiffuse
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 2.0
			#pragma multi_compile __ RectClip_On
			#if RectClip_On
				float4 _EffectClipRect;
			#endif
			sampler2D _MainTex;
			struct appdata_t
			{
		       float4 vertex    : POSITION;
		       float4 color     : COLOR;
		       float2 texcoord0 : TEXCOORD0;
			};
			struct v2f
			{
		       float4 vertex   : SV_POSITION;
		       float4 color : COLOR;
		       float2 texcoord0 : TEXCOORD0;
#if RectClip_On
				float3 worldPos        : TEXCOORD1;
#endif
			};
			inline float Get2DClipping(in float2 position, in float4 clipRect)
			{
				float2 inside = step(clipRect.xy, position.xy) * step(position.xy, clipRect.zw);
				return inside.x * inside.y;
			}
			v2f vert(appdata_t IN)
			{
				  v2f OUT = (v2f)0;
	
				  OUT.vertex = UnityObjectToClipPos(IN.vertex);
				  OUT.texcoord0 = IN.texcoord0;
				  OUT.color = IN.color;
#if RectClip_On
				  OUT.worldPos = mul(unity_ObjectToWorld, float4(IN.vertex.xyz, 1.0)).xyz;
#endif
				  return OUT;
			}
			fixed4 frag(v2f IN) : SV_Target
			{
			     fixed4 color = tex2D(_MainTex, IN.texcoord0) * IN.color;
	
				 #if RectClip_On
					color.rgba *= Get2DClipping(IN.worldPos.xy , _EffectClipRect);
				 #endif
	
			     return color;
            }
			ENDCG
		}
		Pass {
			Name "Caster"
			Tags { "LightMode"="ShadowCaster" }
			Offset 1, 1
			ZWrite On
			ZTest LEqual
			Fog { Mode Off }
			Cull Off
			Lighting Off
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_shadowcaster
			#pragma fragmentoption ARB_precision_hint_fastest
			#include "UnityCG.cginc"
			sampler2D _MainTex;
			fixed _Cutoff;
			struct v2f { 
				V2F_SHADOW_CASTER;
				float2  uv : TEXCOORD1;
			};
			v2f vert (appdata_base v) {
				v2f o;
				TRANSFER_SHADOW_CASTER(o)
				o.uv = v.texcoord;
				return o;
			}
			float4 frag (v2f i) : COLOR {
				fixed4 texcol = tex2D(_MainTex, i.uv);
	
				clip(texcol.a - _Cutoff);
				SHADOW_CASTER_FRAGMENT(i)
			}
			ENDCG
		}
	}
	SubShader {
		Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" }
		Cull Off
		ZWrite Off
		Blend One OneMinusSrcAlpha
		Lighting Off
		Pass {
			Tags { "LightMode" = "ForwardBase" }
			ColorMaterial AmbientAndDiffuse
			SetTexture [_MainTex] {
				Combine texture * primary DOUBLE, texture * primary
			}
		}
	}
}