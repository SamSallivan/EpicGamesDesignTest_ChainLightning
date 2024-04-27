// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Hidden/Distort Effect" 
{

	Properties 
	{
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_DistortTex("",2D) = "black"{}
	}

	CGINCLUDE 

		#include "UnityCG.cginc"
		#pragma multi_compile DISTORT_OFF DISTORT_ON
		#pragma multi_compile GRAYSCALE_OFF GRAYSCALE_ON

		#if defined(SHADER_API_PS3)
            #define FXAA_PS3 1

            // Shaves off 2 cycles from the shader
            #define FXAA_EARLY_EXIT 0
        #elif defined(SHADER_API_XBOX360)
            #define FXAA_360 1

            // Shaves off 10ms from the shader's execution time
            #define FXAA_EARLY_EXIT 1
        #else
            #define FXAA_PC 1
        #endif

        #define FXAA_HLSL_3 1
        #define FXAA_QUALITY__PRESET 39

        #define FXAA_GREEN_AS_LUMA 1

        #pragma target 3.0
        #include "Assets/CGInclude/FXAA3.cginc"

        float3 _QualitySettings;
        float4 _ConsoleSettings;

		uniform sampler2D _MainTex;
		uniform sampler2D _DistortTex;

		float4 _MainTex_TexelSize;
		float4 _MainTex_ST;

		uniform half _RampOffset;

		struct v2f_simple 
		{
			float4 pos : SV_POSITION; 
			half2 uv : TEXCOORD0;

		#if UNITY_UV_STARTS_AT_TOP
			half2 uv2 : TEXCOORD1;
		#endif
		};

		v2f_simple vert_img_AA( appdata_img v )
		{
			v2f_simple o;
			o.pos = UnityObjectToClipPos (v.vertex);
			o.uv = v.texcoord;		
					
			#if UNITY_UV_STARTS_AT_TOP
				o.uv2 = v.texcoord;				
				if (_MainTex_TexelSize.y < 0.0)
					o.uv.y = 1.0 - o.uv.y;
			#endif
			return o;
		}

		fixed4 frag (v2f_simple i) : SV_Target
		{	

			float2 originaluv;

		#ifdef DISTORT_ON
			#if UNITY_UV_STARTS_AT_TOP
				fixed4 distort = tex2D (_DistortTex, i.uv2);
				originaluv = i.uv2 + distort.xy*0.1;
			#else

				fixed4 distort = tex2D (_DistortTex, i.uv) ;
				originaluv = i.uv + distort.xy*0.1;
			#endif

		#else

			#if UNITY_UV_STARTS_AT_TOP
				originaluv = i.uv2;
			#else
				originaluv = i.uv;
			#endif
		#endif

			fixed4 original = tex2D(_MainTex, originaluv);

		#ifdef GRAYSCALE_ON
			fixed grayscale = Luminance(original.rgb);
			fixed4 col = lerp(original ,grayscale  , _RampOffset);
			col.a = original.a;
		#else
			fixed4 col = original;
		#endif
			return col;
		}

		// inline half4 fxaa_color(float2 uv)
		// {
		// 	const float4 consoleUV = uv.xyxy + 0.5 * float4(-_MainTex_TexelSize.xy, _MainTex_TexelSize.xy);
        //     const float4 consoleSubpixelFrame = _ConsoleSettings.x * float4(-1.0, -1.0, 1.0, 1.0) *
        //         _MainTex_TexelSize.xyxy;

        //     const float4 consoleSubpixelFramePS3 = float4(-2.0, -2.0, 2.0, 2.0) * _MainTex_TexelSize.xyxy;
        //     const float4 consoleSubpixelFrameXBOX = float4(8.0, 8.0, -4.0, -4.0) * _MainTex_TexelSize.xyxy;

        // #if defined(SHADER_API_XBOX360)
        //     const float4 consoleConstants = float4(1.0, -1.0, 0.25, -0.25);
        // #else
        //     const float4 consoleConstants = float4(0.0, 0.0, 0.0, 0.0);
        // #endif

        //     half4 color = FxaaPixelShader(
        //         UnityStereoScreenSpaceUVAdjust(uv, _MainTex_ST),
        //         UnityStereoScreenSpaceUVAdjust(consoleUV, _MainTex_ST),
        //         _MainTex, _MainTex, _MainTex, _MainTex_TexelSize.xy,
        //         consoleSubpixelFrame, consoleSubpixelFramePS3, consoleSubpixelFrameXBOX,
        //         _QualitySettings.x, _QualitySettings.y, _QualitySettings.z,
        //         _ConsoleSettings.y, _ConsoleSettings.z, _ConsoleSettings.w, consoleConstants);

        //     return half4(color.rgb, 1.0);
		// }

		// half4 frag_fxaa (v2f_simple i) : SV_Target
		// {	
		// #ifdef DISTORT_ON
		// 	#if UNITY_UV_STARTS_AT_TOP
					
		// 	fixed4 distort = tex2D (_DistortTex, i.uv2);
		// 	half4 original = fxaa_color(i.uv2 + distort.xy*0.1);

		// 	#else

		// 	fixed4 distort = tex2D (_DistortTex, i.uv) ;
		// 	half4 original = fxaa_color(i.uv + distort.xy*0.1);

		// 	#endif

		// #else

		// 	#if UNITY_UV_STARTS_AT_TOP

		// 	half4 original = fxaa_color(i.uv2);

		// 	#else

		// 	half4 original = fxaa_color(i.uv);

		// 	#endif
		// #endif

		// #ifdef GRAYSCALE_ON
		// 	fixed grayscale = Luminance(original.rgb);
		// 	half4 col = lerp(original ,grayscale  , _RampOffset);
		// 	col.a = original.a;
		// #else
		// 	half4 col = original;
		// #endif

		// 	return col;
		// }

	ENDCG

	SubShader 
	{
		Pass 
		{
			ZTest Always  Cull Off ZWrite Off
			Fog { Mode off }

			CGPROGRAM
				#pragma vertex vert_img_AA
				#pragma fragment frag
				#pragma fragmentoption ARB_precision_hint_fastest
			ENDCG		
		}

		// Pass 
		// {
		// 	ZTest Always  Cull Off ZWrite Off
		// 	Fog { Mode off }

		// 	CGPROGRAM
		// 		#pragma vertex vert_img_AA
		// 		#pragma fragment frag_fxaa
		// 		#pragma fragmentoption ARB_precision_hint_fastest
		// 	ENDCG		
		// }
	}
}