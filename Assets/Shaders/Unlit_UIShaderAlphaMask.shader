// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unlit/UIShader Alpha Mask"

{
	Properties
	{
		[PerRendererData] _MainTex ("Sprite Texture", 2D) = "white" {}
        _AlphaTex ("Alpha Texture", 2D) = "white" {}
		
		_BorderBlend("Border Blend Range", Vector) = (0, 0, 0, 0)
		_BorderBlendAlpha("Border Blend Alpha Range", vector) = (0,0,0,0)
		
		_StencilComp ("Stencil Comparison", Float) = 8
		_Stencil ("Stencil ID", Float) = 0
		_StencilOp ("Stencil Operation", Float) = 0
		_StencilWriteMask ("Stencil Write Mask", Float) = 255
		_StencilReadMask ("Stencil Read Mask", Float) = 255

		[Toggle(UNITY_UI_ALPHACLIP)] _UseUIAlphaClip ("Use Alpha Clip", Float) = 0
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
			"LightMode" = "ForwardBase"
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
		ColorMask RGBA

		Pass
		{
		CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"
			#include "Assets/CGInclude/LGameSysUI.cginc"

			#pragma multi_compile __ UNITY_UI_ALPHACLIP SOFT_CLIP
			
			struct appdata_t
			{
				float4 vertex   : POSITION;
				float4 color    : COLOR;
				float2 texcoord : TEXCOORD0;
			};

			struct v2f
			{
				float4 vertex   : SV_POSITION;
				fixed4 color    : COLOR;
				half4 texcoord  : TEXCOORD0;
				float4 worldPosition : TEXCOORD1;
				half2  gray : TEXCOORD3;
			};

            sampler2D _MainTex, _AlphaTex;
			
			fixed4 _TextureSampleAdd;
			float4 _ClipRect;
            float4 _AlphaTex_ST;
		
		#ifdef SOFT_CLIP
			half4 _BorderBlend;
			float4 _BorderBlendAlpha;
		#endif

			v2f vert(appdata_t IN)
			{
				v2f OUT;
				OUT.worldPosition = IN.vertex;
				OUT.vertex = UnityObjectToClipPos(OUT.worldPosition);

				OUT.texcoord.xy = IN.texcoord;
				OUT.texcoord.zw = TRANSFORM_TEX(IN.texcoord , _AlphaTex);
				#ifdef UNITY_HALF_TEXEL_OFFSET
				OUT.vertex.xy += (_ScreenParams.zw-1.0)*float2(-1,1);
				#endif
				
				OUT.color = IN.color;
				OUT.gray.x = clamp(255 * (IN.color.r + IN.color.g + IN.color.b), 0, 1);
				OUT.gray.y = 0;
				return OUT;
			}
		
			fixed4 frag(v2f IN) : SV_Target
			{
				half4 color = (tex2D(_MainTex, IN.texcoord.xy) + _TextureSampleAdd);
                half mask = tex2D(_AlphaTex, IN.texcoord.zw).r;
				color.a *= mask * step(0, IN.texcoord.z) * step(IN.texcoord.z, 1) * step(0, IN.texcoord.w) * step(IN.texcoord.w, 1);
				
				#ifdef SOFT_CLIP
				color.a *= LGameGetSoft2DClippingEx(IN.worldPosition.xy, _ClipRect, _BorderBlend, _BorderBlendAlpha);
				#endif

				fixed4 mixColor = color * IN.color;
				fixed4 grayResult = dot(color, fixed4(0.299, 0.587, 0.114, 0));
				grayResult.a = mixColor.a;
				color = IN.gray.x * mixColor + (1 - IN.gray.x) * grayResult;
				
				#ifdef UNITY_UI_ALPHACLIP
				clip (color.a - 0.001);
				#endif
				return color;
			}
		ENDCG
		}
	}
}
