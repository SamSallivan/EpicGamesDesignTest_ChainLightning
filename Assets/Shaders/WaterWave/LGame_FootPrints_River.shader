// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

Shader "LGame/Effect/FootPrints_River" 
{
Properties 
{
	_MainTex ("Particle Texture", 2D) = "white" {}
}

Category 
{
	SubShader
	{
		Tags { "RenderType" = "Transparent" "Queue" = "Transparent-1" }
		LOD 100
		
		Pass 
		{
			Name "FORWARD"
			Tags {  "LightMode" = "DistortedObjectPass" }
			Blend SrcAlpha OneMinusSrcAlpha
			ColorMask RGB
			Cull Off Lighting Off ZWrite Off ZTest Off
		
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 2.0

			#include "UnityCG.cginc"

			sampler2D _MainTex;
			fixed4 _TintColor;
			
			struct appdata_t {
				float4 vertex : POSITION;
				fixed4 color : COLOR;
				float2 texcoord : TEXCOORD0;
			};

			struct v2f {
				float4 vertex : SV_POSITION;
				fixed4 color : COLOR;
				float2 texcoord : TEXCOORD0;
			};
			
			float4 _MainTex_ST;

			v2f vert (appdata_t v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.color = v.color;
				o.texcoord = TRANSFORM_TEX(v.texcoord,_MainTex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				fixed4 col = i.color * tex2D(_MainTex, i.texcoord);
				return fixed4(0.4, 0.4, col.b, col.a);
			}
			ENDCG 
		}

		Pass
		{
			Name "ForTest"
			Blend SrcAlpha OneMinusSrcAlpha
			ColorMask RGB
			Cull Off Lighting Off ZWrite Off ZTest Off

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 2.0

			#include "UnityCG.cginc"

			sampler2D _MainTex;
			fixed4 _TintColor;

			struct appdata_t {
				float4 vertex : POSITION;
				fixed4 color : COLOR;
				float2 texcoord : TEXCOORD0;
			};

			struct v2f {
				float4 vertex : SV_POSITION;
				fixed4 color : COLOR;
				float2 texcoord : TEXCOORD0;
			};

			float4 _MainTex_ST;

			v2f vert(appdata_t v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.color = v.color;
				o.texcoord = TRANSFORM_TEX(v.texcoord,_MainTex);
				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				fixed4 col = i.color * tex2D(_MainTex, i.texcoord);
				return fixed4(0.4, 0.4, col.b, col.a);
			}
			ENDCG
		}
	}
}
}
