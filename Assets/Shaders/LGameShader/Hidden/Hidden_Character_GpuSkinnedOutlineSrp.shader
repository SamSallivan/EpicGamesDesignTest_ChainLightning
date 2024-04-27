Shader "Hidden/Character/GpuSkinnedOutline Srp"
{
	Properties
	{
		_OutlineCol("OutlineCol", Color) = (0,0,0,1)
		_OutlineScale("Outline Scale", Range(0,1)) = 0.03
	}

		CGINCLUDE
#include "UnityCG.cginc" 
#include "Assets/CGInclude/LGameCG.cginc"
#include "Assets/CGInclude/GpuAnim.cginc"

	fixed4	_OutlineCol;
	half	_OutlineScale;
	half	_DepthOffset;

	struct appdata_uv2_gpu_local
	{
		float4 vertex : POSITION;
		half4 uv2: TEXCOORD1;
		float4 normal : NORMAL;
		UNITY_VERTEX_INPUT_INSTANCE_ID
	};

	struct v2f
	{
		float4 pos : SV_POSITION;
		UNITY_VERTEX_INPUT_INSTANCE_ID
	};

	//vert with dual
	v2f vert(appdata_uv2_gpu_local v)
	{
		v2f o;
		UNITY_SETUP_INSTANCE_ID(v);
		UNITY_TRANSFER_INSTANCE_ID(v, o);

		float posX = GpuSkinUvX();

		half2x4 q0 = GetDualQuat(posX, v.uv2.x);
		half2x4 q1 = GetDualQuat(posX, v.uv2.z);

		half2x4 blendDualQuat = q0 * v.uv2.y;
		if (dot(q0[0], q1[0]) > 0)
			blendDualQuat += q1 * v.uv2.w;
		else
			blendDualQuat -= q1 * v.uv2.w;

		blendDualQuat = NormalizeDualQuat(blendDualQuat);

		float4 pos = float4(TransformFromDualQuat(blendDualQuat, v.vertex), 1);

		o.pos = UnityObjectToClipPos(pos);
		//将法线方向转换到视空间
		float3 vnormal = mul((float3x3)UNITY_MATRIX_IT_MV, normalize(v.normal));
		//将视空间法线xy坐标转化到投影空间，只有xy需要，z深度不需要了
		float2 offset = TransformViewToProjection(vnormal.xy) *0.03;
		//在最终投影阶段输出进行偏移操作
		o.pos.xy += offset * _OutlineScale;

#if defined(UNITY_REVERSED_Z)
		o.pos.z += _DepthOffset;
#else
		o.pos.z -= _DepthOffset;
#endif

		return o;
	}

	fixed4 frag(v2f i) : SV_Target
	{
		UNITY_SETUP_INSTANCE_ID(i);
		return _OutlineCol;
	}

	ENDCG

		//soldier outline with dual																				   
	SubShader
	{

		Tags{ "RenderType" = "AlphaTest" "LightMode" = "CharacterOutlineSrp" "Queue" = "AlphaTest" }
			LOD 10
			Offset 5, 0
			Cull Front
			ZWrite Off
			Blend SrcAlpha OneMinusSrcAlpha

			Pass
		{
			Name "GpuSkinOutlineBase"
			Tags{"LightMode" = "CharacterOutlineSrp"}
			Stencil
			{
				Ref 2
				ReadMask 2
				WriteMask 2
				Comp NotEqual
				Pass Replace
			}

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			ENDCG
		}
	}
}
