Shader "UI/Alpha Mask FOWTexture"
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

		_NeedToRotate("Need to Rotate" , Int) = 0
		_NeedTo90Mirror("Need to 90 mirror" , Int) = 0
        _UIBound("UIBound", Vector) = (0,0,100,100)

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
			Ref			[_Stencil]
			Comp		[_StencilComp]
			Pass		[_StencilOp] 
			ReadMask	[_StencilReadMask]
			WriteMask	[_StencilWriteMask]
		}

		Cull Off
		Lighting Off
		ZWrite Off
		ZTest Less//[unity_GUIZTestMode]
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

			#pragma multi_compile __ UNITY_UI_ALPHACLIP
			#pragma multi_compile __ _FOW_ON _FOW_ON_CUSTOM
			struct appdata_t
			{
				float4 vertex			: POSITION;
				float4 color			: COLOR;
				float2 texcoord			: TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct v2f
			{
				float4 vertex			: SV_POSITION;
				fixed4 color			: COLOR;
				float2 texcoord			: TEXCOORD0;
				float4 worldPosition	: TEXCOORD1;
				UNITY_VERTEX_OUTPUT_STEREO
			};
			
			fixed4			_Color;
			fixed4			_TextureSampleAdd;
			float4			_ClipRect;

			
			#if _FOW_ON || _FOW_ON_CUSTOM
				float		_FOWBlend;
				sampler2D	_FOWTexture;
				//sampler2D	_FOWLastTexture;
                half4       _FOWParam;
                float4      _UIBound;
			#endif
			fixed		_NeedToRotate;
			fixed       _NeedTo90Mirror;

			v2f vert(appdata_t IN)
			{
				v2f OUT;
				UNITY_SETUP_INSTANCE_ID(IN);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(OUT);
				OUT.worldPosition = IN.vertex;
				OUT.vertex = UnityObjectToClipPos(OUT.worldPosition);
				OUT.texcoord = IN.texcoord ; 
				// #if _FOW_ON || _FOW_ON_CUSTOM
					OUT.texcoord = lerp( IN.texcoord , 1 - IN.texcoord , _NeedToRotate);
					
					/*fixed2 tex = OUT.texcoord;
					tex.x = lerp(OUT.texcoord.x , 1 - OUT.texcoord.y , _NeedTo90Mirror);
					tex.y = lerp(OUT.texcoord.y , 1 - OUT.texcoord.x , _NeedTo90Mirror);*/
					OUT.texcoord = lerp(OUT.texcoord , 1-OUT.texcoord.yx , _NeedTo90Mirror);
				// #endif
				OUT.color = IN.color * _Color;
				return OUT;
			}

			sampler2D _MainTex;

			fixed4 frag(v2f IN) : SV_Target
			{
				half4 mainTexColor = tex2D(_MainTex, IN.texcoord);
				half4 color = (mainTexColor + _TextureSampleAdd) * IN.color;

				color.a *= UnityGet2DClipping(IN.worldPosition.xy, _ClipRect) ;

#if _FOW_ON || _FOW_ON_CUSTOM
                float2 fowUV;
                fowUV.xy = ((IN.texcoord.xy - half2(0.5, 0.5)) * _UIBound.zw + _UIBound.xy - _FOWParam.xy) / _FOWParam.zw;

                half4 fow = tex2D(_FOWTexture, fowUV);

                //half4 fowLast = tex2D(_FOWLastTexture, fowUV);
				color.rgb *= 1 - lerp(fow.g, fow.r, _FOWBlend) * 0.7;
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
