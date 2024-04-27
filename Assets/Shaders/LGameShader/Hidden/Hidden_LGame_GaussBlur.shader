Shader "Hidden/LGame_GaussBlur"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _HightResTex ("HightResTex", 2D) = "white" {}
        //_OffsetWidth("OffsetWidth", vector) = (0,0,0,0)
        _BlurPersent("BlurPersent", Range(0, 1)) = 0.5
		_Luminous("Luminous", float) = 1
    }
    SubShader
    {
		CGINCLUDE
        sampler2D _MainTex;
        struct appdata
        {
            float4 vertex : POSITION;
            float2 uv : TEXCOORD0;
        };
		ENDCG
        //Blur	0
        Pass
        {
			Tags{"LightMode" = "ForwardBase"}
			Cull Off ZWrite Off ZTest Always
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag_Blur
            #include "UnityCG.cginc"

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }
            static const half GaussWeight[7] =
            {
                0.0205,
                0.0855,
                0.232,
                0.324,
                0.232,
                0.0855,
                0.0205,
            };
            half2 _OffsetWidth;

            fixed4 frag_Blur(v2f i):SV_Target
            {
                half2 offsetWidth = _OffsetWidth;
                half2 uv = i.uv - offsetWidth * 3.0;
                fixed4 color = 0;
                for(int i = 0; i < 3; i++)
                {
                    color += tex2D(_MainTex, uv) * GaussWeight[i];
                    uv += offsetWidth;
                }
                half4 centerCol = tex2D(_MainTex, uv);
                color += centerCol * GaussWeight[3];
                for(int i = 4; i < 7; i++)
                {
                    uv += offsetWidth;
                    color += tex2D(_MainTex, uv) * GaussWeight[i];
                }
                return color;
            }
     
            ENDCG
        }

        //DownSample	1
        Pass
        {
			Tags{"LightMode" = "ForwardBase"}
			Cull Off ZWrite Off ZTest Always
            CGPROGRAM
            #pragma vertex vert_UpSample
            #pragma fragment frag_UpSample
            #include "UnityCG.cginc"
            struct v2f
            {
                float4 vertex : SV_POSITION;
                half2 uv0 : TEXCOORD;
            };
            v2f vert_UpSample (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv0 = v.uv;

                return o;
            }
            fixed4 frag_UpSample(v2f i):SV_Target
            {
                fixed4 color = 0;
                color = tex2D(_MainTex, i.uv0);
                return color;
            }
     
            ENDCG
        }
        //Blit2FrameBuffer	2
        Pass
        {
			Tags{"LightMode" = "ForwardBase"}
            Cull Off ZWrite Off ZTest Always
            Blend One SrcAlpha
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }
            sampler2D _HightResTex;
            float _BlurPersent;
            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);
                fixed4 colHightRes = tex2D(_HightResTex, i.uv);
                col = lerp(colHightRes, col, _BlurPersent);
                return col;
            }
            ENDCG
        }
			//Blit2FrameBuffer AlphaBlend	3
			Pass
			{
				Tags{"LightMode" = "ForwardBase"}
				Cull Off ZWrite Off ZTest Always
				Blend One SrcAlpha
				CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag

				#include "UnityCG.cginc"
				struct v2f
				{
					float2 uv : TEXCOORD0;
					float4 vertex : SV_POSITION;
				};

				v2f vert(appdata v)
				{
					v2f o;
					o.vertex = UnityObjectToClipPos(v.vertex);
					o.uv = v.uv;
					return o;
				}
				float _BlurPersent;
				float _Luminous;
				float4 frag(v2f i) : SV_Target
				{
					float4 col = tex2D(_MainTex, i.uv)*_Luminous * _BlurPersent;
					col.a = (1 - _BlurPersent) * _Luminous;
					return col;
				}
				ENDCG
			}
				//Blit2FrameBuffer AlphaBlend transform	4
					Pass
				{
					Tags{"LightMode" = "ForwardBase"}
					Cull Off ZWrite Off ZTest Always
					Blend One SrcAlpha
					CGPROGRAM
					#pragma vertex vert
					#pragma fragment frag

					#include "UnityCG.cginc"
					struct v2f
					{
						float2 uv : TEXCOORD0;
						float4 vertex : SV_POSITION;
					};

					v2f vert(appdata v)
					{
						v2f o;
						o.vertex = UnityObjectToClipPos(v.vertex);
						o.uv = v.uv;
	#if UNITY_UV_STARTS_AT_TOP
						o.uv.y = 1 - o.uv.y;
	#endif
						return o;
					}
					float _BlurPersent;
					float _Luminous;
					float4 frag(v2f i) : SV_Target
					{
						float4 col = tex2D(_MainTex, i.uv) *_Luminous * _BlurPersent;
						col.a = (1 - _BlurPersent) * _Luminous;
						return col;
					}
					ENDCG
				}
        /*Pass
        {
			Cull Off ZWrite Off ZTest Always
            CGPROGRAM
            #pragma vertex vert_UpSample
            #pragma fragment frag_UpSample
            #include "UnityCG.cginc"
            struct v2f
            {
                float4 vertex : SV_POSITION;
                half2 uv0 : TEXCOORD;
                half4 uv1 : TEXCOORD1;
                half4 uv2 : TEXCOORD2;
                half4 uv3 : TEXCOORD3;
                half4 uv4 : TEXCOORD4;
            };
            half2 _OffsetWidth;
            v2f vert_UpSample (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                half2 uvOffset = _OffsetWidth * 8;

                o.uv1.xy = v.uv + half2(uvOffset.x * 1, uvOffset.y * 1);
                o.uv1.zw = v.uv + half2(uvOffset.x * 0, uvOffset.y * 1);
                o.uv2.xy = v.uv + half2(uvOffset.x * -1, uvOffset.y * 1);

                o.uv2.zw = v.uv + half2(uvOffset.x * 1, uvOffset.y * 0);
                o.uv0 = v.uv;
                o.uv3.xy = v.uv + half2(uvOffset.x * -1, uvOffset.y * 0);

                o.uv3.zw = v.uv + half2(uvOffset.x * 1, uvOffset.y * -1);
                o.uv4.xy = v.uv + half2(uvOffset.x * 0, uvOffset.y * -1);
                o.uv4.zw = v.uv + half2(uvOffset.x * -1, uvOffset.y * -1);

                return o;
            }
            fixed4 frag_UpSample(v2f i):SV_Target
            {
                fixed4 color = 0;
                color += tex2D(_MainTex, i.uv1.xy);
                color += tex2D(_MainTex, i.uv1.zw);
                color += tex2D(_MainTex, i.uv2.xy);

                color += tex2D(_MainTex, i.uv2.zw);
                color += tex2D(_MainTex, i.uv0);
                color += tex2D(_MainTex, i.uv3.xy);

                color += tex2D(_MainTex, i.uv3.zw);
                color += tex2D(_MainTex, i.uv4.xy);
                color += tex2D(_MainTex, i.uv4.zw);

                color = color / 9;
                return color;
            }
     
            ENDCG
        }*/
    }
}
