// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "UI/UI_UpDownGradientColor"
{
    Properties
    {
		[PerRendererData] _MainTex ("Texture", 2D) = "white" {}
		_TopColor("_TopColor", Color) = (1,1,1,1)
		_ButtomColor("_ButtomColor", Color) = (1,1,1,1)
		_TopY("_TopY", Float) = 0
		_ButtomY("_ButtomY", Float) = 0

		_BorderBlend("Border Blend Range", vector) = (0,0,0,0)
		_ClipRect("Clip Rect", Vector) = (-10000, -10000, 10000, 10000)

		_StencilComp("Stencil Comparison", Float) = 8
		_Stencil("Stencil ID", Float) = 0
		_StencilOp("Stencil Operation", Float) = 0
		_StencilWriteMask("Stencil Write Mask", Float) = 255
		_StencilReadMask("Stencil Read Mask", Float) = 255

		_ColorMask("Color Mask", Float) = 15

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
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
			#include "Assets/CGInclude/LGameUI.cginc"

			#pragma multi_compile __ UNITY_UI_ALPHACLIP
			#pragma multi_compile __ SOFT_CLIP

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
				fixed4 color : COLOR;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
				fixed4 color : COLOR;
				float4 worldPosition : TEXCOORD2;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

			fixed4 _TopColor;
			fixed4 _ButtomColor;
			float _TopY;
			float _ButtomY;

			float4 _BorderBlend;
			float4 _ClipRect;

            v2f vert (appdata v)
            {
                v2f o;
				o.worldPosition = v.vertex;
                o.vertex = UnityObjectToClipPos(v.vertex);

				float rate = (v.vertex.y - _ButtomY) / (_TopY - _ButtomY);
				rate = clamp(rate, 0, 1);
				o.color = lerp(_TopColor, _ButtomColor, rate) * v.color;

                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
				fixed4 color = i.color;
				color.a *= tex2D(_MainTex, i.uv).a;

#ifdef SOFT_CLIP
				color.a *= LGameGetSoft2DClipping(i.worldPosition, _ClipRect, _BorderBlend);
#else
				color.a *= UnityGet2DClipping(i.worldPosition, _ClipRect);
#endif

#ifdef UNITY_UI_ALPHACLIP
				clip(color.a - 0.001);
#endif

                return color;
            }
            ENDCG
        }
    }
}
