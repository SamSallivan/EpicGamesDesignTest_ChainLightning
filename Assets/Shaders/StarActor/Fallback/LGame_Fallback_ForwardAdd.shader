Shader "LGame/Fallback/ForwardAdd"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
	}
	SubShader
	{
		Tags { "Queue" = "Geometry" "RenderType"="Opaque" }
		//LOD 300

		Pass
		{
			Name "FORWARD"
			Tags { "LightMode" = "ForwardBase" }
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"

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

			sampler2D _MainTex;
			float4 _MainTex_ST;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{

				fixed4 col = tex2D(_MainTex, i.uv);
				return col;
			}
			ENDCG
		}

		Pass
		{		  
			Name "SIMPLE_ADD"
			Tags{ "LightMode" = "ForwardAdd" }
			ZWrite Off
			Blend One One
			CGPROGRAM

			#pragma vertex vert
			#pragma fragment frag	
			#pragma multi_compile_fwdadd
			

			#pragma target 3.0
			#include "AutoLight.cginc"	
			#include "Lighting.cginc"	
			struct VertexInput
			{
				half4 vertex : POSITION;
				half2 uv : TEXCOORD0;
			};
			struct VertexOutput
			{
				half4 pos : SV_POSITION;
				half2 uv : TEXCOORD0;
				LIGHTING_COORDS(1, 2)
			};

			fixed4		_Color;
			sampler2D	_MainTex;
			float4		_MainTex_ST;

			VertexOutput vert(VertexInput v)
			{
				VertexOutput o;
				o.uv = v.uv;
				half3 wPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				o.pos = UnityObjectToClipPos(v.vertex);
				TRANSFER_VERTEX_TO_FRAGMENT(o)
				return o;
			}
			fixed4 frag(VertexOutput i) : SV_Target
			{
				fixed attenuation = LIGHT_ATTENUATION(i);
				fixed3 attenColor = attenuation * _LightColor0.xyz;

				fixed3 Col = tex2D(_MainTex,i.uv) * attenColor;
	
				return fixed4(Col , 1);
			}
			ENDCG
		}

	}

}
