Shader "LGame/Character/ShadowPlane_Faset"
{
	SubShader
	{
		Tags { "RenderType"="Opaque" "LightMode"="ForwardBase" "Queue"="AlphaTest-50" }
		LOD 5
		Blend SrcAlpha OneMinusSrcAlpha
		//ZTest Always
		Offset -10,-10
		ZWrite Off
		//ColorMask rgb
		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_instancing   
			
			#include "UnityCG.cginc"

			fixed4	_Color;

			struct appdata
			{
				float4 vertex : POSITION;
				half2 uv : TEXCOORD0;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
				fixed4 color : COLOR;
				half2 uv : TEXCOORD0;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			v2f vert (appdata v)
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID( v , o);

				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				o.color.a = -unity_ObjectToWorld[1][2];
				o.color.rgb = _Color;

				UNITY_TRANSFER_FOG(o,o.vertex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID(i);
				return fixed4(i.color.rgb , (1-length(i.uv - half2(0.5,0.5)) * 2)*i.color.a);
			}
			ENDCG
		}
	}
}
