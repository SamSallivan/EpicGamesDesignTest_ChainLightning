// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Hidden/LGame/Effect/Distortion"
{
	Properties
	{
		_DistortStrength("DistortStrength", Range(0,128)) = 32
		_DistortMaskTex("DistortMaskTex", 2D) = "black" {}
		_MainTex("MainTex", 2D) = "white" {}


	}
		SubShader
	{
		//ZWrite Off
		//Cull Off

		Pass
		{
			//Tags
			//{
			//	"RenderType" = "Transparent"
			//	"Queue" = "Transparent + 100"

			//}
			Tags {  "LightMode" = "DistortionEffectPass" }

			CGPROGRAM
			sampler2D _DistortMaskTex;
			float4 _DistortMaskTex_TexelSize;

			sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _NoiseTex;
			float4 _NoiseTex_ST;
			float _DistortStrength;
			float _DistortTimeFactor;
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
				float4 uv : TEXCOORD0;
				float4 uvgrab : TEXCOORD1;
			};

			v2f vert(appdata v)
			{
				v2f o;
				UNITY_INITIALIZE_OUTPUT(v2f, o);

				o.vertex = UnityObjectToClipPos(v.vertex);
				//o.uvgrab = ComputeGrabScreenPos(o.pos);

				//#if UNITY_UV_STARTS_AT_TOP
				//					float scale = -1.0;
				//#else
				//					float scale = 1.0;
				//#endif
				//o.uvgrab.xy = (float2(o.vertex.x, o.vertex.y * scale) + o.vertex.w) * 0.5;
				o.uvgrab.xy = (float2(o.vertex.x, o.vertex.y) + o.vertex.w) * 0.5;
				o.uvgrab.zw = o.vertex.zw;
				o.uv.xy = v.uv;
				return o;
			}

			float4 frag(v2f i) : SV_Target
			{
				//此处法线信息已经在mask中还原空间，所以要重新解压,从（0，0.8）映射到（-1，1）
				//half2 bump = clamp(0,1,tex2D(_DistortMaskTex, i.uv.xy).xy) - fixed2(0.5,0.5);//*2-1;
				float2 bump = tex2D(_DistortMaskTex, i.uv.xy).xy*2.5-1;
				float2 offset = _DistortStrength * _DistortMaskTex_TexelSize.xy * bump;
				i.uvgrab.xy =offset * i.uvgrab.z + i.uvgrab.xy;
				//return float4(-1*bump,0,1); 
				float4 col = tex2Dproj(_MainTex, UNITY_PROJ_COORD(i.uvgrab));
				return col;
			}

			#pragma vertex vert
			#pragma fragment frag
			ENDCG
		}
	}
}
