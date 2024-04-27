Shader "Hidden/Character/Outline Srp"
{
	Properties
	{
		_OutlineCol("OutlineCol", Color) = (0,0,0,1)
		_OutlineScale("Outline Scale", Range(0,1)) = 0.03
		_AlphaCtrl("AlphaCtrl", Range(0,1)) = 1
		_ScreenOutlineScale("Screen Outline Scale", Range(-1,2)) = 0
		_ScreenOutlineColor("Screen Outline Color", Color) = (0,0,0,1)

		_DissolveTex("Dissolve Texture" , 2D) = "white" {} //溶解贴图
		_DissolveTilling("Dissolve Tilling" , float) = 1
		[hdr]_DissolveRangeCol("Range Color" , Color) = (0,0,0,0)
		_DissolveThreshold("Range Threshold" , Range(0,1)) = 0
	}

	CGINCLUDE
// Upgrade NOTE: excluded shader from OpenGL ES 2.0 because it uses non-square matrices
#pragma exclude_renderers gles

#include "UnityCG.cginc"	
#include "Assets/CGInclude/LGameCharacterDgs.cginc" 

fixed4	_OutlineCol;
		half	_OutlineScale;
		//half	_ScreenOutlineScale;
		fixed4	_ScreenOutlineColor;
		half	_DepthOffset;
#if _ALPHABLEND_ON	||_DISSOLVE 
		half		_AlphaCtrl;
#endif

#if _DISSOLVE
		sampler2D   _DissolveTex;
		half		_DissolveTilling;
		half		_DissolveThreshold;
#endif

#if _ALPHABLEND_ON
		fixed4		_MainColor;
		fixed4		_SubColor;

		sampler2D	_MainTex;
#if _SUBTEX
		sampler2D	_SubTex;
		half		_SubTexLerp;
#endif
#endif


		struct a2v
		{
			float4 vertex			: POSITION;
			float4 texcoord			: TEXCOORD0;
#ifdef _USE_DIRECT_GPU_SKINNING
			half4 tangent	: TANGENT;
			float4 skinIndices : TEXCOORD2;
			float4 skinWeights : TEXCOORD3;
#else
			float3 normal	: NORMAL;
#endif
		};
		struct v2f
		{
			float4 pos	: SV_POSITION;
			float4 uv	: TEXCOORD0;
		};
		inline v2f OutlineVert(a2v v)
		{
			v2f o;
			UNITY_INITIALIZE_OUTPUT(v2f, o);
			float4 pos = v.vertex;

			float3 normal;
#if _USE_DIRECT_GPU_SKINNING

			float4 tangent;
			float3 binormal;

			DecompressTangentNormal(v.tangent, tangent, normal, binormal);
			pos = CalculateGPUSkin(v.skinIndices, v.skinWeights, v.vertex, tangent, normal, binormal);
			//pos = CalculateGPUSkin_L(v.skinIndices, v.skinWeights, v.vertex);
			//normal = v.normal;
			v.texcoord.xy = DecompressUV(v.texcoord.xy, _uvBoundData);
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

			pos = float4(TransformFromDualQuat(blendDualQuat, v.vertex), 1);
			*********************************************************************************************************************/
#else
			normal = v.normal;
#endif
			float4 vertOffset = float4(normal, 0) * _OutlineScale * 0.03;
			o.pos = UnityObjectToClipPos(pos + vertOffset);

			//固定宽度的描边
			//o.pos = UnityObjectToClipPos(pos);
			//float3 vnormal = mul((float3x3)UNITY_MATRIX_IT_MV, v.normal);
			//float2 offset = TransformViewToProjection(vnormal.xy);
			//o.pos.xy += offset * _OutlineScale*o.pos.w*0.01;

			o.uv = v.texcoord.xyxy;
#if _DISSOLVE
			o.uv.zw *= _DissolveTilling;
#endif

#if defined(UNITY_REVERSED_Z)
			o.pos.z += _DepthOffset;
#else
			o.pos.z -= _DepthOffset;
#endif

			return o;
		}
		v2f vert(a2v v)
		{
			return OutlineVert(v);
		}
		v2f vertTrans(a2v v)
		{
			return OutlineVert(v);
		}
		v2f screenOutlineVert(a2v v)
		{
			v2f o;
			UNITY_INITIALIZE_OUTPUT(v2f, o);
			//if (_ScreenOutlineScale <= 0.001)
			//{
			//	o.pos = float4 (0.0, 0.0, 0.0, 0.0);
			//	o.uv = float4 (0.0, 0.0, 0.0, 0.0);
			//}
			//else 
			//{
				float4 pos = v.vertex;
				float3 normal;
	#if _USE_DIRECT_GPU_SKINNING
				float4 tangent;
				float3 binormal;
				DecompressTangentNormal(v.tangent, tangent, normal, binormal);
				pos = CalculateGPUSkin(v.skinIndices, v.skinWeights, v.vertex, tangent, normal, binormal);
				//pos = CalculateGPUSkin_L(v.skinIndices, v.skinWeights, v.vertex);
				//normal = v.normal;
				v.texcoord.xy = DecompressUV(v.texcoord.xy, _uvBoundData);
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
				pos = float4(TransformFromDualQuat(blendDualQuat, v.vertex), 1);
				*********************************************************************************************************************/
	#else
				normal = v.normal;
	#endif
				float4 vertOffset = float4(normal, 0) * 0.043;
				o.pos = UnityObjectToClipPos(pos + vertOffset);// *_ScreenOutlineScale;

				//固定宽度的描边
				//o.pos = UnityObjectToClipPos(pos);
				//float3 vnormal = mul((float3x3)UNITY_MATRIX_IT_MV, v.normal);
				//float2 offset = TransformViewToProjection(vnormal.xy);
				//o.pos.xy += offset * _OutlineScale*o.pos.w*0.01;

				o.uv = v.texcoord.xyxy;
	#if _DISSOLVE
				o.uv.zw *= _DissolveTilling;
	#endif
	#if defined(UNITY_REVERSED_Z)
				o.pos.z += _DepthOffset;
	#else
				o.pos.z -= _DepthOffset;
	#endif
			//}

			return o;
		}
		fixed4 frag(v2f i) : SV_Target
		{
			fixed4 col = _OutlineCol;

			#if _DISSOLVE
				fixed dissolveTex = tex2D(_DissolveTex, i.uv.zw).r;
				half disValue = _DissolveThreshold * 2 - 0.5;
				fixed dissolve = step(disValue , dissolveTex);
				col.a *= dissolve;
			#endif
			#if _ALPHABLEND_ON
				fixed maina = tex2D(_MainTex, i.uv.xy).a * _MainColor.a;
				#if _SUBTEX
					fixed suba = tex2D(_SubTex, i.uv.xy).a * _SubColor.a;
					col.a *= lerp(maina , suba , _SubTexLerp);
				#else
					col.a *= maina;
				#endif
			#endif

			col.a *= 0.5;
			#if _ALPHABLEND_ON	||_DISSOLVE 
				col.a *= _AlphaCtrl;
			#endif

			return col;
		}
		fixed4 screenOutlinefrag(v2f i) : SV_Target
		{
			fixed4 col = _ScreenOutlineColor;

			#if _DISSOLVE
				fixed dissolveTex = tex2D(_DissolveTex, i.uv.zw).r;
				half disValue = _DissolveThreshold * 2 - 0.5;
				fixed dissolve = step(disValue , dissolveTex);
				col.a *= dissolve;
			#endif
			#if _ALPHABLEND_ON
				fixed maina = tex2D(_MainTex, i.uv.xy).a * _MainColor.a;
				#if _SUBTEX
					fixed suba = tex2D(_SubTex, i.uv.xy).a * _SubColor.a;
					col.a *= lerp(maina , suba , _SubTexLerp);
				#else
					col.a *= maina;
				#endif
			#endif

					col.a *= 0.5;// (0.5 * _ScreenOutlineScale);
			#if _ALPHABLEND_ON	||_DISSOLVE 
				col.a *= _AlphaCtrl;
			#endif

			return col;
		}
		ENDCG

			SubShader
		{

			Tags{ "RenderType" = "AlphaTest" "Queue" = "AlphaTest" }

				Blend SrcAlpha OneMinusSrcAlpha

			Pass
			{
				Name "CharacterOutlineSrp"
				Tags { "LightMode" = "CharacterOutlineSrp" }
				Stencil
				{
					Ref 2
					Comp NotEqual
					Pass Replace
				}
				Offset 1,1
				Cull Front

				ZWrite Off
				CGPROGRAM
				#pragma shader_feature __ _SUBTEX
				#pragma shader_feature __ _DISSOLVE _ALPHABLEND_ON 	
				#pragma multi_compile __ _USE_DIRECT_GPU_SKINNING

				#pragma vertex vert
				#pragma fragment frag
				ENDCG
			}
			
			Pass
			{
				Name "CharacterScreenOutlineSrp"
				Tags { "LightMode" = "CharacterScreenOutlineSrp" }
				Stencil
				{
					Ref 3
					Comp Greater
					Pass Replace
				}
				Offset 1,1
				Cull Front
				ZWrite Off
				CGPROGRAM

				#pragma shader_feature __ _SUBTEX
				#pragma shader_feature __ _DISSOLVE _ALPHABLEND_ON 	
				#pragma multi_compile __ _USE_DIRECT_GPU_SKINNING
				#pragma vertex screenOutlineVert
				#pragma fragment screenOutlinefrag
				ENDCG
			}
		}
	
}
