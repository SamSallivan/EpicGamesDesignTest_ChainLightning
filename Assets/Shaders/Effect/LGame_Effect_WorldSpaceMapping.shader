Shader "LGame/Effect/WorldSpaceMapping"
{
    Properties
    {
        [HideInInspector]_AlphaCtrl("AlphaCtrl",range(0,1)) = 1
        [Header(WorldSpaceMapping)]
		[Enum(UnityEngine.Rendering.BlendMode)]_DstFactor("混合：OneMinusSrcAlpha/叠加：One", Float) = 10
        _Color("BaseColor(RGB控制颜色，A可以控制全局透明度)",Color)=(1,1,1,1)
        _MainTex ("色彩贴图", 2D) = "white" {}
        _MaskTex ("蒙版", 2D) = "white" {}
    }
    SubShader
    {
        Tags {"LightMode"="ForwardBase" "Queue"="Transparent" "DisableBatching"="True" "IgnoreProjector" = "True" "RenderType"="Transparent"}
        Blend One [_DstFactor]
        ZWrite Off
        ZTest LEqual
        Cull Off
        LOD 100
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            struct appdata
            {
                float4 vertex : POSITION;
                float2 mainuv : TEXCOORD0;
                float2 maskuv:TEXCOORD1;
            };
            struct v2f
            {
                float2 mainuv : TEXCOORD0;
                float2 maskuv : TEXCOORD1;
                float4 vertex : SV_POSITION;
            };
            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _MaskTex;
            float4 _MaskTex_ST;
            float4 _Color;
            half _AlphaCtrl;
            //这个函数把模型空间坐标映射到世界空间中/This function can map modelspace position to screenspace.
             float2 useWorldPosAsUV(float4 modelvertpos,sampler2D Texture,float4 Texture_ST)
            {
               float3 worldpos=mul(unity_ObjectToWorld,modelvertpos);
               //xz平面是水平面/xz plane is used in the game
               worldpos.xz=TRANSFORM_TEX(worldpos.xz,Texture);
               return worldpos.xz;
            }
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.mainuv =useWorldPosAsUV(v.vertex,_MainTex,_MainTex_ST);
                o.maskuv=TRANSFORM_TEX(v.maskuv,_MaskTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 var_MainTex = tex2D(_MainTex,i.mainuv);
                fixed4 var_MaskTex=tex2D(_MaskTex,i.maskuv);
                //这里默认不采用贴图的Alpha通道，直接取蒙版贴图的R通道作为Alpha值/Use R channel as Alpha channel.
                half opacity=var_MaskTex.r*_Color.a*_AlphaCtrl;
                //没有预乘，在shader里预乘/multiply in shader
                fixed3 finalcolor=var_MainTex.rgb*_Color.rgb*opacity;
                fixed4 outputcol=fixed4(finalcolor,opacity);
                return outputcol;
            }
            ENDCG
        }
    }
}
