Shader "LGame/Transparent/VertColor"
{
	Properties
	{
        [PerRendererData] _MainTex("Sprite Texture", 2D) = "white" {}

	}
	SubShader
	{
		Tags {"Queue" = "Transparent" "RenderType"="Transparent" }
		LOD 100
        Blend SrcAlpha OneMinusSrcAlpha
        Cull Off
        Lighting Off
        ZWrite Off
		Pass
		{
			Tags {  "LightMode" = "ForwardBase"}
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"

			struct v2f
			{
				float4 vertex : SV_POSITION;
				fixed4 color : COLOR;
			};

			struct appdata
			{
				float4 vertex : POSITION;
				fixed4 color : COLOR;
			};
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.color = v.color;
				return o;
			}

            sampler2D _MainTex;
			
			fixed4 frag (v2f i) : SV_Target
			{

				return i.color ;
			}
			ENDCG
		}
	}
}
