Shader "UI/Transparent Color Alpha Clip"
{
    Properties
    {
        [PerRendererData] _MainTex("Sprite Texture", 2D) = "white" {}
        _AlphaClip("Alpha Clip", Range(0, 1)) = 0.001
        _Color("Tint", Color) = (1,1,1,1)
		//_BorderBlend("Border Blend Range", vector) = (0,0,0,0)

        _StencilComp("Stencil Comparison", Float) = 8
        _Stencil("Stencil ID", Float) = 0
        _StencilOp("Stencil Operation", Float) = 0
        _StencilWriteMask("Stencil Write Mask", Float) = 255
        _StencilReadMask("Stencil Read Mask", Float) = 255

        _ColorMask("Color Mask", Float) = 15

        //_ClipRect("Clip Rect", Vector) = (-10000, -10000, 10000, 10000)

        //[Toggle(UNITY_UI_ALPHACLIP)] _UseUIAlphaClip("Use Alpha Clip", Float) = 0
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
        Blend SrcAlpha OneMinusSrcAlpha
        ColorMask[_ColorMask]

        Pass
        {
            Name "Default"
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 2.0

            #include "UnityCG.cginc"
			#include "Assets/CGInclude/LGameUI.cginc"

            #pragma multi_compile __ SOFT_CLIP
			#pragma multi_compile __ USE_CURVE

            struct appdata_t
            {
                float4 vertex    : POSITION;
                fixed4 color     : COLOR;
                float2 texcoord0 : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 vertex   : SV_POSITION;
                fixed4 color : COLOR;
                float2 texcoord0 : TEXCOORD0;
                float4 worldPosition : TEXCOORD2;
                half2  gray : TEXCOORD3;
#ifdef USE_CURVE
				float2 uicurveRate : TEXCOORD4;
#endif
                UNITY_VERTEX_OUTPUT_STEREO
            };

            fixed4 _Color;
            fixed4 _TextureSampleAdd;
            //float4 _ClipRect;
			//float4 _BorderBlend;

            sampler2D _MainTex;
            half _AlphaClip;

			//float _UI_CurveLength;
			//float4 _UI_Curve_View_ClipRect;
			//float4 _UI_Curve_View_BorderBlendRect;
			//float2 _UI_Curve_ColorIncrease_Range;

            v2f vert(appdata_t IN)
            {
                v2f OUT = (v2f)0;
                UNITY_SETUP_INSTANCE_ID(IN);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(OUT);
                OUT.worldPosition = IN.vertex;

//#ifdef USE_CURVE
				//float4 pos = mul(UNITY_MATRIX_MV, IN.vertex);
				//float rate = length(pos.x) / _UI_CurveLength;
				//pos.w += rate * length(rate);
				//OUT.vertex = mul(UNITY_MATRIX_P, pos);

				//float viewCurveRate = LGameGetSoft2DClipping(pos, _UI_Curve_View_ClipRect, _UI_Curve_View_BorderBlendRect);
				//OUT.uicurveRate.x = lerp(_UI_Curve_ColorIncrease_Range.x, _UI_Curve_ColorIncrease_Range.y, viewCurveRate);
//#else
				OUT.vertex = UnityObjectToClipPos(OUT.worldPosition);
//#endif

                OUT.texcoord0 = IN.texcoord0;
                
                OUT.color = IN.color * _Color;
                
				OUT.gray.x = clamp(255 * (IN.color.r + IN.color.g + IN.color.b), 0, 1);
				OUT.gray.y = 0;
                
                return OUT;
            }

            fixed4 frag(v2f IN) : SV_Target
            {
                fixed4 color = (tex2D(_MainTex, IN.texcoord0) + _TextureSampleAdd);
                
                //#ifdef SOFT_CLIP
				//    color.a *= LGameGetSoft2DClipping(IN.worldPosition, _ClipRect, _BorderBlend);
                //#else
                //    color.a *= UnityGet2DClipping(IN.worldPosition , _ClipRect);
                //#endif
                
                clip(color.a - 0.001);

                fixed4 mixColor = color * IN.color;
				fixed4 grayResult = dot(color, fixed4(0.299, 0.587, 0.114, 0));
				grayResult.a = mixColor.a;
				color = IN.gray.x * mixColor + (1 - IN.gray.x) * grayResult;

				//#ifdef USE_CURVE
				//	color.rgb *= IN.uicurveRate.x;
				//#endif

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
