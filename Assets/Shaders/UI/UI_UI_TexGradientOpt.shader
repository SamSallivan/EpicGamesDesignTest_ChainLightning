Shader "UI/UI_TexGradientOpt"
{
	Properties
	{
		[PerRendererData]_MainTex("MainTex",2D) = "white"{}
		_MaskNoise("NoiseTex",2D) = "white"{}
		//_Slice("Slice",float4) = {0,0,0,0}
		_Noise("Noise",float) = 1000
		_NoiseMul("NoiseMul",range(0,1)) = 1
		_NoiseMid("NoiseMid",range(0.2,0.8)) = 0.5
	}
		SubShader
		{
			// No culling or depth
			//Cull Off ZWrite Off ZTest Always
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
			Pass{
	
				CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag

				#include "UnityCG.cginc"

				struct appdata
				{
					float4 vertex : POSITION;
					float4 color    : COLOR;
					float2 uv : TEXCOORD0;
				};

				struct v2f
				{
					float2 uv : TEXCOORD0;
					float4 color    : COLOR;
					float4 vertex : SV_POSITION;
				};

				v2f vert(appdata v)
				{
					v2f o;
					o.vertex = UnityObjectToClipPos(v.vertex);
					o.uv = v.uv;
					o.color = v.color;
					return o;
				}

				sampler2D _MainTex;
				sampler2D _MaskNoise;
				float _Noise;
				float _NoiseMul;
				float _NoiseMid;
				fixed4 frag(v2f o) : SV_Target
				{
					float2 muv = o.uv*_Noise;
					float4 mc = tex2D(_MaskNoise, (muv - floor(muv)));
					mc = 1 + (mc - _NoiseMid) * _NoiseMul;
					mc.a = 1;
					float2 uv = o.uv;
					float4 cl1 = tex2D(_MainTex, uv);
					return cl1*mc;
				}
				ENDCG
			}
		}
}