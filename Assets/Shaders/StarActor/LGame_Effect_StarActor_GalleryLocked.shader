/************************************************************************************
* 给画廊KDA未解锁状态定制的shader
* 因为时间比较紧，可能考虑不够周全，尽量不要用在其他地方
* Dedicated Shader customized for gallery KDA unlocked state
* Because time is tight, it may not be considered fully, so try not to use it in other places
* @yvanliao  2020-12-07 16:19:35
************************************************************************************/

Shader "LGame/Effect/StarActor/GalleryLocked"
{
    Properties
    {
        [hdr]_Color ("Main Color" , color) = (1,1,1,1)
        _MainTex ("Texture", 2D) = "white" {}      


        [Header(Warp)]
        _WarpTex("Warp Texture", 2D) = "bump" {}
        [Enum(UV,0,Screen,1)] _WarpTexUvMode("UV Mode", int) = 0
        _WarpIntensity ("Warp Intensity",range(0,0.3)) = 0.1

        [Header(FlowLight)]
        [hdr]_FlowLightCol ("FlowLight Color" , color) = (1,1,1,1)
        _FlowLightTex("FlowLight Texture", 2D) = "bump" {}
        [Enum(UV,0,Screen,1)] _FlowLightTexUvMode("UV Mode", int) = 0

        [Header(RimLight)]
        [hdr]_RimLightColor("RimLight Color" , color) = (1,1,1,1)
        _RimLighRange("Range" , Range(0.1,10)) = 2
        _RimLighMultipliers("Multipliers" , Range(0,100)) = 1


    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag


            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex   : POSITION;
                float2 uv		: TEXCOORD0;
                float3 normal   : NORMAL;
            };

            struct v2f
            {
                float2 uv		: TEXCOORD0;
                float4 uv2		: TEXCOORD1;
                fixed4 color    : COLOR;
                float4 pos      : SV_POSITION;
            };

            fixed4       _Color;

            sampler2D   _MainTex;
            float4      _MainTex_ST;

            sampler2D   _WarpTex;
            float4      _WarpTex_ST;
            int         _WarpTexUvMode;
            fixed       _WarpIntensity;

            fixed4      _FlowLightCol;
            sampler2D   _FlowLightTex;
            float4      _FlowLightTex_ST;
            int         _FlowLightTexUvMode;

            

            //Rimlight
            fixed4		_RimLightColor;
            half		_RimLighRange;
            half		_RimLighMultipliers;

            inline half2 ScreenUV(half4 pos)
            {
                half4 srcPos = ComputeScreenPos(pos);
                return srcPos.xy /srcPos.w;
            }
            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);

                half2 srcPos = ScreenUV(o.pos);
                o.uv = srcPos *_MainTex_ST.xy + _MainTex_ST.zw; 
                o.uv2 = v.uv.xyxy;
                if(any(_FlowLightTexUvMode))
                {
                    o.uv2.xy =  srcPos;
                }
                if(any(_WarpTexUvMode))
                {
                    o.uv2.zw = srcPos;
                }
                o.uv2.xy =  o.uv2.xy *  _FlowLightTex_ST.xy + _FlowLightTex_ST.zw * _Time.y;
                o.uv2.zw =  o.uv2.zw *  _WarpTex_ST.xy + _WarpTex_ST.zw * _Time.y ;

                fixed3 worldViewDir = normalize(WorldSpaceViewDir(v.vertex));
                fixed3 worldNormal = normalize(UnityObjectToWorldNormal(v.normal));
                half fresnel = 1 - abs(dot(worldViewDir, worldNormal));
                o.color = pow(fresnel, _RimLighRange) ;

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed3 warp = UnpackNormal(tex2D(_WarpTex, i.uv2.zw)).xyz;
                fixed4 col = tex2D(_MainTex, i.uv - warp.xy * _WarpIntensity) * _Color;

                fixed4 flowlight = tex2D(_FlowLightTex , i.uv2.xy) * _FlowLightCol;
                fixed4 fresnel = _RimLightColor * i.color * _RimLighMultipliers * flowlight;

                col.rgb += fresnel.rgb;
                return col;
            }
            ENDCG
        }
    }
}
