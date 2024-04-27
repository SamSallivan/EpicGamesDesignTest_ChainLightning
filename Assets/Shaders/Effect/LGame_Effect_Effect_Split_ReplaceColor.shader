// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

Shader "LGame/Effect/Effect_Split_ReplaceColor"
{
	Properties
	{
		[PerRendererData] _MainTex ("Sprite Texture", 2D) = "white" {}
		_AlphaTex("Sprite Alpha Texture", 2D) = "white" {}
		_Color ("Tint", Color) = (1,1,1,1)

        _BorderBlend("Border Blend Range", vector) = (0,0,0,0)
		_StencilComp ("Stencil Comparison", Float) = 8
		_Stencil ("Stencil ID", Float) = 0
		_StencilOp ("Stencil Operation", Float) = 0
		_StencilWriteMask ("Stencil Write Mask", Float) = 255
		_StencilReadMask ("Stencil Read Mask", Float) = 255

		_ColorMask ("Color Mask", Float) = 15
		[Toggle(UNITY_UI_ALPHACLIP)] _UseUIAlphaClip ("Use Alpha Clip", Float) = 0
	}
	
	SubShader
	{
		//按照unity模板修改了tag
		Tags
		{ 
			"Queue"="Transparent" 
			"IgnoreProjector"="True" 
			"RenderType"="Transparent" 
			"PreviewType"="Plane"
			"CanUseSpriteAtlas"="True"
		}

		Stencil
		{
			Ref [_Stencil]
			Comp [_StencilComp]
			Pass [_StencilOp] 
			ReadMask [_StencilReadMask]
			WriteMask [_StencilWriteMask]
		}
		
		Cull Off
		Lighting Off
		ZWrite Off
		ZTest [unity_GUIZTestMode]
		Blend SrcAlpha OneMinusSrcAlpha
		ColorMask [_ColorMask]
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
				float4 color : COLOR;
				half2 texcoord : TEXCOORD0;
			};

			struct VS_OUTPUT
			{
				float4 pos : SV_POSITION;
                float4 color : COLOR;
				half2 texcoord : TEXCOORD0;
			};
	
			sampler2D _MainTex;
			sampler2D _AlphaTex;

			fixed4 _Color;
			fixed4 _TextureSampleAdd;

			VS_OUTPUT vert (VS_INPUT IN)
			{
				VS_OUTPUT OUT;
				OUT.pos = UnityObjectToClipPos(IN.vertex);
				OUT.texcoord = IN.texcoord;
				OUT.color = IN.color;

				return OUT;
			}
		
			fixed4 frag (VS_OUTPUT IN) : SV_Target
			{
				fixed4 color =(tex2D(_MainTex, IN.texcoord) + _TextureSampleAdd);
                color.a *= tex2D(_AlphaTex,IN.texcoord).r;
                fixed luminance=Luminance(color.rgb);
                fixed3 exColor = fixed3(1,1,1);
				color.rgb=lerp(luminance*exColor,color.rgb,IN.color.r);
                color.a = IN.color.a * color.a;
				#ifdef UNITY_UI_ALPHACLIP
					clip (color.a - 0.001);
				#endif
				return color;
			}
			ENDCG
		}
	}
}