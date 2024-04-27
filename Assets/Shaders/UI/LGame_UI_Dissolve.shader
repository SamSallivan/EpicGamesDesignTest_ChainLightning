Shader "LGame/UI/Dissolve"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _DissolveTex("DissolveTex", 2D) = "white" {}
        _Dissolve("Dissolve", Range(-1, 1)) = 1
        _Range("Range", Range(0, 0.2)) = 0
        [HDR]_EdgeColor("EdgeColor", color) = (1,1,1,1)
    }
    SubShader
    {
        Cull Off ZWrite Off ZTest Always
        Tags { "Queue" = "Transparent" }

        Pass
        {
            Blend one srcAlpha
            // Blend srcalpha oneminussrcalpha
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                half2 uv : TEXCOORD0;
            };

            struct v2f
            {
                half2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            sampler2D _MainTex;
            sampler2D _DissolveTex;
            half _Dissolve;
            half _Range;
            half4 _EdgeColor;
            half RangeSmooth(half range)   // 搞个长拖尾
            {
                half range2 = smoothstep(abs(range), 0, 1);
                range2 = range2 *range2*range2 ;
                range = (range / abs(range)) * range2;
                return range;
            }
            half4 frag (v2f i) : SV_Target
            {
                half4 col = tex2D(_MainTex, i.uv);
                half dissolve = tex2D(_DissolveTex, i.uv);
                half range = (dissolve - _Dissolve) / _Range;
                range = RangeSmooth(range);
                half sdfSigned = (saturate(range * 0.5 + 0.5) - 0.5) * 2.0;     //内正 外负
                half sdfUnSigned = max(1 - abs(sdfSigned), 0);

                col = col * max(sdfSigned, 0)  + sdfUnSigned * _EdgeColor;
                col.a = max(-sdfSigned, 0);     // sdf内部是Blend = 0，sdf外部是Add = 1
                return col;
            }
            ENDCG
        }
    }
}
