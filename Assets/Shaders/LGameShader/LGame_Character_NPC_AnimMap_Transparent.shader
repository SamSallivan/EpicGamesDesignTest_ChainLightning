// Upgrade NOTE: upgraded instancing buffer 'character' to new syntax.
// Upgrade NOTE: upgraded instancing buffer 'effect' to new syntax.

Shader "LGame/Character/NPC_AnimMap_Transparent"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_AnimMap ("AnimMap", 2D) ="white" {}
		_AnimTime("Anim Time", Float) = 0	//动画开始时间，相对于 sinceLevelLoad
		_PauseTime("Pause Time", Float) = 0 //动画暂停 -1 为不暂停，》=0 时 为暂停时的时间
		_PlayVector("Play Info", Vector) = (0,0,0,0)
 
		_FxTex("Effect Texture" , 2D) = "black"{}
		_FxCol("Effect Color" , Color) = (1,1,1,1)
		_FxSpeed("Effect Speed (Z For Intensity)" , vector) = (0,0,1,1)
		[Toggle]_BaronBuff("Baron Buff On?" , float) = 0

		_OffsetColor ("OffsetColor", Color) = (0.0,0.0, 0.0,1.0) //色彩偏移（受击闪白之类）
		_AlphaCtrl("Alpha control", Range(0,1)) = 1
		_ShadowFalloff("Shadow Falloff" , Range(0.01,1)) = 1//阴影衰减
	}

	CGINCLUDE
	#include "UnityCG.cginc" 
	#include "Assets/CGInclude/GpuAnim.cginc"
	#include "Assets/CGInclude/LGameCG.cginc"
	#pragma multi_compile _BARONBUFF_OFF _BARONBUFF_ON
	struct v2f
	{
		float4 pos : SV_POSITION;
		half2 uv	: TEXCOORD0;
		#if	_BARONBUFF_ON
		half2 uv2	: TEXCOORD1;
		#endif
		UNITY_VERTEX_INPUT_INSTANCE_ID
	};

	sampler2D	_MainTex;
	half4		_MainTex_ST;

	UNITY_INSTANCING_BUFFER_START (character)
		UNITY_DEFINE_INSTANCED_PROP (fixed4, _OffsetColor)
#define _OffsetColor_arr character
		UNITY_DEFINE_INSTANCED_PROP (half, _AlphaCtrl)
#define _AlphaCtrl_arr character
	UNITY_INSTANCING_BUFFER_END(character)

	#if	_BARONBUFF_ON
		sampler2D	_FxTex;
		half4		_FxTex_ST ;
		UNITY_INSTANCING_BUFFER_START (effect)
			UNITY_DEFINE_INSTANCED_PROP (fixed4, _FxCol)
#define _FxCol_arr effect
			UNITY_DEFINE_INSTANCED_PROP (half4, _FxSpeed)
#define _FxSpeed_arr effect
		UNITY_INSTANCING_BUFFER_END(effect)
	#endif

	v2f vert (appdata_simple v , uint vid : SV_VertexID)
	{
		v2f o;
		UNITY_SETUP_INSTANCE_ID(v);
		UNITY_TRANSFER_INSTANCE_ID( v , o);

		float4 pos = AnimMapVertex(vid);

		pos = tex2Dlod(_AnimMap, pos);

		o.pos = UnityObjectToClipPos(pos);
		o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
		#if	_BARONBUFF_ON
			o.uv2 = TRANSFORM_TEX(v.texcoord, _FxTex) + UNITY_ACCESS_INSTANCED_PROP(_FxSpeed_arr, _FxSpeed).xy * _Time.y;	
		#endif
		return o;
	}
			
	fixed4 frag (v2f i) : SV_Target
	{
		UNITY_SETUP_INSTANCE_ID(i);

		fixed4 mainTex = tex2D(_MainTex, i.uv.xy);

		half3 col = mainTex.rgb  + UNITY_ACCESS_INSTANCED_PROP(_OffsetColor_arr, _OffsetColor);

		#if	_BARONBUFF_ON
			fixed3 effect = tex2D(_FxTex , i.uv2).rgb * UNITY_ACCESS_INSTANCED_PROP(_FxSpeed_arr, _FxSpeed).z *  UNITY_ACCESS_INSTANCED_PROP(_FxCol_arr, _FxCol).rgb * UNITY_ACCESS_INSTANCED_PROP(_FxCol_arr, _FxCol).a;
			col.rgb += 	effect;
		#endif
		return fixed4(col , UNITY_ACCESS_INSTANCED_PROP(_AlphaCtrl_arr, _AlphaCtrl)) ;
	}
	ENDCG

	//高质量（带动态阴影）
	SubShader
	{
		Tags { "RenderType"="Transparent" "LightMode"="ForwardBase" "Queue"="Transparent" }
		LOD 75
		Blend SrcAlpha OneMinusSrcAlpha
		//实时阴影Pass
		UsePass "LGame/Character/ShadowAnimMap/TRANSPARENTSHADOW"

		//基础Pass
		Pass
		{
			Name "ForwardBase"
			Lighting Off
			//ZTest Always
			ZWrite Off
			Fog { Mode Off }
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			//#pragma multi_compile_instancing
			//#pragma instancing_options forcemaxcount:32
			#pragma target 3.0

			ENDCG
		}
	}

	//高质量（无动态阴影）
	//SubShader
	//{
	//	Tags { "RenderType"="Transparent" "LightMode"="ForwardBase" "Queue"="Transparent" }
	//	LOD 70
	//	Blend SrcAlpha OneMinusSrcAlpha
	//	//基础Pass
	//	Pass
	//	{
	//		Name "ForwardBase"
	//		Lighting Off
	//		//ZTest Always
	//		ZWrite Off
	//		Fog { Mode Off }
	//		CGPROGRAM
	//		#pragma vertex vert
	//		#pragma fragment frag
	//		//#pragma multi_compile_instancing
	//		//#pragma instancing_options forcemaxcount:32
	//		#pragma target 3.0

	//		ENDCG
	//	}
	//	
	//}
	//中质量
	//SubShader
	//{
	//	Tags { "RenderType"="Transparent" "LightMode"="ForwardBase" "Queue"="Transparent" }
	//	LOD 40
	//	Blend SrcAlpha OneMinusSrcAlpha

	//	//基础Pass
	//	Pass
	//	{
	//		Name "ForwardBase"
	//		Lighting Off
	//		Fog { Mode Off }
	//		CGPROGRAM
	//		#pragma vertex vert
	//		#pragma fragment frag
	//		//#pragma multi_compile_instancing
	//		//#pragma instancing_options forcemaxcount:32
	//		#pragma target 2.0

	//		ENDCG
	//	}
	//		
	//}
	//低质量（带动态阴影）
	SubShader
	{
		Tags { "RenderType"="Transparent" "LightMode"="ForwardBase" "Queue"="Transparent" }
		LOD 15
		Blend SrcAlpha OneMinusSrcAlpha
		//实时阴影Pass
		UsePass "LGame/Character/ShadowAnimMap/TRANSPARENTSHADOW"

		//基础Pass
		Pass
		{
			Name "ForwardBase"
			Lighting Off
			Fog { Mode Off }
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			//#pragma multi_compile_instancing
			//#pragma instancing_options forcemaxcount:32
			#pragma target 2.0

			ENDCG
		}
		
		
	}
 	//低质量（无动态阴影）
	//SubShader
	//{
	//	Tags { "RenderType"="Transparent" "LightMode"="ForwardBase" "Queue"="Transparent" }
	//	LOD 10
	//	Blend SrcAlpha OneMinusSrcAlpha

	//	//基础Pass
	//	Pass
	//	{
	//		Name "ForwardBase"
	//		Lighting Off
	//		Fog { Mode Off }
	//		CGPROGRAM
	//		#pragma vertex vert
	//		#pragma fragment frag
	//		//#pragma multi_compile_instancing
	//		//#pragma instancing_options forcemaxcount:32
	//		#pragma target 2.0

	//		ENDCG
	//	}
	//	
	//	
	//}
}
