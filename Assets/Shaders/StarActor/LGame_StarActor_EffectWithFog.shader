Shader "LGame/StarActor/EffectWithFog"
{
    Properties
    {
        _MainTex            ("Texture", 2D) = "white" {}
        _MainColor          ("Color",Color) = (1,1,1,1)
        _UVSpeedRotate      ("UVSpeedRotate",vector) = (0,0,0,0)//(xy for UV,zw for rotate)
        _MaskTex            ("Mask",2D) = "white" {}
        [Header(Fog)]
        _FogColor           ("Fog Color",Color) = (0.0,0.0,0.0,1.0)
        _FogStart           ("Fog Start",float) = 0.0
        _FogEnd             ("Fog End",float) = 300.0
        _AlphaCtrl          ("AlphaCtrl",float) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent"}
        LOD 100
        Cull Off
		Zwrite Off
		Blend SrcAlpha OneMinusSrcAlpha

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
                float3 wPos : TEXCOORD1;
                float2 maskuv :TEXCOORD2;
            };

            sampler2D   _MainTex;
            float4      _MainTex_ST;
            fixed4      _MainColor;
            half4       _UVSpeedRotate;

            sampler2D   _MaskTex;
            float4      _MaskTex_ST;

            half		_FogStart;
            half		_FogEnd;
            fixed4		_FogColor;

            half        _AlphaCtrl;
            
            inline float2 RotateUV(float2 uv,float2 uvRotate)
            {
                float2 outUV;
                outUV = uv - 0.5 ;
                outUV = float2(	outUV.x * uvRotate.y - outUV.y * uvRotate.x ,
                                outUV.x * uvRotate.x + outUV.y * uvRotate.y );
                return outUV + 0.5 ;
            }
            inline float2 TransFormUV(float2 argUV,float4 argST , float4 trans)
            {
                float2 result =  RotateUV(argUV , trans.zw)  * argST.xy + argST.zw;
                result += (1 - argST.xy)*0.5;
                return result + frac(trans.xy * _Time.y);
            }

            half3 SimulateFog(float3 wPos, half3 color)
            {
            	half dist = length(half3(0.0, 0.0, 0.0) - wPos);
            	half factor = saturate((_FogEnd - dist) / (_FogEnd - _FogStart));
            	color = lerp(_FogColor.rgb, color.rgb, factor);
            	return color;
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.wPos = mul(unity_ObjectToWorld,v.vertex).xyz;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TransFormUV(v.uv.xy, _MainTex_ST, _UVSpeedRotate);
                o.maskuv = TRANSFORM_TEX(v.uv,_MaskTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 var_MainTex = tex2D(_MainTex,i.uv);
                half mask =tex2D(_MaskTex,i.maskuv);
                fixed4 col =fixed4(1,1,1,1);
                col.rgb = var_MainTex.rgb;
                col.rgb *= _MainColor.rgb;
                col.rgb *= mask;
                col.rgb = SimulateFog(i.wPos,col.rgb);
                col.a *= mask;
                col.a *= _AlphaCtrl;
                return col;
            }
            ENDCG
        }
    }
    CustomEditor"LGameStarActorEffectWithFogGUI"
}
