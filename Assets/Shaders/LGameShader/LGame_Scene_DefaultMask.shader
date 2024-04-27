Shader "LGame/Scene/DefaultMask"
{
    Properties
    {
		[Header(Do Not Touch)]
		[IntRange]_Stencil("Stencil ID", Range(0,255)) = 3
		[Enum(UnityEngine.Rendering.CompareFunction)]_StencilComp("Stencil Comparison", Float) = 8
		[Enum(UnityEngine.Rendering.StencilOp)]_StencilOp("Stencil Pass", Float) = 2
		[IntRange] _StencilWriteMask("Stencil Write Mask", Range(0,255)) = 255
		[IntRange] _StencilReadMask("Stencil Read Mask", Range(0,255)) = 255
    }



    SubShader
    {
        Tags { "RenderType"="Opaque"  "Queue" = "Geometry"  }
        LOD 100
		Tags {"LightMode" = "ForwardBase" }
		Name "FORWARD"

		Pass 
		{
			ColorMask 0
			ZWrite Off
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
			#pragma fragment frag

			float4 vert(float4 vertex : POSITION) : SV_POSITION
			{
				return UnityObjectToClipPos(vertex);
			}
			half4 frag(float4 pos : SV_POSITION) : SV_Target 
			{
				return half4(1, 1, 1, 1);
			}
			ENDCG
		}

    }

}
