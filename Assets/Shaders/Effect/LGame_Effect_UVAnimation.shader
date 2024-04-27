Shader "LGame/Effect/UVAnimation"
{
    Properties
    {
        [Enum(Off, 0, On, 1)] _ZWriteMode ("ZWriteMode", float) = 0
        [Enum(Less, 2, LessEqual, 4, Greater, 5, Always, 8)] _ZTestMode ("ZTestMode", Float) = 4
        [Enum(UnityEngine.Rendering.CullMode)] _CullMode ("CullMode", float) = 2
        [SimpleToggle] _ScaleOnCenter("Scale On Center", Float) = 1
        _MainTex ("MainTexture", 2D) = "white" {}
        _Vector("LifetimeInput(xy for direction zw for scalesize )" , Vector) = (1,0,1,1)
        [TexRotation]_MainRot("MainTex Rotation" , Vector) = (0,0,0,0)
        [hdr]_Color ("Main Color" , color) = (1,1,1,1)
        _MaskTex ("MaskTexture", 2D) = "white" {}
        [HideInInspector]_AlphaCtrl("Alpha control", Range(0,1)) = 1
    }
    SubShader
    {
        Tags {"LightMode"="ForwardBase" "Queue"="Transparent" "IgnoreProjector" = "True" "RenderType"="Transparent" }
        LOD 100
        Blend One One
        ZWrite [_ZWriteMode]
        ZTest [_ZTestMode]
        Cull [_CullMode]
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                fixed4 color : COLOR;
                float3 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float2 maskuv : TEXCOORD1;
                half4 col       : COLOR;
            };
            sampler2D   _MainTex;
            half4       _MainTex_ST;
            sampler2D   _MaskTex;
            half4       _MaskTex_ST;
            fixed4      _Color;
            half        _AlphaCtrl;
            half4       _Vector;
            half        _ScaleOnCenter;
            half2       _MainRot;
            inline float2 RotateUV(float2 uv,float2 uvRotate)
            {
                float2 outUV;
                outUV = uv - 0.5 * _ScaleOnCenter;
                outUV = float2(	outUV.x * uvRotate.y - outUV.y * uvRotate.x ,
                                outUV.x * uvRotate.x + outUV.y * uvRotate.y );
                return outUV + 0.5 * _ScaleOnCenter;
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.col = v.color;
                o.vertex = UnityObjectToClipPos(v.vertex);
                //当vector设置为初始值时，生命周期设置为不缩放
                float2 uvscale = lerp(_MainTex_ST.xy ,_MainTex_ST.xy*_Vector.zw , v.uv.z);
                float2 uvoffset = _MainTex_ST.zw + v.uv.z * _Vector.xy;
                o.uv = RotateUV(((v.uv-0.5*_ScaleOnCenter- uvoffset) * uvscale +0.5*_ScaleOnCenter),_MainRot.xy);
                o.maskuv = v.uv*_MaskTex_ST.xy+_MaskTex_ST.zw;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv) * i.col;
                fixed mask = tex2D(_MaskTex, i.maskuv).r;
                col*=_Color*mask*_AlphaCtrl;
                return col;
            }
            ENDCG
        }
    }
}
