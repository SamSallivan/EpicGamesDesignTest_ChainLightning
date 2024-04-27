Shader "Hidden/Character/GpuSkinnedOutlineNoDual"
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

	struct appdata_uv3_gpu_local
	{
		float4 vertex : POSITION;
		half4 uv2: TEXCOORD1;
		half4 uv3: TEXCOORD2;
		float4 normal : NORMAL;
		UNITY_VERTEX_INPUT_INSTANCE_ID
	};

	struct v2f
	{
		float4 pos : SV_POSITION;
		UNITY_VERTEX_INPUT_INSTANCE_ID
	};

	//vert with no dual
	v2f vertNoDual(appdata_uv3_gpu_local v)
	{
		v2f o;
		UNITY_SETUP_INSTANCE_ID(v);
		UNITY_TRANSFER_INSTANCE_ID(v, o);

		float posX = GpuSkinUvX();

		half4x4 mat0 = GetMatrix(posX, v.uv2.x);
		half4x4 mat1 = GetMatrix(posX, v.uv2.z);
		half4x4 mat2 = GetMatrix(posX, v.uv3.x);
		half4x4 mat3 = GetMatrix(posX, v.uv3.z);

		float4 pos = mul(mat0, v.vertex) * v.uv2.y + mul(mat1, v.vertex) * v.uv2.w + mul(mat2, v.vertex) * v.uv3.y + mul(mat3, v.vertex) * v.uv3.w;

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

	fixed4 fragNoDual(v2f i) : SV_Target
	{
		UNITY_SETUP_INSTANCE_ID(i);
		return _OutlineCol;
	}
	ENDCG

	//soldier outline with no dual																				   
	SubShader
	{

		Tags { "RenderType" = "AlphaTest" "Queue" = "AlphaTest" }
		LOD 10
		Offset 5,0
		Cull Front
		ZWrite Off
		Blend SrcAlpha OneMinusSrcAlpha

		Pass
		{
			Name "GpuSkinOutlineBase"
			Stencil
			{
				Ref 2
				ReadMask 2
				WriteMask 2
				Comp NotEqual
				Pass Replace
			}

			CGPROGRAM
			//#pragma multi_compile_instancing
			//#pragma instancing_options forcemaxcount:32
			#pragma vertex vertNoDual
			#pragma fragment fragNoDual
			ENDCG
		}
	}
}
