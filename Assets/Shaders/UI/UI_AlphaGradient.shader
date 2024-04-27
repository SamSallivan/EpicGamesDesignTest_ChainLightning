Shader "UI/AlphaGradient"
{
	Properties
	{
		_MainTex("Main Texture", 2D) = "white" {}
	    _AlphaTex("Sprite Alpha Texture", 2D) = "white" {}
		_Color("Tint", Color) = (1, 1, 1, 1)
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
				Name "Default"
				CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag
				#pragma target 2.0

				#include "UnityCG.cginc"
				#include "UnityUI.cginc"

				struct appdata_t
				{
					float4 vertex   : POSITION;
					float4 color    : COLOR;
					float2 texcoord : TEXCOORD0;
					UNITY_VERTEX_INPUT_INSTANCE_ID
				};

				struct v2f
				{
					float4 vertex   : SV_POSITION;
					fixed4 color : COLOR;
					float2 texcoord  : TEXCOORD0;
					float4 worldPosition : TEXCOORD1;
					UNITY_VERTEX_OUTPUT_STEREO
				};

				fixed4 _Color;

				v2f vert(appdata_t IN)
				{
					v2f OUT;
					UNITY_SETUP_INSTANCE_ID(IN);
					UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(OUT);
					OUT.worldPosition = IN.vertex;
					OUT.vertex = UnityObjectToClipPos(OUT.worldPosition);

					OUT.texcoord = IN.texcoord;

					OUT.color = IN.color * _Color;
					return OUT;
				}

				sampler2D _MainTex;
				sampler2D _AlphaTex;

				fixed4 frag(v2f IN) : SV_Target
				{
					half4 color = tex2D(_MainTex, IN.texcoord) * IN.color;
					half4 alphaColor = tex2D(_AlphaTex, IN.texcoord) * IN.color;
					color.a = alphaColor.a;

					return color;
				}
				ENDCG
			}
		}
}
