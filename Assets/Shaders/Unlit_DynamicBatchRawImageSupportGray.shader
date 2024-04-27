Shader "Unlit/Dynamic Batch RawImage Support Gray"
{
    Properties
    {
        [PerRendererData] _MainTex("Sprite Texture", 2D) = "white" {}
        _Color("Tint", Color) = (1,1,1,1)
        _BorderBlend("Border Blend Range", Vector) = (0, 0, 0, 0)

        _StencilComp("Stencil Comparison", Float) = 8
        _Stencil("Stencil ID", Float) = 0
        _StencilOp("Stencil Operation", Float) = 0
        _StencilWriteMask("Stencil Write Mask", Float) = 255
        _StencilReadMask("Stencil Read Mask", Float) = 255

		_ClipRect("Clip Rect", Vector) = (-10000, -10000, 10000, 10000)
        _ColorMask("Color Mask", Float) = 15
        [Toggle(UNITY_UI_ALPHACLIP)] _UseUIAlphaClip("Use Alpha Clip", Float) = 0
    }

    SubShader
    {
        //按照unity模板修改了tag
        Tags
        {
            "Queue" = "Transparent"
            "IgnoreProjector" = "True"
            "RenderType" = "Transparent"
            "PreviewType" = "Plane"
            "CanUseSpriteAtlas" = "True"
        }

        Stencil
        {
            Ref[_Stencil]
            Comp[_StencilComp]
            Pass[_StencilOp]
            ReadMask[_StencilReadMask]
            WriteMask[_StencilWriteMask]
        }

        Cull Off
        Lighting Off
        ZWrite Off
        ZTest[unity_GUIZTestMode]
        Blend SrcAlpha OneMinusSrcAlpha
        ColorMask[_ColorMask]

        Pass
        {
            Name "Default"
			Tags { "LightMode" = "ForwardBase" }
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 2.0

            //貌似没用到这个宏，注释掉了。	by：yvanliao
            // #pragma multi_compile GRAY_OFF GRAY_ON
            #include "UnityCG.cginc"
            #include "UnityUI.cginc"

            //透明度裁切的开关
            #pragma multi_compile __ UNITY_UI_ALPHACLIP

            struct VS_INPUT
            {
                float4 vertex : POSITION;
                fixed4 color : COLOR;
                half2 texcoord : TEXCOORD0;
            };

            struct VS_OUTPUT
            {
                float4 pos : SV_POSITION;
                fixed4 color : COLOR;
                half2 texcoord : TEXCOORD0;
                float4 worldPosition : TEXCOORD1;
            };

            sampler2D _MainTex;

            fixed4 _Color;

            fixed4 _TextureSampleAdd;
            float4 _ClipRect;
            float4 _BorderBlend;


            VS_OUTPUT vert(VS_INPUT IN)
            {
                VS_OUTPUT OUT;
                OUT.worldPosition = IN.vertex;
                OUT.pos = UnityObjectToClipPos(OUT.worldPosition);
                OUT.texcoord = IN.texcoord;
                OUT.color = IN.color;

                return OUT;
            }

            inline float GetSoft2DClipping (in float2 position, in float4 clipRect , in float4 borderBlend)
			{
				//float2 range = max(0, float2(horizontal , vertical));
			 	float2 inside = smoothstep(clipRect.xy , clipRect.xy + borderBlend.xy, position.xy) * smoothstep(clipRect.zw , clipRect.zw - borderBlend.zw, position.xy) ;
			 	return inside.x * inside.y;
			}

            fixed4 frag(VS_OUTPUT IN) : SV_Target
            {
                half4 color = tex2D(_MainTex , IN.texcoord);
                //color.a *= UnityGet2DClipping(IN.worldPosition.xy, _ClipRect);
                color.a *= GetSoft2DClipping(IN.worldPosition.xy, _ClipRect, _BorderBlend);
                
                // 支持顶点色是因为小地图受击闪白需要顶点颜色
                color.rgb = lerp(Luminance(color.rgb).rrr , color.rgb * IN.color.rgb, IN.color.r);
                color.a *= IN.color.a;

                //使用透明度裁切
                #ifdef UNITY_UI_ALPHACLIP
                    clip(color.a - 0.001);
                #endif

                return color;
            }
            ENDCG
        }
    }
}
