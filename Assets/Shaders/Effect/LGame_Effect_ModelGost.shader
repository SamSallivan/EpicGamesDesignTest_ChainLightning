
Shader "LGame/Effect/Model Gost"
{
	Properties
	{
		[HideInInspector][Enum(UnityEngine.Rendering.BlendMode)] 		_SrcFactor ("SrcFactor()", Float) = 5
		[HideInInspector][Enum(UnityEngine.Rendering.BlendMode)] 		_DstFactor ("DstFactor()", Float) = 10
		_Color	("Color" , Color) = (1,1,1,1)//主颜色
		_NoiseTex("Noise Texture" , 2D) = ""{}
		_AlphaCtrl("Alpha control", Range(0,1)) = 1
	}

	//高质量（带动态阴影）																				   
	SubShader
	{
		Tags { "RenderType"="Transparent" "LightMode"="ForwardBase" "Queue"="Transparent" }
		LOD 75

		//基础Pass
		Pass
		{
			Name "ForwardBase"
			ZWrite Off
			Lighting Off
			Fog { Mode Off }
			Blend [_SrcFactor] [_DstFactor]
			CGPROGRAM
			// Upgrade NOTE: excluded shader from OpenGL ES 2.0 because it uses non-square matrices
			#pragma exclude_renderers gles
			#pragma multi_compile __ _USE_DIRECT_GPU_SKINNING

			#pragma vertex vert
			#pragma fragment frag	

			#include "UnityCG.cginc" 
			#include "Assets/CGInclude/LGameCharacterDgs.cginc" 

			struct appdata
			{
				float4	vertex		: POSITION;
				float2	uv			: TEXCOORD0;
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

			fixed4		_Color;
			sampler2D	_NoiseTex;
			half4		_NoiseTex_ST;
	  		half		_AlphaCtrl;


			v2f vert (appdata v)
			{
				v2f o;
				float4 pos = v.vertex;
#if _USE_DIRECT_GPU_SKINNING 
				
				pos = CalculateGPUSkin_L(v.skinIndices, v.skinWeights, v.vertex);
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

				pos = float4(TransformFromDualQuat(blendDualQuat, v.vertex), 1);
				*********************************************************************************************************************/
#endif
				o.pos = UnityObjectToClipPos(pos);
				o.uv = v.uv * _NoiseTex_ST.xy + frac( _NoiseTex_ST.zw * _Time.y) ; 
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{

				fixed4 flowLightCol = tex2D(_NoiseTex, i.uv.xy ) * _Color;
				flowLightCol.rgb *= flowLightCol.a;

				return  flowLightCol * _AlphaCtrl;
			}
			ENDCG
		}
		
		
	}

}