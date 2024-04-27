Shader "Hidden/LightShafts"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
	CGINCLUDE
	#include "UnityCG.cginc"
	struct a2v
	{
		float4 vertex : POSITION;
		float2 uv : TEXCOORD0;
	};
	struct v2f
	{
		float2 uv : TEXCOORD0;
		float4 border : TEXCOORD1;
		float4 vertex : SV_POSITION;
	};
	sampler2D _MainTex;
	sampler2D _LightShaftsTex;
	sampler2D _CameraDepthTexture;
	float _AspectRatio;
	float _RadialBlurParameters;
	float2 _LightShaftParameters;
	float2 _TextureSpaceBlurOrigin;
	float4 _MainTex_TexelSize;
	float4 _BloomTintAndThreshold;

#ifndef NUM_SAMPLES
	#define NUM_SAMPLES 12
#endif
	v2f Vertex(a2v v)
	{
		v2f o;
		o.vertex = UnityObjectToClipPos(v.vertex);
		o.uv = v.uv;
		o.border = float4(_MainTex_TexelSize.xy * 0.5, 1.0 - _MainTex_TexelSize.xy * 0.5);
		return o;
	}
	float Pow4(float t) 
	{
		return t * t* t * t;
	}
	float Pow2(float t) 
	{
		return t * t;
	}
	float4 DownSampleFragment(v2f i) : SV_Target
	{
		float SceneDepth = Linear01Depth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv));
		float2 NormalizedCoordinates = (i.uv - i.border.xy) / i.border.zw;
		// Setup a mask that is 1 at the edges of the screen and 0 at the center
		float EdgeMask = 1.0f - NormalizedCoordinates.x * (1.0f - NormalizedCoordinates.x) * NormalizedCoordinates.y * (1.0f - NormalizedCoordinates.y) * 8.0f;
		EdgeMask = Pow4(EdgeMask);
#if OCCLUSION_TERM	
		// Filter the occlusion mask instead of the depths
		float OcclusionMask = saturate(SceneDepth * _LightShaftParameters.x);
		// Apply the edge mask to the occlusion factor
		float OutColor = max(OcclusionMask, EdgeMask);
		return OutColor;
#else
		float3 SceneColor = tex2D(_MainTex, i.uv).rgb;
		// Only bloom colors over BloomThreshold
		float Luminance = max(dot(SceneColor, half3(.3f, .59f, .11f)), 6.10352e-5);
		float AdjustedLuminance = max(Luminance - _BloomTintAndThreshold.a, 0.0f);
		float3 BloomColor = SceneColor / Luminance * AdjustedLuminance * 2.0f;
		// Only allow bloom from pixels whose depth are in the far half of OcclusionDepthRange
		float BloomDistanceMask = saturate((SceneDepth - .5f / _LightShaftParameters.x) * _LightShaftParameters.x);
		// Setup a mask that is 0 at TextureSpaceBlurOrigin and increases to 1 over distance
		float BlurOriginDistanceMask = 1.0f - saturate(length(_TextureSpaceBlurOrigin.xy - i.uv * float2(1.0, _AspectRatio)) * 2.0f);
		// Calculate bloom color with masks applied
		float3 OutColor = BloomColor * _BloomTintAndThreshold.rgb * BloomDistanceMask * (1.0f - EdgeMask) * Pow2(BlurOriginDistanceMask);
		//#endif
		return float4(OutColor, 1.0);
#endif
	}
	float4 RadialBlurFragment(v2f i) : SV_Target
	{
		float3 BlurredValues = 0;
		// Scale the UVs so that the blur will be the same pixel distance in x and y
		float2 AspectCorrectedUV = i.uv * float2(1.0, _AspectRatio);
		// Increase the blur distance exponentially in each pass
		float PassScale = pow(.4f * NUM_SAMPLES, _RadialBlurParameters);
		float2 AspectCorrectedBlurVector = (_TextureSpaceBlurOrigin.xy - AspectCorrectedUV)
			// Prevent reading past the light position
			* min(0.1f * PassScale, 1.0);
		float2 BlurVector = AspectCorrectedBlurVector / float2(1.0, _AspectRatio);
		[unroll]
		for (int SampleIndex = 0; SampleIndex < NUM_SAMPLES; SampleIndex++)
		{
			float2 SampleUVs = (AspectCorrectedUV + AspectCorrectedBlurVector * SampleIndex / (float)NUM_SAMPLES) / float2(1.0, _AspectRatio);
			// Needed because sometimes the source texture is larger than the part we are reading from
			float2 ClampedUVs = clamp(SampleUVs, i.border.xy, i.border.zw);
			float3 SampleValue = tex2D(_MainTex, ClampedUVs).xyz;
			BlurredValues += SampleValue;
		}
		float3 OutColor = BlurredValues / (float)NUM_SAMPLES;
		return float4(OutColor,1.0);
	}

	float4 LightShaftsBloomFragment(v2f i) : SV_Target
	{
		float4 LightShaftColorAndMask = tex2D(_LightShaftsTex, clamp(i.uv, i.border.xy, i.border.zw));
		float4 Color = tex2D(_MainTex, i.uv);
		return float4(Color.rgb + LightShaftColorAndMask.rgb, 1.0);
	}
	float4 LightShaftsOcclusionFragment(v2f i) : SV_Target
	{
		float4 Color = tex2D(_MainTex, i.uv);
		float LightShaftOcclusion = tex2D(_LightShaftsTex,i.uv).r;
		// LightShaftParameters.w is OcclusionMaskDarkness, use that to control what an occlusion value of 0 maps to
		float FinalOcclusion = lerp(_LightShaftParameters.y, 1, Pow2(LightShaftOcclusion));
		// Setup a mask based on where the blur origin is
		float BlurOriginDistanceMask = saturate(length(_TextureSpaceBlurOrigin.xy - i.uv * float2(1.0, _AspectRatio)) * 0.2f);
		// Fade out occlusion over distance away from the blur origin
		return lerp(FinalOcclusion, 1.0, BlurOriginDistanceMask) * Color;
	}
	ENDCG
    SubShader
    {
        // No culling or depth
        Cull Off ZWrite Off ZTest Always
		// Pass 0
		// Downsample
        Pass
        {
            CGPROGRAM
            #pragma vertex Vertex
            #pragma fragment DownSampleFragment
			#pragma multi_compile _ OCCLUSION_TERM
            ENDCG
        }
		// Pass 1
		// Radial Blur
		Pass
		{
			CGPROGRAM
			#pragma vertex Vertex
			#pragma fragment RadialBlurFragment
			ENDCG
		}
		// Pass 2
		// Light Shafts Bloom
		//Blend One One
		Pass
		{
			//Add
			//Blend One One
			CGPROGRAM
			#pragma vertex Vertex
			#pragma fragment LightShaftsBloomFragment
			ENDCG
		}
		// Pass 3
		// Light Shafts Occlusion
		Pass
		{
			//Multiply
			//Blend DstColor Zero
			CGPROGRAM
			#pragma vertex Vertex
			#pragma fragment LightShaftsOcclusionFragment
			ENDCG
		}
    }
}
