Shader "LGame/CMB/Shadow"
{
	Properties
	{
		_LightInfo("Light Info" , Vector) = (0,-1,0,0)
		_CmbShadowColor("Cmb Shadow Color" , Color) = (0,0,0,1)
		_ShadowFalloff("Shadow Falloff",float) = 0.5
		_AlphaCtrl("Cmb AlphaCtrl" , float) = 1
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100


		//Pass0 Default 
		Pass
		{
			Name "PlaneShadow"
		    Stencil
            {
                Ref 0
                Comp equal
                Pass incrWrap
                Fail keep
                ZFail keep
            }
			   
			Blend SrcAlpha OneMinusSrcAlpha
			ZWrite off
			Offset -1 , 0

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"
			#include "Assets/CGInclude/LGameCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
			};

			struct v2f
			{
				fixed4 color : COLOR;
				float4 pos : SV_POSITION;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			half4 		_LightInfo;
			fixed4 		_CmbShadowColor;
			half 		_ShadowFalloff;
			half		_AlphaCtrl;
			
			v2f vert (appdata v)
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID( v , o);

				//得到阴影的世界空间坐标
				half3 shadowPos = ShadowProjectPos(v.vertex, _LightInfo);

				//转换到裁切空间
				o.pos = UnityWorldToClipPos(shadowPos);

				//得到中心点世界坐标
				half3 center = half3( unity_ObjectToWorld[0].w , _LightInfo.w , unity_ObjectToWorld[2].w);

				//计算阴影衰减
				half falloff = 1-saturate(distance(shadowPos , center) );

				//阴影颜色
				o.color = _CmbShadowColor; 
				o.color.a *= falloff;
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				return i.color * _AlphaCtrl;
			}
			ENDCG
		}
	}
}
