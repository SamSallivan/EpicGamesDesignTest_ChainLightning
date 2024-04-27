// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

Shader "UI/Default"
{
	Properties
	{
		[PerRendererData] _MainTex ("Sprite Texture", 2D) = "white" {}
		_Color ("Tint", Color) = (1,1,1,1)
		
		_StencilComp ("Stencil Comparison", Float) = 8
		_Stencil ("Stencil ID", Float) = 0
		_StencilOp ("Stencil Operation", Float) = 0
		_StencilWriteMask ("Stencil Write Mask", Float) = 255
		_StencilReadMask ("Stencil Read Mask", Float) = 255

		_ColorMask ("Color Mask", Float) = 15

		_BorderBlend("Border Blend Range", Vector) = (0, 0, 0, 0)
		_BorderBlendAlpha("Border Blend Alpha Range", vector) = (0,0,0,0)

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
		Blend SrcAlpha OneMinusSrcAlpha, Zero OneMinusSrcAlpha
		ColorMask [_ColorMask]

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
			#include "Assets/CGInclude/LGameSysUI.cginc"

			#pragma multi_compile __ UNITY_UI_ALPHACLIP SOFT_CLIP 
			
// Disabled by Shader Kit#pragma multi_compile __ SOFT_CLIP
			
			struct appdata_t
			{
				float4 vertex   : POSITION;
				float4 color    : COLOR;
				float2 texcoord : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct v2f
			{
				float4 vertex   : SV_POSITION;
				fixed4 color    : COLOR;
				float2 texcoord  : TEXCOORD0;
				float4 worldPosition : TEXCOORD1;
				UNITY_VERTEX_OUTPUT_STEREO
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
				UNITY_SETUP_INSTANCE_ID(IN);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(OUT);
				OUT.worldPosition = IN.vertex;
				OUT.vertex = UnityObjectToClipPos(OUT.worldPosition);

				OUT.texcoord = IN.texcoord;
				
				OUT.color = IN.color * _Color;
				return OUT;
			}

			sampler2D _MainTex;

			 inline float GetSoft2DClipping (in float2 position, in float4 clipRect , in half4 borderBlend)
			{
				//float2 range = max(0, float2(horizontal , vertical));
			 	float2 inside = smoothstep(clipRect.xy , clipRect.xy + borderBlend.xy, position.xy) * smoothstep(clipRect.zw , clipRect.zw - borderBlend.zw, position.xy) ;
			 	return inside.x * inside.y;
			}

			fixed4 frag(v2f IN) : SV_Target
			{
				half4 color = (tex2D(_MainTex, IN.texcoord,float2(0,0),float2(0,0)) + _TextureSampleAdd) * IN.color;

	#ifdef SOFT_CLIP
					color.a *= LGameGetSoft2DClippingEx(IN.worldPosition.xy, _ClipRect, _BorderBlend, _BorderBlendAlpha);
	//#elif 
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
