// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader  "PhotonShader/Effect/Rim" 
{
    Properties
	{
		[HideInInspector][Enum(UnityEngine.Rendering.BlendMode)] 		_SrcFactor ("SrcFactor()", Float) = 1
		[HideInInspector][Enum(UnityEngine.Rendering.BlendMode)] 		_DstFactor ("DstFactor()", Float) = 1
		[Enum(UnityEngine.Rendering.CullMode)] 							_CullMode ("消隐模式(CullMode)", int) = 2
		[Enum(LessEqual,4,Always,8)]									_ZTestMode ("深度测试(ZTest)", int) = 4
		[SimpleToggle] _ZWrite ("写入深度(ZWrite)", int) = 0
		
		[SimpleToggle] _RgbAsAlpha ("颜色输出至透明(RgbAsAlpha)", int) = 0

        _Color ("Color", Color) = (1,1,1,1)
        _Multiplier	("亮度",range(1,20)) = 1
		
		[SimpleToggle] _ScaleOnCenter("以贴图中心进行uv缩放", Float) = 1
        _MainTex ("MainTex", 2D) = "white" {}
		[TexTransform] _MainTexTransform ("MaitTex Transform" , Vector) = (0,0,0,1) //scrollU , scrollV , scrollRot
		
        _MaskTex ("mask", 2D) = "white" {}
        [TexTransform] _MaskTexTransform ("MaskTex Transform" , Vector) = (0,0,0,1) //scrollU , scrollV , scrollRot
		
		_RimColor("RimColor",color) = (1,1,1,1)
        _RimMultipliers ("rimBrightness", Range(0, 5)) = 1
		_RimRange ("rimRange", Range(0, 20)) = 0

		[HideInInspector] _AlphaCtrl("Alpha control ***Do not edit***", Float) = 1
		[SimpleToggle] _TimeScale("Time Scale", Float) = 1
    }

	CGINCLUDE
// Upgrade NOTE: excluded shader from OpenGL ES 2.0 because it uses non-square matrices
#pragma exclude_renderers gles
		#include "UnityCG.cginc"
		#include "Assets/CGInclude/EffectCG.cginc"
		#include "Assets/CGInclude/LGameCharacterDgs.cginc" 
		struct appdata
		{
			float4 vertex : POSITION;
			float2 uv : TEXCOORD0;
			fixed4 vertexColor : COLOR;
#ifdef _USE_DIRECT_GPU_SKINNING
			half4 tangent	: TANGENT;
			float4 skinIndices : TEXCOORD2;
			float4 skinWeights : TEXCOORD3;
#else
			float3 normal	: NORMAL;
#endif
		};

		struct fragData
		{
			float4 uv12 : TEXCOORD0;
			float3 wPos : TEXCOORD1;
			float3 normalDir : TEXCOORD2;
			float4 vertex : SV_POSITION;
			fixed4 vertexColor : COLOR;
		};

		fixed4 _Color;
		float _Multiplier;

		sampler2D _MainTex;
		float4 _MainTex_ST;
		half4 _MainTexTransform;
		
		sampler2D _MaskTex;
		float4 _MaskTex_ST;
		half4 _MaskTexTransform;
		fixed _AlphaCtrl;

		half _SrcFactor;
		half _RgbAsAlpha;
				
		fixed4 _RimColor;
		half _RimMultipliers;
		half _RimRange;

		fixed _ScaleOnCenter;
		fixed _TimeScale;
		
		fragData vert (appdata v)
		{
			float4 ghostPos = v.vertex;


			float3 normal;
#if _USE_DIRECT_GPU_SKINNING

			float4 tangent;
			float3 binormal;
			DecompressTangentNormal(v.tangent, tangent, normal, binormal);
			ghostPos = CalculateGPUSkin(v.skinIndices, v.skinWeights, v.vertex, tangent, normal, binormal);
			v.uv.xy = DecompressUV(v.uv.xy, _uvBoundData);
			/********************************************************************************************************************
			//使用对偶四元数的逻辑，后面有需要再打开 by yeyang
			half2x4 q0 = GetDualQuat(v.skinIndices.x);
			half2x4 q1 = GetDualQuat(v.skinIndices.y);
			half2x4 q2 = GetDualQuat(v.skinIndices.z);
			half2x4 q3 = GetDualQuat(v.skinIndices.w);

			half2x4 blendDualQuat = q0 * v.skinWeights.x;
			if (dot(q0[0], q1[0]) > 0)
				blendDualQuat += q1 * v.skinWeights.y;
			else
				blendDualQuat -= q1 * v.skinWeights.y;

			if (dot(q0[0], q2[0]) > 0)
				blendDualQuat += q2 * v.skinWeights.z;
			else
				blendDualQuat -= q2 * v.skinWeights.z;

			if (dot(q0[0], q3[0]) > 0)
				blendDualQuat += q3 * v.skinWeights.w;
			else
				blendDualQuat -= q3 * v.skinWeights.w;

			blendDualQuat = NormalizeDualQuat(blendDualQuat);

			ghostPos = float4(TransformFromDualQuat(blendDualQuat, v.vertex), 1);
			 *********************************************************************************************************************/
#else
			normal = v.normal;
#endif
			fragData o = (fragData)0;
			o.vertex =  UnityObjectToClipPos(ghostPos);
			
			o.uv12.xy = TransFormUV(v.uv,_MainTex_ST,_ScaleOnCenter);
			o.uv12.xy = RotateUV(o.uv12.xy,_MainTexTransform.zw);
			o.uv12.xy += _TimeScale * _Time.x * _MainTexTransform.xy;
			
			o.uv12.zw = TransFormUV(v.uv,_MaskTex_ST,_ScaleOnCenter);
			o.uv12.zw = RotateUV(o.uv12.zw,_MaskTexTransform.zw);
			o.uv12.zw += _TimeScale * _Time.x * _MaskTexTransform.xy;
			
			o.normalDir = mul((float3x3)unity_ObjectToWorld, normal);
			o.wPos = mul(unity_ObjectToWorld, ghostPos);
			
			o.vertexColor = v.vertexColor;
			o.vertexColor.a *= _AlphaCtrl;
			return o;
		}
	ENDCG
	
	SubShader
	{
		Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent"}
		LOD 100
		Blend [_SrcFactor] [_DstFactor]
		Cull [_CullMode]
		ZWrite [_ZWrite]
		ZTest [_ZTestMode]

		Pass
		{
			Tags {  "LightMode" = "ForwardBase"}
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 2.0
			#pragma multi_compile __ _USE_DIRECT_GPU_SKINNING

			fixed4 frag (fragData i) : SV_Target
			{
				fixed4 texColor = tex2D(_MainTex, i.uv12.xy);
				fixed4 maskColor = tex2D(_MaskTex, i.uv12.zw);
				
				fixed4 result = (fixed4)1;
				result = texColor;
				result.a *= maskColor.r;
				
				result *= i.vertexColor * _Color * _Multiplier;
				
				float3 viewDirection = normalize(_WorldSpaceCameraPos.xyz - i.wPos.xyz);
                float3 normalDirection = normalize(i.normalDir);

                float fresnel = 1 - max(0,dot(viewDirection.xyz,normalDirection.xyz));

				fixed3 rimColor = _RimColor.rgb *  pow(fresnel,_RimRange);
				
				result.rgb  = result.rgb + rimColor * _RimMultipliers;
				
				float gray = dot(result.rgb,fixed3(0.33,0.34,0.33));
				float aa[2] = {result.a,gray};
				
				fixed4 multiplyColor = lerp(half4(1,1,1,1), result, result.a);
				result = lerp(result, multiplyColor ,_SrcFactor == 0);
				result.a = aa[_RgbAsAlpha];
				
				return result;
			}
			ENDCG
		}

		Pass
		{
			Tags {  "LightMode" = "ForwardBase"}
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile __ _USE_DIRECT_GPU_SKINNING
			fixed4 frag (fragData i) : SV_Target
			{
				return fixed4(0.15, 0.06, 0.03, 0);
			}
			ENDCG
		}
	}

		SubShader
			{
					Tags { "Queue" = "Transparent" "LightMode" = "ForwardBase" "IgnoreProjector" = "True" "RenderType" = "Transparent"}
					LOD 5
					Blend One One
					ZWrite[_ZWrite]
					ZTest[_ZTestMode]
					Cull[_CullMode]

						Pass
						{
							CGPROGRAM
							#pragma vertex vert
							#pragma fragment fragtest
							//#pragma multi_compile_instancing
							//#include "Assets/CGInclude/LGameEffect.cginc" 

							half4 fragtest(fragData i) : SV_Target
							{
								UNITY_SETUP_INSTANCE_ID(i);

								fixed4 texColor = tex2D(_MainTex, i.uv12.xy, float2(0, 0), float2(0, 0));

								return half4(0.15,0.06,0.03, texColor.a < 0.001);
							}
							ENDCG
						}
			}
}
