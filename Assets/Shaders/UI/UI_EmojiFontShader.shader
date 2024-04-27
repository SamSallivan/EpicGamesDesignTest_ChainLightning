// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "UI/EmojiFontShader" {
	Properties {
		[PerRendererData] _MainTex ("Main Texture", 2D) = "white" {}
		_Color ("Tint", Color) = (1,1,1,1)
		
		_StencilComp ("Stencil Comparison", Float) = 8
		_Stencil ("Stencil ID", Float) = 0
		_StencilOp ("Stencil Operation", Float) = 0
		_StencilWriteMask ("Stencil Write Mask", Float) = 255
		_StencilReadMask ("Stencil Read Mask", Float) = 255
		
		_ColorMask ("Color Mask", Float) = 15
		
		[Toggle(UNITY_UI_ALPHACLIP)] _UseUIAlphaClip ("Use Alpha Clip", Float) = 0

		_EmojiTex ("Emoji Texture", 2D) = "white" {}
		_FrameSpeed ("FrameSpeed",Range(0,10)) = 3

		_BorderBlend("Border Blend Range", Vector) = (0, 0, 0, 0)
		_BorderBlendAlpha("Border Blend Alpha Range", vector) = (0,0,0,0)
	}
	
	SubShader
	{
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
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 2.0

			#include "UnityCG.cginc"
			#include "UnityUI.cginc"
			#include "Assets/CGInclude/LGameSysUI.cginc"

			#pragma multi_compile __ UNITY_UI_ALPHACLIP SOFT_CLIP
			
			struct appdata_t
			{
				float4 vertex   : POSITION;
				float4 color    : COLOR;
				float2 texcoord0 : TEXCOORD0;
				float2 texcoord1 : TEXCOORD1;
			};

			struct v2f
			{
				float4 vertex   : SV_POSITION;
				half4 color    : COLOR;
				half2 texcoord0  : TEXCOORD0;
				half2 texcoord1 : TEXCOORD1;
				float4 worldPosition : TEXCOORD2;
			};
			
			fixed4 _Color;
			fixed4 _TextureSampleAdd;
			float4 _ClipRect;

#ifdef SOFT_CLIP
			half4 _BorderBlend;
			float4 _BorderBlendAlpha;
#endif

			v2f vert(appdata_t IN)
			{
				v2f OUT;
				OUT.worldPosition = IN.vertex;
				OUT.vertex = UnityObjectToClipPos(OUT.worldPosition);

				OUT.texcoord0 = IN.texcoord0;
				OUT.texcoord1 = IN.texcoord1;
				
				#ifdef UNITY_HALF_TEXEL_OFFSET
				OUT.vertex.xy += (_ScreenParams.zw-1.0) * float2(-1,1) * OUT.vertex.w;
				#endif
				
				OUT.color = IN.color * _Color;
				return OUT;
			}

			sampler2D _MainTex;
			sampler2D _EmojiTex;
			float _FrameSpeed;

			fixed4 frag(v2f IN) : SV_Target
			{
                // uv0用于font的uv
                // uv0用于alpha， uv1用于sprite
                half4 fontColor = tex2D(_MainTex, IN.texcoord0) + _TextureSampleAdd;

                half4 emojiColor = tex2D(_EmojiTex, IN.texcoord1);

                half useEmoji = step(0.0001, IN.texcoord1.x + IN.texcoord1.y);
                
                half4 color = (1 - useEmoji) * fontColor + useEmoji * emojiColor;
                color *= IN.color;
                
#ifdef SOFT_CLIP
				color.a *= LGameGetSoft2DClippingEx(IN.worldPosition.xy, _ClipRect, _BorderBlend, _BorderBlendAlpha);

		//		color.a *= UnityGet2DClipping(IN.worldPosition.xy, _ClipRect);
#endif

				#ifdef UNITY_UI_ALPHACLIP
				clip (color.a - 0.001);
				#endif

				return color;
			}
			ENDCG
		}
	}
}
