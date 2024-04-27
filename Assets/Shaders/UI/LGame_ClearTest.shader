Shader "LGame/ClearTest"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "black" {}
        _MainTex1 ("Texture1", 2D) = "black" {}
        _MainTex2 ("Texture2", 2D) = "black" {}
        _MainTex3 ("Texture3", 2D) = "black" {}
        _MainTex4 ("Texture4", 2D) = "black" {}
        _MainTex5 ("Texture5", 2D) = "black" {}
        _MainTex6 ("Texture6", 2D) = "black" {}
        _MainTex7 ("Texture7", 2D) = "black" {}
    }
    SubShader
    {
        LOD 100

        Pass
        {
            Tags { "RenderType"="Transparent" "Queue" = "Transparent" "LightMode" = "ForwardBase"}
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float2 uv1 : TEXCOORD1;
                float2 uv2 : TEXCOORD2;
                float2 uv3 : TEXCOORD3;
                float2 uv4 : TEXCOORD4;
                float2 uv5 : TEXCOORD5;
                float2 uv6 : TEXCOORD6;
                float2 uv7 : TEXCOORD7;
                // float2 uv8 : TEXCOORD8;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float2 uv1 : TEXCOORD1;
                float2 uv2 : TEXCOORD2;
                float2 uv3 : TEXCOORD3;
                float2 uv4 : TEXCOORD4;
                float2 uv5 : TEXCOORD5;
                float2 uv6 : TEXCOORD6;
                float2 uv7 : TEXCOORD7;
                // float2 uv8 : TEXCOORD8;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            sampler2D _MainTex1;
            sampler2D _MainTex2;
            sampler2D _MainTex3;
            sampler2D _MainTex4;
            sampler2D _MainTex5;
            sampler2D _MainTex6;
            sampler2D _MainTex7;
            // sampler2D _MainTex8;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);
                fixed4 col1 = tex2D(_MainTex1, i.uv);
                fixed4 col2 = tex2D(_MainTex2, i.uv);
                fixed4 col3 = tex2D(_MainTex3, i.uv);
                fixed4 col4 = tex2D(_MainTex4, i.uv);
                fixed4 col5 = tex2D(_MainTex5, i.uv);
                fixed4 col6 = tex2D(_MainTex6, i.uv);
                fixed4 col7 = tex2D(_MainTex7, i.uv);
                // fixed4 col8 = tex2D(_MainTex8, i.uv);
                // return (col + col1 + col2 + col3 + col4 + col5 + col6 + col7 + col8)*0.01+ half4(0,0,0,0);
                return (col + col1 + col2 + col3 + col4 + col5 + col6 + col7)*0.01+ half4(0,0,0,0);
            }
            ENDCG
        }
        
        Pass
        {
            Tags { "RenderType"="Transparent" "Queue" = "Transparent" }
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float2 uv1 : TEXCOORD1;
                float2 uv2 : TEXCOORD2;
                float2 uv3 : TEXCOORD3;
                float2 uv4 : TEXCOORD4;
                float2 uv5 : TEXCOORD5;
                float2 uv6 : TEXCOORD6;
                float2 uv7 : TEXCOORD7;
                // float2 uv8 : TEXCOORD8;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float2 uv1 : TEXCOORD1;
                float2 uv2 : TEXCOORD2;
                float2 uv3 : TEXCOORD3;
                float2 uv4 : TEXCOORD4;
                float2 uv5 : TEXCOORD5;
                float2 uv6 : TEXCOORD6;
                float2 uv7 : TEXCOORD7;
                // float2 uv8 : TEXCOORD8;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            sampler2D _MainTex1;
            sampler2D _MainTex2;
            sampler2D _MainTex3;
            sampler2D _MainTex4;
            sampler2D _MainTex5;
            sampler2D _MainTex6;
            sampler2D _MainTex7;
            // sampler2D _MainTex8;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);
                fixed4 col1 = tex2D(_MainTex1, i.uv);
                fixed4 col2 = tex2D(_MainTex2, i.uv);
                fixed4 col3 = tex2D(_MainTex3, i.uv);
                fixed4 col4 = tex2D(_MainTex4, i.uv);
                fixed4 col5 = tex2D(_MainTex5, i.uv);
                fixed4 col6 = tex2D(_MainTex6, i.uv);
                fixed4 col7 = tex2D(_MainTex7, i.uv);
                // fixed4 col8 = tex2D(_MainTex8, i.uv);
                return (col + col1 + col2 + col3 + col4 + col5 +col6 +col7)*0.01+ half4(0,0,0,0);
            }
            ENDCG
        }
    }
}
