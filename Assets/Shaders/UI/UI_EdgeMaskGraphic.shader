Shader "UI/EdgeMaskGraphic"
{
    Properties
    {
        [PerRendererData] _MainTex("Sprite Texture", 2D) = "white" {}
        _MaskClipRect("_MaskClipRect", Vector) = (0, 0, 0, 0)
        _MaskBorderBlend("_MaskBorderBlend", Vector) = (0, 0, 0, 0)
    }
    SubShader
    {
        Tags { "Queue" = "Transparent" }
        LOD 100
        Blend SrcAlpha OneMinusSrcAlpha, Zero OneMinusSrcAlpha
        ZWrite Off

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float4 color    : COLOR;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                fixed4 color : COLOR;
                float4 worldPosition : TEXCOORD1;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            float4 _MaskClipRect;
            float4 _MaskBorderBlend;

            inline float GetSoft2DClipping(in float2 position, in float4 clipRect, in half4 borderBlend)
            {
                float2 inside = smoothstep(clipRect.xy, clipRect.xy + borderBlend.xy, position.xy) * smoothstep(clipRect.zw, clipRect.zw - borderBlend.zw, position.xy);
                return inside.x * inside.y;
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.worldPosition = mul(unity_ObjectToWorld, v.vertex);
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.color = v.color;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv) * i.color;
                fixed rate = GetSoft2DClipping(i.worldPosition, _MaskClipRect, _MaskBorderBlend);
                col.a *= (1 - rate);
                return col;
            }
            ENDCG
        }
    }
}
