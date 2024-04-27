Shader "Hidden/Character/Shadow"
{
	Properties
	{
        //_ShadowFalloff("Shadow Falloff" , Range(0.01,1)) = 1//阴影衰减
		_MainColor("Main Color" , Color) = (1,1,1,1)//染色	
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

		half4 		_LightPos;
		fixed4 		_ShadowColor;
		//half 		_ShadowFalloff;
		fixed4		_MainColor;
		#if _ALPHABLEND_ON || _DISSOLVE
			half		_AlphaCtrl;
		#endif

		#if _DISSOLVE
			sampler2D   _DissolveTex;
			half		_DissolveTilling;
			half		_DissolveThreshold;
		#endif
		struct a2v
		{
			float4 vertex : POSITION;
			#if _DISSOLVE
				float4 texcoord : TEXCOORD0;
			#endif
			#ifdef _USE_DIRECT_GPU_SKINNING
				float4 skinIndices : TEXCOORD2;
				float4 skinWeights : TEXCOORD3;
			#endif
		};

		struct v2f
		{
			float4 vertex		: SV_POSITION;
		    fixed4 color		: COLOR;
			#if _DISSOLVE
				half2	uv		: TEXCOORD0;
			#endif
		};

		inline v2f ShadowVert(a2v v)
		 {
		    v2f o;
			UNITY_INITIALIZE_OUTPUT(v2f , o);
			float4 pos = v.vertex;

#if _USE_DIRECT_GPU_SKINNING
		   
		   pos = CalculateGPUSkin_L(v.skinIndices, v.skinWeights, v.vertex);

#if _DISSOLVE
		   v.texcoord.xy = DecompressUV(v.texcoord.xy, _uvBoundData);
#endif
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

			//得到阴影的世界空间坐标
		    float3 worldPos = mul(unity_ObjectToWorld , pos).xyz;
        
		    //灯光方向
		    fixed3 lightDir = normalize(_LightPos.xyz);

		    //阴影的世界空间坐标
			float3 shadowPos;
		    shadowPos.y = min(worldPos.y , _LightPos.w);
			shadowPos.xz = worldPos.xz - lightDir.xz * max(0 , worldPos.y - _LightPos.w) / lightDir.y; 

			//转换到裁切空间												 
			o.vertex = UnityWorldToClipPos(shadowPos);

			//得到中心点世界坐标
			//half2 localDir =  _ShadowFalloff * half2(shadowPos.x - unity_ObjectToWorld[0].w, shadowPos.z - unity_ObjectToWorld[2].w);

			//计算阴影衰减
			//half falloff = 1-dot(localDir , localDir); 
			#if _DISSOLVE
				o.uv = v.texcoord.xy * _DissolveTilling;
			#endif
			//o.color.a = _ShadowColor.a * falloff * _MainColor.a;
			o.color.a = _ShadowColor.a * _MainColor.a;
			#if _ALPHABLEND_ON || _DISSOLVE
				o.color.a *= _AlphaCtrl ;
			#endif
			return o;
		}
		v2f vert (a2v v)
		{
			return ShadowVert(v );
		}
		v2f vertTrans (a2v v)
		{
			return ShadowVert(v);
		}
		fixed4 frag (v2f i) : SV_Target
		{
			fixed4 col = i.color;
			#if _DISSOLVE
				fixed dissolveTex = tex2D(_DissolveTex, i.uv).r; 	
				half disValue =  _DissolveThreshold * 2 -0.5;
				fixed dissolve =  smoothstep(disValue- 0.05 ,disValue+ 0.05 ,dissolveTex);
				col.a *= dissolve;
			#endif

			col.rgb = lerp(half3(1,1,1) , col.rgb ,col.a);
			return col;
		}

	ENDCG
	SubShader
	{
		Tags { "Queue"="AlphaTest" "RenderType"="AlphaTest" }

		Blend DstColor Zero
        ZWrite off
        Offset -1 , 0
        //阴影pass
		Pass
		{
            Name "CharacterShadow"
            Stencil
            {
                Ref 1
                Comp NotEqual
                Pass Replace
            }
			CGPROGRAM
			#pragma shader_feature __ _DISSOLVE _ALPHABLEND_ON 	
			#pragma multi_compile __ _USE_DIRECT_GPU_SKINNING

			#pragma vertex vert
			#pragma fragment frag
			ENDCG
		}
	}
}
