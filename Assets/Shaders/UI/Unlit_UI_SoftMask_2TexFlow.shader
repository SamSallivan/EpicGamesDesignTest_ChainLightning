Shader "Unlit/UI_SoftMask_2TexFlow"
{
	Properties
	{
		[HideInInspector][Enum(UnityEngine.Rendering.BlendMode)] 		_SrcFactor ("SrcFactor()", Float) = 5
		[HideInInspector][Enum(UnityEngine.Rendering.BlendMode)] 		_DstFactor ("DstFactor()", Float) = 10
		_MainColor ("Tint", Color) = (1,1,1,1)
		[PerRendererData] _MainTex ("Alpha", 2D) = "white" {}
		[Space(20)]
		_Tex1("Sprite Texture1", 2D) = "white" {}
		_Color1 ("Color1", Color) = (1,1,1,1)
		_Intensity1("Intensity1" , Range(0,8)) = 1
		[Toggle]_UVrotate1("Tex1 UV Rotate?" , float) = 0
		[LGameSDK.AnimTool.HideIfDisabledDrawer(_UVROTATE1_ON)]_Tex1Rot ("Angle", Float ) = 0

		[Space(20)]
		_Tex2("Sprite Texture2", 2D) = "black" {}
		_Color2 ("Color2", Color) = (1,1,1,1)
		_Intensity2("Intensity2" , Range(0,8)) = 1
		[Toggle]_UVrotate2("Tex2 UV Rotate?" , float) = 0
		[LGameSDK.AnimTool.HideIfDisabledDrawer(_UVROTATE2_ON)]_Tex2Rot ("Angle", Float ) = 0

		[Space(20)]
		_FlowSpeed("Flow Speed(xy for Tex1, zw for Tex2)", vector) = (0,0,0,0)
        _BorderBlend("Border Blend Range", vector) = (0,0,0,0)

		[HideInInspector]_StencilComp ("Stencil Comparison", Float) = 8
		[HideInInspector]_Stencil ("Stencil ID", Float) = 0
		[HideInInspector]_StencilOp ("Stencil Operation", Float) = 0
		[HideInInspector]_StencilWriteMask ("Stencil Write Mask", Float) = 255
		[HideInInspector]_StencilReadMask ("Stencil Read Mask", Float) = 255

		[HideInInspector]_ColorMask ("Color Mask", Float) = 15
        
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
		//Blend SrcAlpha OneMinusSrcAlpha
		Blend [_SrcFactor] [_DstFactor]

		ColorMask [_ColorMask]

		Pass
		{
			Name "Default"
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma shader_feature __ _UVROTATE1_ON
			#pragma shader_feature __ _UVROTATE2_ON
			
			#include "UnityCG.cginc"
			#include "Assets/CGInclude/LGameUI.cginc"



			struct appdata
			{
				float4 vertex	: POSITION;
				fixed4 color	: COLOR;
				float2 texcoord	: TEXCOORD0;
			};

			struct v2f
			{
				float2 uv		: TEXCOORD0;
				float4 flowUV	: TEXCOORD1;
				float4 wPos		: TEXCOORD2;
				fixed4 color	: COLOR;
				float4 pos		: SV_POSITION;
			};

			sampler2D	_MainTex;
			sampler2D	_Tex1,_Tex2;
			fixed4		_Tex1_ST,_Tex2_ST;
			fixed4		_MainColor;
			fixed4		_Color1 , _Color2;
			half		_Intensity1 , _Intensity2;
			fixed4		_TextureSampleAdd;
			half4		_ClipRect;
            half4		_BorderBlend;
			half4		_FlowSpeed;
			#if _UVROTATE1_ON
			half		_Tex1Rot;
			#endif 
			#if _UVROTATE2_ON
			half		_Tex2Rot;
			#endif 
			
			v2f vert (appdata v)
			{
				v2f o;
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
				o.wPos = v.vertex;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = v.texcoord;
			    o.flowUV.xy = LGameTransFormUV(v.texcoord , _Tex1) ;
				#if _UVROTATE1_ON
					o.flowUV.xy = LGameRotateUV(o.flowUV.xy, _Tex1Rot);
				#endif 
				
				o.flowUV.xy += _Time.y * _FlowSpeed.xy;

				o.flowUV.zw = LGameTransFormUV(v.texcoord , _Tex2) ;
				#if _UVROTATE2_ON
					o.flowUV.zw = LGameRotateUV(o.flowUV.zw , _Tex2Rot);
				#endif 
				o.flowUV.zw += _Time.y * _FlowSpeed.zw;

				o.color = v.color * _MainColor;
				return o;
			}

			fixed4 frag (v2f i) : SV_Target
			{
				fixed4 tex1 = tex2D(_Tex1 , i.flowUV.xy ) *_Color1 * _Intensity1;
				fixed4 tex2 = tex2D(_Tex2 , i.flowUV.zw ) *_Color2 * _Intensity2;
				fixed alpha = tex2D(_MainTex , i.uv).r;
				fixed4 color = i.color;
				color.rgb *= (tex1.rgb + tex2.rgb) ;
				color.a *= alpha * tex1.a * tex2.a;
				color.a *= LGameGetSoft2DClipping(i.wPos.xy , _ClipRect , _BorderBlend);

				return color;
			}
			ENDCG
		}
	}
}
