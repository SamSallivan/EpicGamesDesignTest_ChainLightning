Shader "UI/Unlit/UI_Tutorial_Mask_Circle"
{
	Properties
	{
		[PerRendererData] _MainTex("Sprite Texture", 2D) = "white" {}
		_Color("Color", Color) = (1,1,1,1)
		_ClipCircle("Circle", Vector) = (0,0,1,0)
	}
	SubShader
	{
		Tags
		{
			"Queue" = "Transparent"
			"IgnoreProjector" = "True"
			"RenderType" = "Transparent"
			"PreviewType" = "Plane"
			"CanUseSpriteAtlas" = "True"
		}

		Cull Off
		Lighting Off
		ZWrite Off
		ZTest[unity_GUIZTestMode]
		Blend SrcAlpha OneMinusSrcAlpha

		Pass
		{
			Tags { "LightMode" = "ForwardBase" }
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
						
			#include "UnityCG.cginc"
			#include "UnityUI.cginc"

			struct appdata
			{
				float4 vertex   : POSITION;
				float4 color    : COLOR;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct v2f
			{
				float4 vertex   : SV_POSITION;
				fixed4 color : COLOR;
				float4 worldPosition : TEXCOORD1;
				UNITY_VERTEX_OUTPUT_STEREO
			};

			fixed4 _Color;
			float4 _ClipCircle;

			inline fixed UnityGet2DCircleClipping(in float2 position, in float4 clipCircle)
			{
				float distance = length(position - clipCircle.xy);				
				return step(clipCircle.z, distance);
			}


			v2f vert(appdata IN)
			{
				v2f OUT;
				UNITY_SETUP_INSTANCE_ID(IN);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(OUT);
				OUT.worldPosition = IN.vertex;
				OUT.vertex = UnityObjectToClipPos(OUT.worldPosition);
				
				OUT.color = IN.color * _Color;
				return OUT;
			}
			
			fixed4 frag(v2f IN) : SV_Target
			{
				fixed4 color = IN.color;

				color.a *= UnityGet2DCircleClipping(IN.worldPosition.xy, _ClipCircle);

				return color;
			}
			ENDCG
		}
	}
}
