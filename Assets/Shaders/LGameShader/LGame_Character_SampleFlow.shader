// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "LGame/Character/SampleFlow"
{
	Properties
	{

		_MainColor("Color" , Color) = (1,1,1,1)//主颜色
		_MainTex("Texture", 2D) = "white" {} //主纹理
		_OffsetColor("OffsetColor", Color) = (0,0,0,1)  //色彩偏移（受击闪白之类）

		_MaskTex("Mask", 2D) = "white" {} //遮罩贴图
		_MaskCtrl("Mask Control" , Range(0,3)) = 0
		_RangeSoft("Range Soft", Range(0.01,1)) = 1 //溶解虚化范围

		_SpaceCtrl("SpaceCtrl", Range(0,1)) = 0


		_FlowlightCol("FlowlightCol" , Color) = (1,1,1,1)//特效颜色
		_FlowlightMultipliers("Flowlight Multipliers", Float) = 1 //自发光强度

		_EffectTex("Flowlight Texture", 2D) = "black" {} //特效纹理

		//_ShadowFalloff("Shadow Falloff" , Range(0.01,1)) = 0.5//阴影衰减
		[Header(Do Not Touch)]
		_AlphaCtrl("AlphaCtrl", Range(0,1)) = 1
		_OutlineCol("OutlineCol", Color) = (0,0,0,1)
		_OutlineScale("Outline Scale", Range(0,2)) = 1
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
			float4 uv2			: TEXCOORD1;

			fixed4 color : COLOR;
		};
		fixed4		_MainColor;

		sampler2D	_MainTex;
		half4		_MainTex_ST;

		fixed4		_FlowlightCol;
		half		_RangeSoft;
		sampler2D	_EffectTex;
		half4		_EffectTex_ST;
		half		_SpaceCtrl;
		sampler2D	_MaskTex;
		half4		_MaskTex_ST;

		half		_MaskCtrl;
		half		_FlowlightMultipliers;

		fixed4		_OffsetColor;

		half		_AlphaCtrl;
		v2f vert(a2v v)
		{
			v2f o;
			UNITY_INITIALIZE_OUTPUT(v2f, o);

#if _USE_DIRECT_GPU_SKINNING
			v.vertex = CalculateGPUSkin_L(v.skinIndices, v.skinWeights, v.vertex);
			v.texcoord.xy = DecompressUV(v.texcoord.xy, _uvBoundData);
#endif

			float4 pos = v.vertex;

			o.pos = UnityObjectToClipPos(pos);
			o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
			o.uv2.xy = TRANSFORM_TEX(v.texcoord, _MaskTex);
			o.uv2.zw = TRANSFORM_TEX(v.texcoord, _EffectTex);


			half4 srcPos = ComputeScreenPos(o.pos);
			o.uv.zw = (srcPos.xy / srcPos.w) * _EffectTex_ST.xy + _EffectTex_ST.zw;
			o.uv.zw = lerp(o.uv.zw, o.uv2.zw, _SpaceCtrl);
			//fixed3 worldNormal = normalize(UnityObjectToWorldNormal(v.normal));
			fixed3 worldViewDir = normalize(WorldSpaceViewDir(v.vertex));

			return o;
		}

		fixed4 frag(v2f i) : SV_Target
		{
			i.uv2.xy = clamp(float2(0,0),float2(1,1),frac(i.uv2.xy));

			fixed4 mainTex = tex2D(_MainTex, i.uv.xy) * _MainColor;
			fixed4 mask = tex2D(_MaskTex, i.uv2.xy);
			fixed4 effectCol = tex2D(_EffectTex, i.uv.zw) * _FlowlightCol * _FlowlightMultipliers;

			// 部分低端机mask有溢出情况
			half combinMask = smoothstep(_MaskCtrl  , _MaskCtrl + _RangeSoft, mask.r * effectCol.a + _RangeSoft * effectCol.a);
			fixed4 col = mainTex;
			col.rgb = lerp(mainTex.rgb, effectCol.rgb, combinMask);
			col.rgb += _OffsetColor;

			col.a *= _AlphaCtrl;
			return  col;
		}
			ENDCG

			//Base + Shadow																						   
			SubShader
		{
			Tags{ "RenderType" = "AlphaTest" "Queue" = "AlphaTest" }
				LOD 75

				//default pass
				UsePass "Hidden/Character/Shadow/CharacterShadow"
				Pass
			{
				Name "CharacterDefault"
				Tags { "LightMode" = "CharacterDefaultSrp" }
				Blend SrcAlpha OneMinusSrcAlpha
				Lighting Off
				Fog { Mode Off }
				CGPROGRAM
				#pragma multi_compile __ _USE_DIRECT_GPU_SKINNING
				#pragma vertex vert
				#pragma fragment frag	
				ENDCG
			}

				Pass
			{
				Name "CharacterDefault"
				Blend SrcAlpha OneMinusSrcAlpha
				Lighting Off
				Fog { Mode Off }
				CGPROGRAM
				#pragma multi_compile __ _USE_DIRECT_GPU_SKINNING
				#pragma vertex vert
				#pragma fragment frag	
				ENDCG
			}
				//srp pass
				UsePass "Hidden/Character/Shadow Srp/CharacterShadowSrp"
				UsePass "Hidden/Character/Shadow Srp/CharacterSoftShadowSrp"
				//UsePass "Hidden/Character/Ahri_skin01 Srp/CharacterDefaultSrp"
				UsePass "Hidden/Character/Outline Srp/CharacterOutlineSrp"
				UsePass "Hidden/Character/Outline Srp/CharacterScreenOutlineSrp"

		}


		////Base																					   
		//SubShader
		//{
		//	Tags { "RenderType"="Opaque"  "Queue"="AlphaTest" }
		//	LOD 15

		//	//default pass
		//	Pass
		//	{
		//		Name "CharacterDefault"
		//		Blend One OneMinusSrcAlpha
		//		Lighting Off
		//		Fog { Mode Off }
		//		CGPROGRAM
		//		#pragma multi_compile __ _USE_DIRECT_GPU_SKINNING
		//		#pragma vertex vert
		//		#pragma fragment frag	
		//		ENDCG
		//	}
		//	
		//	//srp pass
		//	UsePass "Hidden/Character/Ahri_skin01 Srp/CharacterDefaultSrp"
		//}
}
