Shader "LGame/CMB/Outline"
{
	Properties
	{
		_OutlineCol("Cmb Outline Color" , Color) = (0,0,0,1)
		_OutlineSize("Cmb Outline Size" , float) = .2
		_AlphaCtrl("Cmb AlphaCtrl" , float) = 1
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100
						   

		//Pass0 Default 
		Pass
		{
			Name "Outline"
			Cull Front
			ZWrite Off
			Offset -1 , 0
			//ZTest Always
			Blend One OneMinusSrcAlpha
			CGPROGRAM

			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"

			fixed4	_OutlineCol;
			half	_OutlineSize;
			half	_AlphaCtrl;
			struct v2f_outline
			{
				float4 pos : SV_POSITION;
			};
			
			v2f_outline vert(appdata_full v)
			{
				v2f_outline o;
				o.pos = UnityObjectToClipPos(v.vertex);
				//将法线方向转换到视空间
				float3 vnormal = mul((float3x3)UNITY_MATRIX_IT_MV, v.normal);
				//将视空间法线xy坐标转化到投影空间，只有xy需要，z深度不需要了
				float2 offset = TransformViewToProjection(vnormal.xy);
				//在最终投影阶段输出进行偏移操作
				o.pos.xy += offset * _OutlineSize;
				return o;
			}
			
			fixed4 frag(v2f_outline i) : SV_Target
			{
				//这个Pass直接输出描边颜色
				return _OutlineCol * _AlphaCtrl;
			}

			ENDCG
		}
		}
}
