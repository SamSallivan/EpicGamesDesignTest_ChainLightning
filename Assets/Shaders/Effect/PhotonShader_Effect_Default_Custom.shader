// Upgrade NOTE: upgraded instancing buffer 'effectAlpha' to new syntax.
// Upgrade NOTE: upgraded instancing buffer 'effectDissolve' to new syntax.
// Upgrade NOTE: upgraded instancing buffer 'effectFlow' to new syntax.
// Upgrade NOTE: upgraded instancing buffer 'effectMain' to new syntax.
// Upgrade NOTE: upgraded instancing buffer 'effectMask' to new syntax.
// Upgrade NOTE: upgraded instancing buffer 'fow' to new syntax.

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader  "PhotonShader/Effect/Default_Custom" 
{
    Properties
	{
		[HideInInspector]_AlphaCtrl("AlphaCtrl",range(0,1)) = 1
		[HideInInspector][Enum(UnityEngine.Rendering.BlendMode)] 		_SrcFactor ("SrcFactor()", Float) = 5
		[HideInInspector][Enum(UnityEngine.Rendering.BlendMode)] 		_DstFactor ("DstFactor()", Float) = 10
		[Enum(UnityEngine.Rendering.CullMode)] 							_CullMode ("消隐模式(CullMode)", int) = 0
		[Enum(LessEqual,4,Always,8)]									_ZTestMode ("深度测试(ZTest)", int) = 4
        [Enum(RGB,14,ALL,15, NONE,0)]									_ColorMask ("颜色遮罩(ColorMask)", int) = 15

        [HideInInspector] _Offset ("Offset" , Float) = 0

        _Color ("Color", Color) = (1,1,1,1)
        _Multiplier	("亮度",range(1,20)) = 1
		
		[SimpleToggle] _ScaleOnCenter("以贴图中心进行uv缩放", Float) = 1
        _MainTex ("MainTex", 2D) = "white" {}
		[WrapMode] _MainTexWrapMode ("MainTex wrapMode", Vector) = (1,1,0,0)
        [TexTransform] _MainTexTransform ("MaitTex Transform" , Vector) = (0,0,0,1) //scrollU , scrollV , scrollRot

        _MaskTex ("mask", 2D) = "white" {}
		[WrapMode] _MaskTexWrapMode ("MaskTex wrapMode", Vector) = (1,1,0,0)
        [TexTransform] _MaskTexTransform ("MaskTex Transform" , Vector) = (0,0,0,1) //scrollU , scrollV , scrollRot

        _DissolveTex ("dissolveTex", 2D) = "white" {}
		[SimpleToggle]_ToggleDissolveTex ("RepeatUV",Float) = 1
		_DissolveRange("Dissolve Range", Range(0, 10)) = 0
        _DissolveColor1("dissolveColor1",color) = (1,0,0,1)
        _DissolveColor2("dissolveColor2",color) = (0,0,0,1)
        [TexRotation]_DissolveRot ("dissolve rotation", Vector) = (0,1,0)
		
        _FlowTex ("flow", 2D) = "black" {}
		[SimpleToggle]_ToggleFlowTex("RepeatUV",Float) = 1
        [TexTransform] _FlowTexTransform ("FlowTex Transform" , Vector) = (0,0,0,1) //scrollU , scrollV , scrollRot
        _FlowScale ("flow value", Range(0, 2)) = 0	
		
		_FowBlend("FOW Blend" ,Range(0,1)) = 0	  
		[SimpleToggle] _TimeScale("Time Scale", Float) = 1

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
			float4 customData:TEXCOORD2;
			#if RectClip_On
				float3 viewPos	: TEXCOORD3;
			#endif

			float4 vertex : SV_POSITION;
			fixed4 vertexColor : COLOR;
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
#define _Color_arr effectAlpha
			UNITY_DEFINE_INSTANCED_PROP(half ,_Multiplier)
#define _Multiplier_arr effectAlpha
		UNITY_INSTANCING_BUFFER_END(effectAlpha)

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
			half4 _EffectClipRect;
		#endif

		fixed _ScaleOnCenter;
		uniform float4  _MainTex_TexelSize;
		fixed _TimeScale;

		inline float Get2DClipping (in float2 position, in float4 clipRect)
		{
			float2 inside = step(clipRect.xy, position.xy) * step(position.xy, clipRect.zw);
			return inside.x * inside.y;
		}

		fragData vert (appdata v)
		{
			fragData o = (fragData)0;
			UNITY_SETUP_INSTANCE_ID(v);
			UNITY_TRANSFER_INSTANCE_ID( v , o);

			o.vertex =  UnityObjectToClipPos(v.vertex);

			#if RectClip_On
				o.viewPos = UnityObjectToViewPos(v.vertex);
			#endif
		
			o.uv12.xy = TransFormUV (v.uv ,UNITY_ACCESS_INSTANCED_PROP(_MainTex_ST_arr, _MainTex_ST),_ScaleOnCenter);
			o.uv12.xy = RotateUV(o.uv12.xy,UNITY_ACCESS_INSTANCED_PROP(_MainTexTransform_arr, _MainTexTransform).zw);
			o.uv12.xy += _TimeScale * _Time.z * UNITY_ACCESS_INSTANCED_PROP(_MainTexTransform_arr, _MainTexTransform).xy;
			
			#if MaskTex_On
				o.uv12.zw = TransFormUV(v.uv,UNITY_ACCESS_INSTANCED_PROP(_MaskTex_ST_arr, _MaskTex_ST),_ScaleOnCenter);
				o.uv12.zw = RotateUV(o.uv12.zw,UNITY_ACCESS_INSTANCED_PROP(_MaskTexTransform_arr, _MaskTexTransform).zw);
				o.uv12.zw += _TimeScale * _Time.z * UNITY_ACCESS_INSTANCED_PROP(_MaskTexTransform_arr, _MaskTexTransform).xy;
			#endif

			#if DissolveTex_On	
				o.uv34.xy = TransFormUV(v.uv , UNITY_ACCESS_INSTANCED_PROP(_DissolveTex_ST_arr, _DissolveTex_ST),_ScaleOnCenter);
				o.uv34.xy = RotateUV(o.uv34.xy, _DissolveRot);
			#endif

			#if FlowTex_On
				o.uv34.zw = TransFormUV(v.uv,UNITY_ACCESS_INSTANCED_PROP(_FlowTex_ST_arr, _FlowTex_ST),_ScaleOnCenter);
				o.uv34.zw = RotateUV(o.uv34.zw,UNITY_ACCESS_INSTANCED_PROP(_FlowTexTransform_arr, _FlowTexTransform).zw);
				o.uv34.zw +=  _TimeScale * _Time.z * UNITY_ACCESS_INSTANCED_PROP(_FlowTexTransform_arr, _FlowTexTransform).xy;
			#endif
					
			fixed4	fowCol = lerp (1.0.rrrr , UNITY_ACCESS_INSTANCED_PROP(_FogCol_arr, _FogCol) ,UNITY_ACCESS_INSTANCED_PROP(_FowBlend_arr, _FowBlend));
			o.vertexColor = v.vertexColor * UNITY_ACCESS_INSTANCED_PROP(_Color_arr, _Color) * UNITY_ACCESS_INSTANCED_PROP(_Multiplier_arr, _Multiplier) ;
			o.vertexColor.rgb *= fowCol.rgb;
			o.customData = v.uv.z;
			return o;
		}

	ENDCG

	SubShader
	{
		Tags { "Queue"="Transparent" "LightMode" = "ForwardBase" "IgnoreProjector"="True" "RenderType"="Transparent"}
		LOD 100
		ColorMask [_ColorMask]
		Blend [_SrcFactor] [_DstFactor]
		Cull [_CullMode]
		ZWrite off
		ZTest [_ZTestMode]
        Offset [_Offset] , [_Offset]

		Pass
		{
			CGPROGRAM

			#pragma vertex vert
			#pragma fragment frag

			#pragma target 2.0

			//#pragma multi_compile_instancing
			#pragma shader_feature MaskTex_On
			#pragma shader_feature DissolveTex_On
			#pragma shader_feature FlowTex_On
			#pragma shader_feature RectClip_On

			
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
				fixed4 result = texColor;

				#if DissolveTex_On
					i.uv34.xy = lerp(i.uv34.xy, frac(i.uv34.xy), _ToggleDissolveTex);
					fixed4 dissolveColor = tex2D(_DissolveTex, i.uv34.xy, float2(0, 0), float2(0, 0));
					float clipValue = dissolveColor.r - i.customData.x*1.2 + 0.1;
					result.a *= smoothstep(0.001,0.1 , clipValue);
					clipValue = clamp(clipValue * _DissolveRange  ,0,1);
					fixed4 dissColor = lerp(_DissolveColor1,_DissolveColor2,smoothstep(0.2 , 0.3,clipValue));
					clipValue = clamp(clipValue  + step(i.customData.x,0.001),0,1);
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
					result.a *= Get2DClipping(i.viewPos.xy , _EffectClipRect);
				#endif
				
				result.a *= UNITY_ACCESS_INSTANCED_PROP(_AlphaCtrl_arr, _AlphaCtrl);

				return result;
			}
			ENDCG
		}
	}

	SubShader
	{
		Tags { "Queue"="Transparent" "LightMode" = "ForwardBase" "IgnoreProjector"="True" "RenderType"="Transparent"}
		LOD 5
		ColorMask [_ColorMask]
		Blend One One
		Cull [_CullMode]
		ZWrite off
		ZTest [_ZTestMode]
        Offset [_Offset] , [_Offset]

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			//#pragma multi_compile_instancing
			
			half4 frag(fragData i) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID(i);

				fixed4 texColor = tex2D(_MainTex, i.uv12.xy, float2(0, 0), float2(0, 0));

				return half4(0.15,0.06,0.03, texColor.a < 0.001);
			}
			ENDCG
		}
	}
}
