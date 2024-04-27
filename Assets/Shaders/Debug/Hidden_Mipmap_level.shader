Shader "Hidden/Mipmap_level"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
	}

	SubShader 
	{ 
		Tags { "Queue" = "Geometry" "RenderType"="Opaque" "RenderType" = "AlphaTest" }

		Pass
		{
			Tags { "LightMode" = "ForwardBase" }
			Fog { Mode Off }

			CGPROGRAM
			#include "Assets/CGInclude/RenderDebugCG.cginc"
			#pragma vertex vert
			#pragma fragment frag_mipmap  

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

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				return o;
			}

			sampler2D _MainTex;

			fixed4 frag_mipmap(v2f i) : SV_Target 
			{
				fixed3 c = tex2D(_MainTex, i.uv).rgb;

				return GetMipmapsLevelColor(c,i.uv);
			}
			
			ENDCG
		}
	}

	 /*SubShader 
	 { 
	 	Tags { "Queue" = "Transparent" "RenderType"="Transparent" }

	 	Pass
	 	{
	 		Tags { "LightMode" = "ForwardBase" }
	 		ZWrite off
	 		ZTest Always
	 		Fog { Mode Off }


	 		CGPROGRAM
	 		#include "Assets/CGInclude/RenderDebugCG.cginc"
	 		#pragma vertex vert
	 		#pragma fragment frag_mipmap  

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

	 		v2f vert (appdata v)
	 		{
	 			v2f o;
	 			o.vertex = UnityObjectToClipPos(v.vertex);
	 			o.uv = v.uv;
	 			return o;
	 		}

	 		sampler2D _MainTex;

	 		fixed4 frag_mipmap(v2f i) : SV_Target 
	 		{
	 			fixed3 c = tex2D(_MainTex, i.uv).rgb;

	 			return GetMipmapsLevelColor(c,i.uv);
	 		}
			
	 		ENDCG
	 	}
	 }*/
}
