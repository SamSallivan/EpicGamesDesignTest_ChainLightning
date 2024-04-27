Shader "LGame/Fallback/PlanarShadow"
{
	Properties
	{
	}
	SubShader
	{
		Tags { "RenderType" = "Opaque" }
		LOD 100
		Pass
		{
			Name "SHADOWPLANE"
			Tags { "LightMode" = "ForwardBase" }
			Stencil
			{
				Ref 0
				Comp equal
				Pass incrWrap
			}
			Blend SrcAlpha OneMinusSrcAlpha
			ZWrite Off
			Offset -10,-10
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"
			struct v2f
			{
				float4 vertex : SV_POSITION;
			};
			v2f vert(float4 vertex : POSITION)
			{
				v2f o;

				half3 worldPos = mul(unity_ObjectToWorld , vertex).xyz;
				fixed3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
				half3 shadowPos;
				shadowPos.y = min(worldPos.y , 0.0);
				shadowPos.xz = worldPos.xz - lightDir.xz * max(0.0 , worldPos.y) / lightDir.y;
				o.vertex = UnityWorldToClipPos(shadowPos);
				return o;
			}
			fixed4 frag(v2f i) : SV_Target
			{
				return half4(0,0,0,0.5);
			}
			ENDCG
		}
	}
}
