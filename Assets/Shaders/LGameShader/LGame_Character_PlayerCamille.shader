Shader "LGame/Character/Player Camille"
{
	Properties
	{
		_Color	("Color" , Color) = (1,1,1,1)//主颜色
		_MainTex ("Texture", 2D) = "white" {} //主纹理
		_FxColor ("Fx Color" , Color) = (0,0,0,1)//主颜色
		_FxMultiplier("Fx Multipliers", Range(0, 8)) = 1
		_FxControl("Fx Control" , Range(0,1)) = 0

	}

	CGINCLUDE
// Upgrade NOTE: excluded shader from OpenGL ES 2.0 because it uses non-square matrices
#pragma exclude_renderers gles
	#include "UnityCG.cginc" 
	#include "Assets/CGInclude/LGameCharacterDgs.cginc" 
	fixed4		_Color;
	fixed4		_FxColor;
	sampler2D	_MainTex;
	half4		_MainTex_ST;

	half		_FxControl;
	half		_FxMultiplier;

	struct a2v
	{
		float4 vertex : POSITION;
		half2 texcoord : TEXCOORD0;
#ifdef _USE_DIRECT_GPU_SKINNING
		float4 skinIndices : TEXCOORD2;
		float4 skinWeights : TEXCOORD3;
#endif
	};

	struct v2f
	{
		float4	pos			: SV_POSITION;
		float2	uv			: TEXCOORD0;
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
		return o;
	}
		
	fixed4 frag (v2f i) : SV_Target
	{
		half4 mainTex = tex2D(_MainTex, i.uv.xy) * _Color;

		half4 col = lerp(mainTex , mainTex *   fixed4(_FxColor.rgb * _FxMultiplier, 0)  , _FxControl);
		return  col ;
	}										   

 	ENDCG
	//高质量（带动态阴影）																				   
	SubShader
	{
		Tags { "RenderType"="Opaque" "LightMode"="ForwardBase" "Queue"="AlphaTest" }
		LOD 10
		 //ZWrite Off
		 Cull Off

		//基础Pass
		Pass
		{
			Blend One OneMinusSrcAlpha
			Name "ForwardBase"
			Lighting Off
			Fog { Mode Off }
			CGPROGRAM
            #pragma target 3.0
			#pragma multi_compile __ _USE_DIRECT_GPU_SKINNING

			#pragma vertex vert
			#pragma fragment frag	
            

			ENDCG
		}
		
		
	}
	SubShader
	{
			Tags { "Queue" = "Transparent" "LightMode" = "ForwardBase" "IgnoreProjector" = "True" "RenderType" = "Transparent"}
			LOD 5
			Blend One One
			ZWrite[_ZWriteMode]
			ZTest[_ZTestMode]
			Cull[_CullMode]

				Pass
				{
					CGPROGRAM
					#pragma vertex vert
					#pragma fragment fragtest
					//#pragma multi_compile_instancing
					//#include "Assets/CGInclude/LGameEffect.cginc" 

					half4 fragtest(v2f i) : SV_Target
					{
						UNITY_SETUP_INSTANCE_ID(i);

						fixed4 texColor = tex2D(_MainTex, i.uv.xy, float2(0, 0), float2(0, 0));

						return half4(0.15,0.06,0.03, texColor.a < 0.001);
					}
					ENDCG
				}
	}
}
