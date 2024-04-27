Shader "LGame/Effect/Gray"
{
    Properties
    {
        _MainTex ("Base (RGB) Trans (A)", 2D) = "white" {}
        [SimpleToggle]_UseColor("UseColor",Range(0,1))=1
        _ColorStrength("ColorStrength",Range(0,1))=1
        _Alpha("Alpha",Range(0,1))=1
    }
    SubShader
    {
        Tags 
        {
            "Queue" = "Transparent"
            "IgnoreProjector" = "True"
            "RenderType" = "Transparent"
            "PreviewType" = "Plane"
            "LightMode" = "ForwardBase"
        }
        LOD 100
        ZWrite Off
        Blend SrcAlpha OneMinusSrcAlpha
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex               : POSITION;
                float2 uv                   : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex               : SV_POSITION;
                float2 uv                   : TEXCOORD0;
            };

            sampler2D               _MainTex;
            float4                  _MainTex_ST;
            half                    _UseColor;
            half                    _ColorStrength;
            half                    _Alpha;
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
                col.a*=_Alpha;
                col.rgb = lerp(Luminance(col.rgb).rrr , col.rgb, _UseColor*_ColorStrength);
                return col;
            }
            ENDCG
        }
    }
}
