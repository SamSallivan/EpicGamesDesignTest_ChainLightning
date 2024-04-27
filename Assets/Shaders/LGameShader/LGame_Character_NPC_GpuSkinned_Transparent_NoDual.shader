// Upgrade NOTE: upgraded instancing buffer 'character' to new syntax.

Shader "LGame/Character/NPC_GpuSkinned_Transparent_Nodual"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_AnimMap ("AnimMap", 2D) ="white" {}
		_AnimTime("Anim Time", Float) = 0	//动画开始时间，相对于 sinceLevelLoad
		_PauseTime("Pause Time", Float) = 0 //动画暂停 -1 为不暂停，》=0 时 为暂停时的时间
		_PlayVector("Play Info", Vector) = (0,0,0,0)
		_OffsetColor ("OffsetColor", Color) = (0.0,0.0, 0.0,1.0) //色彩偏移（受击闪白之类）
		_AlphaCtrl("Alpha control", Range(0,1)) = 1
		_ShadowFalloff("Shadow Falloff" , Range(0.01,1)) = 1//阴影衰减
		_OutlineCol("OutlineCol", Color) = (0,0,0,1)     //outline color
		_OutlineScale("Outline Scale", Range(0,2)) = 1   //outline scale

		//scan mat
		_Color1("Color1" , Color) = (0.313,0,0,1)
		_Color2("Color2" , Color) = (0.431,0,0,1)
		_Speed("Speed" , float) = 2
		_MaxScale("Max Scale" , Range(0,4)) = 1.1
	}
	CGINCLUDE
	#include "UnityCG.cginc" 
	#include "Assets/CGInclude/LGameCG.cginc"
	#include "Assets/CGInclude/GpuAnim.cginc"

	struct v2f
	{
		half2 uv : TEXCOORD0;
		float4 pos : SV_POSITION;
#if _SCAN_MAT_ON
		fixed4 col : COLOR;
#endif
		UNITY_VERTEX_INPUT_INSTANCE_ID
	};

	sampler2D	_MainTex;
	sampler2D	_MaskTex;
	half4		_MainTex_ST;
#if _SCAN_MAT_ON
	fixed4 	_Color1;
	fixed4 	_Color2;
	half	_Speed;
	half	_MaxScale;
#endif

	UNITY_INSTANCING_BUFFER_START (character)
		UNITY_DEFINE_INSTANCED_PROP (fixed4, _OffsetColor)
#define _OffsetColor_arr character
		UNITY_DEFINE_INSTANCED_PROP (half, _AlphaCtrl)
#define _AlphaCtrl_arr character
	UNITY_INSTANCING_BUFFER_END(character)

	v2f vert (appdata_uv3_gpu v)
	{
		v2f o;
		UNITY_SETUP_INSTANCE_ID(v);
		UNITY_TRANSFER_INSTANCE_ID( v , o);

		float posX = GpuSkinUvX();

		half4x4 mat0 = GetMatrix(posX, v.uv2.x);
		half4x4 mat1 = GetMatrix(posX, v.uv2.z);
		half4x4 mat2 = GetMatrix(posX, v.uv3.x);
		half4x4 mat3 = GetMatrix(posX, v.uv3.z);

		float4 pos = mul(mat0, v.vertex) * v.uv2.y + mul(mat1, v.vertex) * v.uv2.w + mul(mat2, v.vertex) * v.uv3.y + mul(mat3, v.vertex) * v.uv3.w;

		/*half2x4 q0 = GetDualQuat(posX, v.uv2.x);
		half2x4 q1 = GetDualQuat(posX, v.uv2.z);

		half2x4 blendDualQuat = q0 * v.uv2.y;
		if (dot(q0[0], q1[0]) > 0)
			blendDualQuat += q1 * v.uv2.w;
		else
			blendDualQuat -= q1 * v.uv2.w;

		blendDualQuat = NormalizeDualQuat(blendDualQuat);

		float4 pos = float4(TransformFromDualQuat(blendDualQuat, v.vertex), 1);*/
#if _SCAN_MAT_ON
		half weight = abs(frac(_Time.y * _Speed) - 0.5) * 2;//sin(_Time.y * _Speed) * 0.5 + 0.5;
		pos.xyz *= lerp(1, _MaxScale, weight);
		o.pos = UnityObjectToClipPos(pos);
		o.col = lerp(_Color1, _Color2, weight);
#else
       	o.pos = UnityObjectToClipPos(pos);
		o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);				
#endif
		return o;
	}	

	fixed4 frag (v2f i) : SV_Target
	{
		UNITY_SETUP_INSTANCE_ID(i);
#if _SCAN_MAT_ON
	return i.col;
#else
		fixed4 mainTex = tex2D(_MainTex, i.uv);

		half3 col = mainTex.rgb + UNITY_ACCESS_INSTANCED_PROP (_OffsetColor_arr, _OffsetColor);

		return fixed4(col , UNITY_ACCESS_INSTANCED_PROP(_AlphaCtrl_arr, _AlphaCtrl)) ;
#endif
	}
	ENDCG

	//高质量（Base + Shadow + Outline）
	SubShader
	{
		Tags { "RenderType"="Transparent"  "Queue"="Transparent" }
		LOD 75
		Blend SrcAlpha OneMinusSrcAlpha
		
		//default pass
		UsePass "LGame/Character/Shadow_GpuSkinned_Nodual/Shadow"
		Pass
		{
			Name "NPCGpuSkinned"
			Lighting Off
			//ZTest Always
			//ZWrite Off
			Fog { Mode Off }
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			//#pragma multi_compile_instancing
			//#pragma instancing_options forcemaxcount:32
			#pragma multi_compile __ _SCAN_MAT_ON

			ENDCG
		}
		UsePass "Hidden/Character/GpuSkinnedOutlineNoDual/GpuSkinOutlineBase"

		//srp pass
		UsePass "LGame/Character/Shadow_GpuSkinned_Nodual Srp/CharacterShadowSrp"
		UsePass "LGame/Character/Shadow_GpuSkinned_Nodual Srp/Shadow"
		UsePass "Hidden/LGame/Character/NPC_GpuSkinned_Transparent_Nodual Srp/NPCGpuSkinnedTransParentNoDualDefault"
		UsePass "Hidden/Character/GpuSkinnedOutlineNoDual Srp/GpuSkinOutlineBase"

	}

	//高质量（Base + Shadow）
	//SubShader
	//{
	//	Tags { "RenderType"="Transparent"  "Queue"="Transparent" }
	//	LOD 70
	//	Blend SrcAlpha OneMinusSrcAlpha
 //       
	//	//default pass
	//	UsePass "LGame/Character/Shadow_GpuSkinned_Nodual/Shadow"
	//	Pass
	//	{
	//		Name "NPCGpuSkinned"
	//		Lighting Off
	//		//ZTest Always
	//		//ZWrite Off
	//		Fog { Mode Off }
	//		CGPROGRAM
	//		#pragma vertex vert
	//		#pragma fragment frag
	//		//#pragma multi_compile_instancing
	//		//#pragma instancing_options forcemaxcount:32
	//		#pragma multi_compile __ _SCAN_MAT_ON

	//		ENDCG
	//	}
	//	
	//	//srp pass
	//	UsePass "LGame/Character/Shadow_GpuSkinned_Nodual Srp/Shadow"
	//	UsePass "Hidden/LGame/Character/NPC_GpuSkinned_Transparent_Nodual Srp/NPCGpuSkinnedTransParentNoDualDefault"

	//}

	////低质量（Base + Outline）
	//SubShader
	//{
	//	Tags { "RenderType"="Transparent" "Queue"="Transparent" }
	//	LOD 15
	//	Blend SrcAlpha OneMinusSrcAlpha
	//	
	//	//default pass
	//	Pass
	//	{
	//		Name "NPCGpuSkinned"
	//		Lighting Off
	//		Fog { Mode Off }
	//		CGPROGRAM
	//		#pragma vertex vert
	//		#pragma fragment frag
	//		//#pragma multi_compile_instancing
	//		//#pragma instancing_options forcemaxcount:32
	//		#pragma multi_compile __ _SCAN_MAT_ON

	//		ENDCG
	//	}
	//	UsePass "Hidden/Character/GpuSkinnedOutlineNoDual/GpuSkinOutlineBase"

	//	//srp pass
	//	UsePass "Hidden/LGame/Character/NPC_GpuSkinned_Transparent_Nodual Srp/NPCGpuSkinnedTransParentNoDualDefault"
	//	UsePass "LGame/Character/Shadow_GpuSkinned_Nodual Srp/SoftShadow"
	//	UsePass "Hidden/Character/GpuSkinnedOutlineNoDual Srp/GpuSkinOutlineBase"
	//}
 	//低质量（Base）
	//SubShader
	//{
	//	Tags { "RenderType"="Transparent"  "Queue"="Transparent" }
	//	LOD 10
	//	Blend SrcAlpha OneMinusSrcAlpha
	//	
	//	//default pass
	//	Pass
	//	{
	//		Name "NPCGpuSkinned"
	//		Lighting Off
	//		Fog { Mode Off }
	//		CGPROGRAM
	//		#pragma vertex vert
	//		#pragma fragment frag
	//		//#pragma multi_compile_instancing
	//		//#pragma instancing_options forcemaxcount:32
	//		#pragma multi_compile __ _SCAN_MAT_ON

	//		ENDCG
	//	}

	//	//srp pass
	//	UsePass "Hidden/LGame/Character/NPC_GpuSkinned_Transparent_Nodual Srp/NPCGpuSkinnedTransParentNoDualDefault"
	//	UsePass "LGame/Character/Shadow_GpuSkinned_Nodual Srp/SoftShadow"
	//}

	//描边后处理
	//SubShader
	//{
	//	Tags { "RenderType"="Opaque"}
	//	LOD 1
	//	
	//	UsePass "Hide/GpuSkinned/MeshAlpha/BASE"
	//}
}
