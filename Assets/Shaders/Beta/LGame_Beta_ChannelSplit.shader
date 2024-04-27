Shader "Hidden/Lgame_SplitChannel_Shader"
{
    Properties
    {
        _MainTex                                        ("Texture", 2D) = "white" {}
        _RGBAValue                                      ("_RGBAValue",vector)=(1,1,1,1)
        _Animation                                      ("_Animation",Range(-1,1))=-1
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

            sampler2D                                   _MainTex;
            float4                                      _MainTex_ST;
            float4                                      _RGBAValue;
            half                                        _Animation;
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
                fixed4 colbefore=col;
                fixed4 colR=fixed4(col.rrrr);
                fixed4 colG=fixed4(col.gggg);
                fixed4 colB=fixed4(col.bbbb);
                fixed4 colA=fixed4(col.aaaa);
                fixed4 colAll=col;
                half value=_RGBAValue.r*_RGBAValue.g*_RGBAValue.b*_RGBAValue.a;
                col=lerp(colR*_RGBAValue.r+colG*_RGBAValue.g+colB*_RGBAValue.b+colA*_RGBAValue.a,colAll,value) ;
                //制作渐变动画，制作渐变流光
                col=lerp(col,colbefore,smoothstep(0.45,0.55,_Animation+i.uv.y));
                col=lerp(col,fixed4(0,1,0,1),frac(smoothstep(0.45,0.55,_Animation+i.uv.y)));
                return col;
            }
            ENDCG
        }
    }
}
