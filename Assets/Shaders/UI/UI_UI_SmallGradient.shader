Shader "UI/UI_SmallGradient"
{
	Properties
	{
		_MainTex("Texture",2D) = "white"{}
		_TopColor("TopColor",Color) = (1,1,1,1)
		_ButtomColor("ButtomColor",Color) = (0,0,0,1)
		_NoseMul("_NoseMul",float) = 1
		_Noise("Noise",float) = 1000
		_Shift("Shift",range(0,1)) = 1
	}
		SubShader
		{
			// No culling or depth
			//Cull Off ZWrite Off ZTest Always
			
			Blend SrcAlpha OneMinusSrcAlpha
			Pass
			{
				CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag

				#include "UnityCG.cginc"

				struct appdata
				{
					float4 vertex : POSITION;
					float2 uv : TEXCOORD0;
					float4 color    : COLOR;
				};

				struct v2f
				{
					float4 vertex : SV_POSITION;
					float4 color    : COLOR;
					float2 uv : TEXCOORD0;
				};

				sampler2D _MainTex;
				float4 _TopColor;
				float4 _ButtomColor;
				float _NoseMul;
				float _Noise;
				float _Shift;
				//float4 _MainTex_TexelSize;

				v2f vert(appdata v)
				{
					v2f o;
					o.vertex = UnityObjectToClipPos(v.vertex);
					o.uv = v.uv.xy;
					o.color = v.color;
					return o;
				}



				float4 gradient(float2 uv) {
					return _TopColor * uv.y + _ButtomColor * (1 - uv.y);
				}

				fixed4 frag(v2f o) : SV_Target
				{ 
					float2 muv = o.uv * _Noise;
					muv = muv - floor(muv);	
					float4 mc = (tex2D(_MainTex, muv) - _Shift)*_NoseMul;
					o.uv.y = o.uv.y + mc.r;
					float4 cl1 = gradient(o.uv);
					return cl1 * o.color;
				}
				ENDCG
			}
		}
}