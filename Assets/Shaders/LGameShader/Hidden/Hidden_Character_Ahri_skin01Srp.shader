// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Hidden/Character/Ahri_skin01 Srp"
{
	Properties
	{
		
		_MainColor	("Color" , Color) = (1,1,1,1)//主颜色
		_MainTex ("Texture", 2D) = "white" {} //主纹理
		_OffsetColor ("OffsetColor", Color) = (0,0,0,1)  //色彩偏移（受击闪白之类）

		_MaskTex ("Mask", 2D) = "white" {} //遮罩贴图
		_MaskCtrl("Mask Control" , vector) = (0,0,0,0)

		_EffectCol("Effect Color" , Color) = (1,1,1,1)//特效颜色
		_EffectTex ("Effect Texture", 2D) = "black" {} //特效纹理

		[Space]
		[hdr]_RimLightColor("RimLight Color" , Color) = (0,0,0,1) //边缘光颜色
		_RimLighRange("RimLigh Range", Range(0.1,10)) = 1 //边缘光范围

		_ShadowFalloff("Shadow Falloff" , Range(0.01,1)) = 0.5//阴影衰减
		_AlphaCtrl("AlphaCtrl", Range(0,1)) = 1
		//[Toggle]_Alphablend("Transparent", float) = 1
	}

	CGINCLUDE
// Upgrade NOTE: excluded shader from OpenGL ES 2.0 because it uses non-square matrices
#pragma exclude_renderers gles
	#include "UnityCG.cginc" 
	#include "Assets/CGInclude/LGameCharacterDgs.cginc" 
	#define  _ALPHABLEND_ON

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
		float4 pos			: SV_POSITION;
		float4 uv			: TEXCOORD0;
		fixed4 color		: COLOR;
	};
	fixed4		_MainColor;

	sampler2D	_MainTex;
	half4		_MainTex_ST;

	fixed4		_EffectCol;
	sampler2D	_EffectTex;
	half4		_EffectTex_ST;

	sampler2D	_MaskTex;
	half4		_MaskCtrl;

	fixed4		_RimLightColor;
	half		_RimLighRange ;

	fixed4		_OffsetColor;		  

	half		_AlphaCtrl;
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

		half4 srcPos = ComputeScreenPos(o.pos);
		o.uv.zw = (srcPos.xy /srcPos.w)* _EffectTex_ST.xy + frac(_EffectTex_ST.zw * _Time.y); 
				
		fixed3 worldNormal = normalize(UnityObjectToWorldNormal(v.normal));
		fixed3 worldViewDir = normalize(WorldSpaceViewDir(v.vertex));
				
		//顶点边缘光
		half fresnel = 1-max(0.01, dot(worldViewDir, worldNormal)) ;
		fresnel = max(0.01, fresnel);
		o.color = pow(fresnel, _RimLighRange) ;

		return o;
	}

	fixed4 frag (v2f i) : SV_Target
	{
		fixed4 mainTex = tex2D(_MainTex, i.uv.xy) * _MainColor;
		fixed4 mask = tex2D(_MaskTex, i.uv.xy) * _MaskCtrl; 
		fixed4 effectCol = tex2D(_EffectTex, i.uv.zw) * _EffectCol;
		

		fixed4 col = lerp(lerp(effectCol , _RimLightColor , i.color)  , mainTex , mask.r + mask.g + mask.b + mask.a) ;
		col.rgb += _OffsetColor ;

		col.a *= _AlphaCtrl;
		col.rgb *= col.a;
		return  col;
		}
	ENDCG
																					   
	SubShader
	{
		Tags { "RenderType"="Opaque" "LightMode" = "CharacterDefaultSrp" "Queue"="AlphaTest" }

		//基础Pass
		Pass
		{
			Name "CharacterDefaultSrp"
			Tags { "LightMode" = "CharacterDefaultSrp" }
			Blend One OneMinusSrcAlpha
			Lighting Off
			Fog { Mode Off }
			CGPROGRAM
			#pragma multi_compile __ _USE_DIRECT_GPU_SKINNING

			#pragma vertex vert
			#pragma fragment frag	

			ENDCG
		}
		
		
	}

}
