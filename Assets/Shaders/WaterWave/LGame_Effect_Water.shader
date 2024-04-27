Shader "LGame/Effect/Water"
{
	Properties
	{
		// 水体部分
		_NoiseMap("_NoiseMap", 2D) = "white" {}
		[Header(noise params)]
		_NoiseParameter("x：第一层密集度  y：第二层密集度  z: 顶点色对扰动的影响  w：扰动的高度偏移量", Vector) = (2.00000, 4.00000, 0.40000, 2.00000)     // x: noise1 的uv缩放强度  y：noise2 的uv缩放强度  z: 控制顶点色对uv扰动的影响强度
		_NoiseParameter2("x：第一层uv流动速度  y：第二层uv流动速度  z: 涟漪强度  w：平面反射扰动强度", Vector) = (0.60000, -0.30000, 0.66000, 0.33000)  // x: noise1 的流动速度(即uv偏移速度)  y: noise2 的流动速度(即uv偏移速度)  z：控制涟漪强度
		_WaterFogColor("深水颜色", Color) = (0.18274, 0.25846, 0.38235)		// 深水处颜色 （顶点色趋向于白）
		_WaterFogColor2("浅水颜色", Color) = (0.45618, 0.66000, 0.66000)	// 浅水处颜色 （顶点色趋向于黑）

		// 特效部分
		[Space(20)]
		[HDR]_Color("Color", Color) = (1,1,1,1)
		_Multiplier("亮度",range(1,20)) = 1
		[Space(20)]
		_MainTex("MainTex", 2D) = "white" {}
		[WrapMode] _MainTexWrapMode("MainTex wrapMode", Vector) = (1,1,0,0)
		[TexTransform] _MainTexTransform("MaitTex Transform" , Vector) = (0,0,0,1) //scrollU , scrollV , scrollRot

		[Space(20)]
		_MaskTex("mask", 2D) = "white" {}
		[WrapMode] _MaskTexWrapMode("MaskTex wrapMode", Vector) = (1,1,0,0)
		[TexTransform] _MaskTexTransform("MaskTex Transform" , Vector) = (0,0,0,1) //scrollU , scrollV , scrollRot

		[Space(20)]
		_FlowTex("flow", 2D) = "black" {}
		[TexTransform] _FlowTexTransform("FlowTex Transform" , Vector) = (0,0,0,1) //scrollU , scrollV , scrollRot
		_FlowScale("flow value", Range(0, 2)) = 0
	}

		SubShader
		{
			Tags { "Queue" = "Transparent" "LightMode" = "ForwardBase" "IgnoreProjector" = "True" "RenderType" = "Transparent"}
			Blend SrcAlpha OneMinusSrcAlpha, Zero OneMinusSrcAlpha
			Cull Off
			Zwrite Off
			ZTest LEqual
			ZClip True
			ColorMask RGB
			LOD 100

			Stencil
			{
				Ref 0
				Comp Always
				Pass Keep
				Fail Keep
				ZFail Keep
			}

			Pass
			{
				CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag
				#pragma multi_compile __ _WATERWAVE_ON
				#pragma multi_compile __ _FOW_ON _FOW_ON_CUSTOM

				#include "UnityCG.cginc"
				#include "Assets/CGInclude/EffectCG.cginc"
				#include "Assets/CGInclude/LGameFog.cginc"
				//#define _WATERWAVE_ON 1

				struct appdata
				{
					float4 vertex : POSITION;
					fixed4 vertexColor : COLOR;
					float2 uv : TEXCOORD0;
				};

				struct v2f
				{
					float4 vertex : SV_POSITION;
					float4 uv12 : TEXCOORD1;
					float2 uv34 : TEXCOORD2;
					fixed4 multipColor : TEXCOORD3;
	#if _WATERWAVE_ON
					fixed4 vertexColor : COLOR;
					half4 srcPos	: TEXCOORD4;
					half3 viewDir	: TEXCOORD5;
					float4 noiseUV	: TEXCOORD6;
	#endif
	#if _FOW_ON || _FOW_ON_CUSTOM
					half2 fowuv		: TEXCOORD7;
	#endif
				};

				fixed4 _Color;
				// fixed4 _FogCol;
				half _FowBlend;
				half _Multiplier;
				sampler2D _MainTex;
				half4 _MainTex_ST;
				half4 _MainTexTransform;
				fixed4 _MainTexWrapMode;

				sampler2D _MaskTex;
				half4 _MaskTex_ST;
				half4 _MaskTexTransform;
				fixed4 _MaskTexWrapMode;

				sampler2D _FlowTex;
				half4 _FlowTex_ST;
				half4 _FlowTexTransform;
				half _FlowScale;

	#if _WATERWAVE_ON
				half4 _NoiseParameter;
				half4 _NoiseParameter2;
				half3 _WaterFogColor;
				half3 _WaterFogColor2;
				sampler2D _NoiseMap;
				float4 _NoiseMap_ST;
				uniform sampler2D _GlobalUnderWaterRT;
				uniform sampler2D _GlobalDistortionRT;
				uniform float4 _GlobalDistortionRT_TexelSize;
	#endif

				v2f vert(appdata v)
				{
					v2f o;
					float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
					o.vertex = UnityWorldToClipPos(worldPos.xyz);

	#if _WATERWAVE_ON
					o.srcPos = ComputeScreenPos(o.vertex);
					o.viewDir = normalize(UnityWorldSpaceViewDir(worldPos)); // 获取世界空间下的视角方向
					o.vertexColor = v.vertexColor;
	#endif

					o.uv12.xy = TransFormUV(v.uv, _MainTex_ST,  1);
					o.uv12.xy = RotateUV(o.uv12.xy, _MainTexTransform.zw);
					o.uv12.xy += frac(_Time.z * _MainTexTransform.xy);

					// MaskTex
					o.uv12.zw = TransFormUV(v.uv, _MaskTex_ST, 1);
					o.uv12.zw = RotateUV(o.uv12.zw, _MaskTexTransform.zw);
					o.uv12.zw += frac(_Time.z * _MaskTexTransform.xy);

					// FlowTex
					o.uv34.xy = TransFormUV(v.uv, _FlowTex_ST,1);
					o.uv34.xy = RotateUV(o.uv34.xy, _FlowTexTransform.zw);
					o.uv34.xy += frac(_Time.z * _FlowTexTransform.xy);

					fixed4 fowCol = lerp(1.0.rrrr, _FogCol, _FowBlend);
	#if _WATERWAVE_ON
					o.multipColor = v.vertexColor * _Color * 1.28 * fowCol;
	#else
					o.multipColor = v.vertexColor * _Color * _Multiplier * fowCol;
	#endif

	#if _WATERWAVE_ON
					o.noiseUV = v.uv.xyxy * _NoiseParameter.xxyy + frac(_Time.xxxx * float4(-1, 1, -1, 1) * _NoiseParameter2.xxyy);
	#endif
	#if _FOW_ON || _FOW_ON_CUSTOM
			o.fowuv = half2 ((worldPos.x - _FOWParam.x) / _FOWParam.z, (worldPos.z - _FOWParam.y) / _FOWParam.w);
	#endif
					return o;
				}

				fixed4 frag(v2f i) : SV_Target
				{
					fixed4 finalCol = fixed4(0,0,0,1);

	#if _WATERWAVE_ON
					fixed2 screenPos = (i.srcPos.xy / i.srcPos.w);
					// 采样计算法线扰动结果
					fixed2 n1 = UnpackNormal(tex2D(_NoiseMap, i.noiseUV.xy)).xy;
					fixed2 n2 = UnpackNormal(tex2D(_NoiseMap, i.noiseUV.zw)).xy;
					fixed3 N = fixed3(0, 0, 0);
					N.xz = n1 + n2;
					N.y = _NoiseParameter.w;
					N = normalize(N);

					// 开始叠加涟漪交互扰动结果
					fixed3 rippleNosie = tex2D(_GlobalDistortionRT, screenPos).zzz; // only b channel 
					N = normalize(N + rippleNosie * _NoiseParameter2.z);

					// 改为模拟后处理截屏的方式获取主纹理
					fixed2 projUv = saturate(screenPos + (N.xz * i.vertexColor.a * _NoiseParameter.zz));
					fixed4 underwaterCol = tex2D(_GlobalUnderWaterRT, projUv); // *_Color;
					underwaterCol.a = 1.0;

					// ================== 水体深浅颜色 ==================
					// 根据顶点色线性插值得到水体颜色（顶点色绘制标识水体深浅颜色过渡） 
					// 顶点色表示水的深浅
					// 越白=越深= _WaterFogColor 越强， 反之 _WaterFogColor 越强
					fixed3 waterFogCol = lerp(_WaterFogColor2.rgb, _WaterFogColor.rgb, i.vertexColor.a);

					// 将顶点色最小值控制在0.6
					// 得到最终的水体颜色
					fixed4 waterCol = fixed4(0,0,0,1);
					waterCol.rgb = lerp(underwaterCol, underwaterCol * 2.0 * waterFogCol, min(i.vertexColor.a, 0.6));
					waterCol.a = lerp(0, waterCol.a, i.vertexColor.a);
					// waterCol.a = lerp(0, waterCol.a, _Switch); // _Switch 控制全局开关  // 咱们先注释
	#endif

					// FlowTex
					float4 flowUV = i.uv12.xyxy;
					i.uv34.xy = frac(i.uv34.xy);
					fixed4 flowColor = tex2D(_FlowTex, i.uv34.xy, float2(0,0), float2(0,0));
					flowUV = (i.uv12.xy + (flowColor.xy - 0.5) * _FlowScale).xyxy;
					flowUV.xy = lerp(flowUV.xy, frac(flowUV.xy), _MainTexWrapMode.xy);

					// MainTex
					fixed4 texColor = tex2D(_MainTex, flowUV.xy, float2(0, 0), float2(0, 0));
					fixed4 result = texColor;

					// MaskTex
					float4 maskUV = i.uv12.zwzw;
					maskUV.xy = lerp(maskUV.xy, frac(maskUV.xy), _MaskTexWrapMode.xy);
					fixed4 maskColor = tex2D(_MaskTex, maskUV.xy, float2(0, 0), float2(0, 0));
					result.a *= maskColor.r;

					// other
					result *= i.multipColor;
					result.a = saturate(result.a);

					// test debug
					//return result;    // 只输出特效
					// return waterCol;    // 只输出水
	#if _WATERWAVE_ON
					//finalCol = result * result.a + (1 - result.a)*waterCol;
					finalCol = result * result.a + waterCol;
	#else
					finalCol = result;
	#endif

					// Apply Fog
            		#if _FOW_ON || _FOW_ON_CUSTOM
						LGameFogApply(finalCol, i.vertex.xyz, i.fowuv);
            		#endif
					
					return finalCol;
				}
				ENDCG
			}
		}
}
