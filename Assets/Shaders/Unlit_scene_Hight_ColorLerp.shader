Shader "Unlit/scene_Hight_ColorLerp"
{
	Properties
	{
		_ColorUp("Color Up" , Color) = (1,1,1,1)
		_ColorDown("Color Down" , Color) = (1,1,1,1)
		_Range("Range" , Range(0,1)) = 1
		_Offset("Offset" , float) = 0
		_MainTex ("Texture", 2D) = "white" {}
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_fog
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				half2 uv:TEXCOORD0;
			};

			struct v2f
			{
				float4 vertex	: SV_POSITION;
				float3 worldPos	: TEXCOORD0;
				half2 uv:TEXCOORD1;
			};

			fixed4	_ColorUp;
			fixed4	_ColorDown;
			half	_Range;
			half	_Offset;
			sampler2D _MainTex;
			float4 _MainTex_ST;
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;
				o.uv = TRANSFORM_TEX(v.uv,_MainTex);
				return o; 
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				fixed4 col = tex2D(_MainTex,i.uv);
				col *= lerp(_ColorDown , _ColorUp , saturate( i.worldPos.y * _Range - _Offset));
				return col;
			}
			ENDCG
		}
	}
}
