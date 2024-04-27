Shader "LGame/Fallback/MotionBlurFur"
{
    Properties
    {

    }
	SubShader
	{
		Tags{ "RenderType" = "Opaque" "Queue" = "AlphaTest" "PerformanceChecks" = "False" }
		LOD 300
		Pass
		{
			Stencil {
				Ref 16
				Comp always
				Pass replace
			}
			Name "FlowMap"
			Tags
			{
				"LightMode" = "VertexLit"
			}
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"
			struct appdata
			{
				half4 vertex : POSITION;
			};
			struct v2f
			{
				half4 vertex	: SV_POSITION;
			};
			v2f vert(appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				return o;
			}
			fixed4 frag(v2f i) : SV_Target
			{
				return 0.0f;
			}
			ENDCG
		}
    }
}
