Shader "LGame/BlitCopy"
{
    Properties
    {
		_MainTex ("Texture", 2D) = "white" {}
    }

    SubShader {
        Pass {
            ZTest Always Cull Off ZWrite Off

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            sampler2D _MainTex;

            struct appdata_t {
                float4 vertex : POSITION;
                float2 texcoord : TEXCOORD0;
            };

            struct v2f {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            v2f vert (appdata_t v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);

                o.uv = v.texcoord;
                // Flip UV in DX like graphics APIs (https://docs.unity3d.com/Manual/SL-PlatformDifferences.html)
				#if UNITY_UV_STARTS_AT_TOP
                    o.uv.y = o.uv.y * -1.0 + 1.0;   // 1 mad
				#endif

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);
                return col;
            }
            ENDCG
        }
    }

    Fallback Off
}
