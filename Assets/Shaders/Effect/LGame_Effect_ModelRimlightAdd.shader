
Shader "LGame/Effect/Model Rimlight Add"
{
	Properties
	{
		_RimLighColor("RimLigh Color" , Color) = (1,1,1,1)//主颜色
		_RimLighRange("RimLigh Range", Range(0.1,10)) = 1 //边缘光范围
		_RimLighMultipliers("RimLigh Multipliers", Range(0, 5)) = 1//边缘光强度
		[SimpleToggle]_UseCustomData("使用CustomData控制此项", float) = 0

		[HideInInspector]_AlphaCtrl("Alpha control", Range(0,1)) = 1
		[Toggle]_HighQuality("使用更高质量的边缘光（慎用）" ,float) = 0

	}

		//高质量（带动态阴影）																				   
		SubShader
	{
		Tags { "RenderType" = "Transparent" "LightMode" = "ForwardBase" "Queue" = "Transparent" }
		LOD 75

		//基础Pass
		Pass
		{
			Name "ForwardBase"
			ZWrite Off
			Lighting Off
			Fog { Mode Off }
			Blend One One
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag	
			#pragma shader_feature _HIGHQUALITY_OFF _HIGHQUALITY_ON
			#include "UnityCG.cginc" 
			struct appdata
			{
				float4	vertex		: POSITION;
				half3	normal		: NORMAL;
				float4	customData	: TEXCOORD0;
			};

			struct v2f
			{
				float4	pos			: SV_POSITION;


			#if _HIGHQUALITY_ON
				float4	worldViewDir: TEXCOORD0;// w存customData
				half3	worldNormal	: NORMAL;
			#else
				half3	rimlight	: TEXCOORD1;
			#endif

			};
			fixed4		_RimLighColor;
			half		_RimLighRange;
			half		_RimLighMultipliers;
			half		_AlphaCtrl;
			half		_UseCustomData;

			v2f vert(appdata v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);

				half3 worldNormal = UnityObjectToWorldNormal(v.normal);
				half3 worldViewDir = normalize(WorldSpaceViewDir(v.vertex));
			#if _HIGHQUALITY_ON
				o.worldNormal = worldNormal;
				o.worldViewDir.xyz = worldViewDir;
				o.worldViewDir.w = v.customData.w;
			#else
				half fresnel = pow(1 - abs(dot(worldViewDir, worldNormal)), _RimLighRange);
				// 粒子custom data控制边缘光强度
				_RimLighMultipliers = lerp(_RimLighMultipliers, _RimLighMultipliers * v.customData.w, _UseCustomData);
				o.rimlight = fresnel * _RimLighColor.rgb * _RimLighMultipliers * _AlphaCtrl;
			#endif
				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				fixed3 col = (fixed3)1;
			#if _HIGHQUALITY_ON
				half3 worldViewDir = normalize(i.worldViewDir.xyz);
				float customData = i.worldViewDir.w;
				half3 worldNormal = normalize(i.worldNormal);
				half fresnel = pow(1 - abs(dot(worldViewDir, worldNormal)), _RimLighRange);
				_RimLighMultipliers = lerp(_RimLighMultipliers, _RimLighMultipliers * customData, _UseCustomData);
				col = fresnel * _RimLighColor.rgb * _RimLighMultipliers * _AlphaCtrl;
			#else
				col = i.rimlight;
			#endif
				return  fixed4(col, 1);
			}
			ENDCG
		}
	}

		SubShader
			{
					Tags { "Queue" = "Transparent" "LightMode" = "ForwardBase" "IgnoreProjector" = "True" "RenderType" = "Transparent"}
					LOD 5
					Blend One One
					ZWrite[_ZWriteMode]
					ZTest[_ZTestMode]
					Cull[_CullMode]

						Pass
						{
							CGPROGRAM
							#pragma vertex vert
							#pragma fragment fragtest
							//#pragma multi_compile_instancing
							#include "Assets/CGInclude/LGameEffect.cginc" 

							half4 fragtest(v2f i) : SV_Target
							{
								UNITY_SETUP_INSTANCE_ID(i);

								fixed4 texColor = tex2D(_MainTex, i.uvMain.xy, float2(0, 0), float2(0, 0));

								return half4(0.15,0.06,0.03, texColor.a < 0.001);
							}
							ENDCG
						}
			}
}