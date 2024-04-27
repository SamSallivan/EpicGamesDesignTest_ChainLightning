Shader "PhotonShader/Effect/Skill Indicator"
{
    Properties
	{
		[HideInInspector]_AlphaCtrl("AlphaCtrl",range(0,1)) = 1
		[HideInInspector][Enum(UnityEngine.Rendering.BlendMode)] 		_SrcFactor ("SrcFactor()", Float) = 5
		[HideInInspector][Enum(UnityEngine.Rendering.BlendMode)] 		_DstFactor ("DstFactor()", Float) = 10
		[Enum(UnityEngine.Rendering.CullMode)] 							_CullMode ("消隐模式(CullMode)", int) = 0
        [Enum(RGB,14,ALL,15, NONE,0)]									_ColorMask ("颜色遮罩(ColorMask)", int) = 15

        _Color ("Color", Color) = (1,1,1,1)
        _Multiplier	("亮度",range(1,20)) = 1

		[SimpleToggle] _ScaleOnCenter("以贴图中心进行uv缩放", Float) = 1
        _MainTex ("MainTex", 2D) = "white" {}
        [WrapMode] _MainTexWrapMode ("MainTex wrapMode", Vector) = (1,1,0,0)
        [TexTransform] _MainTexTransform ("MaitTex Transform" , Vector) = (0,0,0,1) //scrollU , scrollV , scrollRot
        //[Toggle] _MainTex_BlendFilter_Toggle("是否开启 MainTex 通道过滤", Float) = 0
        _MainTex_BlendFilter ("MainTex 通道过滤(请勿手动修改)", Color) = (1, 1, 1, 1)

        _MaskTex ("mask", 2D) = "white" {}
		[WrapMode] _MaskTexWrapMode ("MaskTex wrapMode", Vector) = (1,1,0,0)
        [TexTransform] _MaskTexTransform ("MaskTex Transform" , Vector) = (0,0,0,1) //scrollU , scrollV , scrollRot
        _MaskTex_BlendFilter ("MaskTex 通道过滤(请勿手动修改)", Color) = (1, 0, 0, 1)

        _DissolveTex ("dissolveTex", 2D) = "white" {}
		[SimpleToggle]_ToggleDissolveTex("RepeatUV",Float) = 1
        _Dissolve ("dissolveValue", Range(0, 1)) = 0
		_DissolveRange("Dissolve Range", Range(0, 10)) = 0
        _DissolveColor1("dissolveColor1",color) = (1,0,0,1)
        _DissolveColor2("dissolveColor2",color) = (0,0,0,1)
        [TexRotation]_DissolveRot ("dissolve rotation", Vector) = (0,1,0)
        _DissolveTex_BlendFilter ("DissolveTex 通道过滤(请勿手动修改)", Color) = (1, 0, 0, 1)
		
        _FlowTex ("flow", 2D) = "black" {}
		[SimpleToggle]_ToggleFlowTex("RepeatUV",Float) = 1
        [TexTransform] _FlowTexTransform ("FlowTex Transform" , Vector) = (0,0,0,1) //scrollU , scrollV , scrollRot
        _FlowScale ("flow value", Range(0, 2)) = 0		  
    }

	CGINCLUDE
		#include "UnityCG.cginc"
		#include "Assets/CGInclude/EffectCG.cginc"

		struct appdata
		{
			float4 vertex : POSITION;
			float2 uv : TEXCOORD0;
			fixed4 vertexColor : COLOR;
		};

		struct fragData
		{
			float4 uv12 : TEXCOORD0;
			float4 uv34 : TEXCOORD1;
			float4 vertex : SV_POSITION;
			fixed4 vertexColor : COLOR;
		};

		half _AlphaCtrl;
		fixed4 _Color;
		half _Multiplier;

		sampler2D _MainTex;
		float4  _MainTex_ST;
		half4   _MainTexTransform;
		fixed4  _MainTexWrapMode;
        
        fixed4 _MainTex_BlendFilter;
        //fixed _MainTex_BlendFilter_Toggle;

		#if MaskTex_On
			sampler2D _MaskTex;
			float4 _MaskTex_ST;
			half4 _MaskTexTransform;
			fixed4 _MaskTexWrapMode;
            fixed4 _MaskTex_BlendFilter;
		#endif

		#if DissolveTex_On	
			sampler2D _DissolveTex;
			float4 _DissolveTex_ST;
			half _Dissolve;
			half _DissolveRange;
			half _ToggleDissolveTex;
			half2 _DissolveRot;
			fixed4 _DissolveColor1;
			fixed4 _DissolveColor2;
            fixed4 _DissolveTex_BlendFilter;
		#endif

		#if FlowTex_On
			sampler2D _FlowTex;
			float4 _FlowTex_ST;
			half4 _FlowTexTransform;
			half _FlowScale;
			half _ToggleFlowTex;
		#endif

		fixed _ScaleOnCenter;

		fragData vert (appdata v)
		{
			fragData o = (fragData)0;
			o.vertex =  UnityObjectToClipPos(v.vertex);
			
			o.uv12.xy = TransFormUV (v.uv ,_MainTex_ST,_ScaleOnCenter);
			o.uv12.xy = RotateUV(o.uv12.xy,_MainTexTransform.zw);
			o.uv12.xy += _Time.z * _MainTexTransform.xy;

			#if MaskTex_On
				o.uv12.zw = TransFormUV(v.uv,_MaskTex_ST,_ScaleOnCenter);
				o.uv12.zw = RotateUV(o.uv12.zw,_MaskTexTransform.zw);
				o.uv12.zw += _Time.z * _MaskTexTransform.xy;
			#endif

			#if DissolveTex_On	
				o.uv34.xy = TransFormUV(v.uv ,_DissolveTex_ST,_ScaleOnCenter);
				o.uv34.xy = RotateUV(o.uv34.xy,_DissolveRot);
			#endif

			#if FlowTex_On
				o.uv34.zw = TransFormUV(v.uv,_FlowTex_ST,_ScaleOnCenter);
				o.uv34.zw = RotateUV(o.uv34.zw,_FlowTexTransform.zw);
				o.uv34.zw +=  _Time.z * _FlowTexTransform.xy;
			#endif
							
			o.vertexColor = v.vertexColor * _Color * _Multiplier;
			return o;
		}

		fixed4 fragResult(fragData i)
		{
			float4 flowUV = i.uv12.xyxy;

			#if FlowTex_On
				i.uv34.zw = lerp(i.uv34.zw, frac(i.uv34.zw), _ToggleFlowTex);
				fixed4 flowColor = tex2D(_FlowTex, i.uv34.zw, float2(0, 0), float2(0, 0));
				flowUV = (i.uv12.xy + (flowColor.xy - 0.5) * _FlowScale).xyxy;
			#endif

            flowUV.xy=lerp(flowUV.xy, frac(flowUV.xy), _MainTexWrapMode.xy);

            fixed4 texColor = tex2D(_MainTex, flowUV.xy, float2(0, 0), float2(0, 0));

            #ifdef _MAINTEX_BLENDFILTER_TOGGLE_ON
                texColor.rgb = dot(texColor.rgb, _MainTex_BlendFilter.rgb);
            #endif

			fixed4 result = texColor;

			#if DissolveTex_On
				i.uv34.xy= lerp(i.uv34.xy, frac(i.uv34.xy), _ToggleDissolveTex);
                half dissolveAlpha = dot(tex2D(_DissolveTex, i.uv34.xy, float2(0, 0), float2(0, 0)).rgb, _DissolveTex_BlendFilter.rgb);
				float clipValue = dissolveAlpha - _Dissolve*1.2+0.1;
				result.a *= step(0.001 , clipValue);
				clipValue = clamp(clipValue * _DissolveRange  ,0,1);
				fixed4 dissColor = lerp(_DissolveColor1,_DissolveColor2,clipValue  > 0.2);
				clipValue = clamp(clipValue  + (_Dissolve  < 0.001),0,1);
				result.rgb = lerp(dissColor + texColor,texColor,clipValue).rgb;
			#endif

			#if MaskTex_On
				float4 maskUV = i.uv12.zwzw;
				maskUV.xy = lerp(maskUV.xy, frac(maskUV.xy), _MaskTexWrapMode.xy);
				half maskAlpha = dot(tex2D(_MaskTex, maskUV.xy, float2(0, 0), float2(0, 0)).rgb , _MaskTex_BlendFilter.rgb);
				result.a *= maskAlpha;
			#endif
			
			result *= i.vertexColor;
		
			result.a *= _AlphaCtrl;

			return result;
		}
	ENDCG
	
	SubShader
	{
		Tags { "Queue"="AlphaTest-100"  "IgnoreProjector"="True" "RenderType"="AlphaTest"}
		LOD 10
		ColorMask [_ColorMask]
		Blend [_SrcFactor] [_DstFactor]
		Cull [_CullMode]
		ZWrite Off
		//Offset -1, -1

		//first pass
		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 2.0
			#pragma shader_feature MaskTex_On
			#pragma shader_feature DissolveTex_On
			#pragma shader_feature FlowTex_On
            #pragma multi_compile __ _MAINTEX_BLENDFILTER_TOGGLE_ON

			fixed4 frag (fragData i) : SV_Target
			{
				return fragResult(i);
			}
			ENDCG
		}

		//default second pass
		Pass
		{
			ZTest Greater
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 2.0

			#pragma shader_feature MaskTex_On
			#pragma shader_feature DissolveTex_On
			#pragma shader_feature FlowTex_On
            #pragma multi_compile __ _MAINTEX_BLENDFILTER_TOGGLE_ON
			
			fixed4 frag (fragData i) : SV_Target
			{
				fixed4 result = fragResult(i);
				result.a *= 0.2;
				return result;
			}
			ENDCG
		}

		//first pass srp
		Pass
		{
			Tags {"LightMode" = "IndicatorPass"}
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 2.0
			#pragma shader_feature MaskTex_On
			#pragma shader_feature DissolveTex_On
			#pragma shader_feature FlowTex_On
            #pragma multi_compile __ _MAINTEX_BLENDFILTER_TOGGLE_ON

			fixed4 frag (fragData i) : SV_Target
			{
				return fragResult(i);
			}
			ENDCG
		}
		//default second pass srp
		Pass
		{
			Tags {"LightMode" = "IndicatorCoveredPass"}
			ZTest Greater
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 2.0

			#pragma shader_feature MaskTex_On
			#pragma shader_feature DissolveTex_On
			#pragma shader_feature FlowTex_On
            #pragma multi_compile __ _MAINTEX_BLENDFILTER_TOGGLE_ON
			
			fixed4 frag (fragData i) : SV_Target
			{
				fixed4 result = fragResult(i);
				result.a *= 0.2;
				return result;
			}
			ENDCG
		}

	}


	SubShader
	{
		Tags { "Queue"="AlphaTest-100" "IgnoreProjector"="True" "RenderType"="AlphaTest"}
		LOD 5

		ColorMask [_ColorMask]
		Blend [_SrcFactor] [_DstFactor]
		Cull [_CullMode]
        ZTest Always
		ZWrite Off
		Offset -10, -10

		//first pass
		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#pragma shader_feature FlowTex_On
			
			half4 frag (fragData i) : SV_Target
			{
				float4 flowUV = i.uv12.xyxy;

				#if FlowTex_On
					i.uv34.zw = lerp(i.uv34.zw, frac(i.uv34.zw), _ToggleFlowTex);
					fixed4 flowColor = tex2D(_FlowTex, i.uv34.zw, float2(0, 0), float2(0, 0));
					flowUV = (i.uv12.xy + (flowColor.xy - 0.5) * _FlowScale).xyxy;
				#endif

				flowUV.xy=lerp(flowUV.xy, frac(flowUV.xy), _MainTexWrapMode.xy);

				fixed4 texColor = tex2D(_MainTex, flowUV.xy, float2(0, 0), float2(0, 0));
				
				return half4(0.15,0.06,0.03, texColor.a < 0.001);
			}
			ENDCG
		}

		//default second pass
		Pass
		{
			ZTest Greater
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#pragma shader_feature FlowTex_On
			
			half4 frag (fragData i) : SV_Target
			{
				float4 flowUV = i.uv12.xyxy;

				#if FlowTex_On
					i.uv34.zw = lerp(i.uv34.zw, frac(i.uv34.zw), _ToggleFlowTex);
					fixed4 flowColor = tex2D(_FlowTex, i.uv34.zw, float2(0, 0), float2(0, 0));
					flowUV = (i.uv12.xy + (flowColor.xy - 0.5) * _FlowScale).xyxy;
				#endif

				flowUV.xy=lerp(flowUV.xy, frac(flowUV.xy), _MainTexWrapMode.xy);

				fixed4 texColor = tex2D(_MainTex, flowUV.xy, float2(0, 0), float2(0, 0));

				return half4(0.15,0.06,0.03,texColor.a < 0.001);
			}
			ENDCG
		}
		//first pass srp
		Pass
		{
			Tags {"LightMode" = "IndicatorPass"}
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#pragma shader_feature FlowTex_On
			
			half4 frag (fragData i) : SV_Target
			{
				float4 flowUV = i.uv12.xyxy;

				#if FlowTex_On
					i.uv34.zw = lerp(i.uv34.zw, frac(i.uv34.zw), _ToggleFlowTex);
					fixed4 flowColor = tex2D(_FlowTex, i.uv34.zw, float2(0, 0), float2(0, 0));
					flowUV = (i.uv12.xy + (flowColor.xy - 0.5) * _FlowScale).xyxy;
				#endif

				flowUV.xy=lerp(flowUV.xy, frac(flowUV.xy), _MainTexWrapMode.xy);

				fixed4 texColor = tex2D(_MainTex, flowUV.xy, float2(0, 0), float2(0, 0));
				
				return half4(0.15,0.06,0.03, texColor.a < 0.001);
			}
			ENDCG
		}

		//default second pass srp
		Pass
		{
			Tags {"LightMode" = "IndicatorCoveredPass"}
			ZTest Greater
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#pragma shader_feature FlowTex_On
			
			half4 frag (fragData i) : SV_Target
			{
				float4 flowUV = i.uv12.xyxy;

				#if FlowTex_On
					i.uv34.zw = lerp(i.uv34.zw, frac(i.uv34.zw), _ToggleFlowTex);
					fixed4 flowColor = tex2D(_FlowTex, i.uv34.zw, float2(0, 0), float2(0, 0));
					flowUV = (i.uv12.xy + (flowColor.xy - 0.5) * _FlowScale).xyxy;
				#endif

				flowUV.xy=lerp(flowUV.xy, frac(flowUV.xy), _MainTexWrapMode.xy);

				fixed4 texColor = tex2D(_MainTex, flowUV.xy, float2(0, 0), float2(0, 0));

				return half4(0.15,0.06,0.03,texColor.a < 0.001);
			}
			ENDCG
		}
	}
}