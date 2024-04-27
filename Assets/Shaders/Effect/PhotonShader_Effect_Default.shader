// Upgrade NOTE: upgraded instancing buffer 'effectAlpha' to new syntax.
// Upgrade NOTE: upgraded instancing buffer 'effectDissolve' to new syntax.
// Upgrade NOTE: upgraded instancing buffer 'effectFlow' to new syntax.
// Upgrade NOTE: upgraded instancing buffer 'effectMain' to new syntax.
// Upgrade NOTE: upgraded instancing buffer 'effectMask' to new syntax.
// Upgrade NOTE: upgraded instancing buffer 'fow' to new syntax.

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader  "PhotonShader/Effect/Default" 
{
    Properties
	{
		[HideInInspector]_AlphaCtrl("AlphaCtrl",range(0,1)) = 1
		[HideInInspector]_OffsetFactor("Offset Factor ",Float) =0
		[HideInInspector]_OffsetUnits("Offset Units ",Float) = 0
		[HideInInspector][Enum(UnityEngine.Rendering.BlendMode)] 		_SrcFactor ("SrcFactor()", Float) = 5
		[HideInInspector][Enum(UnityEngine.Rendering.BlendMode)] 		_DstFactor ("DstFactor()", Float) = 10
		[HideInInspector][Enum(UnityEngine.Rendering.BlendMode)] 		_SrcAlphaFactor ("SrcAlphaFactor()", Float) = 0
		[HideInInspector][Enum(UnityEngine.Rendering.BlendMode)] 		_DstAlphaFactor ("DstAlphaFactor()", Float) = 10
		[Enum(UnityEngine.Rendering.CullMode)] 							_CullMode ("消隐模式(CullMode)", int) = 0
		[Enum(LessEqual,4,Always,8)]									_ZTestMode ("深度测试(ZTest)", int) = 4
        [Enum(RGB,14,ALL,15, NONE,0)]									_ColorMask ("颜色遮罩(ColorMask)", int) = 15
		[Header(Do Not Touch HDR Intensity)]
        [HDR]_Color ("Color", Color) = (1,1,1,1)
		[HideInInspector]_OffsetColor ("OffsetColor", Color) = (0,0,0,0)  //色彩偏移（受击闪白之类）
		_OffsetColorLerp ("OffsetColor", Float) = 0
        _Multiplier	("亮度",range(1,20)) = 1

		[HideInInspector]_GradientTex("Gradient Texture", 2D) = "white" {}
		
		[SimpleToggle] _ScaleOnCenter("以贴图中心进行uv缩放", Float) = 1
        _MainTex ("MainTex", 2D) = "white" {}
		[WrapMode] _MainTexWrapMode ("MainTex wrapMode", Vector) = (1,1,0,0)
        [TexTransform] _MainTexTransform ("MaitTex Transform" , Vector) = (0,0,0,1) //scrollU , scrollV , scrollRot

        _MaskTex ("mask", 2D) = "white" {}
		[WrapMode] _MaskTexWrapMode ("MaskTex wrapMode", Vector) = (1,1,0,0)
        [TexTransform] _MaskTexTransform ("MaskTex Transform" , Vector) = (0,0,0,1) //scrollU , scrollV , scrollRot

        _DissolveTex ("dissolveTex", 2D) = "white" {}
		[SimpleToggle]_ToggleDissolveTex ("RepeatUV",Float) = 1
        _Dissolve ("dissolveValue", Range(0, 1)) = 0
		_DissolveRange("Dissolve Range", Range(0, 10)) = 0
        _DissolveColor1("dissolveColor1",color) = (1,0,0,1)
        _DissolveColor2("dissolveColor2",color) = (0,0,0,1)
        [TexRotation]_DissolveRot ("dissolve rotation", Vector) = (0,1,0)
		
        _FlowTex ("flow", 2D) = "black" {}
		[SimpleToggle]_ToggleFlowTex("RepeatUV",Float) = 1
        [TexTransform] _FlowTexTransform ("FlowTex Transform" , Vector) = (0,0,0,1) //scrollU , scrollV , scrollRot
        _FlowScale ("flow value", Range(0, 2)) = 0	
		
		_FowBlend("FOW Blend" ,Range(0,1)) = 0	  
		[Toggle]_CardClip("Card Clip",Float) = 0
		[HideInInspector] _StencilComp("Stencil Comparison", Float) = 8
		[HideInInspector] _Stencil("Stencil ID", Float) = 0
		[HideInInspector] _StencilOp("Stencil Operation", Float) = 0
		[HideInInspector] _StencilWriteMask("Stencil Write Mask", Float) = 255
		[HideInInspector] _StencilReadMask("Stencil Read Mask", Float) = 255
		[SimpleToggle] _TimeScale("Time Scale", Float) = 1
		
		[Toggle] _IsDissolveSecond ("Is DissolveSecond?", Int) = 0  // 溶解世界反向（比如铁男大招  半径内半径外通过该参数取反 或者两个效果溶解切换的表现）
		[Enum(VRSDefault,0,VRS1x1,1,VRS1x2,2,VRS2x1,3,VRS2x2,4,VRS4x2,5,VRS4x4,6)] _ShadingRate("Fragment Shading Rate", Float) = 0
    }

	CGINCLUDE
		#include "UnityCG.cginc"
		#include "Assets/CGInclude/EffectCG.cginc"

		struct appdata
		{
			float4 vertex : POSITION;
			float4 uv : TEXCOORD0;
			fixed4 vertexColor : COLOR;
			UNITY_VERTEX_INPUT_INSTANCE_ID
		};

		struct fragData
		{
			float4 uv12 : TEXCOORD0;
			float4 uv34 : TEXCOORD1;

			#if RectClip_On || _ENABLE_DISSOLVE_WORLD
				float3 worldPos	: TEXCOORD2;
			#endif

			float4 vertex : SV_POSITION;
			fixed4 vertexColor : COLOR;
			
			#if _CARDCLIP_ON
				float4 screenPos:TEXCOORD3;
				float4 pivot:TEXCOORD4;
			#endif
			UNITY_VERTEX_INPUT_INSTANCE_ID
		};

		UNITY_INSTANCING_BUFFER_START(fow)
			UNITY_DEFINE_INSTANCED_PROP(fixed4 ,_FogCol) 
#define _FogCol_arr fow
			UNITY_DEFINE_INSTANCED_PROP(half , _FowBlend )
#define _FowBlend_arr fow
		UNITY_INSTANCING_BUFFER_END(fow)

		UNITY_INSTANCING_BUFFER_START (effectAlpha)
			UNITY_DEFINE_INSTANCED_PROP(half ,_AlphaCtrl)
#define _AlphaCtrl_arr effectAlpha
			UNITY_DEFINE_INSTANCED_PROP(fixed4 ,_Color)
#define _OffsetColor_arr effectAlpha
			UNITY_DEFINE_INSTANCED_PROP(fixed4 ,_OffsetColor)
#define _OffsetColorLerp_arr effectAlpha
			UNITY_DEFINE_INSTANCED_PROP(half ,_OffsetColorLerp)			
#define _Color_arr effectAlpha
			UNITY_DEFINE_INSTANCED_PROP(half ,_Multiplier)
#define _Multiplier_arr effectAlpha
		UNITY_INSTANCING_BUFFER_END(effectAlpha)

		#if _GRADIENT_ON
			sampler2D _GradientTex; 
		#endif

		sampler2D _MainTex;
		UNITY_INSTANCING_BUFFER_START (effectMain)
			UNITY_DEFINE_INSTANCED_PROP(half4 ,_MainTex_ST)
#define _MainTex_ST_arr effectMain
			UNITY_DEFINE_INSTANCED_PROP(half4 ,_MainTexTransform)
#define _MainTexTransform_arr effectMain
			UNITY_DEFINE_INSTANCED_PROP(fixed4 ,_MainTexWrapMode)
#define _MainTexWrapMode_arr effectMain
		UNITY_INSTANCING_BUFFER_END(effectMain)
        
		#if MaskTex_On
			sampler2D _MaskTex;
			UNITY_INSTANCING_BUFFER_START (effectMask)
				UNITY_DEFINE_INSTANCED_PROP(half4 ,_MaskTex_ST)
#define _MaskTex_ST_arr effectMask
				UNITY_DEFINE_INSTANCED_PROP(half4 ,_MaskTexTransform)
#define _MaskTexTransform_arr effectMask
				UNITY_DEFINE_INSTANCED_PROP(fixed4 ,_MaskTexWrapMode)
#define _MaskTexWrapMode_arr effectMask
			UNITY_INSTANCING_BUFFER_END(effectMask)
		#endif

		#if DissolveTex_On	
			sampler2D _DissolveTex ;
			half _DissolveRange;
			half _ToggleDissolveTex;
			half2 _DissolveRot;
			fixed4 _DissolveColor1;
			fixed4 _DissolveColor2;
			UNITY_INSTANCING_BUFFER_START (effectDissolve)
				UNITY_DEFINE_INSTANCED_PROP(half4 ,_DissolveTex_ST)
#define _DissolveTex_ST_arr effectDissolve
				UNITY_DEFINE_INSTANCED_PROP(half ,_Dissolve)
#define _Dissolve_arr effectDissolve
			UNITY_INSTANCING_BUFFER_END(effectDissolve)
		#endif

		#if FlowTex_On 
			sampler2D _FlowTex ;
			half _ToggleFlowTex;
			UNITY_INSTANCING_BUFFER_START (effectFlow)
				UNITY_DEFINE_INSTANCED_PROP(half4 ,_FlowTex_ST)
#define _FlowTex_ST_arr effectFlow
				UNITY_DEFINE_INSTANCED_PROP(half4 ,_FlowTexTransform)
#define _FlowTexTransform_arr effectFlow
				UNITY_DEFINE_INSTANCED_PROP(half ,_FlowScale)
#define _FlowScale_arr effectFlow
			UNITY_INSTANCING_BUFFER_END(effectFlow)
		#endif

		#if RectClip_On
			float4 _EffectClipRect;	// UI裁剪需要高精度
		#endif

		fixed _ScaleOnCenter;
		uniform float4  _MainTex_TexelSize;
		fixed _TimeScale;

		inline float Get2DClipping (in float2 position, in float4 clipRect)
		{
			float2 inside = step(clipRect.xy, position.xy) * step(position.xy, clipRect.zw);
			return inside.x * inside.y;
		}

		#if _CARDCLIP_ON
			float4 _Piovt;
		#endif
		half CardClip(half4 pos)
		{
			//固定宽高200*328
			half4 range = half4(pos.x - 100.0, pos.x + 100.0, pos.y-164.0, pos.y+164.0);
			return (range.x < pos.z) && (pos.z < range.y) && (range.z < pos.w) && (pos.w < range.w);
		}

		float _IsDissolveSecond;
        #if _ENABLE_DISSOLVE_WORLD
	        uniform vector _DissolveWorldPos;		// 溶解世界 - 中心坐标
	        uniform float _DissolveWorldRadius;		// 溶解世界 - 半径（控制溶解切换的面积）
	        uniform float _DissolveWorldAmount;		// 溶解世界 - 过渡距离（控制过渡边缘效果，默认值0.1）
        #endif

        // 场景过渡：溶解切换
        inline void LGameApplyDissolveWorld(inout float4 finalCol, in float3 worldPos)
        {
	        // 两个场景动态溶解切换过渡效果
	        #if _ENABLE_DISSOLVE_WORLD
		        float3 dis = distance(_DissolveWorldPos, worldPos.xyz); // TODO: 这个后续可以修改为基于相机的距离
		        float3 R = 1 - saturate(dis/_DissolveWorldRadius);  // 获取区域面积信息
                float alpha = 0;
		        if(_IsDissolveSecond == 1) // TODO: 效率优化
		        {
		            alpha = step(R, _DissolveWorldAmount);
		        }
		        else
		        {
			        alpha = step(_DissolveWorldAmount, R);
		        }
		        if(alpha == 0)
			    {
				    finalCol.rgb = half3(0,0,0);
			    }
		        clip(alpha - 0.001);
	        #endif
        }
	
		/////////////
		fragData vert (appdata v)
		{
			fragData o = (fragData)0;
			UNITY_SETUP_INSTANCE_ID(v);
			UNITY_TRANSFER_INSTANCE_ID( v , o);

			o.vertex =  UnityObjectToClipPos(v.vertex);

			#if RectClip_On || _ENABLE_DISSOLVE_WORLD
				o.worldPos = mul(unity_ObjectToWorld, float4(v.vertex.xyz,1.0)).xyz;
			#endif
		
			o.uv12.xy = TransFormUV (v.uv ,UNITY_ACCESS_INSTANCED_PROP(_MainTex_ST_arr, _MainTex_ST),_ScaleOnCenter);
			o.uv12.xy = RotateUV(o.uv12.xy,UNITY_ACCESS_INSTANCED_PROP(_MainTexTransform_arr, _MainTexTransform).zw);
			o.uv12.xy += frac(_TimeScale * _Time.z* UNITY_ACCESS_INSTANCED_PROP(_MainTexTransform_arr, _MainTexTransform).xy) ;
			
			#if MaskTex_On
				o.uv12.zw = TransFormUV(v.uv,UNITY_ACCESS_INSTANCED_PROP(_MaskTex_ST_arr, _MaskTex_ST),_ScaleOnCenter);
				o.uv12.zw = RotateUV(o.uv12.zw,UNITY_ACCESS_INSTANCED_PROP(_MaskTexTransform_arr, _MaskTexTransform).zw);
				o.uv12.zw += frac(_TimeScale *  _Time.z * UNITY_ACCESS_INSTANCED_PROP(_MaskTexTransform_arr, _MaskTexTransform).xy) ;
			#endif

			#if DissolveTex_On	
				o.uv34.xy = TransFormUV(v.uv , UNITY_ACCESS_INSTANCED_PROP(_DissolveTex_ST_arr, _DissolveTex_ST),_ScaleOnCenter);
				o.uv34.xy = RotateUV(o.uv34.xy, _DissolveRot);
			#endif

			#if FlowTex_On
				o.uv34.zw = TransFormUV(v.uv,UNITY_ACCESS_INSTANCED_PROP(_FlowTex_ST_arr, _FlowTex_ST),_ScaleOnCenter);
				o.uv34.zw = RotateUV(o.uv34.zw,UNITY_ACCESS_INSTANCED_PROP(_FlowTexTransform_arr, _FlowTexTransform).zw);
				o.uv34.zw +=  frac(_TimeScale *  _Time.z * UNITY_ACCESS_INSTANCED_PROP(_FlowTexTransform_arr, _FlowTexTransform).xy);
			#endif
					
			fixed4	fowCol = lerp (1.0.rrrr , UNITY_ACCESS_INSTANCED_PROP(_FogCol_arr, _FogCol) ,UNITY_ACCESS_INSTANCED_PROP(_FowBlend_arr, _FowBlend));

			fixed4 tempCol = UNITY_ACCESS_INSTANCED_PROP(_Color_arr, _Color);
			fixed4 offsetCol = UNITY_ACCESS_INSTANCED_PROP(_OffsetColor_arr, _OffsetColor);
			tempCol.rgb = lerp(tempCol.rgb , offsetCol.rgb ,  UNITY_ACCESS_INSTANCED_PROP(_OffsetColorLerp_arr, _OffsetColorLerp));
			o.vertexColor = v.vertexColor * tempCol* UNITY_ACCESS_INSTANCED_PROP(_Multiplier_arr, _Multiplier) ;
			o.vertexColor.rgb *= fowCol.rgb;

			#if _CARDCLIP_ON
				o.pivot = ComputeScreenPos(mul(UNITY_MATRIX_VP, half4(_Piovt.xyz,1)));
				o.screenPos = ComputeScreenPos(o.vertex);
			#endif
			return o;
		}

	ENDCG

	SubShader
	{
		Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent"}
		LOD 100
		// ShadingRate[_ShadingRate]
		ColorMask [_ColorMask]
		Blend [_SrcFactor] [_DstFactor],[_SrcAlphaFactor] [_DstAlphaFactor]
		Cull [_CullMode]
		ZWrite off
		ZTest [_ZTestMode]
        Offset [_OffsetFactor] , [_OffsetUnits]

		Stencil
		{
			Ref[_Stencil]
			Comp[_StencilComp]
			Pass[_StencilOp]
			ReadMask[_StencilReadMask]
			WriteMask[_StencilWriteMask]
		}

		Pass
		{
			Tags { "LightMode" = "ForwardBase" }
			CGPROGRAM

			#pragma vertex vert
			#pragma fragment frag

			#pragma target 2.0
            
			#pragma multi_compile __ _GRADIENT_ON
			#pragma shader_feature MaskTex_On
			#pragma shader_feature DissolveTex_On
			#pragma shader_feature FlowTex_On
			//#pragma multi_compile_instancing	
			#pragma multi_compile __ RectClip_On
			#pragma shader_feature _CARDCLIP_ON
			#pragma multi_compile __ _ENABLE_DISSOLVE_WORLD

			fixed4 frag (fragData i) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID(i);

			    float4 flowUV = i.uv12.xyxy;

				#if FlowTex_On
					i.uv34.zw = lerp(i.uv34.zw, frac(i.uv34.zw), _ToggleFlowTex);
					fixed4 flowColor = tex2D(_FlowTex, i.uv34.zw,float2(0,0),float2(0,0));
					flowUV = (i.uv12.xy + (flowColor.xy - 0.5) * UNITY_ACCESS_INSTANCED_PROP(_FlowScale_arr, _FlowScale)).xyxy;
				#endif
				
				flowUV.xy = lerp(flowUV.xy, frac(flowUV.xy), UNITY_ACCESS_INSTANCED_PROP(_MainTexWrapMode_arr, _MainTexWrapMode).xy);
				
				fixed4 texColor = tex2D(_MainTex, flowUV.xy, float2(0, 0), float2(0, 0));
				
				#if _GRADIENT_ON
					fixed4  gradientCol = tex2D(_GradientTex, flowUV.xy, float2(0, 0), float2(0, 0));
					texColor *= gradientCol;
				#endif

				fixed4 result = texColor;

				#if DissolveTex_On
					i.uv34.xy = lerp(i.uv34.xy, frac(i.uv34.xy), _ToggleDissolveTex);
                    fixed4 dissolveColor = tex2D(_DissolveTex, i.uv34.xy, float2(0, 0), float2(0, 0));
					float clipValue = dissolveColor.r - UNITY_ACCESS_INSTANCED_PROP(_Dissolve_arr, _Dissolve)*1.2 + 0.1;
					result.a *= smoothstep(0.001,0.1 , clipValue);
					clipValue = clamp(clipValue * _DissolveRange  ,0,1);
					fixed4 dissColor = lerp(_DissolveColor1,_DissolveColor2,smoothstep(0.2 , 0.3,clipValue));
					clipValue = clamp(clipValue  + step(UNITY_ACCESS_INSTANCED_PROP(_Dissolve_arr, _Dissolve),0.001),0,1);
					result.rgb =  lerp(dissColor + texColor,texColor,clipValue).rgb;
				#endif

				#if MaskTex_On
					float4 maskUV = i.uv12.zwzw;
					maskUV.xy = lerp(maskUV.xy, frac(maskUV.xy), UNITY_ACCESS_INSTANCED_PROP(_MaskTexWrapMode_arr, _MaskTexWrapMode).xy);
                    fixed4 maskColor = tex2D(_MaskTex, maskUV.xy, float2(0, 0), float2(0, 0));
                    result.a *= maskColor.r;
				#endif
				
				result *= i.vertexColor;

				#if RectClip_On
					result.a *= Get2DClipping(i.worldPos.xy , _EffectClipRect);
				#endif				
				result.a *= UNITY_ACCESS_INSTANCED_PROP(_AlphaCtrl_arr, _AlphaCtrl);
				#if _CARDCLIP_ON
					i.pivot.xy = i.pivot.xy / i.pivot.zw;
					i.screenPos.xy = i.screenPos.xy / i.screenPos.zw;
					result.a *= CardClip(half4(i.pivot.xy,i.screenPos.xy)*_ScreenParams.xyxy);
				#endif

				// Apply Dissolve World
				#if _ENABLE_DISSOLVE_WORLD
					LGameApplyDissolveWorld(result, i.worldPos.xyz);
				#endif
				
				result.a=saturate(result.a);
				return result;
			}
			ENDCG
		}
		
		Pass
		{
			Tags {  "LightMode" = "BloomMaskPass" }
			CGPROGRAM

			#pragma vertex vert
			// #pragma fragment frag
			#pragma fragment fragBloomMask
			#pragma target 2.0

			#pragma shader_feature MaskTex_On
			#pragma multi_compile __ RectClip_On
			#pragma shader_feature _CARDCLIP_ON

			fixed4 fragBloomMask (fragData i) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID(i);

			    float4 flowUV = i.uv12.xyxy;
				flowUV.xy = lerp(flowUV.xy, frac(flowUV.xy), UNITY_ACCESS_INSTANCED_PROP(_MainTexWrapMode_arr, _MainTexWrapMode).xy);
				
				fixed4 texColor = tex2D(_MainTex, flowUV.xy, float2(0, 0), float2(0, 0));
				fixed4 result = texColor;

				#if MaskTex_On
					float4 maskUV = i.uv12.zwzw;
					maskUV.xy = lerp(maskUV.xy, frac(maskUV.xy), UNITY_ACCESS_INSTANCED_PROP(_MaskTexWrapMode_arr, _MaskTexWrapMode).xy);
                    fixed4 maskColor = tex2D(_MaskTex, maskUV.xy, float2(0, 0), float2(0, 0));
                    result.a *= maskColor.r;
				#endif
				
				result *= i.vertexColor;

				#if RectClip_On
					result.a *= Get2DClipping(i.worldPos.xy , _EffectClipRect);
				#endif				
				result.a *= UNITY_ACCESS_INSTANCED_PROP(_AlphaCtrl_arr, _AlphaCtrl);
				#if _CARDCLIP_ON
					i.pivot.xy = i.pivot.xy / i.pivot.zw;
					i.screenPos.xy = i.screenPos.xy / i.screenPos.zw;
					result.a *= CardClip(half4(i.pivot.xy,i.screenPos.xy)*_ScreenParams.xyxy);
				#endif
				result.a=saturate(result.a);
				
				return result;
			}
			ENDCG
		}
	}

	SubShader
	{
		Tags { "Queue"="Transparent" "LightMode" = "ForwardBase" "IgnoreProjector"="True" "RenderType"="Transparent"}
		LOD 5
		Blend One One
		Cull [_CullMode]
		ZWrite off
		ZTest [_ZTestMode]
		Offset[_OffsetFactor] ,[_OffsetUnits]

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			//#pragma multi_compile_instancing	
			#pragma shader_feature FlowTex_On
			
			half4 frag (fragData i) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID(i);
                
				fixed4 texColor = tex2D(_MainTex, i.uv12.xy, float2(0, 0), float2(0, 0));

				return half4(0.15,0.06,0.03, texColor.a < 0.001);
			}
			ENDCG
		}
	}
}
