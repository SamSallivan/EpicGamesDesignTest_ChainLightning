Shader "UI/Effect2UI" 
{
    Properties
    {
        _MainTex("Main Texture", 2D) = "white" {}
        _AlphaTex("Alpha Texture",2D) ="white"{}
        _Color("Tint", Color) = (1, 1, 1, 1)
		[HideInInspector][Enum(UnityEngine.Rendering.BlendMode)] 		_SrcFactor("SrcFactor()", Float) = 5
		[HideInInspector][Enum(UnityEngine.Rendering.BlendMode)] 		_DstFactor("DstFactor()", Float) = 10
		[HideInInspector][Enum(UnityEngine.Rendering.BlendMode)] 		_SrcAlphaFactor("SrcAlphaFactor()", Float) = 0
		[HideInInspector][Enum(UnityEngine.Rendering.BlendMode)] 		_DstAlphaFactor("DstAlphaFactor()", Float) = 10

        _StencilComp("Stencil Comparison", Float) = 8
        _Stencil("Stencil ID", Float) = 0
        _StencilOp("Stencil Operation", Float) = 0
        _StencilWriteMask("Stencil Write Mask", Float) = 255
        _StencilReadMask("Stencil Read Mask", Float) = 255
        _ColorMask("Color Mask", Float) = 15

        _ClipRect("Clip Rect", Vector) = (-10000, -10000, 10000, 10000)
        _BorderBlend("Border Blend Range", vector) = (0,0,0,0)
        _BorderBlendAlpha("Border Blend Alpha Range", vector) = (0,0,0,0)
		_UVRect("UvRect", Vector) = (0,0,1,1)
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
			"LightMode" = "ForwardBase"
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
            ColorMask[_ColorMask]
        //finalValue = sourceFactor * sourceValue operation destinationFactor * destinationValue
        //Blend <source factor> <destination factor>
        //Blend <source factor RGB> <destination factor RGB>, <source factor alpha> <destination factor alpha>

		//Blend One OneMinusSrcAlpha
        Blend One SrcAlpha
		//Blend[_SrcFactor][_DstFactor],[_SrcAlphaFactor][_DstAlphaFactor]
            
        Pass
        {
            Name "Default"
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 2.0

            #include "UnityCG.cginc"
            #include "UnityUI.cginc"
            #include "Assets/CGInclude/LGameSysUI.cginc"
		
            #pragma multi_compile __ SOFT_CLIP
            
            struct appdata_t
            {
                float4 vertex   : POSITION;
                fixed4 color    : COLOR;
                float2 texcoord : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 vertex   : SV_POSITION;
				fixed4 color : COLOR;
                float2 texcoord  : TEXCOORD0;
                float4 worldPosition : TEXCOORD1;
                UNITY_VERTEX_OUTPUT_STEREO
            };

			float _Alpha;
            float4 _ClipRect;
            float4 _BorderBlend;
            float4 _BorderBlendAlpha;
			float4 _UVRect;

            v2f vert(appdata_t IN)
            {
                v2f OUT;
                UNITY_SETUP_INSTANCE_ID(IN);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(OUT);

                OUT.worldPosition = IN.vertex;
                OUT.vertex = UnityObjectToClipPos(IN.vertex);

				OUT.texcoord = IN.texcoord * _UVRect.zw + _UVRect.xy;

                OUT.color = IN.color;
                return OUT;
            }

            sampler2D _MainTex;

            sampler2D _AlphaTex;
                
            fixed4 frag(v2f IN) : SV_Target
            {
                fixed4 color = tex2D(_MainTex, IN.texcoord);// *IN.color;
                fixed4 alphaColor = tex2D(_AlphaTex,IN.texcoord);
                //color.rgb *= IN.color.rgb;

                fixed a = IN.color.a;
#ifdef SOFT_CLIP
                a *= LGameGetSoft2DClippingEx(IN.worldPosition, _ClipRect, _BorderBlend, _BorderBlendAlpha);
#endif
                //饱和度计算，使用顶点色的 r 值控制饱和度
                color.rgb = lerp(Luminance(color.rgb).rrr, color.rgb, IN.color.r);
				//亮度计算，使用顶点色的 g 值控制亮度
                color.rgb *= IN.color.g;
                
                color.rgb *= a;
                color.a += (1 - a);
                color.a = clamp(color.a,0,1);
                color.a *= alphaColor.r;
                //color.rgb *= color.a;
				//color.a *= _Alpha;
				//color.a *= step(0.01f, color.r + color.g + color.b);

                return color;
            }
			
			
            ENDCG
        }
    }
}