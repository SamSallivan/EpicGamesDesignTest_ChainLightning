Shader "LGame/Beta/Character/PlayerDefault"
{
	Properties
	{
		_AlphaCtrl ("Alpha Control", Range(0,1)) = 1
		_AlphaCtrlForArtist ("Alpha Control", Range(0,1)) = 1
		_BlendMode("Blend Mode",float) = 0
		[Enum(UnityEngine.Rendering.CompareFunction)] _StencilComp ("Stencil Comparison", Int) = 8
		[IntRange] _Stencil ("Stencil value", Range(0,255)) = 0 
		[Enum(UnityEngine.Rendering.StencilOp)] _StencilOp ("Stencil Operation", Int) = 0 
		[IntRange] _ReadMask ("Stencil Read Mask", Range(0,255)) = 255
		[IntRange] _WriteMask ("Stencil Write Mask", Range(0,255)) = 255
		[Enum(UnityEngine.Rendering.CompareFunction)] _ZTestMode ("Z Test", Int) = 4
		[Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend ("Blend Source", Int) = 1
		[Enum(UnityEngine.Rendering.BlendMode)] _DstBlend ("Blend Destination", Int) = 0 
		[Enum(Off, 0, On, 1)] _ZWriteMode ("Z Write", Int) = 1 
		[Enum(UnityEngine.Rendering.CullMode)] _CullMode ("Cull Mode", Int) = 2
		[Enum(UnityEngine.Rendering.ColorWriteMask)] _ColorMask ("ColorMask", Float) = 15
		[IntRange] _OptionAreaExpanded ("Should expand option", Range(0,1)) = 0

		_MainTint ("Main Tint Color", Color) = (1,1,1,1) // *
		_MainTex ("Main Texture", 2D) = "white" {}
		_MainTex_UV ("Main Texture Animation", Vector) = (0,0,0,0)
		_OffsetColor ("Main Offset Color", Color) = (0,0,0,1) // +

		_SubtexMatcapCombinedTexture ("Combined - Subtex + MatCap", 2D) = "white"{}
		_SubtexMatcapCombinedWrapMode ("Combined - Subtex + MatCap", Vector) = (11,11,11,0) // x,y,z -> three channels; 0 = clamp, 1 = repeat, 2 = mirror; 10*uMode + vMode
		_SubTexMask_ST ("Sub Tex Mask Scale Offset", Vector) = (1,1,0,0)
		_SubTexMask_UV ("Sub Tex Mask UV Animation", Vector) = (0,0,0,0)
		_SubTint ("Sub Tint Color", Color) = (1,1,1,1)
		_SubTex ("Sub Texture", 2D) = "white" {}
		_SubOffsetColor ("Sub Offset Color", Color) = (0,0,0,1)

		_SubTexLerp ("Sub Texture Lerp", Range(0,1)) = 0.5 
		_SubDissolveTex_ST ("Sub Texture Dissolve Scale Offset", Vector) = (1,1,0,0)
		_SubDissolveTex_UV ("Sub Texture Dissolve Texture UV Animation", Vector) = (0,0,0,0)
		[HDR]_SubDissolveColor ("Sub Texture Dissolve Color", Color) = (0,0,0,1)
		_SubDissolveRange ("Sub Texture Dissolve Range", Range(0.01, 0.5)) = 0.5

		_MatCapMask_ST ("MatCap Mask Scale Offset", Vector) = (1,1,0,0)
		_MatCapMask_UV ("MatCap Mask UV Animation", Vector) = (0,0,0,0)
		_MatCapTex ("MatCap Texture", 2D) = "white" {}
		_MatCapTint ("MatCap Tint Color", Color) = (0.66,0.66,0.66,1)
		_MatCapRoughness ("MatCap Roughness", Range(0,1)) = 0.5
		_MatCapIntensity ("MatCap Intensity", Range(0,1)) = 1

		[Enum(No, 0, Yes, 1)] _RimlightLighten ("Rimlight Lighten?", Float) = 0
		[Enum(No, 0, Yes, 1)] _RimlightDarken ("Rimlight Darken?", Float) = 0
		_RimFlowCombinedTexture ("Combined Texture - Rimlight + Flowlight", 2D) = "white" {}
		_RimFlowCombinedWrapMode ("Combined - Rimlight + Flowlight", Vector) = (11,11,11,0)
		_RimlightMask_ST ("Rimlight Mask Scale Offset", Vector) = (1,1,0,0)
		_RimlightMask_UV ("Rimlight Mask UV Animation", Vector) = (0,0,0,0)
		[HDR]_RimlightColor ("Rimlight Color", Color) = (0,0,0,1)
		_RimlightRange ("Rimlight Range", Range(0.1,10)) = 1
		_RimlightIntensity ("Rimlight Intensity", Range(0,5)) = 1
		[Enum(On, 0, Off, 1)] _RimlightInverse ("Invert Rimlight?", Int) = 1
		_RimlightNoise ("Rimlight Noise", 2D) = "white" {}
		_RimlightNoise_ST ("Rimlight Noise Scale Offset", Vector) = (1,1,0,0)
		_RimlightNoise_UV ("Rimlight Noise UV Animation", Vector) = (0,0,0,0)
		_RimlightNoiseSampleSpace ("Rimlight Noise Sample Space", float) = 0
		_RimlightEulerAngles ("Rimlight Euler Angles", Vector) = (0,0,0,0)
		_RimlightProjectionNormal ("Rimlight World Projection Normal", Vector) = (1,0,0,1)
		_RimlightRPM1 ("", Vector) = (1,0,0,0)
		_RimlightRPM2 ("", Vector) = (0,1,0,0)
		_RimlightRPM3 ("", Vector) = (0,0,1,0)

		_FlowlightMask_ST ("Flowlight Mask Scale Offset", Vector) = (1,1,0,0)
		_FlowlightMask_UV ("Flowlight Mask UV Animation", Vector) = (0,0,0,0)
		_FlowlightTint ("Flowlight Tint Color", Color) = (1,1,1,1)
		_FlowlightIntensity ("Flowlight Intensity", Range(0,5)) = 1 
		_FlowlightTex ("Flowlight Texture", 2D) = "white" {}
		_FlowlightTex_UV ("Flowlight Texture UV Animation", Vector) = (0,0,0,0)
		_FlowlightSampleSpace ("Flowlight Sample Space", float) = 0
		_FlowlightEulerAngles("Flowlight Euler Angles", Vector) = (0,0,0,0)
		_FlowlightProjectionNormal ("Flowlight Projection Normal", Vector) = (1,0,0,1)
		_FlowlightLighten ("Flowlight Lighten?", Float) = 0 
		_FlowlightDarken ("Flowlight Darken?", Float) = 0
		_FlowlightRPM1 ("", Vector) = (1,0,0,0)
		_FlowlightRPM2 ("", Vector) = (0,1,0,0)
		_FlowlightRPM3 ("", Vector) = (0,0,1,0)

		_DissolveSampleSpace ("Dissolve Sample Space", float) = 0
		_DissolveCombinedTexture ("Dissolve Combined Texture", 2D) = "white"{}
		_DissolveCombinedWrapMode ("Dissolve wrap mode", Vector) = (11,11,0,0)
		_DissolveMask_ST ("Dissolve Mask Scale Offset", Vector) = (1,1,0,0)
		_DissolveMask_UV ("Dissolve Mask UV Animation", Vector) = (0,0,0,0)
		_DissolveTex_ST ("Dissolve Texture Scale Offset", Vector) = (1,1,0,0)
		_DissolveTex_UV ("Dissolve Texture UV Animation", Vector) = (0,0,0,0)
		_DissolveRange ("Dissolve Range", Range(0.01, 0.5)) = 0.25 
		_DissolveThreshold ("Dissolve Threshold", Range(0,1)) = 0.5 
		[HDR]_DissolveRangeCol ("Dissolve Range Color", Color) = (0,0,0,1)
		_DissolveEulerAngles ("Dissolve Euler Angles", Vector) = (0,0,0,0)
		_DissolveProjectionNormal ("Dissolve Projection Normal", Vector) = (1,0,0,1)
		_DissolveRPM1 ("", Vector) = (1,0,0,0)
		_DissolveRPM2 ("", Vector) = (0,1,0,0)
		_DissolveRPM3 ("", Vector) = (0,0,1,0)
		
		_OutlineColor ("Outline Color", Color) = (0,0,0,1)
		_OutlineScale ("Outline Scale", Range(0.1,2)) = 1
		_ScreenOutlineColor ("Screen Outline Color", Color) = (0,0,0,1)
		_ScreenOutlineScale ("Screem Outline Scale", Range(-1,2)) = 0
		_DepthOffset("Depth Offset", Range(-0.5,0.5)) = 0

	}

	CGINCLUDE 
		#include "UnityCG.cginc"
		#include "Assets/CGInclude/LGameCharacterDgs.cginc"

		fixed _AlphaCtrl;
		fixed _AlphaCtrlForArtist;

		fixed4 _MainTint;
		fixed4 _OffsetColor;
		sampler2D _MainTex; // RGBA
		half4 _MainTex_ST;

	#if _SUBTEX || _SUBTEX_DISSOLVE || _METAL
		sampler2D _SubtexMatcapCombinedTexture;
		uint4 _SubtexMatcapCombinedWrapMode;
	#endif

	#if _SUBTEX || _SUBTEX_DISSOLVE
		//sampler2D _SubTexMask; // _SubtexMatcapCombinedTexture.R
		half4 _SubTexMask_ST;
		half2 _SubTexMask_UV;
		fixed4 _SubTint;
		fixed4 _SubOffsetColor;
		fixed _SubTexLerp;
		sampler2D _SubTex; // RGB
		half4 _SubTex_ST;
	#endif

	#if _SUBTEX_DISSOLVE
		//sampler2D _SubDissolveTex; // _SubtexMatcapCombinedTexture.G
		half4 _SubDissolveTex_ST;
		half2 _SubDissolveTex_UV;
		fixed4 _SubDissolveColor;
		fixed _SubDissolveRange;
	#endif

	#if _METAL
		//sampler2D _MatCapMask; // _SubtexMatcapCombinedTexture.B
		half4 _MatCapMask_ST;
		half2 _MatCapMask_UV;
		sampler2D _MatCapTex; // RGB
		fixed4 _MatCapTint;
		half _MatCapRoughness;
		fixed _MatCapIntensity;
	#endif

	#if _RIMLIGHT || _RIMLIGHT_WORLD || _RIMLIGHT_NOISE || _FLOWLIGHT || _FLOWLIGHT_WORLD
		sampler2D _RimFlowCombinedTexture;
		uint4 _RimFlowCombinedWrapMode;
	#endif

	#if _RIMLIGHT || _RIMLIGHT_WORLD || _RIMLIGHT_NOISE
		//sampler2D _RimlightMask; // _RimFlowCombinedTexture.R
		half4 _RimlightMask_ST;
		half2 _RimlightMask_UV;
		fixed4 _RimlightColor;
		fixed _RimlightRange;
		fixed _RimlightIntensity;
		fixed _RimlightInverse;
		fixed _RimlightLighten;
		fixed _RimlightDarken;
	#endif

	#if _RIMLIGHT_NOISE
		fixed _RimlightNoiseSampleSpace;
	#endif

	#if _RIMLIGHT_WORLD || _RIMLIGHT_NOISE
		sampler2D _RimlightNoise; // _RimFlowCombinedTexture.G
		half4 _RimlightNoise_ST;
		half2 _RimlightNoise_UV;
	#endif

	#if _RIMLIGHT_WORLD
		half4 _RimlightProjectionNormal;
		half4 _RimlightRPM1;
		half4 _RimlightRPM2;
		half4 _RimlightRPM3;
	#endif

	#if _FLOWLIGHT
		fixed _FlowlightSampleSpace;
	#endif

	#if _FLOWLIGHT_WORLD || _FLOWLIGHT
		//sampler2D _FlowlightMask; // _RimFlowCombinedTexture.B
		half4 _FlowlightMask_ST;
		half2 _FlowlightMask_UV;
		fixed4 _FlowlightTint;
		fixed _FlowlightIntensity;
		sampler2D _FlowlightTex; // RGBA
		half4 _FlowlightTex_ST;
		half2 _FlowlightTex_UV;
		half _FlowlightLighten;
		half _FlowlightDarken;
	#endif

	#if _FLOWLIGHT_WORLD
		half4 _FlowlightProjectionNormal;
		half4 _FlowlightRPM1;
		half4 _FlowlightRPM2;
		half4 _FlowlightRPM3;
	#endif

	#if _DISSOLVE
		fixed _DissolveSampleSpace;
	#endif

	#if _DISSOLVE_WORLD || _DISSOLVE
		sampler2D _DissolveCombinedTexture;
		uint4 _DissolveCombinedWrapMode;
		//sampler2D _DissolveMask; // _DissolveCombinedTexture.R
		half4 _DissolveMask_ST;
		half2 _DissolveMask_UV;
		//sampler2D _DissolveTex; // _DissolveCombinedTexture.G
		half4 _DissolveTex_ST;
		half2 _DissolveTex_UV;
		fixed _DissolveRange;
		fixed _DissolveThreshold;
		fixed4 _DissolveRangeCol;
	#endif

	#if _DISSOLVE_WORLD
		half4 _DissolveProjectionNormal;
		half4 _DissolveRPM1;
		half4 _DissolveRPM2;
		half4 _DissolveRPM3;
	#endif

		fixed4 _OutlineColor;
		fixed _OutlineScale;
		fixed4 _ScreenOutlineColor;
		fixed _ScreenOutlineScale;
		half _DepthOffset;

		half4 _LightPos;
		fixed4 _ShadowColor;
		fixed4 _SoftShadowColor;

		inline fixed4 sampleMixedTexture(uint wrapMode, half2 uv, sampler2D mixedTexture)
		{
		#if _WRAPMODE_ON
			// wrapMode = 10*uMode + vMode, 0 = clamp, 1 = repeat, 2 = mirror
			// e.g. 00 -> clampUV, 21 -> mirrorU and repeatV
			uint wrapV = fmod(wrapMode, 10);
			uint wrapU = (wrapMode - wrapV) / 10;
			/*
				clamp -> saturate(uv) 
				repeat -> frac(uv) 
				mirror -> frac(abs(uv)) 
			*/
			half2 wrapUV = half2(
				saturate(uv.x) * (1 - saturate(wrapU)) + saturate(wrapU) * frac(abs(uv.x) * saturate(wrapU - 1) + uv.x * (1 - saturate(wrapU - 1))),
				saturate(uv.y) * (1 - saturate(wrapV)) + saturate(wrapV) * frac(abs(uv.y) * saturate(wrapV - 1) + uv.y * (1 - saturate(wrapV - 1)))
			);
			// Why tex2Dgrad? https://forum.unity.com/threads/strange-render-artifact-dotted-white-lines-along-quad-borders.795870/#post-5296011
			fixed4 sampled = tex2Dgrad(mixedTexture, wrapUV, ddx(uv), ddy(uv));
		#else
			fixed4 sampled = tex2D(mixedTexture, uv);
		#endif
			return sampled;
		}
	ENDCG

	SubShader
	{
		Pass 
		{
			Name "CharacterDefaultSrp"
			Tags { "LightMode"="CharacterDefaultSrp" }
			
			Blend [_SrcBlend] [_DstBlend]
			ZWrite [_ZWriteMode]
			ZTest [_ZTestMode]
			Cull [_CullMode]
			ColorMask [_ColorMask]
			Lighting Off 
			Fog { Mode Off }
			Stencil 
			{
				Ref[_Stencil]
				Comp[_StencilComp]
				Pass[_StencilOp]
				ReadMask [_ReadMask]
				WriteMask [_WriteMask]
			}

			CGPROGRAM
			#pragma multi_compile __ _SUBTEX _SUBTEX_DISSOLVE
			#pragma multi_compile __ _METAL
			#pragma multi_compile __ _RIMLIGHT _RIMLIGHT_WORLD _RIMLIGHT_NOISE
			#pragma multi_compile __ _FLOWLIGHT_WORLD _FLOWLIGHT
			#pragma multi_compile __ _DISSOLVE_WORLD _DISSOLVE
			#pragma multi_compile __ _WRAPMODE_ON
			#pragma multi_compile __ _USE_DIRECT_GPU_SKINNING
			#pragma vertex vert
			#pragma fragment frag

			struct a2v
			{
				float4 vertex : POSITION;
				half2 texcoord : TEXCOORD0;
			#if _USE_DIRECT_GPU_SKINNING
				float4 skinIndices : TEXCOORD2;
				float4 skinWeights : TEXCOORD3;
			#endif
			#if _METAL || _RIMLIGHT || _RIMLIGHT_WORLD || _RIMLIGHT_NOISE
				float3 normal : NORMAL;
			#endif
			};

			struct v2f 
			{
				float4 pos : SV_POSITION;
				half2 uv : TEXCOORD0;

			#if _SUBTEX || _SUBTEX_DISSOLVE
				half4 uvSubTex : TEXCOORD1; // xy: Mask, zw: Dissolve Tex 
			#endif

			#if _METAL
				half4 uvMatCap : TEXCOORD2;
			#endif

			#if _RIMLIGHT || _RIMLIGHT_WORLD || _RIMLIGHT_NOISE
				half fresnel : TEXCOORD3;
				half4 uvRimlight : TEXCOORD4; // xy: Mask, zw: Noise Tex 
			#endif

			#if _FLOWLIGHT_WORLD || _FLOWLIGHT
				half4 uvFlowlight : TEXCOORD5; // xy: Mask, zw: Flow Tex
			#endif

			#if _DISSOLVE_WORLD || _DISSOLVE
				half4 uvDissolve : TEXCOORD6;
			#endif
			};

			v2f vert(a2v i)
			{
				v2f o;
				UNITY_INITIALIZE_OUTPUT(v2f, o);

				float4 pos = i.vertex;

			#if _USE_DIRECT_GPU_SKINNING
				pos = CalculateGPUSkin_L(i.skinIndices, i.skinWeights, pos);
				i.texcoord = DecompressUV(i.texcoord, _uvBoundData);
			#endif

				float4 clipPos = UnityObjectToClipPos(pos);
				o.pos = clipPos;
				o.uv = i.texcoord * _MainTex_ST.xy + _MainTex_ST.zw + (1 - _MainTex_ST.xy) * 0.5;

			#if _METAL || _RIMLIGHT || _RIMLIGHT_WORLD || _RIMLIGHT_NOISE
				float3 worldNormal = UnityObjectToWorldNormal(i.normal);
			#endif
			#if _RIMLIGHT_WORLD || _FLOWLIGHT_WORLD || _DISSOLVE_WORLD
				float4 worldPos = mul(unity_ObjectToWorld, pos);
			#endif
			#if _RIMLIGHT_NOISE || _FLOWLIGHT || _DISSOLVE
				float4 screenPos = ComputeScreenPos(o.pos);
			#endif

			#if _SUBTEX || _SUBTEX_DISSOLVE
				o.uvSubTex.xy = i.texcoord * _SubTexMask_ST.xy + _SubTexMask_ST.zw + frac(_SubTexMask_UV.xy * _Time.y) + (1 - _SubTexMask_ST.xy) * 0.5;
			#endif
			#if _SUBTEX_DISSOLVE
				o.uvSubTex.zw = i.texcoord * _SubDissolveTex_ST.xy + _SubDissolveTex_ST.zw + frac(_SubDissolveTex_UV.xy * _Time.y) + (1 - _SubDissolveTex_ST.xy) * 0.5;
			#endif

			#if _METAL
				o.uvMatCap.xy = i.texcoord * _MatCapMask_ST.xy + _MatCapMask_ST.zw + frac(_MatCapMask_UV.xy * _Time.y) + (1 - _MatCapMask_ST.xy) * 0.5;
				o.uvMatCap.zw = normalize(mul(UNITY_MATRIX_V, worldNormal).xyz) * 0.5 + 0.5;
			#endif

			#if _RIMLIGHT || _RIMLIGHT_WORLD || _RIMLIGHT_NOISE
				fixed3 worldViewDir = normalize(WorldSpaceViewDir(pos));
				half fresnel = _RimlightInverse - (_RimlightInverse * 2 - 1) * abs(dot(worldViewDir, worldNormal));
				o.fresnel = pow(fresnel, _RimlightRange);
				o.uvRimlight.xy = i.texcoord * _RimlightMask_ST.xy + _RimlightMask_ST.zw + frac(_RimlightMask_UV.xy * _Time.y) + (1 - _RimlightMask_ST.xy) * 0.5;
			#endif

			#if _RIMLIGHT_WORLD
				half4x4 _RimlightInvWorldProjectionMatrix = half4x4(_RimlightRPM1, _RimlightRPM2, _RimlightRPM3, half4(0,0,0,1));
				float3 rimlightProjNormal = _RimlightProjectionNormal;
				float3 rimlightProjP = worldPos.xyz - dot(rimlightProjNormal, worldPos.xyz) * rimlightProjNormal; 
				o.uvRimlight.zw = (mul(_RimlightInvWorldProjectionMatrix, rimlightProjP).xz) * _RimlightNoise_ST.xy + _RimlightNoise_ST.zw + frac(_RimlightNoise_UV.xy * _Time.y) + (1 - _RimlightNoise_ST.xy) * 0.5;
			#endif

			#if _RIMLIGHT_NOISE
				if (_RimlightNoiseSampleSpace < 1)
				{
					o.uvRimlight.zw = i.texcoord * _RimlightNoise_ST.xy + _RimlightNoise_ST.zw + frac(_RimlightNoise_UV.xy * _Time.y) + (1 - _RimlightNoise_ST.xy) * 0.5;
				}
				else
				{
					o.uvRimlight.zw = (screenPos.xy / screenPos.w) * _RimlightNoise_ST.xy + _RimlightNoise_ST.zw + frac(_RimlightNoise_UV.xy * _Time.y) + (1 - _RimlightNoise_ST.xy) * 0.5;
				}
			#endif

			#if _FLOWLIGHT || _FLOWLIGHT_WORLD
				o.uvFlowlight.xy = i.texcoord * _FlowlightMask_ST.xy + _FlowlightMask_ST.zw + frac(_FlowlightMask_UV.xy * _Time.y) + (1 - _FlowlightMask_ST.xy) * 0.5;
			#endif
			#if _FLOWLIGHT_WORLD
				half4x4 _FlowlightInvWorldProjectionMatrix = half4x4(_FlowlightRPM1, _FlowlightRPM2, _FlowlightRPM3, half4(0,0,0,1));
				float3 flowlightProjNormal = _FlowlightProjectionNormal;
				float3 flowlightProjP = worldPos.xyz - dot(flowlightProjNormal, worldPos.xyz) * flowlightProjNormal;
		
				o.uvFlowlight.zw = (mul(_FlowlightInvWorldProjectionMatrix, flowlightProjP).xz) * _FlowlightTex_ST.xy
					+ _FlowlightTex_ST.zw + frac(_FlowlightTex_UV.xy * _Time.y) + (1 - _FlowlightTex_ST.xy) * 0.5;
			#endif

			#if _FLOWLIGHT
				if (_FlowlightSampleSpace < 1)
				{
					o.uvFlowlight.zw = i.texcoord * _FlowlightTex_ST.xy + _FlowlightTex_ST.zw + frac(_FlowlightTex_UV.xy * _Time.y) + (1 - _FlowlightTex_ST.xy) * 0.5;
				}
				else
				{
					o.uvFlowlight.zw = (screenPos.xy / screenPos.w) * _FlowlightTex_ST.xy + _FlowlightTex_ST.zw + frac(_FlowlightTex_UV.xy * _Time.y) + (1 - _FlowlightTex_ST.xy) * 0.5;
				}
			#endif

			#if _DISSOLVE || _DISSOLVE_WORLD
				o.uvDissolve.xy = i.texcoord * _DissolveMask_ST.xy + _DissolveMask_ST.zw + frac(_DissolveMask_UV.xy * _Time.y) + (1 - _DissolveMask_ST.xy) * 0.5;
			#endif
			#if _DISSOLVE_WORLD
				half4x4 _DissolveInvWorldProjectionMatrix = half4x4(_DissolveRPM1, _DissolveRPM2, _DissolveRPM3, half4(0,0,0,1));
				float3 dissolveProjNormal = _DissolveProjectionNormal;
				float3 dissolveProjP = worldPos.xyz - dot(dissolveProjNormal, worldPos.xyz) * dissolveProjNormal;
				o.uvDissolve.zw = (mul(_DissolveInvWorldProjectionMatrix, dissolveProjP).xz) * _DissolveTex_ST.xy 
					+ _DissolveTex_ST.zw + frac(_DissolveTex_UV.xy * _Time.y) + (1 - _DissolveTex_ST.xy) * 0.5;
			#endif

			#if _DISSOLVE
				if (_DissolveSampleSpace < 1)
				{
					o.uvDissolve.zw = i.texcoord * _DissolveTex_ST.xy + _DissolveTex_ST.zw + frac(_DissolveTex_UV.xy * _Time.y) + (1 - _DissolveTex_ST.xy) * 0.5;
				}
				else
				{
					o.uvDissolve.zw = (screenPos.xy / screenPos.w) * _DissolveTex_ST.xy + _DissolveTex_ST.zw + frac(_DissolveTex_UV.xy * _Time.y) + (1 - _DissolveTex_ST.xy) * 0.5;
				}
			#endif

			#if defined(UNITY_REVERSED_Z)
				o.pos.z += _DepthOffset;
			#else
				o.pos.z -= _DepthOffset;
			#endif

				return o;
			}

			fixed4 frag(v2f v) : SV_Target
			{
				fixed4 col = tex2D(_MainTex, v.uv) * _MainTint;
	
			#if _SUBTEX || _SUBTEX_DISSOLVE
				fixed subTexMask = sampleMixedTexture(_SubtexMatcapCombinedWrapMode.r, v.uvSubTex.xy, _SubtexMatcapCombinedTexture).r;
				fixed4 subCol = tex2D(_SubTex, v.uv) * _SubTint;
				subCol.rgb += _SubOffsetColor.rgb;
			#endif

			#if _SUBTEX
				col = lerp(col, subCol, _SubTexLerp * subTexMask);
			#endif

			#if _SUBTEX_DISSOLVE
				fixed subDissolveTex = sampleMixedTexture(_SubtexMatcapCombinedWrapMode.g, v.uvSubTex.zw, _SubtexMatcapCombinedTexture).g;
				fixed subDissolve = smoothstep(_SubTexLerp * 2 - 0.5 - _SubDissolveRange, _SubTexLerp * 2 - 0.5 + _SubDissolveRange, subDissolveTex);
				subCol = lerp(subCol, _SubDissolveColor, subDissolve * subTexMask);
				col.rgb = lerp(col.rgb, subCol.rgb, (1 - subDissolve) * subTexMask * _SubTint.a);
			#endif

			col.rgb *= col.a;

			#if _RIMLIGHT || _RIMLIGHT_WORLD || _RIMLIGHT_NOISE
				fixed rimlightMask = sampleMixedTexture(_RimFlowCombinedWrapMode.r, v.uvRimlight.xy, _RimFlowCombinedTexture).r;

				_RimlightColor.rgb = 
					lerp(
						lerp(col.rgb * (1 - _RimlightColor).a + _RimlightColor.rgb, col.rgb + _RimlightColor.rgb, _RimlightLighten)
																				  , col.rgb * _RimlightColor.rgb, _RimlightDarken);
				_RimlightColor.rgb *= _RimlightColor.a;

			  #if _RIMLIGHT_WORLD || _RIMLIGHT_NOISE
				fixed rimlightNoise = sampleMixedTexture(_RimFlowCombinedWrapMode.g, v.uvRimlight.zw, _RimFlowCombinedTexture).g;
				rimlightNoise = lerp(rimlightNoise, 1.0.rrr, v.fresnel);
				col = lerp(col, _RimlightColor, v.fresnel * rimlightMask * _RimlightIntensity * rimlightNoise);
			  #else
				col = lerp(col, _RimlightColor, v.fresnel * _RimlightIntensity * rimlightMask);
			  #endif
			#endif

			#if _FLOWLIGHT_WORLD || _FLOWLIGHT
				fixed flowlightMask = sampleMixedTexture(_RimFlowCombinedWrapMode.b, v.uvFlowlight.xy, _RimFlowCombinedTexture).b;
				fixed4 flowlightCol = tex2D(_FlowlightTex, v.uvFlowlight.zw) * _FlowlightTint;
				flowlightCol.rgb = 
					lerp(
						lerp(col.rgb * (1 - flowlightCol).a + flowlightCol.rgb, col.rgb + flowlightCol.rgb, _FlowlightLighten)
																				  , col.rgb * flowlightCol.rgb, _FlowlightDarken);
				col = lerp(col, flowlightCol, flowlightCol.a * _FlowlightIntensity * flowlightMask);
			#endif

			#if _METAL
				fixed matCapMask = sampleMixedTexture(_SubtexMatcapCombinedWrapMode.b, v.uvMatCap.xy, _SubtexMatcapCombinedTexture).b;
				half perceptual_roughness = 1 - _MatCapRoughness;
				half mip = perceptual_roughness * (12.2 - 4.2 * perceptual_roughness);
				fixed4 matCapCol = tex2Dlod(_MatCapTex, half4(v.uvMatCap.zw, 0, mip)) * _MatCapTint;
				matCapCol.rgb = lerp(0.3.rrr, matCapCol.rgb, _MatCapIntensity);
				col.rgb += (matCapCol.rgb * 2 - 0.6) * matCapMask * _MatCapTint.a * col.a;
			#endif

			#if _DISSOLVE_WORLD || _DISSOLVE
				fixed dissolveMask = sampleMixedTexture(_DissolveCombinedWrapMode.r, v.uvDissolve.xy, _DissolveCombinedTexture).r;
				fixed dissolveTex = sampleMixedTexture(_DissolveCombinedWrapMode.g, v.uvDissolve.zw, _DissolveCombinedTexture).g;
				fixed dissolve = smoothstep(_DissolveThreshold * 2 - 0.5 - _DissolveRange, _DissolveThreshold * 2 - 0.5 + _DissolveRange, dissolveTex);
				fixed4 cachedColor = col;
				col.rgb = lerp(_DissolveRangeCol.rgb, col.rgb, dissolve);
				col = lerp(cachedColor, col*dissolve, dissolveMask);
			#endif
	
				col.rgb += _OffsetColor.rgb;
				col *= _AlphaCtrl * _AlphaCtrlForArtist;

				return col;
			}

			ENDCG
		}

		Pass 
		{
			Name "CharacterOutlineSrp"
			Tags { "LightMode"="CharacterOutlineSrp" "RenderType"="AlphaTest" "Queue"="AlphaTest" }
			Stencil
			{
				Ref 2
				Comp NotEqual
				Pass Replace 
			}
			Blend SrcAlpha OneMinusSrcAlpha 
			Offset 1,1 
			Cull Front 
			ZWrite Off 

			CGPROGRAM 
			#pragma multi_compile __ _DISSOLVE_WORLD _DISSOLVE
			#pragma multi_compile __ _USE_DIRECT_GPU_SKINNING

			#pragma vertex vert_outline
			#pragma fragment frag_outline 
			struct a2v
			{
				float4 vertex : POSITION;
				half2 texcoord : TEXCOORD0;
				float3 normal : NORMAL;
			#if _USE_DIRECT_GPU_SKINNING
				half4 tangent : TANGENT;
				float4 skinIndices : TEXCOORD2;
				float4 skinWeights : TEXCOORD3;
			#endif
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
				half2 uv : TEXCOORD0;
			#if _DISSOLVE_WORLD || _DISSOLVE
				half4 uvDissolve : TEXCOORD1;
			#endif
			};

			v2f vert_outline(a2v v) 
			{
				v2f o;
				UNITY_INITIALIZE_OUTPUT(v2f, o);

				float4 pos = v.vertex;
				float3 normal;

			#if _USE_DIRECT_GPU_SKINNING
				float4 tangent;
				float3 binormal;
				DecompressTangentNormal(v.tangent, tangent, normal, binormal);
				pos = CalculateGPUSkin(v.skinIndices, v.skinWeights, pos, tangent, normal, binormal);
				v.texcoord = DecompressUV(v.texcoord, _uvBoundData);
			#else
				normal = v.normal;
			#endif

				float4 outlinePos = pos + float4(normal, 0) * _OutlineScale * 0.03;
				o.pos = UnityObjectToClipPos(outlinePos);

				o.uv = v.texcoord;

			#if _DISSOLVE || _DISSOLVE_WORLD
				o.uvDissolve.xy = v.texcoord * _DissolveMask_ST.xy + _DissolveMask_ST.zw + frac(_DissolveMask_UV.xy * _Time.y) + (1 - _DissolveMask_ST.xy) * 0.5;
			#endif
			#if _DISSOLVE_WORLD
				half4x4 _DissolveInvWorldProjectionMatrix = half4x4(_DissolveRPM1, _DissolveRPM2, _DissolveRPM3, half4(0,0,0,1));
				float4 worldPos = mul(unity_ObjectToWorld, outlinePos);
				float3 dissolveProjNormal = _DissolveProjectionNormal;
				float3 dissolveProjP = worldPos.xyz - dot(dissolveProjNormal, worldPos.xyz) * dissolveProjNormal;
				o.uvDissolve.zw = (mul(_DissolveInvWorldProjectionMatrix, dissolveProjP).xz) * _DissolveTex_ST.xy 
					+ _DissolveTex_ST.zw + frac(_DissolveTex_UV.xy * _Time.y) + (1 - _DissolveTex_ST.xy) * 0.5;
			#endif

			#if _DISSOLVE
				if (_DissolveSampleSpace == 0)
				{
					o.uvDissolve.zw = v.texcoord * _DissolveTex_ST.xy + _DissolveTex_ST.zw + frac(_DissolveTex_UV.xy * _Time.y);
				}
				else
				{
					float4 screenPos = ComputeScreenPos(o.pos);
					o.uvDissolve.zw = (screenPos.xy / screenPos.w) * _DissolveTex_ST.xy + _DissolveTex_ST.zw + frac(_DissolveTex_UV.xy * _Time.y);
				}
			#endif

			#if defined(UNITY_REVERSED_Z)
				o.pos.z += _DepthOffset;
			#else
				o.pos.z -= _DepthOffset;
			#endif
		
				return o;
			}

			fixed4 frag_outline(v2f i) : SV_Target
			{
				fixed4 col = _OutlineColor;

			#if _DISSOLVE_WORLD || _DISSOLVE
				fixed dissolveMask = sampleMixedTexture(_DissolveCombinedWrapMode.r, i.uvDissolve.xy, _DissolveCombinedTexture).r;
				fixed dissolveTex = sampleMixedTexture(_DissolveCombinedWrapMode.g, i.uvDissolve.zw, _DissolveCombinedTexture).g;
				fixed dissolve = smoothstep(_DissolveThreshold * 2 - 0.5 - _DissolveRange, _DissolveThreshold * 2 - 0.5 + _DissolveRange, dissolveTex);
				col.a = lerp(col.a, col.a * dissolve, dissolveMask);
			#endif

				fixed mainAlpha = tex2D(_MainTex, i.uv).a * _MainTint.a;
				col.a *= mainAlpha;

				col.a *= 0.5;
				col.a *= _AlphaCtrl * _AlphaCtrlForArtist;

				return col;
			}
			ENDCG
		}

		Pass 
		{
			Name "CharacterScreenOutlineSrp"
			Tags { "LightMode"="CharacterScreenOutlineSrp" "RenderType"="AlphaTest" "Queue"="AlphaTest" }
			Stencil 
			{
				Ref 3
				Comp Greater
				Pass Replace
			}
			Blend SrcAlpha OneMinusSrcAlpha 
			Offset 1,1
			Cull Front 
			ZWrite Off 

			CGPROGRAM
			#pragma multi_compile __ _DISSOLVE_WORLD _DISSOLVE
			#pragma multi_compile __ _USE_DIRECT_GPU_SKINNING

			#pragma vertex vert_screenOutline
			#pragma fragment frag_screenOutline
			struct a2v
			{
				float4 vertex : POSITION;
				half2 texcoord : TEXCOORD0;
				float3 normal : NORMAL;
			#if _USE_DIRECT_GPU_SKINNING
				half4 tangent : TANGENT;
				float4 skinIndices : TEXCOORD2;
				float4 skinWeights : TEXCOORD3;
			#endif
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
				half2 uv : TEXCOORD0;
			#if _DISSOLVE_WORLD || _DISSOLVE
				half4 uvDissolve : TEXCOORD1;
			#endif
			};

			v2f vert_screenOutline(a2v v)
			{
				v2f o;
				UNITY_INITIALIZE_OUTPUT(v2f, o);

				if (_ScreenOutlineScale <= 0.001)
				{
					o.pos = float4(0.0, 0.0, 0.0, 0.0);
					o.uv = half2(0.0, 0.0);
				#if _DISSOLVE_WORLD || _DISSOLVE
					o.uvDissolve = half4(0.0, 0.0, 0.0, 0.0);
				#endif
				}
				else 
				{
					float4 pos = v.vertex;
					float3 normal;

				#if _USE_DIRECT_GPU_SKINNING
					float4 tangent;
					float3 binormal;
					DecompressTangentNormal(v.tangent, tangent, normal, binormal);
					pos = CalculateGPUSkin(v.skinIndices, v.skinWeights, pos, tangent, normal, binormal);
					v.texcoord = DecompressUV(v.texcoord, _uvBoundData);
				#else
					normal = v.normal;
				#endif

					float4 outlinePos = pos + float4(normal, 0) * _ScreenOutlineScale * 0.043;
					o.pos = UnityObjectToClipPos(outlinePos);

					o.uv = v.texcoord;

				#if _DISSOLVE || _DISSOLVE_WORLD
					o.uvDissolve.xy = v.texcoord * _DissolveMask_ST.xy + _DissolveMask_ST.zw + frac(_DissolveMask_UV.xy * _Time.y) + (1 - _DissolveMask_ST.xy) * 0.5;
				#endif
				#if _DISSOLVE_WORLD
					half4x4 _DissolveInvWorldProjectionMatrix = half4x4(_DissolveRPM1, _DissolveRPM2, _DissolveRPM3, half4(0,0,0,1));
					float4 worldPos = mul(unity_ObjectToWorld, outlinePos);
					float3 dissolveProjNormal = _DissolveProjectionNormal;
					float3 dissolveProjP = worldPos.xyz - dot(dissolveProjNormal, worldPos.xyz) * dissolveProjNormal;
					o.uvDissolve.zw = (mul(_DissolveInvWorldProjectionMatrix, dissolveProjP).xz) * _DissolveTex_ST.xy + _DissolveTex_ST.zw + frac(_DissolveTex_UV.xy * _Time.y);
				#endif

				#if _DISSOLVE
					if (_DissolveSampleSpace < 1)
					{
						o.uvDissolve.zw = v.texcoord * _DissolveTex_ST.xy + _DissolveTex_ST.zw + frac(_DissolveTex_UV.xy * _Time.y);
					}
					else
					{
						float4 screenPos = ComputeScreenPos(o.pos);
						o.uvDissolve.zw = (screenPos.xy / screenPos.w) * _DissolveTex_ST.xy + _DissolveTex_ST.zw + frac(_DissolveTex_UV.xy * _Time.y);
					}
				#endif

				#if defined(UNITY_REVERSED_Z)
					o.pos.z += _DepthOffset;
				#else
					o.pos.z -= _DepthOffset;
				#endif
				}

				return o;
			}

			fixed4 frag_screenOutline(v2f i) : SV_Target
			{
				fixed4 col = _ScreenOutlineColor;

			#if _DISSOLVE_WORLD || _DISSOLVE
				fixed dissolveMask = sampleMixedTexture(_DissolveCombinedWrapMode.r, i.uvDissolve.xy, _DissolveCombinedTexture).r;
				fixed dissolveTex = sampleMixedTexture(_DissolveCombinedWrapMode.g, i.uvDissolve.zw, _DissolveCombinedTexture).g;
				fixed dissolve = smoothstep(_DissolveThreshold * 2 - 0.5 - _DissolveRange, _DissolveThreshold * 2 - 0.5 + _DissolveRange, dissolveTex);
				col.a = lerp(col.a, col.a * dissolve, dissolveMask);
			#endif

				fixed mainAlpha = tex2D(_MainTex, i.uv).a * _MainTint.a;
				col.a *= mainAlpha;

				col.a *= (0.5 * _ScreenOutlineScale);
				col.a *= _AlphaCtrl * _AlphaCtrlForArtist;

				return col;
			}

			ENDCG
		}

		Pass
		{
			Name "CharacterShadowSrp"
			Tags { "LightMode"="CharacterShadowSrp" "Queue"="AlphaTest" "RenderType"="AlphaTest" }
			Stencil
			{
				Ref 1
				Comp NotEqual
				Pass Replace
			}
			Blend DstColor Zero
			ZWrite off
			Offset -1, 0

			CGPROGRAM
			#pragma multi_compile __ _DISSOLVE _DISSOLVE_WORLD
			#pragma multi_compile __ _USE_DIRECT_GPU_SKINNING

			#pragma vertex vert_shadow
			#pragma fragment frag_hardShadow
			struct a2v
			{
				float4 vertex : POSITION;
				half2 texcoord : TEXCOORD0;
			#if _USE_DIRECT_GPU_SKINNING
				float4 skinIndices : TEXCOORD2;
				float4 skinWeights : TEXCOORD3;
			#endif
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
				half2 uv : TEXCOORD0;
			#if _DISSOLVE_WORLD || _DISSOLVE
				half4 uvDissolve : TEXCOORD1;
			#endif
				fixed4 color : COLOR;
				float4 shadowMask : TEXCOORD2;
			};

			v2f vert_shadow(a2v v)
			{
				v2f o;
				UNITY_INITIALIZE_OUTPUT(v2f, o);
				float4 pos = v.vertex;

			#if _USE_DIRECT_GPU_SKINNING
				pos = CalculateGPUSkin_L(v.skinIndices, v.skinWeights, v.vertex);
			  #if _DISSOLVE_UV
				v.texcoord = DecompressUV(v.texcoord, _uvBoundData);
			  #endif
			#endif

			float4 worldPos = mul(unity_ObjectToWorld, pos);

			#if _DISSOLVE || _DISSOLVE_WORLD 
				o.uvDissolve.xy = v.texcoord * _DissolveMask_ST.xy + _DissolveMask_ST.zw + frac(_DissolveMask_UV.xy * _Time.y) + (1 - _DissolveMask_ST.xy) * 0.5;
			#endif
			#if _DISSOLVE_WORLD
				half4x4 _DissolveInvWorldProjectionMatrix = half4x4(_DissolveRPM1, _DissolveRPM2, _DissolveRPM3, half4(0,0,0,1));
				float3 dissolveProjNormal = _DissolveProjectionNormal;
				float3 dissolveProjP = worldPos.xyz - dot(dissolveProjNormal, worldPos.xyz) * dissolveProjNormal;
				o.uvDissolve.zw = (mul(_DissolveInvWorldProjectionMatrix, dissolveProjP).xz) * _DissolveTex_ST.xy + _DissolveTex_ST.zw + frac(_DissolveTex_UV.xy * _Time.y);
			#endif

			#if _DISSOLVE
				if (_DissolveSampleSpace < 1)
				{
					o.uvDissolve.zw = v.texcoord * _DissolveTex_ST.xy + _DissolveTex_ST.zw + frac(_DissolveTex_UV.xy * _Time.y);
				}
				else
				{
					float4 screenPos = ComputeScreenPos(pos);
					o.uvDissolve.zw = (screenPos.xy / screenPos.w) * _DissolveTex_ST.xy + _DissolveTex_ST.zw + frac(_DissolveTex_UV.xy * _Time.y);
				}
			#endif

				o.shadowMask = float4(step(_LightPos.w, worldPos.y), 1,1,1);

				fixed3 lightDir = normalize(_LightPos.xyz);
		
				float3 shadowPos;
				shadowPos.y = min(worldPos.y, _LightPos.w);
				shadowPos.xz = worldPos.xz - lightDir.xz * max(0, worldPos.y - _LightPos.w) / lightDir.y;

				o.pos = UnityWorldToClipPos(shadowPos);
				o.uv = v.texcoord;

				o.color.a = _ShadowColor.a * _MainTint.a;
				o.color.a *= _AlphaCtrl * _AlphaCtrlForArtist;

				return o;
			}

			fixed4 frag_hardShadow(v2f i) : SV_Target
			{
				fixed4 col = i.color.a * tex2D(_MainTex, i.uv).a;
			#if _DISSOLVE_WORLD || _DISSOLVE
				fixed dissolveMask = sampleMixedTexture(_DissolveCombinedWrapMode.r, i.uvDissolve.xy, _DissolveCombinedTexture).r;
				fixed dissolveTex = sampleMixedTexture(_DissolveCombinedWrapMode.g, i.uvDissolve.zw, _DissolveCombinedTexture).g;
				fixed dissolve = smoothstep(_DissolveThreshold * 2 - 0.5 - _DissolveRange, _DissolveThreshold * 2 - 0.5 + _DissolveRange, dissolveTex);
				col = lerp(col, col * dissolve, dissolveMask);
			#endif
				col.rgb = lerp(half3(1,1,1), col.rgb, col.a);
				return col;
			}
			ENDCG
		}

		Pass 
		{
			Name "CharacterSoftShadowSrp"
			Tags { "LightMode"="ShadowPrepass" "Queue"="AlphaTest" "RenderType"="AlphaTest" }

			CGPROGRAM 
			#pragma multi_compile __ _DISSOLVE _DISSOLVE_WORLD
			#pragma multi_compile __ _USE_DIRECT_GPU_SKINNING

			#pragma vertex vert_shadow
			#pragma fragment frag_softShadow
			struct a2v
			{
				float4 vertex : POSITION;
				half2 texcoord : TEXCOORD0;
			#if _USE_DIRECT_GPU_SKINNING
				float4 skinIndices : TEXCOORD2;
				float4 skinWeights : TEXCOORD3;
			#endif
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
				half2 uv : TEXCOORD0;
			#if _DISSOLVE_WORLD || _DISSOLVE
				half4 uvDissolve : TEXCOORD1;
			#endif
				fixed4 color : COLOR;
				float4 shadowMask : TEXCOORD2;
			};

			v2f vert_shadow(a2v v)
			{
				v2f o;
				UNITY_INITIALIZE_OUTPUT(v2f, o);
				float4 pos = v.vertex;

			#if _USE_DIRECT_GPU_SKINNING
				pos = CalculateGPUSkin_L(v.skinIndices, v.skinWeights, v.vertex);
			  #if _DISSOLVE_UV
				v.texcoord = DecompressUV(v.texcoord, _uvBoundData);
			  #endif
			#endif

			float4 worldPos = mul(unity_ObjectToWorld, pos);

			#if _DISSOLVE || _DISSOLVE_WORLD 
				o.uvDissolve.xy = v.texcoord * _DissolveMask_ST.xy + _DissolveMask_ST.zw + frac(_DissolveMask_UV.xy * _Time.y) + (1 - _DissolveMask_ST.xy) * 0.5;
			#endif
			#if _DISSOLVE_WORLD
				half4x4 _DissolveInvWorldProjectionMatrix = half4x4(_DissolveRPM1, _DissolveRPM2, _DissolveRPM3, half4(0,0,0,1));
				float3 dissolveProjNormal = _DissolveProjectionNormal;
				float3 dissolveProjP = worldPos.xyz - dot(dissolveProjNormal, worldPos.xyz) * dissolveProjNormal;
				o.uvDissolve.zw = (mul(_DissolveInvWorldProjectionMatrix, dissolveProjP).xz) * _DissolveTex_ST.xy + _DissolveTex_ST.zw + frac(_DissolveTex_UV.xy * _Time.y);
			#endif

			#if _DISSOLVE
				if (_DissolveSampleSpace < 1)
				{
					o.uvDissolve.zw = v.texcoord * _DissolveTex_ST.xy + _DissolveTex_ST.zw + frac(_DissolveTex_UV.xy * _Time.y);
				}
				else
				{
					float4 screenPos = ComputeScreenPos(pos);
					o.uvDissolve.zw = (screenPos.xy / screenPos.w) * _DissolveTex_ST.xy + _DissolveTex_ST.zw + frac(_DissolveTex_UV.xy * _Time.y);
				}
			#endif

				o.shadowMask = float4(step(_LightPos.w, worldPos.y), 1,1,1);

				fixed3 lightDir = normalize(_LightPos.xyz);
		
				float3 shadowPos;
				shadowPos.y = min(worldPos.y, _LightPos.w);
				shadowPos.xz = worldPos.xz - lightDir.xz * max(0, worldPos.y - _LightPos.w) / lightDir.y;

				o.pos = UnityWorldToClipPos(shadowPos);
				o.uv = v.texcoord;

				o.color.a = _ShadowColor.a * _MainTint.a;
				o.color.a *= _AlphaCtrl * _AlphaCtrlForArtist;

				return o;
			}

			fixed4 frag_softShadow(v2f i) : SV_Target
			{
				fixed4 col = tex2D(_MainTex, i.uv).a * _SoftShadowColor.a * i.shadowMask.r * _MainTint.a * i.color.a;
			#if _DISSOLVE_WORLD || _DISSOLVE
				fixed dissolveMask = sampleMixedTexture(_DissolveCombinedWrapMode.r, i.uvDissolve.xy, _DissolveCombinedTexture).r;
				fixed dissolveTex = sampleMixedTexture(_DissolveCombinedWrapMode.g, i.uvDissolve.zw, _DissolveCombinedTexture).g;
				fixed dissolve = smoothstep(_DissolveThreshold * 2 - 0.5 - _DissolveRange, _DissolveThreshold * 2 - 0.5 + _DissolveRange, dissolveTex);
				col = lerp(col, col * dissolve, dissolveMask);
			#endif
				return fixed4(0.0f, col.yzw);
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

			struct a2v
			{
				float4 vertex	: POSITION;
				half4 uv		: TEXCOORD0;
			};
			struct v2f
			{
				float4 pos		: SV_POSITION;
				float4 uvMain	: TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			v2f vert(a2v i)
            {
				v2f o;
				o.pos = UnityObjectToClipPos(i.vertex);
				o.uvMain = i.uv;
				return o;
			}

			half4 fragtest(v2f i) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID(i);

				fixed4 texColor = tex2D(_MainTex, i.uvMain.xy, float2(0, 0), float2(0, 0));

				return half4(0.15,0.06,0.03, texColor.a < 0.001);
			}
			ENDCG
		}
	}

	CustomEditor"LGameSDK.AnimTool.LGameChampionGUI"
}
