Shader "Spine/Spine-Skeleton-AlphaTex_Test" {
	Properties {
		_Cutoff ("Shadow alpha cutoff", Range(0,1)) = 0.1
		[NoScaleOffset] _MainTex ("Main Texture", 2D) = "black" {}
		//[NoScaleOffset] _AlphaTex ("Alpha Texture", 2D) = "while" {}
		_AlphaCtrl("Alpha Control", Range(0, 1)) = 1
		[HideInInspector][Enum(UnityEngine.Rendering.BlendMode)] 		_SrcFactor("SrcFactor()", Float) = 5
		[HideInInspector][Enum(UnityEngine.Rendering.BlendMode)] 		_DstFactor("DstFactor()", Float) = 10
		[HideInInspector][Enum(UnityEngine.Rendering.BlendMode)] 		_SrcAlphaFactor("SrcAlphaFactor()", Float) = 5
		[HideInInspector][Enum(UnityEngine.Rendering.BlendMode)] 		_DstAlphaFactor("DstAlphaFactor()", Float) = 10
	}

	SubShader {
		Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" }

		Fog { Mode Off }
		Cull Off
		ZWrite Off
		Blend[_SrcFactor][_DstFactor],[_SrcAlphaFactor][_DstAlphaFactor]
		Lighting Off

		Pass {
			Name "ForwardBase"
			Tags { "LightMode" = "ForwardBase" }
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma fragmentoption ARB_precision_hint_fastest
			#pragma multi_compile __ RectClip_On
			#include "UnityCG.cginc"
			#include "UnityUI.cginc"
			sampler2D _MainTex;// , _AlphaTex;
			fixed _Cutoff;
			fixed _AlphaCtrl;

			struct a2v {
				float4 vertex : POSITION;
				float4 texcoord : TEXCOORD0;
				fixed4 color : COLOR;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct v2f { 
				float4 pos : SV_POSITION;
				float2  uv : TEXCOORD0; 
#if RectClip_On
				float3 worldPos        : TEXCOORD3;
#endif
				fixed4 color : COLOR0;
				UNITY_VERTEX_OUTPUT_STEREO
			};
			/*
			inline float Get2DClipping(in float2 position, in float4 clipRect)
			{
				float2 inside = step(clipRect.xy, position.xy) * step(position.xy, clipRect.zw);
				return inside.x * inside.y;
			}
			*/
			v2f vert (a2v v) {
				v2f o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
				o.pos = UnityObjectToClipPos(v.vertex) ;
				o.uv = v.texcoord;
				o.color = v.color;
				//o.color.a *= _AlphaCtrl;
#if RectClip_On
				o.worldPos = mul(unity_ObjectToWorld, float4(v.vertex.xyz, 1.0)).xyz;
#endif
				return o;
			}

#if RectClip_On
			float4      _EffectClipRect;
#endif

			float4 frag (v2f i) : SV_Target {
				fixed4 texcol = tex2D(_MainTex, i.uv) * i.color;
				//fixed alpha = tex2D(_AlphaTex, i.uv).r;
				//clip(alpha - _Cutoff);
				//return fixed4(texcol.rgb, alpha) * i.color;
#if RectClip_On
				texcol *= UnityGet2DClipping(i.worldPos.xy, _EffectClipRect); //float4(991.7388, 997.4133, 999.3387, 1002.4));;
#endif
				return texcol * _AlphaCtrl;
			}
			ENDCG
		}
	}

}
