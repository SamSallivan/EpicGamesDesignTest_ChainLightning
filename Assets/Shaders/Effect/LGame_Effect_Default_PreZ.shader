Shader "LGame/Effect/Default_PreZ"
{
    Properties
    {
		_AlphaCtrl("AlphaCtrl",range(0,1)) = 1

		[HideInInspector] _OptionMode("__OptionMode",float) = 0	
		[HideInInspector] _BlendMode ("__BlendMode",float) = 0
        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend ("__src", float) = 1.0
        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlend ("__dst", float) = 0.0
		[Enum(Off, 0, On, 1)] _ZWriteMode ("__ZWriteMode", float) = 0
		[Enum(UnityEngine.Rendering.CullMode)] _CullMode ("__CullMode", float) = 2
		[Enum(Less, 2, LessEqual, 4, Greater, 5, Always, 8)] _ZTestMode ("__ZTestMode", Float) = 2
		//添加亮度乘数，默认值为1，保证现有资源不受影响
		_Multiplier("_Multiplier",Range(1,20))=1

		[Toggle]_WrapMode("Custom WrapMode", Float) = 0
		[Toggle]_ScreenUV("Screen Space Mode", Float) = 0

		[SimpleToggle] _ScaleOnCenter("Scale On Center", Float) = 1

		
		[HideInInspector]_OffsetColor ("OffsetColor", Color) = (0,0,0,0) 
		[HideInInspector]_OffsetColorLerp ("OffsetColor", Float) = 0

		[hdr]_Color ("Main Color" , color) = (1,1,1,1)
        _MainTex ("Main Texture", 2D) = "white" {}
		_MainTexTransform ("MainTexTransform" , vector) = (0,0,0,1)
		[SimpleToggle] _MainTexUvMode("UV Mode", Float) = 0

		_MaskTex ("Mask Texture", 2D) = "white" {}
		_MaskTexTransform ("Mask Transform" , vector) = (0,0,0,1)
		[SimpleToggle] _MaskTexUvMode("UV Mode", Float) = 0

		_MainWrapMode ("WrapMode" , vector) = (1,1,1,1)



		_DissolveTex("Dissolve Texture", 2D) = "white" {}
		_DissolveTexTransform ("_DissolveTex Transform" , vector) = (0,0,0,1)
		[SimpleToggle] _DissolveTexUvMode("UV Mode", Float) = 0
		[SimpleToggle] _UseCustomData("Use Custom Data", Float) = 0
		_DissolveValue("Dissolve", range(0,1)) = 0
		_DissolveRangeSize ("Range Size", range(0.01,0.5)) = 0.1
		[hdr]_DissolveRangeCol ("Range Color" , color) = (1,1,1,1)

		_WarpTex("Warp Texture", 2D) = "bump" {}
		_WarpTexTransform ("FlowTex Transform" , Vector) = (0,0,0,1)
		[SimpleToggle] _WarpTexUvMode("UV Mode", Float) = 0
		_WarpIntensity("Warp Intensity" , range(0,1)) = 1

		_SubWrapMode ("WrapMode" , vector) = (1,1,1,1)

		_BillboardRotation("Rotation", vector) = (0,0,0,0)
		_BillboardScale("Scale", vector) = (1,1,1,0)
		_BillboardMatrix0("Matrix1", vector) = (0,0,0,0)
		_BillboardMatrix1("Matrix2", vector) = (0,0,0,0)
		_BillboardMatrix2("Matrix3", vector) = (0,0,0,0)


		[HideInInspector] _StencilComp("Stencil Comparison", Float) = 8
		[HideInInspector] _Stencil("Stencil ID", Float) = 0
		[HideInInspector] _StencilOp("Stencil Operation", Float) = 0
		[HideInInspector] _StencilWriteMask("Stencil Write Mask", Float) = 255
		[HideInInspector] _StencilReadMask("Stencil Read Mask", Float) = 255
    }
    SubShader
    {
        Tags {"LightMode"="ForwardBase" "Queue"="Transparent" "RenderType"="Transparent"  }
        LOD 100

        Blend [_SrcBlend] [_DstBlend]
        ZWrite [_ZWriteMode]
        ZTest [_ZTestMode]
        Cull [_CullMode]

		Stencil
		{
			Ref[_Stencil]
			Comp[_StencilComp]
			Pass[_StencilOp]
			ReadMask[_StencilReadMask]
			WriteMask[_StencilWriteMask]
		}

		Pass
        {
            Name "PerZ"
            ZWrite On
            ColorMask 0
        }

        //srp Pass
		Pass
        {
            Name "PerZ"
            Tags { "LightMode" = "PerZPass" }
            ZWrite On
            ColorMask 0
        }

		UsePass "LGame/Effect/Default/EffectDefault"
    }

	SubShader
	{
		Tags { "Queue" = "Transparent" "LightMode" = "ForwardBase" "IgnoreProjector" = "True" "RenderType" = "Transparent"}
		LOD 5
		Blend One One
		ZWrite[_ZWriteMode]
		ZTest[_ZTestMode]
		Cull[_CullMode]

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment fragtest
			#pragma multi_compile_instancing 
			#include "Assets/CGInclude/LGameEffect.cginc" 

			half4 fragtest(v2f i) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID(i);

				fixed4 texColor = tex2D(_MainTex, i.uvMain.xy, float2(0, 0), float2(0, 0));

				return half4(0.15,0.06,0.03, texColor.a < 0.001);
			}
			ENDCG
		}
	}
	
	CustomEditor"LGameEffectDefaultGUI"
}
