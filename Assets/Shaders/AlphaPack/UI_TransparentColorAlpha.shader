Shader "UI/Transparent Color Alpha"
{
    Properties
    {
        [PerRendererData] _MainTex("Sprite Texture", 2D) = "white" {}
        _Color("Tint", Color) = (1,1,1,1)
		_BorderBlend("Border Blend Range", vector) = (0,0,0,0)
		_BorderBlendAlpha("Border Blend Alpha Range", vector) = (0,0,0,0)

        _StencilComp("Stencil Comparison", Float) = 8
        _Stencil("Stencil ID", Float) = 0
        _StencilOp("Stencil Operation", Float) = 0
        _StencilWriteMask("Stencil Write Mask", Float) = 255
        _StencilReadMask("Stencil Read Mask", Float) = 255

        _ColorMask("Color Mask", Float) = 15

        _ClipRect("Clip Rect", Vector) = (-10000, -10000, 10000, 10000)

        [Toggle(UNITY_UI_ALPHACLIP)] _UseUIAlphaClip("Use Alpha Clip", Float) = 0
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

        LOD 100

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
        Blend SrcAlpha OneMinusSrcAlpha, Zero OneMinusSrcAlpha
        ColorMask[_ColorMask]

        Pass
        {
            Name "Default"
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 2.0

            #include "UnityCG.cginc"
			#include "Assets/CGInclude/LGameSysUI.cginc"

            #pragma multi_compile __ UNITY_UI_ALPHACLIP
            #pragma multi_compile __ SOFT_CLIP
			#pragma multi_compile __ USE_CURVE
			#pragma multi_compile __ USE_HSV_COLOR
			

            struct appdata_t
            {
                float4 vertex    : POSITION;
                float4 color     : COLOR;
                float2 texcoord0 : TEXCOORD0;

                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 vertex   : SV_POSITION;
                float4 color : COLOR;
                float2 texcoord0 : TEXCOORD0;
                float4 worldPosition : TEXCOORD1;
                half2  gray : TEXCOORD3;

                UNITY_VERTEX_OUTPUT_STEREO
            };

            fixed4 _Color;
            fixed4 _TextureSampleAdd;
            float4 _ClipRect;
			float4 _BorderBlend;
			float4 _BorderBlendAlpha;

            sampler2D _MainTex;

#ifdef USE_CURVE
			float _UI_CurveLength;
			float4 _UI_Curve_View_ClipRect;
			float4 _UI_Curve_View_BorderBlendRect;
			float2 _UI_Curve_ColorIncrease_Range;
#endif
            v2f vert(appdata_t IN)
            {
                v2f OUT = (v2f)0;
                UNITY_SETUP_INSTANCE_ID(IN);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(OUT);
                OUT.worldPosition = IN.vertex;
#ifdef USE_CURVE
				float4 pos = mul(UNITY_MATRIX_MV, IN.vertex);
				float rate = length(pos.x) / _UI_CurveLength;
				float w = pos.w + rate * length(rate);
				pos.yz /= w;
				OUT.vertex = mul(UNITY_MATRIX_P, pos);
#else
				OUT.vertex = UnityObjectToClipPos(OUT.worldPosition);
#endif
                OUT.texcoord0 = IN.texcoord0;
                
                OUT.color = IN.color * _Color;
                
				OUT.gray.x = clamp(255 * (IN.color.r + IN.color.g + IN.color.b), 0, 1);
				OUT.gray.y = 0;
                
                return OUT;
            }

            fixed4 frag(v2f IN) : SV_Target
            {
                fixed4 color = (tex2D(_MainTex, IN.texcoord0) + _TextureSampleAdd);
                
                #ifdef SOFT_CLIP
				    color.a *= LGameGetSoft2DClippingEx(IN.worldPosition, _ClipRect, _BorderBlend, _BorderBlendAlpha);

                #endif

                
				#ifdef UNITY_UI_ALPHACLIP
				    clip(color.a - 0.001);
				#endif

#if USE_HSV_COLOR
				color.a = color.a * IN.color.a;
				float3 hsv = RGB2HSV(IN.color.rgb);
				float3 colorHSV = RGB2HSV(color.rgb);

				colorHSV.x += hsv.x;
				colorHSV.x %= 360;

				colorHSV.y *= (1 - hsv.y);
				colorHSV.z *= hsv.z;

				color.rgb = HSV2RGB(colorHSV.xyz);
#else
				fixed4 mixColor = color * IN.color;
				fixed4 grayResult = dot(color, fixed4(0.299, 0.587, 0.114, 0));
				grayResult.a = mixColor.a;
				color = IN.gray.x * mixColor + (1 - IN.gray.x) * grayResult;
#endif
                return color;
            }
            ENDCG
        }
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
        LOD 5

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
        Blend One One
        ColorMask[_ColorMask]

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

            struct appdata_t
            {
                float4 vertex    : POSITION;
            };

            float4 vert(appdata_t IN) : SV_POSITION
            {
                return UnityObjectToClipPos(IN.vertex);
            }
			
			fixed4 frag () : SV_Target
			{
				return fixed4(0.15, 0.06, 0.03, 0);
			}
			ENDCG
		}
	}
}
