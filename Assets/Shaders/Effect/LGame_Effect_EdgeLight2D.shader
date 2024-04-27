Shader "LGame/Effect/EdgeLight2D"
{
	Properties
	{
		_MainTex("MainTex", 2D) = "white" {}
		[Toggle(_GrayTexEnable)]_GrayTexEnable("_GrayTexEnable", float) = 0
		_EdgeLightDataTex("R-Gray/G-Edge",2D) = "white"{}
		_NoiseTilingTex("NoiseTilingTex", 2D) = "white" {}
		[HDR]_Color("LightColor", Color) = (1,1,1,1)
		_BasePointLightFactor("BasePointLightFactor", range(1, 10)) = 1
		_NoisePointLightFactor("NoisePointLightFactor", range(1, 100)) = 1
		_BaseRangeLightFactor("BaseRangeLightFactor", range(1, 10)) = 1
		_NoiseRangeLightFactor("NoiseRangeLightFactor", range(1, 100)) = 1
	}
		SubShader
		{
			Tags { "RenderType" = "Opaque"  }
			LOD 100

			Pass
			{
				Tags{ "LightMode" = "ForwardBase" }
				ZWrite On
				ZTest Less
				CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag
				#pragma shader_feature _GrayTexEnable

				#include "UnityCG.cginc"

				struct appdata
				{
					float4 vertex : POSITION;
					half2 uv : TEXCOORD0;
				};

				struct v2f
				{
					half2 uv : TEXCOORD0;
					half2 uv1 : TEXCOORD1;
					float3 wPos : TEXCOORD2;
					float4 vertex : SV_POSITION;
				};

				sampler2D _MainTex;
				half4 _MainTex_ST;
				sampler2D _EdgeLightDataTex;
				sampler2D _NoiseTilingTex;
				half4 _NoiseTilingTex_ST;
				half4 _Color;

				float _BasePointLightFactor;
				float _NoisePointLightFactor;
				float4 _Light2DPointPos;

				float _BaseRangeLightFactor;
				float _NoiseRangeLightFactor;
				float4 _Light2DRangePos;
				float4 _Light2DRangeBox;

				v2f vert(appdata v)
				{
					v2f o;
					o.vertex = UnityObjectToClipPos(v.vertex);
					o.uv = TRANSFORM_TEX(v.uv, _MainTex);
					o.uv1 = TRANSFORM_TEX(v.uv, _NoiseTilingTex);
					o.wPos = mul(unity_ObjectToWorld, v.vertex);

					return o;
				}
				half4 frag(v2f i) : SV_Target
				{
					half4 baseCol = tex2D(_MainTex, i.uv);
					half noise = tex2D(_NoiseTilingTex, i.uv1).r;
					half2 data = tex2D(_EdgeLightDataTex, i.uv).rg;
					half edge = data.g;

					#if defined(_GrayTexEnable)
					half grayCol = data.r;
					#else
					half grayCol = saturate(dot(baseCol.rgb, half3(0.3, 0.59, 0.11)));
					#endif

					half baseLight = grayCol;
					half noiseLight = (noise + edge) * grayCol;

					float pointLight = noiseLight * _NoisePointLightFactor + baseLight * _BasePointLightFactor;
					float rangeLight = noiseLight * _NoiseRangeLightFactor + baseLight * _BaseRangeLightFactor;

					float pointDis = length(i.wPos - _Light2DPointPos.xyz);
					float rangeDis = length((i.wPos - _Light2DRangePos.xyz) / (_Light2DRangeBox.xyz + 1e-2f));

					pointDis = saturate(_Light2DPointPos.w / (pointDis * pointDis + 1e-2f));

					float delta = saturate(1.0f - pow(rangeDis, 5.0f) * 32.0f);
					rangeDis = saturate(_Light2DRangePos.w / (rangeDis * rangeDis + 1e-2f)) * delta;

					#if defined(_GrayTexEnable)
						pointLight = pointLight * 0.1f;
						rangeLight = rangeLight * 0.1f;
					#endif
					float light = pointLight * pointDis + rangeLight * rangeDis;
					light = light - 1e-4f;
					light = clamp(light,0.0f, 100.0f);
					half4 col = baseCol + light * _Color;
					col.a = baseCol.a;
					clip(col.a - 0.5);
					return col;
				}
				ENDCG
			}
		}
}
