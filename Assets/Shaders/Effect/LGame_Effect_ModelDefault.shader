Shader "LGame/Effect/ModelDefault"
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
		[hdr]_MainColor("Main Color" , Color) = (1,1,1,1)//染色	
		_MainTex ("Main Texture(RGBA)", 2D) = "white" {} //主纹理

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
		_DissolveThreshold("Range Threshold" , Range(0,1)) = 0
		_DissolveRangeSize ("Range Size", range(0.01,0.5)) = 0

		_OutlineCol("OutlineCol", Color) = (0,0,0,1)
		_OutlineScale("Outline Scale", Range(0,2)) = 1

		_ShadowFalloff("Shadow Falloff" , Range(0.01,1)) = 0.5//阴影衰减

		_AlphaCtrl("AlphaCtrl", Range(0,1)) = 1
		_DepthOffset("Depth Offset", Range(-0.5,0.5)) = 0
		
		[Toggle] _IsDissolveSecond ("Is DissolveSecond?", Int) = 0  // 溶解世界反向（比如铁男大招  半径内半径外通过该参数取反 或者两个效果溶解切换的表现）

		[Enum(VRSDefault,0,VRS1x1,1,VRS1x2,2,VRS2x1,3,VRS2x2,4,VRS4x2,5,VRS4x4,6)] _ShadingRate("Fragment Shading Rate", Float) = 0
	}


	//Base + Shadow + Outline																			   
	SubShader
	{
		Tags { "RenderType"="AlphaTest" "Queue"="AlphaTest" }
		// ShadingRate[_ShadingRate]
		LOD 75
		//Base Pass
		Pass
		{
			Name "ForwardBase"
			Tags { "LightMode" = "ForwardBase" }

            Blend [_SrcBlend] [_DstBlend]
			ZWrite [_ZWriteMode]
			ZTest [_ZTestMode]
			Cull [_CullMode]
			Lighting Off
			Fog { Mode Off }
			CGPROGRAM
			#pragma target 3.0
			
			#pragma shader_feature __ _DISSOLVE _ALPHABLEND_ON 		
			#pragma shader_feature __ _METAL 			
			#pragma multi_compile __ _RIMLIGHT
			#pragma shader_feature __ _FLOWLIGHTUV _FLOWLIGHTSCREEN 
			#pragma multi_compile __ _USE_DIRECT_GPU_SKINNING
			#pragma multi_compile __ _FOW_ON_CUSTOM
			#pragma multi_compile __ _ENABLE_DISSOLVE_WORLD
			
			#pragma vertex vert
			#pragma fragment frag
			#define LGAME_USEFOW
			#define LGAME_DISSOLVE_WORLD
			#include "Assets/CGInclude/LGameCharacter.cginc"
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
