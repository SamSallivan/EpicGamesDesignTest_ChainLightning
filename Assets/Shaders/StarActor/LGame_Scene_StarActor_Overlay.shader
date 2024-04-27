Shader "LGame/Scene/StarActor/Overlay"
{
    Properties
    {
		[Header(Default)]
		[HideInInspector]_OffsetFactor("Offset Factor ",Float) = 0
		[HideInInspector]_OffsetUnits("Offset Units ",Float) = 0
		[HideInInspector][Enum(UnityEngine.Rendering.BlendMode)] 		_SrcFactor("SrcFactor()", Float) = 5
		[HideInInspector][Enum(UnityEngine.Rendering.BlendMode)] 		_DstFactor("DstFactor()", Float) = 10
		[HideInInspector][Enum(UnityEngine.Rendering.BlendMode)] 		_SrcAlphaFactor("SrcAlphaFactor()", Float) = 0
		[HideInInspector][Enum(UnityEngine.Rendering.BlendMode)] 		_DstAlphaFactor("DstAlphaFactor()", Float) = 10
		[Enum(UnityEngine.Rendering.CullMode)] 							_CullMode("消隐模式(CullMode)", int) = 0
		[Enum(Off,0,On,1)]												_ZWriteMode("深度写入(ZWrite)", int) = 1
		[Enum(LessEqual,4,Always,8)]									_ZTestMode("深度测试(ZTest)", int) = 8
		[Enum(RGB,14,ALL,15, NONE,0)]									_ColorMask("颜色遮罩(ColorMask)", int) = 15
		_Color("Color", Color) = (1,1,1,1)
		_Multiplier("亮度",range(1,20)) = 1
		[HideInInspector]_GradientTex("Gradient Texture", 2D) = "white" {}
		[SimpleToggle] _ScaleOnCenter("以贴图中心进行uv缩放", Float) = 1
		_MainTex("MainTex", 2D) = "white" {}
		[WrapMode] _MainTexWrapMode("MainTex WrapMode", Vector) = (1,1,0,0)
		[TexTransform] _MainTexTransform("MainTex Transform" , Vector) = (0,0,0,1) //scrollU , scrollV , scrollRot
		_MaskTex("MaskTex", 2D) = "white" {}
		[WrapMode] _MaskTexWrapMode("MaskTex WrapMode", Vector) = (1,1,0,0)
		[TexTransform] _MaskTexTransform("MaskTex Transform" , Vector) = (0,0,0,1) //scrollU , scrollV , scrollRot
		_DissolveTex("DissolveTex", 2D) = "white" {}
		[SimpleToggle]_ToggleDissolveTex("RepeatUV",Float) = 1
		_Dissolve("Dissolve Value", Range(0, 1)) = 0
		_DissolveRange("Dissolve Range", Range(0, 10)) = 0
		_DissolveColor1("Dissolve Color1",color) = (1,0,0,1)
		_DissolveColor2("Dissolve Color2",color) = (0,0,0,1)
		[TexRotation]_DissolveRot("Dissolve Rotation", Vector) = (0,1,0)
		_FlowTex("FlowTex", 2D) = "black" {}
		[SimpleToggle]_ToggleFlowTex("RepeatUV",Float) = 1
		[TexTransform] _FlowTexTransform("FlowTex Transform" , Vector) = (0,0,0,1) //scrollU , scrollV , scrollRot
		_FlowScale("Flow Value", Range(0, 2)) = 0
		[HideInInspector] _StencilComp("Stencil Comparison", Float) = 8
		[HideInInspector] _Stencil("Stencil ID", Float) = 0
		[HideInInspector] _StencilOp("Stencil Operation", Float) = 0
		[HideInInspector] _StencilWriteMask("Stencil Write Mask", Float) = 255
		[HideInInspector] _StencilReadMask("Stencil Read Mask", Float) = 255
    }
	CGINCLUDE
	#include "UnityCG.cginc"
	#include "Assets/CGInclude/EffectCG.cginc"
	struct appdata
	{
		float4 vertex : POSITION;
		float4 uv : TEXCOORD0;
		fixed4 color : COLOR;
	};
	struct fragData
	{
		float4 uv12 : TEXCOORD0;
		float4 uv34 : TEXCOORD1;
		float4 vertex : SV_POSITION;
		fixed4 color : COLOR;
	};

	sampler2D _MainTex;
	half4 _MainTex_ST;
	float4 _MainTexTransform;
	fixed4 _MainTexWrapMode;
	fixed4 _Color;
	half _Multiplier;

#if _GRADIENT_ON
	sampler2D _GradientTex;
#endif

#if MaskTex_On
	sampler2D _MaskTex;
	half4 _MaskTex_ST;
	float4 _MaskTexTransform;
	fixed4 _MaskTexWrapMode;
#endif

#if DissolveTex_On	
		sampler2D _DissolveTex;
		half _DissolveRange;
		half _ToggleDissolveTex;
		half2 _DissolveRot;
		fixed4 _DissolveColor1;
		fixed4 _DissolveColor2;
		half4 _DissolveTex_ST;
		half _Dissolve;
#endif

#if FlowTex_On
		sampler2D _FlowTex;
		half _ToggleFlowTex;
		half4 _FlowTex_ST;
		float4 _FlowTexTransform;
		half _FlowScale;
#endif
		fixed _ScaleOnCenter;
		uniform float4  _MainTex_TexelSize;
		/////////////
		fragData vert(appdata v)
		{
			fragData o = (fragData)0;
			o.vertex = UnityObjectToClipPos(v.vertex);
			o.uv12.xy = TransFormUV(v.uv, _MainTex_ST, _ScaleOnCenter);
			o.uv12.xy = RotateUV(o.uv12.xy, _MainTexTransform.zw);
			o.uv12.xy += frac(_Time.z* _MainTexTransform.xy);

#if MaskTex_On
			o.uv12.zw = TransFormUV(v.uv,_MaskTex_ST, _ScaleOnCenter);
			o.uv12.zw = RotateUV(o.uv12.zw, _MaskTexTransform.zw);
			o.uv12.zw += frac(_Time.z * _MaskTexTransform.xy);
#endif

#if DissolveTex_On	
			o.uv34.xy = TransFormUV(v.uv,_DissolveTex_ST, _ScaleOnCenter);
			o.uv34.xy = RotateUV(o.uv34.xy, _DissolveRot);
#endif

#if FlowTex_On
			o.uv34.zw = TransFormUV(v.uv, _FlowTex_ST, _ScaleOnCenter);
			o.uv34.zw = RotateUV(o.uv34.zw, _FlowTexTransform.zw);
			o.uv34.zw += frac(_Time.z * _FlowTexTransform.xy);
#endif
			o.color = v.color*_Color*_Multiplier;
			return o;
		}
	ENDCG
    SubShader
    {
        Tags { "Queue" = "AlphaTest+150" "RenderType" = "Transparent" }
		ZWrite[_ZWriteMode]
		ZTest[_ZTestMode]
		Cull [_CullMode]
		ColorMask[_ColorMask]
		Offset[_OffsetFactor] ,[_OffsetUnits]
		Blend[_SrcFactor][_DstFactor],[_SrcAlphaFactor][_DstAlphaFactor]
		Stencil {
			Ref 16
			Comp NotEqual
			Pass keep
	    }
		//Stencil
		//{
		//	Ref[_Stencil]
		//	Comp[_StencilComp]
		//	Pass[_StencilOp]
		//	ReadMask[_StencilReadMask]
		//	WriteMask[_StencilWriteMask]
		//}
		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 3.0
			#pragma multi_compile __ _GRADIENT_ON
			#pragma shader_feature MaskTex_On
			#pragma shader_feature DissolveTex_On
			#pragma shader_feature FlowTex_On
			fixed4 frag(fragData i) : SV_Target
			{
				float4 flowUV = i.uv12.xyxy;
				#if FlowTex_On
					i.uv34.zw = lerp(i.uv34.zw, frac(i.uv34.zw), _ToggleFlowTex);
					fixed4 flowColor = tex2D(_FlowTex, i.uv34.zw, float2(0, 0), float2(0, 0));
					flowUV = (i.uv12.xy + (flowColor.xy - 0.5) * _FlowScale).xyxy;
				#endif
				flowUV.xy = lerp(flowUV.xy, frac(flowUV.xy), _MainTexWrapMode.xy);
				fixed4 texColor = tex2D(_MainTex, flowUV.xy, float2(0, 0), float2(0, 0));
				#if _GRADIENT_ON
					fixed4  gradientCol = tex2D(_GradientTex, flowUV.xy, float2(0, 0), float2(0, 0));
					texColor *= gradientCol;
				#endif
				fixed4 result = texColor;
				#if DissolveTex_On
					i.uv34.xy = lerp(i.uv34.xy, frac(i.uv34.xy), _ToggleDissolveTex);
					half dissolveAlpha = tex2D(_DissolveTex, i.uv34.xy, float2(0, 0), float2(0, 0)).r;
					float clipValue = dissolveAlpha - _Dissolve*1.2 + 0.1;
					result.a *= smoothstep(0.001,0.1 , clipValue);
					clipValue = clamp(clipValue * _DissolveRange  ,0,1);
					fixed4 dissColor = lerp(_DissolveColor1,_DissolveColor2,smoothstep(0.2 , 0.3,clipValue));
					clipValue = clamp(clipValue + step(_Dissolve,0.001),0,1);
					result.rgb = lerp(dissColor + texColor,texColor,clipValue).rgb;
				#endif

				#if MaskTex_On
					float4 maskUV = i.uv12.zwzw;
					maskUV.xy = lerp(maskUV.xy, frac(maskUV.xy), _MaskTexWrapMode.xy);
					half maskAlpha = tex2D(_MaskTex, maskUV.xy, float2(0, 0), float2(0, 0)).r;
					result.a *= maskAlpha;
				#endif
				result *= i.color;
				result.a = saturate(result.a);
				return result;
			}
			ENDCG
		}
    }
}
