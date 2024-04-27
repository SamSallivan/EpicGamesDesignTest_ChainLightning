Shader "Hidden/Lgame_DefaultTextureWindow_Shader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
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
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                col=lerp(fixed4(0.2,0.2,0.2,0.2),fixed4(0.25,0.25,0.25,0.25),step(i.uv.x,0.05));
                col=lerp(col,fixed4(0.25,0.25,0.25,0.25),step(0.95,i.uv.x));
                col=lerp(col,fixed4(0.25,0.25,0.25,0.25),step(0.95,i.uv.y));
                col=lerp(col,fixed4(0.25,0.25,0.25,0.25),step(i.uv.y,0.05));
                return col;
            }
            ENDCG
        }
    }
}
