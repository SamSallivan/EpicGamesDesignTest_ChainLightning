Shader "LGame/Scene/WaterWave"
{
	Properties
	{
		//_Mode("__mode", Float) = 0.0
		//_SrcBlend("__src", Float) = 5
		//_DstBlend("__dst", Float) = 10
		//[HideInInspector] _ZWrite("__zw", Float) = 1.0

		_Color("Color", Color) = (1,1,1,1)
		_WaterWaveTwo("WaterWave Texture", 2D) = "white" {}
		_WaterWaveMask("WaterWave ShowRange", 2D) = "white" {}

		_WaverIntensity("Waver Intensity",  Range(0,10)) = 0.15
		//_WaverHighCurve("Waver High Curve",  Range(0,10)) = 2
		_WaverSpeed("WaverMove speed",  Range(0,10)) = 1
		_WaverTexSpeed("WaverTex speed Y",  Range(0,0.5)) = 1
		_WaverTexSpeedX("WaverTex speed x",  Range(0,1)) = 1


	}

		CGINCLUDE
		#include "UnityCG.cginc"
		#include "Assets/CGInclude/LGameFog.cginc"

			struct appdata
		{
			float4 vertex	: POSITION;
			float2 uv		: TEXCOORD0;
			float2 uv2		: TEXCOORD1;
		};

		struct v2f
		{
			fixed4 color : COLOR;
			float4 vertex	: SV_POSITION;
			float4 uv		: TEXCOORD0;
			float4 uv2		: TEXCOORD1;
#if _FOW_ON || _FOW_ON_CUSTOM
			half2 fowuv		: TEXCOORD2;
#endif
			float4 test :  TEXCOORD3;
			DECLARE_FOG_V2F(4)
		};

		fixed4		_Color;
		sampler2D	_WaterWaveMask;
		float4		_WaterWaveMask_ST;
		sampler2D	_WaterWaveTwo;
		float4		_WaterWaveTwo_ST;

		half		_Brightness;

#if _HIGHFOG_ON
		fixed4		_HighFogCol;
		half		_HighFogOffset;
		half		_HighFogRange;
#endif

		half4 _ActorPos;
		half _WaverIntensity;
		//half _WaverHighCurve;
		half _WaverSpeed;
		half _WaverTexSpeed;
		half _WaverTexSpeedX;
		//half _SceneDepthOffset;

//		inline float4 AnimateVertex2(float3 worldPos)
//		{
//#if _WAVE_ON
//			float2 offset = (sin((_Time.y + worldPos.xz - worldPos.y * _WaverHighCurve) * _WaverSpeed) * _WaverIntensity) * worldPos.y * 0.5;
//			worldPos.xz += offset;
//			return float4(worldPos, 1);
//#else
//			return float4(worldPos, 1);
//#endif
//		}

		inline float4 AnimateVertex2(float3 worldPos)
		{
			float offset = (sin((_Time.y + worldPos.xz - worldPos.y * 2) * _WaverSpeed) * _WaverIntensity) * worldPos.y * 0.5;
			worldPos += half3(offset, offset*0.2, offset);
			return float4(worldPos, 1);

		}

		v2f vert(appdata v)
		{
			v2f o;

			float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
			float4 mdlPos = AnimateVertex2(worldPos);

			o.vertex = UnityWorldToClipPos(mdlPos.xyz);
			o.test = mdlPos.xyzz;

			o.uv.xy = TRANSFORM_TEX(v.uv, _WaterWaveMask);

			half waveValue = 0.1;
			half waveValueDouble = _WaverTexSpeed;

			//双向折线周期运算函数
			//half lineWaveDouble = abs(-floor(_Time.y * waveValueDouble) + _Time.y * waveValueDouble-0.5) * 4 - 1;
			//half lineWaveDouble = clamp(abs(-floor(_Time.y* waveValueDouble) + _Time.y * waveValueDouble - 0.5) * 4,0,1);
			half lineWaveDouble = _Time.y * waveValueDouble;

			//单项折线周期运算函数
			//half lineWave =  - floor(_Time.y * waveValue) + _Time.y * waveValue -0.5 ;
				
			o.uv.zw = o.uv.xy - half2(-_Time.y * 0.1*_WaverTexSpeedX,0);

			o.uv2.xy = TRANSFORM_TEX(v.uv2, _WaterWaveTwo);

			o.uv2.zw = half2(o.uv2.x + _Time.y*0.05, o.uv2.y -  lineWaveDouble -0.5 );

			//o.uv2.xy *= 1.2;
			o.uv2.xy += half2(-_Time.y * 0.01, lineWaveDouble );
			//o.uv2 = v.uv2;
#if _FOW_ON || _FOW_ON_CUSTOM
			o.fowuv = half2 ((worldPos.x - _FOWParam.x) / _FOWParam.z, (worldPos.z - _FOWParam.y) / _FOWParam.w);
			o.worldPos = worldPos;
#endif
			o.color = saturate(worldPos.y * 2);
#if _HIGHFOG_ON
			o.color.rgb = saturate((worldPos.y - _HighFogOffset) * _HighFogRange) * _HighFogCol.a;
#endif


			return o;
		}

		ENDCG

			SubShader
		{

			LOD 100

			Tags
			{

			"LightMode" = "ForwardBase"
			"Queue" = "AlphaTest-10"
			"IgnoreProjector" = "true"
			"RenderType" = "TransparentCuout"
			}

			Pass
			{
				Name "FORWARD"
				Tags { "LightMode" = "ForwardBase" }
				BlendOp Add
				//Blend[_SrcBlend][_DstBlend]

				ZWrite off
				Blend SrcAlpha OneMinusSrcAlpha

				//Cull Off
				CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag
				#pragma multi_compile __ _FOW_ON _FOW_ON_CUSTOM
				#pragma shader_feature _ALPHACLIP_ON 
				//#pragma shader_feature _WAVE_ON 
				#pragma shader_feature _HIGHFOG_ON 
				#include "UnityCG.cginc"
				#include "Assets/CGInclude/LGameFog.cginc"

				fixed4 frag(v2f i) : SV_Target
				{

					fixed4 col = tex2D(_WaterWaveMask, i.uv.zw); //mask

					fixed4 colwaveOne = tex2D(_WaterWaveTwo, i.uv2.zw);
					fixed4 colwaveTwo = tex2D(_WaterWaveTwo, i.uv2.xy);

					// Apply Fog
					 #if _FOW_ON || _FOW_ON_CUSTOM
						LGameFogApplySpecial(col, i.worldPos.xyz, i.fowuv); 
					#endif
					
					#if _HIGHFOG_ON
						col.rgb = lerp(col.rgb , _HighFogCol.rgb , i.color.rgb);
					#endif
					//half maska= clamp(col.r * 0.4+col.g*0.8+col.b * 0.3 ,0,1);
					half maska= col.r ;
					half alpha = clamp(maska  * colwaveOne.r +maska * colwaveTwo.g + maska * colwaveTwo.b ,0,1);

					//col.rgb = i.uv2.w;
					//col.rgb = max(max(colwaveTwo.rgb, colwaveOne.rgb) * _Color.rgb,col.rgb);
					col.rgb = max(max(colwaveTwo.rgb, colwaveOne.rgb) * _Color.rgb,col.rgb);

					//col.rgb = colwaveOne.rgb;

					col.a = alpha* _Color.a;
					//col.a = 1;

					return col;
				}
				ENDCG
		}

		}

			SubShader
			{
				Tags { "Queue" = "Geometry" "RenderType" = "Opaque" }
				LOD 10

				Pass
				{
					Name "FORWARD"
					Tags { "LightMode" = "ForwardBase" }
					Fog { Mode Off }

					CGPROGRAM
					#include "Assets/CGInclude/RenderDebugCG.cginc"
					#pragma vertex vert
					#pragma fragment frag_mipmap  

					fixed4 frag_mipmap(v2f i) : SV_Target
					{
						fixed3 c = 0;
						fixed4 tex = tex2D(_WaterWaveMask, i.uv.zw);
						c = tex.rgb;

						return GetMipmapsLevelColor(c,i.uv);
					}

					ENDCG
				}
			}


				SubShader
					{
						Tags { "Queue" = "Geometry" "RenderType" = "Opaque" }
						LOD 5
						Blend One One

						Pass
						{
							Name "FORWARD"
							Tags { "LightMode" = "ForwardBase" }
							Fog { Mode Off }

							CGPROGRAM
							#pragma vertex vert
							#pragma fragment frag  

						// fragment shader
						fixed4 frag(v2f i) : SV_Target
						{
							return fixed4(0.15, 0.06, 0.03, 0);
						}

						ENDCG
					}
					}

}
