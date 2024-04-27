Shader "Hidden/UnderwaterFog"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_WaterHeight("Water Height", Float) = 0
		_FogStart("Fog Start", Float) = 0.95
		_FogEnd("Fog End", Float) = 1
		_FogColor("Fog Color", Color) = (1,1,1,1)
	}
	SubShader
	{
		// No culling or depth
		Cull Off ZWrite Off ZTest Always

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
			sampler2D _CameraDepthTexture;
			half _WaterHeight;
			half _FogEnd;
			half _FogStart;
			fixed4 _FogColor;
			float3 computeCameraSpacePosFromDepthAndInvProjMat(float2 uv, float depth)
			{
				float4 clipPos = float4(uv, depth, 1.0);
				clipPos.xyz = 2.0f * clipPos.xyz - 1.0f;
				float4 camPos = mul(unity_CameraInvProjection, clipPos);
				camPos.xyz /= camPos.w;
				camPos.z *= -1;
				float4 worldPos = mul(unity_CameraToWorld, half4(camPos.xyz, 1));
				return worldPos;
			}

			fixed3 ApplyFog(float depth, fixed3 col)
			{
				half fogFactor = (_FogEnd - abs(depth)) / (_FogEnd - _FogStart);
				fogFactor = clamp(fogFactor, 0.0, 1.0);
				fixed3 fog = lerp(_FogColor.rgb, col.rgb, fogFactor);
				return fog;
			}
			fixed4 frag(v2f i) : SV_Target
			{
				float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv.xy);
				#if defined(UNITY_REVERSED_Z)
					depth = 1 - depth;
				#endif
				float3 nearClipPos= computeCameraSpacePosFromDepthAndInvProjMat(i.uv.xy, 0);
				float3 worldPos= computeCameraSpacePosFromDepthAndInvProjMat(i.uv.xy, depth);
				float temp = nearClipPos.y- _WaterHeight;
				temp = temp > 0 ? 0 : 1;
				fixed4 color = tex2D(_MainTex, i.uv);
				color.rgb = lerp(color.rgb, ApplyFog(depth, color.rgb), temp);
				return color;
			}
			ENDCG
		}
	}
}
