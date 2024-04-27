// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

//By paulwu

Shader "Moba/SimpleRTBlur" {
    Properties {
		[PerRendererData] _MainTex("Sprite Texture", 2D) = "white" {}
	    _blurTexture("Blur Texture", 2D) = "white" {}
		_Color("BlendColor", Color) = (1,1,1,1)
	    _BorderBlend("Border Blend Range", vector) = (0,0,0,0)
    }


	// hight quality
    SubShader {
		Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" }
		LOD 100
		Cull Off
		Lighting Off
		ZWrite Off
		Fog { Mode Off }
		Offset -1, -1
		Blend SrcAlpha OneMinusSrcAlpha
 
        Pass {
            Tags { "LightMode" = "ForwardBase" }
               
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma fragmentoption ARB_precision_hint_fastest
            #include "UnityCG.cginc"
			#include "UnityUI.cginc"
               
            struct appdata_t {
                float4 vertex : POSITION;
				float2 texcoord: TEXCOORD0;
				fixed4 color : COLOR;
            };
               
            struct v2f {
                float4 vertex : POSITION;
				float2 uvgrab : TEXCOORD0;
				float4 worldPosition : TEXCOORD1;
				fixed4 color : COLOR;
            };
            
			float4 _ClipRect;
			float4 _BorderBlend;

			inline float GetSoft2DClipping(in float2 position, in float4 clipRect, in float4 borderBlend)
			{
				float2 inside = smoothstep(clipRect.xy, clipRect.xy + borderBlend.xy, position.xy) * smoothstep(clipRect.zw, clipRect.zw - borderBlend.zw, position.xy);
				return inside.x * inside.y;
			}

            v2f vert (appdata_t v) {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
				o.uvgrab = v.texcoord;
				//if (_ProjectionParams.x < 0)
				//	o.uvgrab.y = 1.0 - v.texcoord.y;
				o.worldPosition = v.vertex;
				o.color = v.color;
                return o;
            }
               
			sampler2D _blurTexture;
			fixed4 _Color;
               
            fixed4 frag( v2f i ) : COLOR {
				fixed4 color = tex2D(_blurTexture,i.uvgrab);
				color.rgb = lerp(_Color.rgb ,color.rgb, _Color.a);
				color.a = i.color.a;
				//color.a *= UnityGet2DClipping(i.worldPosition.xy, _ClipRect);
				color.a *= GetSoft2DClipping(i.worldPosition.xy, _ClipRect, _BorderBlend);
				return color;
            }
            ENDCG
        }
    
    }

	//// low quality
 //   SubShader {
	//	Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" }
	//	Blend SrcAlpha OneMinusSrcAlpha
	//	LOD 200
	//	Cull Off
	//	Lighting Off
	//	ZWrite Off
	//	Fog { Mode Off }
	//	Offset -1, -1

 
 //       Pass {
 //           Tags { "LightMode" = "Always" }
               
 //           CGPROGRAM
 //           #pragma vertex vert
 //           #pragma fragment frag
 //           #pragma fragmentoption ARB_precision_hint_fastest
 //           #include "UnityCG.cginc"
               
 //           struct appdata_t {
 //               float4 vertex : POSITION;
 //               //float2 texcoord: TEXCOORD0;
	//			fixed4 color : COLOR;
 //           };
               
 //           struct v2f {
 //               float4 vertex : POSITION;
 //               //float4 uvgrab : TEXCOORD0;
	//			fixed4 color : COLOR;
 //           };
               
 //           v2f vert (appdata_t v) {
 //               v2f o;
 //               o.vertex = mul(UNITY_MATRIX_MVP, v.vertex);
 //               //#if UNITY_UV_STARTS_AT_TOP
 //               //float scale = 1.0;
 //               //#else
 //               //float scale = -1.0;
 //               //#endif
 //               //o.uvgrab.xy = (float2(o.vertex.x, o.vertex.y*scale) + o.vertex.w) * 0.5;
 //               //o.uvgrab.zw = o.vertex.zw;
	//			o.color = v.color;
 //               return o;
 //           }
               
 //           //sampler2D _blurTexture : register(s6);
	//		//sampler2D _blurTexture;

               
 //           fixed4 frag( v2f i ) : COLOR {

	//			fixed4 color = fixed4(0.0f,0.0f,0.0f,1.0f);
	//			color.a = 0.95f;
	//			return color;
 //           }
 //           ENDCG
 //       }
    
 //   }
}