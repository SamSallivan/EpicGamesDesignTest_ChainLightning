// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "LGame/Character/Player CamilleHitFx"
{
	Properties
	{
		_Color	("Color" , Color) = (1,1,1,1)//主颜色
		_MainTex ("Texture", 2D) = "white" {} //主纹理
		_RimLightColor("RimLight Color" , Color) = (0,0,0,1) //边缘光颜色
		_RimLighRange("RimLigh Range", Range(0.1,10)) = 1 //边缘光范围
		_RimLighMultipliers ("RimLigh Multipliers", Range(0, 5)) = 1//边缘光强度
		_ShadowFalloff("Shadow Falloff" , Range(0.01,1)) = 1//阴影衰减

	}

	CGINCLUDE
// Upgrade NOTE: excluded shader from OpenGL ES 2.0 because it uses non-square matrices
#pragma exclude_renderers gles
	#include "UnityCG.cginc" 
	#include "Assets/CGInclude/LGameCG.cginc"
	#include "Assets/CGInclude/LGameCharacterDgs.cginc" 
	fixed4		_Color;
	sampler2D	_MainTex;
	half4		_MainTex_ST;

	struct a2v {
		float4 vertex : POSITION; 
		float3 normal : NORMAL;
		float4 texcoord : TEXCOORD0;
#ifdef _USE_DIRECT_GPU_SKINNING
		float4 skinIndices : TEXCOORD2;
		float4 skinWeights : TEXCOORD3;
#endif
	};

	struct v2f
	{
		float4	pos			: SV_POSITION;
		float2	uv			: TEXCOORD0;
		fixed3 rim			: COLOR;
	};

	v2f vert (a2v v)
	{
		v2f o;
		UNITY_INITIALIZE_OUTPUT(v2f, o);
		float4 pos = v.vertex;

#if _USE_DIRECT_GPU_SKINNING
		
	   pos = CalculateGPUSkin_L(v.skinIndices, v.skinWeights, v.vertex);
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
#endif

		o.pos = UnityObjectToClipPos(pos);
		o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
		// 计算边缘光
		fixed3 viewDir = normalize(WorldSpaceViewDir(v.vertex));
		fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
		o.rim = GetRimLight(worldNormal, viewDir);
		return o;
	}
		
	fixed4 frag (v2f i) : SV_Target
	{
		half4 col = tex2D(_MainTex, i.uv.xy) * _Color;
		col.rgb += i.rim;
		return  col ;
	}										   

 	ENDCG
	//高质量（带动态阴影）																				   
	SubShader
	{
		Tags { "RenderType"="Opaque" "Queue"="AlphaTest" }
		LOD 75
		 //ZWrite Off
		 Cull Back
		//实时阴影Pass
		//UsePass "Hidden/Character/Shadow/BASE"


		//基础Pass
		Pass
		{
			Blend SrcAlpha One
			Name "ForwardBase"
			Lighting Off
			Fog { Mode Off }
			CGPROGRAM
			#pragma multi_compile __ _USE_DIRECT_GPU_SKINNING

			#pragma vertex vert
			#pragma fragment frag	


			ENDCG
		}
		
		
	}
	////高质量（无动态阴影）
	//SubShader
	//{
	//	Tags { "RenderType"="Opaque" "LightMode"="ForwardBase" "Queue"="AlphaTest" }
	//	LOD 70

	//	//基础Pass
	//	Pass
	//	{
	//		Name "ForwardBase"
	//		Lighting Off
	//		Fog { Mode Off }
	//		CGPROGRAM
	//		#pragma multi_compile __ _USE_DIRECT_GPU_SKINNING

	//		#pragma vertex vert
	//		#pragma fragment frag	

	//		ENDCG
	//	}
	//	
	//}
	//中质量
	//SubShader
	//{
	//	Tags { "RenderType"="Opaque" "LightMode"="ForwardBase" "Queue"="AlphaTest" }
	//	LOD 40
	//	//基础Pass
	//	Pass
	//	{
	//		Name "ForwardBase"
	//		Lighting Off
	//		Fog { Mode Off }
	//		CGPROGRAM
	//		#pragma multi_compile __ _USE_DIRECT_GPU_SKINNING

	//		#pragma vertex vert
	//		#pragma fragment frag	

	//		ENDCG
	//	}
	//}
	//低质量 （带动态阴影）
	SubShader
	{
		Tags { "RenderType"="Opaque" "LightMode"="ForwardBase" "Queue"="AlphaTest" }
		LOD 15
		//实时阴影Pass
		//UsePass "Hidden/Character/Shadow/BASE"
		//基础Pass
		Pass
		{
			Name "ForwardBase"
			Lighting Off
			Fog { Mode Off }
			CGPROGRAM
			#pragma multi_compile __ _USE_DIRECT_GPU_SKINNING

			#pragma vertex vert
			#pragma fragment frag	

			ENDCG
		}	
	}
	//低质量 （无动态阴影）
	//SubShader
	//{
	//	Tags { "RenderType"="Opaque" "LightMode"="ForwardBase" "Queue"="AlphaTest" }
	//	LOD 10
	//	//基础Pass
	//	Pass
	//	{
	//		Name "ForwardBase"
	//		Lighting Off
	//		Fog { Mode Off }
	//		CGPROGRAM
	//		#pragma multi_compile __ _USE_DIRECT_GPU_SKINNING

	//		#pragma vertex vert
	//		#pragma fragment frag	
	//		ENDCG
	//	}
	//	
	//	
	//}
}
