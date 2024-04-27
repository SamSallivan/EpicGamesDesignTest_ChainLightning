Shader "StarActorRnederCollectShader"
{
    Properties
    {
		_MainTex("Texture", 2D) = "white" {}
    }

	SubShader
	{
		Tags { "Queue" = "Transparent" "LightMode" = "ForwardBase" "IgnoreProjector" = "True" "RenderType" = "Transparent"}
		Blend One One
		Cull off
		ZWrite off
		ZTest off

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment fragtest

			sampler2D _MainTex;

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
			};

			v2f vert(appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				return o;
			}

			half4 fragtest(v2f i) : SV_Target
			{
				fixed4 texColor = tex2D(_MainTex, i.uv.xy, float2(0, 0), float2(0, 0));

				return half4(0.015,0.06,0.03, texColor.a < 0.001);
			}
			ENDCG
		}
	}
	
	CustomEditor"LGameSDK.AnimTool.LGameEffectDefaultGUI"
}
