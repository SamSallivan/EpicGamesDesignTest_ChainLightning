// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "UI/EmojiFontShaderShadow" {
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

		_ShadowColor("Shadow Color", Color) = (0, 0, 0, 0.5)
        _ShadowOffsetX("Shadow Offset X", Float) = 1
        _ShadowOffsetY("Shadow Offset Y", Float) = -1
	}
	CGINCLUDE

		#include "UnityCG.cginc"
		#include "UnityUI.cginc"

		struct appdata_t_shadow
		{
			float4 vertex   : POSITION;
			float2 texcoord : TEXCOORD0;
			float2 texcoord1: TEXCOORD1;
			UNITY_VERTEX_INPUT_INSTANCE_ID
		};

		struct appdata_t_default
		{
			float4 vertex   : POSITION;
			float4 color    : COLOR;
			float2 texcoord0 : TEXCOORD0;
			float2 texcoord1 : TEXCOORD1;
		};

		struct v2f_shadow
		{
			float4 vertex   : SV_POSITION;
			float2 texcoord  : TEXCOORD0;
			float4 worldPosition : TEXCOORD1;
			float4 uvRect: TEXCOORD2;
			UNITY_VERTEX_OUTPUT_STEREO
		};

		struct v2f_default
		{
			float4 vertex   : SV_POSITION;
			half4 color    : COLOR;
			half2 texcoord0  : TEXCOORD0;
			half2 texcoord1 : TEXCOORD1;
			float4 worldPosition : TEXCOORD2;
		};

		sampler2D _MainTex;
		fixed4 _ShadowColor;
		half _ShadowOffsetX;
		half _ShadowOffsetY;
		float4 _ClipRect;
		half4 _BorderBlend;
		fixed4 _Color;
		fixed4 _TextureSampleAdd;
		sampler2D _EmojiTex;
		float _FrameSpeed;
		float4 _MainTex_TexelSize;

		v2f_shadow vert_shadow(appdata_t_shadow IN)
		{
			v2f_shadow OUT;
			UNITY_SETUP_INSTANCE_ID(IN);
			UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(OUT);
			OUT.worldPosition = IN.vertex;
			OUT.vertex = UnityObjectToClipPos(OUT.worldPosition);
			OUT.texcoord = IN.texcoord;

			float uvRectTag = step(1, IN.texcoord1.x) * step(1, IN.texcoord1.y);
			float2 diagUV = float2(IN.texcoord1.x - 2, IN.texcoord1.y - 2);
			OUT.uvRect = float4(min(IN.texcoord, diagUV), max(IN.texcoord, diagUV)) * uvRectTag;
			return OUT;
		}

		inline float GetSoft2DClipping(in float2 position, in float4 clipRect, in half4 borderBlend)
		{
			//float2 range = max(0, float2(horizontal , vertical));
			float2 inside = smoothstep(clipRect.xy, clipRect.xy + borderBlend.xy, position.xy) * smoothstep(clipRect.zw, clipRect.zw - borderBlend.zw, position.xy);
			return inside.x * inside.y;
		}

		fixed SampleAlpha(int pIndex, v2f_shadow IN)
		{
			const fixed sinArray[8] = { 0, 0.707, 1, 0.707, 0, -0.707, -1, -0.707 };
			const fixed cosArray[8] = { 1, 0.707, 0, -0.707, -1, -0.707, 0, 0.707 };
			float2 texOffCoord = IN.texcoord + _MainTex_TexelSize.xy * float2(cosArray[pIndex] * _ShadowOffsetX, sinArray[pIndex] * _ShadowOffsetY);
			// 仅采样在当前字符UV框内的像素
			return (tex2D(_MainTex, texOffCoord)).a * _ShadowColor.a * 
				step(texOffCoord.x, IN.uvRect.z) * step(texOffCoord.y, IN.uvRect.w) * step(IN.uvRect.x, texOffCoord.x) * step(IN.uvRect.y, texOffCoord.y);
		}

		fixed4 frag_shadow(v2f_shadow IN) : SV_Target
		{
			fixed4 color = fixed4(0, 0, 0, 0);

			color.rgb = _ShadowColor.rgb;
			color.a += SampleAlpha(0, IN); color.a += SampleAlpha(1, IN); color.a += SampleAlpha(2, IN); color.a += SampleAlpha(3, IN);
			color.a += SampleAlpha(4, IN); color.a += SampleAlpha(5, IN); color.a += SampleAlpha(6, IN); color.a += SampleAlpha(7, IN);
			color.a = clamp(color.a, 0, 1);

#ifdef SOFT_CLIP
				color.a *= GetSoft2DClipping(IN.worldPosition.xy, _ClipRect, _BorderBlend);

//				color.a *= UnityGet2DClipping(IN.worldPosition.xy, _ClipRect);
#endif

#ifdef UNITY_UI_ALPHACLIP
					clip(color.a - 0.001);
#endif
			return color;
		}

		v2f_default vert_default(appdata_t_default IN)
		{
			v2f_default OUT;
			OUT.worldPosition = IN.vertex;
			OUT.vertex = UnityObjectToClipPos(OUT.worldPosition);
			float emojiTag = step(IN.texcoord1.x, 1) * step(IN.texcoord1.y, 1);

			OUT.texcoord0 = IN.texcoord0;
			OUT.texcoord1 = IN.texcoord1 * emojiTag;

#ifdef UNITY_HALF_TEXEL_OFFSET
			OUT.vertex.xy += (_ScreenParams.zw - 1.0) * float2(-1, 1) * OUT.vertex.w;
#endif

			OUT.color = IN.color * _Color;
			return OUT;
		}

		fixed4 frag_default(v2f_default IN) : SV_Target
		{
			// uv0用于font的uv
			// uv0用于alpha， uv1用于sprite
			half4 fontColor = tex2D(_MainTex, IN.texcoord0) + _TextureSampleAdd;

			half4 emojiColor = tex2D(_EmojiTex, IN.texcoord1);

			half useEmoji = step(0.0001, IN.texcoord1.x + IN.texcoord1.y);

			half4 color = (1 - useEmoji) * fontColor + useEmoji * emojiColor;
			color *= IN.color;

			color.a *= UnityGet2DClipping(IN.worldPosition.xy, _ClipRect);

			#ifdef UNITY_UI_ALPHACLIP
			clip(color.a - 0.001);
			#endif

			return color;
		}

	ENDCG
	
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
		
		//default pass
		Pass
            {
                Name "EmojiFontShadow"
                CGPROGRAM
                #pragma vertex vert_shadow
                #pragma fragment frag_shadow
                #pragma target 2.0
                #pragma multi_compile __ UNITY_UI_ALPHACLIP
                #pragma multi_compile __ SOFT_CLIP
                ENDCG
            }

		Pass
		{
			Name "EmojiFontDefault"
			CGPROGRAM
			#pragma vertex vert_default
			#pragma fragment frag_default
			#pragma target 2.0
			#pragma multi_compile __ UNITY_UI_ALPHACLIP
			ENDCG
		}

		//srp pass
		Pass
		{
			Name "EmojiFontShadowSrp"
			Tags { "LightMode" = "EmojiFontShadow" }
			CGPROGRAM
			#pragma vertex vert_shadow
			#pragma fragment frag_shadow
			#pragma target 2.0
			#pragma multi_compile __ UNITY_UI_ALPHACLIP
			#pragma multi_compile __ SOFT_CLIP
			ENDCG
		}

		Pass
		{
			Name "EmojiFontDefaultSrp"
			Tags { "LightMode" = "EmojiFontDefault" }
			CGPROGRAM
			#pragma vertex vert_default
			#pragma fragment frag_default
			#pragma target 2.0
			#pragma multi_compile __ UNITY_UI_ALPHACLIP
			ENDCG
		}
	}
}
