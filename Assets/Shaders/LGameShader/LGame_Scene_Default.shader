Shader "LGame/Scene/Default"
{
    Properties
    {
		[HideInInspector] _Mode ("__mode", Float) = 0.0
        [HideInInspector] _SrcBlend ("__src", Float) = 1.0
        [HideInInspector] _DstBlend ("__dst", Float) = 0.0
        [HideInInspector] _ZWrite ("__zw", Float) = 1.0

		_Color("Color", Color) = (1,1,1,1)
        _MainTex ("Texture", 2D) = "white" {}
		_LightMap ("LightMap", 2D) = "gray" {}
		_LightMapIntensity("LightMap Intensity",  Range(0,1)) = 1
		_AbientCol("Anbient Color" , Color) = (0,0,0,0)
		_Cutoff("Cutoff" , Range(0,1)) = 0.5
		_MaskColor("MaskColor", Color) = (1,0,0,1)
		_DissolveThreshold("CutoffHigh" , Range(-3,3)) = -3
		_MoveNoise("MoveNoise" , Range(0,1)) = 0
		_NoiseRate("NoiseRate", Range(0,3)) = 0
		[Toggle] _IsDissolveSecond ("Is DissolveSecond?", Int) = 0  // 溶解世界反向（比如铁男大招  半径内半径外通过该参数取反 或者两个效果溶解切换的表现）
    	
		_StencilComp("Stencil Comparison", Float) = 5
		_Stencil("Stencil ID", Float) = 3
		_StencilOp("Stencil Operation", Float) = 1
		[HideInInspector] _StencilWriteMask("Stencil Write Mask", Float) = 255
		[HideInInspector] _StencilReadMask("Stencil Read Mask", Float) = 255

		[Toggle] _RECEIVE ("Receive Shadow?", Float) = 0		
		[SimpleToggle] _EnableLDR("Enable LDR", Float) = 0
		[Enum(VRSDefault,0,VRS1x1,1,VRS1x2,2,VRS2x1,3,VRS2x2,4,VRS4x2,5,VRS4x4,6)] _ShadingRate("Fragment Shading Rate", Float) = 0
    }

	CGINCLUDE
		#define LGAME_DISSOLVE_WORLD
		#include "UnityCG.cginc"
		#include "Assets/CGInclude/LGameCharacterDgs.cginc"
		#include "Assets/CGInclude/LGameFog.cginc"
		#include "Assets/CGInclude/LGameDissolveWorld.cginc"

		struct appdata
		{
			float4 vertex	: POSITION;
			float2 uv		: TEXCOORD0;
			float2 uv2		: TEXCOORD1;
#ifdef _USE_DIRECT_GPU_SKINNING
			float4 skinIndices : TEXCOORD2;
			float4 skinWeights : TEXCOORD3;
#endif
		};

		struct v2f
		{
			fixed4 color : COLOR;
			float4 vertex	: SV_POSITION;
			float2 uv		: TEXCOORD0;
			float2 uv2		: TEXCOORD1;
#if _FOW_ON || _FOW_ON_CUSTOM
			half2 fowuv		: TEXCOORD2;
#endif
//#if (_SOFTSHADOW_ON && _RECEIVE_ON)
#if _SOFTSHADOW_ON
			half4 srcPos	: TEXCOORD3;
#endif
#if _ALPHACLIP_ON || _MOVENOISE_ON || _FOW_ON || _FOW_ON_CUSTOM
			float4 posWorld	: TEXCOORD4;
#endif
			DECLARE_FOG_V2F(5)
		};

		fixed4		_Color;
		sampler2D	_MainTex;
		float4		_MainTex_ST;

		half		_Brightness;

#if _MOVENOISE_ON
		float		_NoiseRate;
		half		_MoveNoise;
#endif
#if _ALPHACLIP_ON
		half		 _Cutoff;
		half		_DissolveThreshold;
		half4		_MaskColor;
#endif
#if _HIGHFOG_ON
		fixed4		_HighFogCol;
		half		_HighFogOffset;
		half		_HighFogRange;
#endif
#if _LIGHTMAP_ON
		sampler2D		_LightMap;
		fixed4			_AbientCol;
		half			_LightMapIntensity;
		half			_EnableLDR;
#endif
//#if (_SOFTSHADOW_ON && _RECEIVE_ON)
#if _SOFTSHADOW_ON
		fixed4 _SoftShadowColor;
		sampler2D _Temp1	;
#endif
		//half _SceneDepthOffset;

		v2f vert(appdata v)
		{
			v2f o;
#if _USE_DIRECT_GPU_SKINNING
			v.vertex = CalculateGPUSkin_L(v.skinIndices, v.skinWeights, v.vertex);
			v.uv.xy = DecompressUV(v.uv.xy, _uvBoundData);
#endif

			float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
#if _MOVENOISE_ON
			worldPos.xz += sin(float2(worldPos.zx - worldPos.yy) + _Time.y * _NoiseRate) * clamp(0, 1, worldPos.y * worldPos.y * 0.1) * _MoveNoise;
#endif
			o.vertex = UnityWorldToClipPos(worldPos.xyz);
#if _ALPHACLIP_ON

			float y = clamp(-5, 5, worldPos.y  * 0.1+2);
			o.posWorld = float4(y.xxxx);
#endif
			o.worldPos = worldPos;
			
			o.uv = TRANSFORM_TEX(v.uv, _MainTex);
			o.uv2 = v.uv2;
#if _FOW_ON || _FOW_ON_CUSTOM
			o.fowuv = half2 ((worldPos.x - _FOWParam.x) / _FOWParam.z, (worldPos.z - _FOWParam.y) / _FOWParam.w);
#endif
			o.color = saturate(worldPos.y * 2);
#if _HIGHFOG_ON
			o.color.rgb = saturate((worldPos.y - _HighFogOffset) * _HighFogRange) * _HighFogCol.a;
#endif

//#if (_SOFTSHADOW_ON && _RECEIVE_ON)
#if _SOFTSHADOW_ON
			o.srcPos = ComputeScreenPos(o.vertex);
#endif

			return o;
		}

	ENDCG

    SubShader
    {
        Tags { "RenderType"="Opaque"  "RenderType"="AlphaTest" }
		// ShadingRate[_ShadingRate]
        LOD 100

        Pass
        {
            Name "FORWARD"
            Tags { "LightMode" = "ForwardBase" }
			BlendOp [_BlendOp]
            Blend [_SrcBlend] [_DstBlend]
            ZWrite [_ZWrite]
			//Cull Off
			Stencil
			{
				Ref 3
				Comp Greater
				Pass Zero
				ReadMask[_StencilReadMask]
				WriteMask[_StencilWriteMask]
			}
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
#pragma multi_compile __ _FOW_ON _FOW_ON_CUSTOM
#pragma multi_compile __ _SOFTSHADOW_ON
//#pragma shader_feature _RECEIVE_ON
#pragma shader_feature _ALPHACLIP_ON
#pragma shader_feature _MOVENOISE_ON
#pragma shader_feature _LIGHTMAP_ON
#pragma multi_compile __ _USE_DIRECT_GPU_SKINNING
// Disabled by Shader Kit#pragma shader_feature _HIGHFOG_ON
#pragma multi_compile __ _ENABLE_DISSOLVE_WORLD

            #include "UnityCG.cginc"

            fixed4 frag (v2f i) : SV_Target
            {

                fixed4 col = tex2D(_MainTex, i.uv) * _Color;

				#if _ALPHACLIP_ON
					float ClipMask = smoothstep(_DissolveThreshold, _DissolveThreshold + 0.05, i.posWorld.y) ;
					//float VeryLowFix = clamp(0,1,step(-2.0, i.posWorld.x) + ClipMask);
					col.xyz += (1-ClipMask) * _MaskColor.rgb* _MaskColor.a*2;
					//col.xyz = ClipMask.xxx;
					//float y = smoothstep(_CutoffHigh, _CutoffHigh + 0.05, clamp(-5, 5, worldPos.y * 0.1));

					clip(col.a* ClipMask - _Cutoff);
				#endif

            	// Apply Fog
            	#if _FOW_ON || _FOW_ON_CUSTOM
					LGameFogApply(col, i.worldPos.xyz, i.fowuv);
            	#endif

				#if _LIGHTMAP_ON
					fixed3 lightMap = tex2D(_LightMap, i.uv2);
					col.rgb = col.rgb + (lightMap * 2.0 - 1.0) * (1.0 - _EnableLDR) * _LightMapIntensity;
					col.rgb = col.rgb * lerp(1.0.rrr, lightMap * 2.0, _EnableLDR * _LightMapIntensity);
					col.rgb *= 1.0 + _AbientCol;
				#endif
				#if _HIGHFOG_ON
					col.rgb = lerp(col.rgb , _HighFogCol.rgb , i.color.rgb);	
				#endif


				col.rgb *= 1.0 + _Brightness;
				col.a *= i.color.a;

            	// Apply Dissolve World
            	LGameApplyDissolveWorld(col, i.worldPos.xyz);
            	
				//#if (_SOFTSHADOW_ON && _RECEIVE_ON)
				#if _SOFTSHADOW_ON
					half shadowMask = float3(1, 1, 1) - i.color.rrr;
					half shadow = tex2D(_Temp1 ,i.srcPos.xy/ i.srcPos.w).b* shadowMask;
					col.rgb =lerp(col.rgb , _SoftShadowColor.rgb,shadow);
				#endif
                return col ;
            }
            ENDCG
        }

    }

	SubShader 
	{ 
		Tags { "Queue" = "Geometry" "RenderType"="Opaque" }
		LOD 10

		Pass
		{
			Name "FORWARD"
			Tags { "LightMode" = "ForwardBase" }
			Fog { Mode Off }

			CGPROGRAM
			#include "Assets/CGInclude/RenderDebugCG.cginc"
			#pragma multi_compile __ _USE_DIRECT_GPU_SKINNING
			#pragma vertex vert
			#pragma fragment frag_mipmap  

			fixed4 frag_mipmap(v2f i) : SV_Target 
			{
				fixed3 c = 0;
				fixed4 tex = tex2D(_MainTex, i.uv);
				c = tex.rgb;

				return GetMipmapsLevelColor(c,i.uv);
			}
			
			ENDCG
		}
	}

	SubShader 
	{ 
		Tags { "Queue" = "Geometry" "RenderType"="Opaque" }
		LOD 5
		Blend One One

		Pass
		{
			Name "FORWARD"
			Tags { "LightMode" = "ForwardBase" }
			Fog { Mode Off }

			CGPROGRAM
			#pragma multi_compile __ _USE_DIRECT_GPU_SKINNING

			#pragma vertex vert
			#pragma fragment frag  

			// fragment shader
			fixed4 frag (v2f i) : SV_Target 
			{
				return fixed4(0.15, 0.06, 0.03, 0);
			}
			
			ENDCG
		}
	}
	

	CustomEditor"LGameScenceDefaultGUI"
}
