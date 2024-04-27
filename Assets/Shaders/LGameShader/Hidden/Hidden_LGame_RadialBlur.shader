Shader "Hidden/LGame_RadialBlur"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Cull Off ZWrite Off ZTest Always
        CGINCLUDE
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
        ENDCG

        Pass
        {
            Blend srcAlpha oneminussrcAlpha

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            sampler2D _MainTex;
            half2 _BlurCenter;
            half _StepLenght;
            int _SampleCount;
            half _LerpFactor;

            half4 frag (v2f i) : SV_Target
            {
       		half2 dir = _BlurCenter.xy - i.uv;
                half dist = length(dir);
                half4 outColor = 0;
                UNITY_LOOP 
                for (int j = 0; j < _SampleCount; ++j)
                {
                    half step = _StepLenght * j;
                    half2 uv = i.uv + dir * step;
                    outColor += tex2D(_MainTex, uv);
                }
                outColor /= half(_SampleCount);
                outColor.a = saturate(_LerpFactor * dist);
                return outColor;
            }
            ENDCG
        }

    }
}
