Shader "UI/UI_Mask_Smooth_Circle"
{
	Properties
	{
		_Color("Color", Color) = (1,1,1,1)
		_ClipCircle("Circle", Vector) = (0,0,100,100)
		[PerRendererData]_MainTex("Texture",2D) = "white" {}
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
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"
			#include "UnityUI.cginc"

			struct appdata
			{
				float4 vertex   : POSITION;
				float4 color    : COLOR;
				float2 uv : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex   : SV_POSITION;
				fixed4 color : COLOR;
				float4 worldPosition : TEXCOORD1;
				UNITY_VERTEX_OUTPUT_STEREO
			};

			fixed _Fade;
			fixed4 _Color;
			float4 _ClipCircle;
			sampler2D _MainTex;

			inline float UnityGet2DCircleClipping(in float2 position, in float4 clipCircle)
			{
				float distance = length(position - clipCircle.xy);
				float fair_end = clipCircle.w + clipCircle.z;
				return smoothstep(clipCircle.z, fair_end, distance);
			}


			v2f vert(appdata IN)
			{
				v2f OUT;
				UNITY_SETUP_INSTANCE_ID(IN);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(OUT);
				OUT.worldPosition = IN.vertex;
				OUT.vertex = UnityObjectToClipPos(OUT.worldPosition);
				OUT.uv = IN.uv;
				OUT.color = IN.color * _Color;
				return OUT;
			}

			fixed4 frag(v2f IN) : SV_Target
			{
				fixed4 col = tex2D(_MainTex, IN.uv);
				fixed4 color = col * IN.color;
				color.a *= UnityGet2DCircleClipping(IN.worldPosition.xy, _ClipCircle);
				return color;
			}
			ENDCG
		}
	}
}
