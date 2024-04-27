/*********************************************************************************
2017-10-19 11:55:57
@yvanliao
1.通过 Image 组件里的 color.r 控制饱和度
2.支持ETC1 （也可以自己设置透明贴图）
3.支持UGUI Mask

2017-10-26 18:55:57
@yvanliao
皮肤选择界面的shader
1.使用R通道控制整体饱和度
2.根据uv高度控制透明度
3.使用G通道控制模糊（均值模糊）
4.支持ugui自带Mask
*********************************************************************************/


Shader "Unlit/Transparent Alpha Split Blur Gray"
{
	Properties
	{
		[PerRendererData] _MainTex ("Sprite Texture", 2D) = "white" {}
		_AlphaTex("Sprite Alpha Texture", 2D) = "white" {}
		_Color ("Tint", Color) = (1,1,1,1)

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
		//按照unity模板修改了tag。by：yvanliao
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
			#pragma target 3.0

			//貌似没用到这个宏，注释掉了。	by：yvanliao
           // #pragma multi_compile GRAY_OFF GRAY_ON
			#include "UnityCG.cginc"
			#include "UnityUI.cginc"
	
			//透明度裁切的开关
			#pragma multi_compile __ UNITY_UI_ALPHACLIP

			struct VS_INPUT
			{
				float4 vertex : POSITION;
				fixed4 color : COLOR;
				half2 texcoord : TEXCOORD0;
			};

			struct VS_OUTPUT
			{
				float4 pos : SV_POSITION;
				fixed4 color : COLOR;
				half2 texcoord : TEXCOORD0;
				half4 uv12 : TEXCOORD1;
				half4 uv34 : TEXCOORD2;

				float4 worldPosition : TEXCOORD3;
			};
	
			sampler2D _MainTex;
			sampler2D _AlphaTex;

			fixed4 _Color;

			float4 _MainTex_TexelSize; 
			fixed4 _TextureSampleAdd;
			float4 _ClipRect;


			VS_OUTPUT vert (VS_INPUT IN)
			{
				VS_OUTPUT OUT;
				OUT.worldPosition = IN.vertex;
				OUT.pos = UnityObjectToClipPos(OUT.worldPosition);
				OUT.texcoord = IN.texcoord;

				OUT.uv12.xy = IN.texcoord.xy + (1 - IN.color.g) * _MainTex_TexelSize * float2( 0, -1) * 10;  
				OUT.uv12.zw = IN.texcoord.xy + (1 - IN.color.g) * _MainTex_TexelSize * float2(-1,  0) * 10;  
				OUT.uv34.xy = IN.texcoord.xy + (1 - IN.color.g) * _MainTex_TexelSize * float2( 0,  1) * 10;  
				OUT.uv34.zw = IN.texcoord.xy + (1 - IN.color.g) * _MainTex_TexelSize * float2( 1,  0) * 10;

				OUT.color = IN.color;

				return OUT;
			}


			fixed4 frag (VS_OUTPUT IN) : SV_Target
			{

				//使用unity自带的函数计算主纹理和透明度纹理
				fixed4 color = fixed4(0,0,0,0); 
				
				color += UnityGetUIDiffuseColor(IN.texcoord, _MainTex, _AlphaTex, _TextureSampleAdd) ;

				//模糊
				color += UnityGetUIDiffuseColor(IN.uv12.xy, _MainTex, _AlphaTex, _TextureSampleAdd) ;
				color += UnityGetUIDiffuseColor(IN.uv12.zw, _MainTex, _AlphaTex, _TextureSampleAdd) ;
				color += UnityGetUIDiffuseColor(IN.uv34.xy, _MainTex, _AlphaTex, _TextureSampleAdd) ;
				color += UnityGetUIDiffuseColor(IN.uv34.zw, _MainTex, _AlphaTex, _TextureSampleAdd) ;
				color *= 0.2;
				
				//Mask相关的一些计算。 by：yvanliao
				color.a *= UnityGet2DClipping(IN.worldPosition.xy, _ClipRect) * IN.color.a;

				color.a *= saturate(IN.texcoord.y*2 - 0.1);

				//饱和度计算，使用顶点色的r值控制饱和度
				color.rgb = lerp( Luminance(color.rgb).rrr , color.rgb , IN.color.r);

				//使用透明度裁切。 by：yvanliao
				#ifdef UNITY_UI_ALPHACLIP
					clip (color.a - 0.001);
				#endif

				return color;
			}
			ENDCG
		}
	}
}
