Shader "UI/Transparent Color Alpha Font"
{
    Properties
    {
        [PerRendererData]_MainTex("Sprite Texture", 2D) = "white" {}
		_FontTex("Font Texture", 2D) = "white"{}
        _Color("Tint", Color) = (1,1,1,1)
		_BorderBlend("Border Blend Range", vector) = (0,0,0,0)

        _StencilComp("Stencil Comparison", Float) = 8
        _Stencil("Stencil ID", Float) = 0
        _StencilOp("Stencil Operation", Float) = 0
        _StencilWriteMask("Stencil Write Mask", Float) = 255
        _StencilReadMask("Stencil Read Mask", Float) = 255

        _ColorMask("Color Mask", Float) = 15
        _BorderWidth ("Border Width", Float) = 1
        _BorderColor ("Border Color", Color) = (0,0,0,1)
        _FontSmooth("Font Smooth", Range(0.01,0.8)) = 0.5

        _ClipRect("Clip Rect", Vector) = (-10000, -10000, 10000, 10000)

        [Toggle(FONT_OUTLINE)] _FONT_OUTLINE("Text OutLine", Float) = 0
        [Toggle(UNITY_UI_ALPHACLIP)] _UseUIAlphaClip("Use Alpha Clip", Float) = 0
        //[KeywordEnum(Img, Font, Outline)] _MODE ("Overlay mode", Float) = 0
    }

    SubShader
    {
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

            #include "UnityCG.cginc"
            #include "UnityUI.cginc"

            #pragma multi_compile __ UNITY_UI_ALPHACLIP
            #pragma multi_compile __ FONT_OUTLINE

            struct appdata_t
            {
                float4 vertex    : POSITION;
                fixed4 color     : COLOR;
                float2 texcoord0 : TEXCOORD0;
                float2 texcoord1 : TEXCOORD1;
                float4 tangent : TANGENT;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 vertex   : SV_POSITION;
                fixed4 color : COLOR;
                float2 texcoord0 : TEXCOORD0;
                float2 texcoord1 : TEXCOORD1;
                float4 worldPosition : TEXCOORD3;
                fixed2  gray : TEXCOORD4;
                half3 borderWidth : NORMAL;

                #ifdef FONT_OUTLINE
                    half4 clipRect : TEXCOORD2;
                #endif
                UNITY_VERTEX_OUTPUT_STEREO
            };

            fixed4 _Color;
            fixed4 _TextureSampleAdd;
            float4 _ClipRect;
			float4 _BorderBlend;
            half _BorderWidth;
			fixed4 _BorderColor;

            sampler2D _MainTex;
			sampler2D _FontTex;
            half4 _FontTex_TexelSize;
            fixed _FontSmooth;


            v2f vert(appdata_t IN)
            {
                v2f OUT;
                UNITY_SETUP_INSTANCE_ID(IN);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(OUT);
                OUT.worldPosition = IN.vertex;
                OUT.vertex = UnityObjectToClipPos(OUT.worldPosition);

				OUT.color = IN.color * _Color;
                OUT.texcoord0 = IN.texcoord0;
                OUT.texcoord1 = IN.texcoord1;
                
                OUT.gray.x = clamp(255 * (IN.color.r + IN.color.g + IN.color.b), 0, 1);
                OUT.gray.y = 0;

                #ifdef FONT_OUTLINE
                    half2 borderWidth = _BorderWidth / _FontTex_TexelSize.zw;
                    OUT.clipRect = half4(IN.tangent.xy + borderWidth,IN.tangent.zw - borderWidth);
                    OUT.borderWidth.xy = borderWidth;
                #endif

                OUT.borderWidth.z = step(0.001,IN.texcoord0.x+IN.texcoord0.y);

                return OUT;
            }

			inline float GetSoft2DClipping (in float2 position, in float4 clipRect , in float4 borderBlend)
			{
				//float2 range = max(0, float2(horizontal , vertical));
			 	float2 inside = smoothstep(clipRect.xy , clipRect.xy + borderBlend.xy, position.xy) * smoothstep(clipRect.zw , clipRect.zw - borderBlend.zw, position.xy) ;
			 	return inside.x * inside.y;
			}

            fixed4 frag(v2f IN) : SV_Target
            {
                fixed4 color;

                if(IN.borderWidth.z == 0)
                {
                    fixed4 fontColor = 1;
				    fontColor.a = (tex2D(_FontTex, IN.texcoord1) + _TextureSampleAdd).a;
                    color = fontColor;

                    #ifdef FONT_OUTLINE
                        //color.a = step(_FontSmooth , color.a);
                        fixed4 border1 = tex2D(_FontTex, IN.texcoord1 + IN.borderWidth.xy);
                        fixed4 border2 = tex2D(_FontTex, IN.texcoord1 - IN.borderWidth.xy);
                        IN.borderWidth.x = -IN.borderWidth.x;
                        fixed4 border3 = tex2D(_FontTex, IN.texcoord1 + IN.borderWidth.xy);
                        fixed4 border4 = tex2D(_FontTex, IN.texcoord1 - IN.borderWidth.xy);
                        fixed2 insideXY = step(IN.clipRect.xy,IN.texcoord1.xy);
                        fixed2 insideZW = step(IN.texcoord1.xy,IN.clipRect.zw);
                        border1 *= insideZW.x * insideZW.y;
                        border2 *= insideXY.x * insideXY.y;
                        border3 *= insideXY.x * insideZW.y;
                        border4 *= insideZW.x * insideXY.y;
                        fixed4 border = _BorderColor;
                        border.a = saturate(border1.a + border2.a + border3.a + border4.a);
                        color = color * color.a + border * (1 - color.a);
                    #endif
                    //return color;
                }
                else
                {
                    color = tex2D(_MainTex, IN.texcoord0) + _TextureSampleAdd;
                }
                
				color.a *= GetSoft2DClipping(IN.worldPosition.xy, _ClipRect , _BorderBlend);

				#ifdef UNITY_UI_ALPHACLIP
				        clip(color.a - 0.001);
				#endif

                //calculate gray
                fixed4 mixColor = color * IN.color;
                fixed4 grayFactor = fixed4(0.299, 0.587, 0.114, 0);
                fixed4 grayResult = dot(color, grayFactor);
                grayResult.a = mixColor.a;

                color = IN.gray.x * mixColor + (1 - IN.gray.x) * grayResult;

                return color;
            }
            ENDCG
        }
    }
}
