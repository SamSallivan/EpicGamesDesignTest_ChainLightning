// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

Shader "LGame/Effect/MaskableObject"
{
	Properties
	{
		_AlphaCtrl("AlphaCtrl",range(0,1)) = 1

		_Color("Color", Color) = (1,1,1,1)
		_MainTex("Albedo", 2D) = "white" {}
		_RimLightColor("RimLight Color" , Color) = (0,0,0,1) //±ﬂ‘µπ‚—’…´
		_RimLighRange("RimLigh Range", Range(0.1,10)) = 1 //±ﬂ‘µπ‚∑∂Œß
		_RimLighMultipliers("RimLigh Multipliers", Range(0, 5)) = 0//±ﬂ‘µπ‚«ø∂»

		[Header(In Mask)]
		_MaskColor("Mask Color", Color) = (0.5,0.5,0.5,0.5)

		[Header(xxxxxxxxxxxxxxxxxx)]
		[Header(Do Not Touch part)]
		[Header(xxxxxxxxxxxxxxxxxx)]


		[Enum(Off, 0, On, 1)]_ZWrite("ZWrite", Float) = 1

		[IntRange]_Stencil("Stencil ID", Range(0,255)) = 5
		[Enum(UnityEngine.Rendering.CompareFunction)]_StencilComp("Stencil Comparison", Float) = 5
		[Enum(UnityEngine.Rendering.StencilOp)]_StencilOp("Stencil Pass", Float) = 1
		[IntRange] _StencilWriteMask("Stencil Write Mask", Range(0,255)) = 255
		[IntRange] _StencilReadMask("Stencil Read Mask", Range(0,255)) = 255
	}

	CGINCLUDE
		#include "UnityCG.cginc" 
		struct a2v
		{
			float3 normal	: NORMAL;

			half2 texcoord			: TEXCOORD0;
			float4 vertex			: POSITION;
		};
		struct v2f
		{
			fixed4 	color : COLOR;

			half2 uv			: TEXCOORD0;
			float4 pos			: SV_POSITION;
		};


		half4		_Color;
		half4		_MaskColor ;
		sampler2D	_MainTex;
		half4		_MainTex_ST;
		fixed4		_RimLightColor;
		half		_RimLighRange;
		half		_RimLighMultipliers;
		half		_AlphaCtrl;

		v2f vert(a2v v)
		{
			v2f o;

			o.pos = UnityObjectToClipPos(v.vertex);
			o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex);

			fixed3 objViewDir = normalize(ObjSpaceViewDir(v.vertex));
			o.color.rgb = _RimLightColor ;
			o.color.a = pow(1 - abs(dot(objViewDir, normalize(v.normal))),_RimLighRange) * _RimLighMultipliers;
			
			return o;
		}

		fixed4 frag_m(v2f i) : SV_Target
		{
			fixed4 col = tex2D(_MainTex, i.uv) * _Color ;
			col.rgb += 	i.color.rgb  * i.color.a; 
			col.a *= _AlphaCtrl;
			col.rgb *= col.a;
			return  col* _MaskColor;
		}
		fixed4 frag(v2f i) : SV_Target
		{
			fixed4 col = tex2D(_MainTex, i.uv) * _Color ;
			col.rgb += 	i.color.rgb  * i.color.a; 
			col.a *= _AlphaCtrl;
			col.rgb *= col.a;
			return  col;
		}
	ENDCG
	SubShader
	{
		Tags{"Queue" = "Transparent" "RenderType" = "Transparent"}
		LOD 75
		//’⁄’÷÷–‰÷»æ
		Pass
		{
			Name "MaskableObjectPass"
			ZWrite off
			ZTest Greater
			Blend SrcAlpha OneMinusSrcAlpha
			Stencil
			{
				Ref[_Stencil]
				Comp[_StencilComp]
				Pass[_StencilOp]
				ReadMask[_StencilReadMask]
				WriteMask[_StencilWriteMask]
			}
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag_m
			ENDCG
		}
		//ª˘¥°Pass
		Pass
		{
			Name "Defut"
			ZWrite[_ZWrite]
			Blend One OneMinusSrcAlpha
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			ENDCG
		}
		//’⁄’÷÷–‰÷»æ
		Pass
		{
			Tags{"LightMode" = "ForwardBaseMultiPass"}

			Name "MaskableObjectPass"
			ZWrite off
			ZTest Greater
			Blend SrcAlpha OneMinusSrcAlpha
			Stencil
			{
				Ref[_Stencil]
				Comp[_StencilComp]
				Pass[_StencilOp]
				ReadMask[_StencilReadMask]
				WriteMask[_StencilWriteMask]
			}
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag_m
			ENDCG
		}
		//ª˘¥°Pass
		Pass
		{
			Tags{"LightMode" = "ForwardBase"}
			Name "Defut"
			ZWrite[_ZWrite]
			Blend One OneMinusSrcAlpha
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			ENDCG
		}

	}
}
