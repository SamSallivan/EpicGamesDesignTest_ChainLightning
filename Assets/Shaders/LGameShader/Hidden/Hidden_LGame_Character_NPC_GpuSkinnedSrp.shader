// Upgrade NOTE: upgraded instancing buffer 'character' to new syntax.
// Upgrade NOTE: upgraded instancing buffer 'effect' to new syntax.

// Upgrade NOTE: replaced 'UNITY_INSTANCE_ID' with 'UNITY_VERTEX_INPUT_INSTANCE_ID'

Shader "Hidden/LGame/Character/NPC_GpuSkinned Srp"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_AnimMap ("AnimMap", 2D) ="white" {}
		//_AnimTime("Anim Time", Float) = 0	//动画开始时间，相对于 sinceLevelLoad
		//_PauseTime("Pause Time", Float) = 0 //动画暂停 -1 为不暂停，》=0 时 为暂停时的时间
		//_PlayVector("Play Info", Vector) = (0,0,0,0)

		//_LightColor("Light Color" , Color) = (1,1,1,1)//灯光颜色
		_FxTex("Effect Texture" , 2D) = "black"{}
		_FxCol("Effect Color" , Color) = (1,1,1,1)
		_FxSpeed("Effect Speed (Z For Intensity)" , vector) = (0,0,1,1)
		[Toggle]_BaronBuff("Baron Buff On?" , float) = 0

		_OffsetColor ("OffsetColor", Color) = (0.0,0.0, 0.0,1.0) //色彩偏移（受击闪白之类）
		_ShadowFalloff("Shadow Falloff" , Range(0.01,1)) = 1//阴影衰减
		_OutlineCol("OutlineCol", Color) = (0,0,0,1)     //outline color
		_OutlineScale("Outline Scale", Range(0,2)) = 1   //outline scale

		//scan mat
		_Color1("Color1" , Color) = (0.313,0,0,1)
		_Color2("Color2" , Color) = (0.431,0,0,1)
		_Speed("Speed" , float) = 2
		_MaxScale("Max Scale" , Range(0,4)) = 1.1
	}
	CGINCLUDE
	#include "UnityCG.cginc" 
	#include "Assets/CGInclude/LGameCG.cginc"
    #include "Assets/CGInclude/GpuAnim.cginc"

	struct v2f
	{
		float4 pos : SV_POSITION;
		half3 uv	: TEXCOORD0;
		#if	_BARONBUFF_ON
		half2 uv2	: TEXCOORD1;
		#endif
#if _SCAN_MAT_ON
		fixed4 col : COLOR;
#endif
		UNITY_VERTEX_INPUT_INSTANCE_ID
	};

	sampler2D	_MainTex;
	half4		_MainTex_ST;
#if _SCAN_MAT_ON
	fixed4 	_Color1;
	fixed4 	_Color2;
	half	_Speed;
	half	_MaxScale;
#endif

	UNITY_INSTANCING_BUFFER_START (character)
		UNITY_DEFINE_INSTANCED_PROP (fixed4, _OffsetColor)
#define _OffsetColor_arr character
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

	v2f vert (appdata_uv2 v)
	{
		v2f o;
		UNITY_SETUP_INSTANCE_ID(v);
		UNITY_TRANSFER_INSTANCE_ID( v , o);

		float posX = GpuSkinUvX();

		half2x4 q0 = GetDualQuat(posX, v.uv2.x);
		half2x4 q1 = GetDualQuat(posX, v.uv2.z);

		half2x4 blendDualQuat = q0 * v.uv2.y;
		if(dot(q0[0],q1[0])>0)
			blendDualQuat += q1 * v.uv2.w;
		else
			blendDualQuat -= q1 * v.uv2.w;

		blendDualQuat = NormalizeDualQuat(blendDualQuat);

		float4 pos =  float4(TransformFromDualQuat(blendDualQuat, v.vertex), 1);
#if _SCAN_MAT_ON
		half weight = abs(frac(_Time.y * _Speed) - 0.5) * 2;//sin(_Time.y * _Speed) * 0.5 + 0.5;
		pos.xyz *= lerp(1, _MaxScale, weight);
		o.pos = UnityObjectToClipPos(pos);
		o.col = lerp(_Color1, _Color2, weight);
#else
		o.pos = UnityObjectToClipPos(pos);
		o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
		o.uv.z = GetOulineValue(); // 描边
		#if	_BARONBUFF_ON
			o.uv2 = TRANSFORM_TEX(v.texcoord, _FxTex) + UNITY_ACCESS_INSTANCED_PROP(_FxSpeed_arr, _FxSpeed).xy * _Time.y;	
		#endif
#endif
		return o;
	}
			
	fixed4 frag_outline (v2f i) : SV_Target
	{
		UNITY_SETUP_INSTANCE_ID(i);
#if _SCAN_MAT_ON
	return i.col;
#else
		fixed4 mainTex = tex2D(_MainTex, i.uv.xy);

		half3 col = mainTex.rgb  + UNITY_ACCESS_INSTANCED_PROP (_OffsetColor_arr, _OffsetColor);

		#if	_BARONBUFF_ON
			fixed3 effect = tex2D(_FxTex , i.uv2).rgb * UNITY_ACCESS_INSTANCED_PROP(_FxSpeed_arr, _FxSpeed).z *  UNITY_ACCESS_INSTANCED_PROP(_FxCol_arr, _FxCol).rgb * UNITY_ACCESS_INSTANCED_PROP(_FxCol_arr, _FxCol).a;
			col.rgb += 	effect;
		#endif

		return  fixed4(col.rgb, i.uv.z) ;
#endif
	}
	ENDCG

	//高质量
	SubShader
	{
		Tags { "RenderType"="Opaque" "LightMode" = "NPCGpuSkinnedDefault" "Queue"="AlphaTest" }

		//基础Pass
		Pass
		{
			Name "NPCGpuSkinnedDefault"
			Tags{"LightMode"="NPCGpuSkinnedDefault"}
			Lighting Off
			Fog { Mode Off }
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag_outline
			//#pragma multi_compile_instancing
			//#pragma instancing_options forcemaxcount:32
			#pragma multi_compile _BARONBUFF_OFF _BARONBUFF_ON
			#pragma multi_compile __ _SCAN_MAT_ON
			
			ENDCG
		}
		
		
	}
}
