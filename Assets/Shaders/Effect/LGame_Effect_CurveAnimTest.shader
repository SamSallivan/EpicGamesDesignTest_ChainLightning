Shader "LGame/Effect/CurveAnimTest"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_Angle ("Angle" , float) = 1
		_Offset ("Offset" , float) = 1
		_Lerp("Lerp" ,Range(0,1)) = 1
		[HideInInspector]_AlphaCtrl("AlphaCtrl",range(0,1)) = 1
		[HideInInspector][Enum(UnityEngine.Rendering.BlendMode)] 		_SrcFactor ("SrcFactor()", Float) = 5
		[HideInInspector][Enum(UnityEngine.Rendering.BlendMode)] 		_DstFactor ("DstFactor()", Float) = 10

	}
	SubShader
	{
		Tags { "Queue"="Transparent" "RenderType"="Transparent" "LightMode" = "ForwardBase"}
		LOD 100

		Pass
		{
			Blend [_SrcFactor] [_DstFactor]
			ZWrite Off
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

			sampler2D	_MainTex;
			float4		_MainTex_ST;
			half		_Angle;
			half		_Offset;
			half		_Lerp;
			half		_AlphaCtrl;
			
			inline float2 RotateUV(float2 uv,half2 angle)
			{
			    float2 outUV;
			    half sinA = sin(angle);
				half cosA = cos(angle);
			    outUV = float2(uv.x * cosA - uv.y * sinA , uv.x * sinA + uv.y * cosA);
			    return outUV;
			}

			v2f vert (appdata v)
			{
				v2f o;
				float4 newVertex = v.vertex;
				
				newVertex.yz = RotateUV(v.vertex.yz , (v.vertex.y - _Offset) *_Angle);
				newVertex.x *= _Lerp;
				o.vertex = UnityObjectToClipPos(lerp(newVertex, v.vertex , _Lerp));
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				// sample the texture
				fixed4 col = tex2D(_MainTex, i.uv);
				col.a = _AlphaCtrl;
				return col;
			}
			ENDCG
		}
	}

}
