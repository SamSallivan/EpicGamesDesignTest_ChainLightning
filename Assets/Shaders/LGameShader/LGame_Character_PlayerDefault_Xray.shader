Shader "LGame/Character/PlayerDefault_Xray"
{																		
	Properties
	{
		[HideInInspector] _OptionMode("__OptionMode",float) = 0	
		[HideInInspector] _Mode ("__mode", Float) = 0.0
        [HideInInspector] _SrcBlend ("__src", Float) = 1.0
        [HideInInspector] _DstBlend ("__dst", Float) = 0.0
		[Enum(Off, 0, On, 1)]_ZWriteMode ("__ZWriteMode", float) = 1
		[Enum(UnityEngine.Rendering.CullMode)]_CullMode ("__CullMode", float) = 2
		[Enum(UnityEngine.Rendering.CompareFunction)]_ZTestMode ("__ZTestMode", Float) = 4

		_OffsetColor ("OffsetColor", Color) = (0,0,0,1)  //色彩偏移（受击闪白之类）
		_MainColor("Main Color" , Color) = (1,1,1,1)//染色	
		_MainTex ("Main Texture(RGBA)", 2D) = "white" {} //主纹理

		_SubColor("Sub Color" , Color) = (1,1,1,1)//染色	
		_SubTex("Sub Texture(RGBA)", 2D) = "white" {} //替换纹理
		_SubTexLerp("SubTexture Lerp", Range(0,1)) = 0 //主次纹理的插值
		[Enum(UV , 0, Screen , 1)] _SubTexMode("Sample Mode", Float) = 0.0

		_NoiseTex("Noise Texture(R)", 2D) = "white" {} //噪音纹理
		_NoiseTiling("Noise Tiling" , float) = 1
		[hdr]_EdgeColor("Edge Color" , Color) = (0,0,0,1) //溶解边缘颜色
		_EdgeWidth("Edge Width" , Range(0.01,0.5)) = 0.5 //溶解边缘宽度

		_MaskTex ("Mask (R for Metallic ,  B for Alpha , G for flowlight)", 2D) = "white" {} //遮罩贴图

		_MatCap("MatCap Texture (RGB)", 2D) = "" {} //MatCap贴图
		_MatCapColor("MatCap Color" , Color) = (1,1,1,1)//MatCap颜色
		_MatCapIntensity("MatCap Intensity", Range(0,8)) =1 //MatCap贴图强度

		[Enum(multiply, 0, Add , 1)] _RimLightBlendMode("RimlightBlendMode", int) = 0//边缘光混合模式
		_RimLightColor("RimLight Color" , Color) = (0,0,0,1) //边缘光颜色
		_RimLighRange("RimLigh Range", Range(0.1,10)) = 1 //边缘光范围
		_RimLighMultipliers ("RimLigh Multipliers", Range(0, 5)) = 0//边缘光强度

		[Enum(UV , 0, Screen , 1)] _FlowlightMode("Sample Mode", Float) = 0.0
		_FlowlightTex("Flowlight Texture" , 2D) = "" {} //自发光贴图
		_FlowlightCol("Flowlight Color", Color) = (0,0,0,1)  //自发光颜色
		_FlowlightMultipliers("Emission Multipliers", Float) =1 //自发光强度
		[Enum(multiply, 0, Add , 1,alpha,2)] _FlowLightBlendMode("BlendMode", int) = 1//流光混合模式	

		_DissolveTex("Dissolve Texture" , 2D) = "white" {} //溶解贴图
		_DissolveTilling("Dissolve Tilling" , float) = 1
		[hdr]_DissolveRangeCol("Range Color" , Color) = (0,0,0,0)
		_DissolveThreshold("Range Threshold" , Range(0,1)) = 1
		_DissolveRangeSize ("Range Size", range(0.01,0.5)) = 0.01

		_OutlineCol("OutlineCol", Color) = (0,0,0,1)
		_OutlineScale("Outline Scale", Range(0,2)) = 1
		_ScreenOutlineScale("Screen Outline Scale", Range(-1,2)) = 0
		_ScreenOutlineColor("Screen Outline Color", Color) = (0,0,0,1)

		_ShadowFalloff("Shadow Falloff" , Range(0.01,1)) = 0.5//阴影衰减

		_AlphaCtrl("AlphaCtrl", Range(0,1)) = 1
		_DepthOffset("Depth Offset", Range(-0.5,0.5)) = 0

		[header(Xray)]
		[hdr]_RimLightColor_xray("RimLight Color" , Color) = (0,0,0,1) //边缘光颜色
		_RimLighRange_xray("RimLigh Range", Range(0.1,10)) = 1 //边缘光范围

		//Add One more pass
		_GhostShadowDir_xray("GhostShadow Dir",vector)=(0,0,0,0) //残影方向
		_GhostShadowCol_xray("GhostShadow Col",Color)=(0,0,0,0) //残影颜色
	}

	//Base + Shadow + Outline																			   
	SubShader
	{
		Tags { "RenderType"="AlphaTest" "Queue"="AlphaTest" }
		LOD 75
		//Xray Pass built in
		Pass
		{
			Name "Xray"
            Blend One OneMinusSrcAlpha
			ZWrite Off
			ZTest Greater
			Lighting Off
			Fog { Mode Off }
			CGPROGRAM
			#pragma target 3.0
			#pragma multi_compile __ _USE_DIRECT_GPU_SKINNING
			#pragma vertex vert
			#pragma fragment frag	
			#include "UnityCG.cginc"
			#include "Assets/CGInclude/LGameCharacterDgs.cginc"
			struct a2v
			{
				float4 vertex	: POSITION;
				float4 texcoord	: TEXCOORD1;
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
				float4	pos			: SV_POSITION;
				half3	normal		: TEXCOORD1;
				half3	worldPos	: TEXCOORD2;
			};
			fixed4		_RimLightColor_xray;
			half		_RimLighRange_xray;
			half		_RimLighMultipliers_xray;
			v2f vert(a2v v)
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
				o.pos = UnityObjectToClipPos(pos);
				o.normal = normal;
				o.worldPos =  mul(unity_ObjectToWorld, v.vertex).xyz;
				return o;
			}
			fixed4 frag(v2f i) : SV_Target
			{
				half4 col = _RimLightColor_xray;
				fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
				fixed3 worldNormal = UnityObjectToWorldNormal(i.normal);
				half fresnel = 1 - abs(dot(worldViewDir, worldNormal));
				col.a = pow(fresnel, _RimLighRange_xray);
				col.rgb *= col.a ;
				return col;
			}
			ENDCG
		}
		//default pass
		Pass
		{
			Name "CharacterDefault"
            Blend [_SrcBlend] [_DstBlend]
			ZWrite [_ZWriteMode]
			ZTest [_ZTestMode]
			Cull [_CullMode]
			Lighting Off
			Fog { Mode Off }
			CGPROGRAM
			#pragma target 3.0
			#pragma multi_compile __ _SUBTEX
			#pragma multi_compile __ _DISSOLVE _ALPHABLEND_ON 		
			#pragma multi_compile __ _METAL 			
			#pragma multi_compile __ _RIMLIGHT
			#pragma multi_compile __ _FLOWLIGHTUV _FLOWLIGHTSCREEN
			#pragma multi_compile __ _USE_DIRECT_GPU_SKINNING
			#pragma vertex vert
			#pragma fragment frag	
			#include "Assets/CGInclude/LGameCharacter.cginc"
			#include "Assets/CGInclude/LGameCharacterDgs.cginc"
			ENDCG
		}
		//Xray Pass
		Pass
		{
			Name "CharacterMultiPass"
			Tags { "LightMode"="CharacterMultiPass" }
            Blend One OneMinusSrcAlpha
			ZWrite Off
			ZTest Greater
			Lighting Off
			Fog { Mode Off }
			CGPROGRAM
			#pragma target 3.0
			#pragma multi_compile __ _USE_DIRECT_GPU_SKINNING
			#pragma vertex vert
			#pragma fragment frag	
			#include "UnityCG.cginc"
			#include "Assets/CGInclude/LGameCharacterDgs.cginc"
			struct a2v
			{
				float4 vertex	: POSITION;
				float4 texcoord	: TEXCOORD1;
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
				float4	pos			: SV_POSITION;
				half3	normal		: TEXCOORD1;
				half3	worldPos	: TEXCOORD2;
			};
			fixed4		_RimLightColor_xray;
			half		_RimLighRange_xray;
			half		_RimLighMultipliers_xray;
			v2f vert(a2v v)
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
				o.pos = UnityObjectToClipPos(pos);
				o.normal = normal;
				o.worldPos =  mul(unity_ObjectToWorld, v.vertex).xyz;
				return o;
			}
			fixed4 frag(v2f i) : SV_Target
			{
				half4 col = _RimLightColor_xray;
				fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
				fixed3 worldNormal = UnityObjectToWorldNormal(i.normal);
				half fresnel = 1 - abs(dot(worldViewDir, worldNormal));
				col.a = pow(fresnel, _RimLighRange_xray);
				col.rgb *= col.a ;
				return col;
			}
			ENDCG
		}
		//Xray Outline Pass
		Pass
		{
			Name "XrayOutline"
			Tags { "LightMode"="ForwardBase"}
            Blend One OneMinusSrcAlpha
			ZWrite Off
			ZTest LEqual
			Cull Front
			Lighting Off
			Fog { Mode Off }
			CGPROGRAM
			#pragma target 3.0
			#pragma multi_compile __ _USE_DIRECT_GPU_SKINNING
			#pragma vertex vert
			#pragma fragment frag	
			#include "UnityCG.cginc"
			#include "Assets/CGInclude/LGameCharacterDgs.cginc"
			half		_AlphaCtrl;
			float3		_GhostShadowDir_xray;
			fixed4		_GhostShadowCol_xray;


			struct a2v
			{
				float4 vertex	: POSITION;
				float4 texcoord	: TEXCOORD1;
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
				float4	pos			: SV_POSITION;
			};
			v2f vert(a2v v)
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
					v.texcoord.xy = DecompressUV(v.texcoord.xy, _uvBoundData);
				#else
					normal = v.normal;
				#endif
				o.pos = UnityObjectToClipPos(pos);
				o.pos.xy+=_GhostShadowDir_xray.xy;
				return o;
			}
			fixed4 frag(v2f i) : SV_Target
			{
				half4 col = _GhostShadowCol_xray;
				col.a *=_AlphaCtrl;
				col.rgb*=col.a;
				return col;
			}
			ENDCG
		}
		UsePass "Hidden/Character/Shadow Srp/CharacterShadowSrp"
		UsePass "Hidden/Character/Shadow Srp/CharacterSoftShadowSrp"
		UsePass "Hidden/LGame/Character/PlayerDefault Srp/CharacterDefaultSrp"
		UsePass "Hidden/Character/Outline Srp/CharacterOutlineSrp"
		UsePass "Hidden/Character/Outline Srp/CharacterScreenOutlineSrp"
		


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
			#include "Assets/CGInclude/LGameEffect.cginc" 

			half4 fragtest(v2f i) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID(i);

				fixed4 texColor = tex2D(_MainTex, i.uvMain.xy, float2(0, 0), float2(0, 0));

				return half4(0.15,0.06,0.03, texColor.a < 0.001);
			}
			ENDCG
		}
	}

	CustomEditor"LGameCharacterHeroGUI"
}
