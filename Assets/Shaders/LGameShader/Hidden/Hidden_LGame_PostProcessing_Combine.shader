Shader "Hidden/LGame/PostProcessing/Combine"
{
	Properties
	{
		_MainTex ("_MainTex", 2D) = "white" {}
		
		// Bloom
		_BloomTex ("_BloomTex", 2D) = "black" {}
		_RenderScaleParam ("_RenderScaleParam", Vector) = (1.00000,1.00000,1.00000,1.00000)
		_Bloom_Params ("_Bloom_Params", Vector) = (01.00000,1.00000,1.00000,1.00000)
		_DisabledAlpha ("_DisabledAlpha", float) = 00.00000
		
		// Distort
		_DistortStrength("DistortStrength", Range(0,128)) = 32
		_DistortMaskTex("DistortMaskTex", 2D) = "black" {}
	}
	SubShader
	{
		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile __ _BLOOM_ON
			#pragma multi_compile __ _DISTORT_ON
			#pragma shader_feature _DISTORT_DEBUG_ON
			#include "UnityCG.cginc"
			

			struct a2v
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float4 vertex : SV_Position;
				float4 uv : TEXCOORD0;
				#if _DISTORT_ON
					float4 uvgrab : TEXCOORD1;
				#endif
			};
			
			sampler2D _MainTex;
			uniform float4 _MainTex_ST;
			#if _BLOOM_ON
				sampler2D _BloomTex;
				float4 _RenderScaleParam;
				float4 _Bloom_Params;
				half _DisabledAlpha;
			#endif
			
			#if _DISTORT_ON
				sampler2D _DistortMaskTex;
				float4 _DistortMaskTex_TexelSize;
				sampler2D _NoiseTex;
				float4 _NoiseTex_ST;
				float _DistortStrength;
				float _DistortTimeFactor;
			#endif
			
			
			// 压暗算法
			half3 EncodeFunc(half3 resultCol)
			{
			    half3 tempCol = resultCol.rgb;
			    resultCol.xyz = (-tempCol.xyz) + float3(1.01900005, 1.01900005, 1.01900005);
			    resultCol.xyz = tempCol.xyz / resultCol.xyz;
			    resultCol.xyz = resultCol.xyz * float3(0.155000001, 0.155000001, 0.155000001);
			    return resultCol;
			}

			v2f vert(a2v v)
			{
				v2f o = (v2f)0; // 改造：先不用三角形的做法，改回四边形
				o.vertex = UnityObjectToClipPos(v.vertex);

				// #if _BLOOM_ON
				// 	o.uv.zw = v.uv.xy * _RenderScaleParam.xy;
				// #endif

				#if _DISTORT_ON
					o.uvgrab.xy = (float2(o.vertex.x, o.vertex.y) + o.vertex.w) * 0.5;
					o.uvgrab.zw = o.vertex.zw;
					// o.uv.xy = v.uv;
				#endif
				
				o.uv.xy = TRANSFORM_TEX(v.uv.xy, _MainTex);
				return o;
			}

			half4 frag(v2f i) : SV_Target
			{
				half4 SV_Target0 = half4(0,0,0,0);
				half4 mainCol = half4(0,0,0,0);
				
				// 扭曲
				#if _DISTORT_ON
					//此处法线信息已经在mask中还原空间，所以要重新解压,从（0，0.8）映射到（-1，1）
					//half2 bump = clamp(0,1,tex2D(_DistortMaskTex, i.uv.xy).xy) - fixed2(0.5,0.5);//*2-1;
					float2 bump = tex2D(_DistortMaskTex, i.uv.xy).xy*2.5-1;
					float2 offset = _DistortStrength * _DistortMaskTex_TexelSize.xy * bump;
					float4 debuguv= i.uvgrab;
					i.uvgrab.xy = offset * i.uvgrab.z + i.uvgrab.xy;
					mainCol = tex2Dproj(_MainTex, UNITY_PROJ_COORD(i.uvgrab));
				#if _DISTORT_DEBUG_ON
					fixed4 debugBase = tex2Dproj(_MainTex, UNITY_PROJ_COORD(debuguv));
					fixed4 debugCol = tex2Dproj(_DistortMaskTex, UNITY_PROJ_COORD(debuguv));//preview
					mainCol = lerp(debugBase,debugCol,debugCol.a);//preview
				#endif
				#endif
					// return col;	
				
				SV_Target0 = mainCol;
				
				#if _BLOOM_ON
					fixed3 bloomCol = tex2D(_BloomTex, i.uv.xy).rgb * _Bloom_Params.xxx;
					// 如果开了扭曲，就用扭曲便宜后的 MainTex
					// 如果没有开扭曲，就自己采样 MainTex
					#if !_DISTORT_ON
						mainCol = tex2D(_MainTex, i.uv.xy);
					#endif
				
					// fixed4 mainCol = tex2D(_MainTex, finalUVXY);
					
					// 进行压暗处理
					half3 resultCol = EncodeFunc(mainCol.rgb);
					
					// bloomTex 与 blitTex 混合
					bloomCol = resultCol + bloomCol * _Bloom_Params.yzw;
					bloomCol = min(bloomCol, float3(16.0, 16.0, 16.0));
					
					half3 tempCol1 = bloomCol * float3(0.532999992, 0.532999992, 0.532999992) + float3(0.150999993, 0.150999993, 0.150999993);
					tempCol1 *= bloomCol;
					
					half3 tempCol2 = bloomCol * float3(0.526000023, 0.526000023, 0.526000023) + float3(0.200000003, 0.200000003, 0.200000003);
					tempCol2 *= bloomCol;
					tempCol2 += float3(0.0270000007, 0.0270000007, 0.0270000007);
					SV_Target0.xyz = tempCol1 / tempCol2;
					half maxAlpha = (mainCol.r + mainCol.g + mainCol.b) * _DisabledAlpha;
					SV_Target0.a = clamp((maxAlpha * 1000.0 + mainCol.a), 0.0, 1.0);
				#endif
				

				// lut 调色
				// TODO:...
				
				
				return SV_Target0;
			}
			ENDCG
		}
	}
}