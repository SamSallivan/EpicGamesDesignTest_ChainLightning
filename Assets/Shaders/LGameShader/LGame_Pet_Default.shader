Shader "LGame/Pet/Default"
{
	Properties
	{
		[Header(Main Maps)]
		_MainTex ("Main Texture", 2D) = "white" {}
		_MainColor("Main Color" , Color) = (1,1,1,1)//染色	
		[Toggle] _CombinedTex ("Is _MainTex combined?", Int) = 0

		[Space]
		[Toggle(_RIMLIGHT)] _Rimlight ("Rimlight", float) = 0
		[HideIfDisabled(_RIMLIGHT)]_RimLightColor("RimLight Color" , Color) = (0,0,0,1) //边缘光颜色
		[HideIfDisabled(_RIMLIGHT)]_RimLighRange("RimLight Range", Range(0.1,10)) = 1 //边缘光范围
		[HideIfDisabled(_RIMLIGHT)]_RimLighMultipliers ("RimLight Multipliers", Range(0, 5)) = 0//边缘光强度
		[HideIfDisabledEnum(_RIMLIGHT, multiply, 0, Add , 1)] _RimLightBlendMode("Rimlight BlendMode", int) = 0//边缘光混合模式

		[Space]
		[SimpleToggle] _FlowlightToggle ("Flowlight", float) = 0
		[Enum(UV, 0, Screen , 1)] _Flowlight ("Sample Mode", Float) = 0.0
		[HideOnFloat(_FlowlightToggle, 0, Flowlight)] _FlowlightTex("Flowlight Texture" , 2D) = "" {} //自发光贴图
		[HideOnFloat(_FlowlightToggle, 0, Flowlight)] _FlowlightCol("Flowlight Color", Color) = (0,0,0,1)  //自发光颜色
		[HideOnFloat(_FlowlightToggle, 0, Flowlight)] _FlowlightMultipliers("Flowlight Multipliers", Float) =1 //自发光强度
		[HideIfDisabledEnum(_FLOWLIGHTUV._FLOWLIGHTSCREEN, multiply, 0, Add, 1, alpha,2)] _FlowLightBlendMode("Flowlight BlendMode", int) = 1//流光混合模式
		
		[Space]
		[Header(Outline)]
		_OutlineCol("OutlineCol", Color) = (0,0,0,1)
		_OutlineScale("Outline Scale", Range(0,1)) = 0.03
		_ScreenOutlineScale("Screen Outline Scale", Range(-1,2)) = 0
		_ScreenOutlineColor("Screen Outline Color", Color) = (0,0,0,1)
		
		[Space]
		[Header(Misc)]
        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend ("SrcBlend", Float) = 1.0
		[Enum(UnityEngine.Rendering.BlendMode)] _DstBlend ("DestBlend", Float) = 0.0
		[Enum(Off, 0, On, 1)]_ZWriteMode ("ZWriteMode", float) = 1
		[Enum(UnityEngine.Rendering.CullMode)]_CullMode ("CullMode", float) = 2
		[Enum(UnityEngine.Rendering.CompareFunction)]_ZTestMode ("ZTestMode", Float) = 4
	}
	SubShader
	{
		Tags { "RenderType"="AlphaTest" "Queue"="AlphaTest" }
		LOD 75
		
		// Default render pipeline
		UsePass "Hidden/Character/Shadow/CharacterShadow"
		Pass
		{
			Name "PetDefault"
            Blend [_SrcBlend] [_DstBlend]
			ZWrite [_ZWriteMode]
			ZTest [_ZTestMode]
			Cull [_CullMode]
			Lighting Off
			Fog { Mode Off }
			CGPROGRAM
			#pragma target 3.0
			#pragma shader_feature_local _COMBINEDTEX_ON
			#pragma multi_compile __ _RIMLIGHT
			#pragma multi_compile __ _FLOWLIGHTUV _FLOWLIGHTSCREEN
			#pragma multi_compile __ _USE_DIRECT_GPU_SKINNING
			#pragma vertex vert
			#pragma fragment frag
			#include "Assets/CGInclude/LGameInGamePetCG.cginc"
			ENDCG
		}
		UsePass "Hidden/Character/Outline/CharacterOutline"
		
		// Srp 
		UsePass "Hidden/Character/Shadow Srp/CharacterShadowSrp"
		UsePass "Hidden/Character/Shadow Srp/CharacterSoftShadowSrp"
		Pass
		{
			Name "PetDefaultSrp"
			Tags { "LightMode" = "CharacterDefaultSrp" }
            Blend [_SrcBlend] [_DstBlend]
			ZWrite [_ZWriteMode]
			ZTest [_ZTestMode]
			Cull [_CullMode]
			Lighting Off
			Fog { Mode Off }
			CGPROGRAM
			#pragma target 3.0
			#pragma shader_feature _COMBINEDTEX_ON
			#pragma multi_compile __ _RIMLIGHT
			#pragma multi_compile __ _FLOWLIGHTUV _FLOWLIGHTSCREEN
			#pragma multi_compile __ _USE_DIRECT_GPU_SKINNING
			#pragma vertex vert
			#pragma fragment frag
			#include "Assets/CGInclude/LGameInGamePetCG.cginc"
			ENDCG
		}
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
	CustomEditor "CustomShaderGUI.LGameInGamePetGUI"
}