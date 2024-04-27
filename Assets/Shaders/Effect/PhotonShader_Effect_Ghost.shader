// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader  "PhotonShader/Effect/Ghost" 
{
    Properties
	{
		[HideInInspector][Enum(UnityEngine.Rendering.BlendMode)] 		_SrcFactor ("SrcFactor()", Float) = 1
		[HideInInspector][Enum(UnityEngine.Rendering.BlendMode)] 		_DstFactor ("DstFactor()", Float) = 1
		[Enum(UnityEngine.Rendering.CullMode)] 							_CullMode ("消隐模式(CullMode)", int) = 2
		[Enum(LessEqual,4,Always,8)]									_ZTestMode ("深度测试(ZTest)", int) = 4
		[Enum(RGB,14,ALL,15, NONE,0)]									_ColorMask ("颜色遮罩(ColorMask)", int) = 15
		[SimpleToggle] _ZWrite ("写入深度(ZWrite)", float) = 0
		
		[SimpleToggle] _RgbAsAlpha ("颜色输出至透明(RgbAsAlpha)", int) = 0

        _Color ("Color", Color) = (1,1,1,1)
        _Multiplier	("亮度",range(1,20)) = 1
		
		[SimpleToggle] _ScaleOnCenter("以贴图中心进行uv缩放", Float) = 1
        _MainTex ("MainTex", 2D) = "white" {}
        [TexTransform] _MainTexTransform ("MaitTex Transform" , Vector) = (0,0,0,1) //scrollU , scrollV , scrollRot
		
        _MaskTex ("mask", 2D) = "white" {}
        [TexTransform] _MaskTexTransform ("MaskTex Transform" , Vector) = (0,0,0,1) //scrollU , scrollV , scrollRot
		
        _RimMultipliers ("rimBrightness", Range(0, 5)) = 1
		_RimRange ("rimRange", Range(0, 1)) = 0
		[SimpleToggle] _RimInvert ("Rim反向", int) = 0
		[SimpleToggle] _TimeScale("Time Scale", Float) = 1
    }
	
	SubShader
	{
		Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" "LightMode" = "ForwardBase"}
		LOD 100
		Blend [_SrcFactor] [_DstFactor]
		Cull [_CullMode]
		ZWrite [_ZWrite]
		ZTest [_ZTestMode]
		ColorMask [_ColorMask]
		//Pass
		//{
		  // ZWrite On
		  // ColorMask 0
		//}

		Pass
		{
			Lighting Off
			//ZTest Always
			ZWrite Off
			Fog { Mode Off }

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#pragma target 2.0
			#include "UnityCG.cginc"
			#include "Assets/CGInclude/EffectCG.cginc"

			#pragma multi_compile MultiplyBlend_Off	MultiplyBlend_On

			struct appdata
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float2 uv : TEXCOORD0;
				fixed4 vertexColor : COLOR;
			};

			struct fragData
			{
				float4 uv12 : TEXCOORD0;
				float3 wPos : TEXCOORD1;
				float3 normalDir : TEXCOORD2;
				float4 vertex : SV_POSITION;
				fixed4 vertexColor : COLOR;
			};

			fixed4 _Color;
			half _Multiplier;

            sampler2D _MainTex;
			float4 _MainTex_ST;
			half4 _MainTexTransform;
			
			sampler2D _MaskTex;
			float4 _MaskTex_ST;
			half4 _MaskTexTransform;

			half _SrcFactor;
			half _RgbAsAlpha;
			
			half _RimMultipliers;
			half _RimRange;
			half _RimInvert;

			fixed _ScaleOnCenter;
			fixed _TimeScale;
			
			fragData vert (appdata v)
			{
				fragData o = (fragData)0;
				o.vertex =  UnityObjectToClipPos(v.vertex);
				
				o.uv12.xy = TransFormUV(v.uv,_MainTex_ST,_ScaleOnCenter);
				o.uv12.xy = RotateUV(o.uv12.xy,_MainTexTransform.zw);
				o.uv12.xy += _TimeScale * _Time.x * _MainTexTransform.xy;
				
				o.uv12.zw = TransFormUV(v.uv,_MaskTex_ST,_ScaleOnCenter);
				o.uv12.zw = RotateUV(o.uv12.zw,_MaskTexTransform.zw);
				o.uv12.zw +=  _TimeScale * _Time.x * _MaskTexTransform.xy;
				
                o.normalDir = mul((float3x3)unity_ObjectToWorld, v.normal);
                o.wPos = mul(unity_ObjectToWorld, v.vertex);
				
				o.vertexColor = v.vertexColor * _Color * _Multiplier ;
				return o;
			}
			
			fixed4 frag (fragData i) : SV_Target
			{
				fixed4 texColor = tex2D(_MainTex, i.uv12.xy);
				fixed4 maskColor = tex2D(_MaskTex, i.uv12.zw);
				
				fixed4 result = (fixed4)1;
				result = texColor;
				result.a *= maskColor.r;
				
				result *= i.vertexColor;
				
				float3 viewDirection = normalize(_WorldSpaceCameraPos.xyz - i.wPos.xyz);
                float3 normalDirection = normalize(i.normalDir);

                float fresnel[2] ;
				fresnel[0] =  max(0,dot(viewDirection.xyz,normalDirection.xyz));
				fresnel[1] = 1 - fresnel[0]; 
			
				float cfre = clamp(fresnel[_RimInvert] / (_RimRange*2),0,1);

				result  = result * pow(cfre,_RimRange*8) * _RimMultipliers ;
				
				float gray = dot(result.rgb,fixed3(0.33,0.34,0.33));
				float aa[2] = {result.a,gray};
				
				# if MultiplyBlend_On
					fixed4 multiplyColor = lerp(fixed4(1,1,1,1), result, result.a);
					result = lerp(result, multiplyColor ,_SrcFactor == 0);
				#endif
				result.a = aa[_RgbAsAlpha];
				
				return result;
			}
			ENDCG
		}
	}
	
	SubShader
	{
		Tags { "Queue" = "Transparent" "LightMode" = "ForwardBase" "IgnoreProjector" = "True" "RenderType" = "Transparent"}
		LOD 5
		Blend One One
		ZWrite[_ZWrite]
		ZTest[_ZTestMode]
		Cull[_CullMode]

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment fragtest
			#include "Assets/CGInclude/LGameEffect.cginc" 

			half4 fragtest(v2f i) : SV_Target
			{
				fixed4 texColor = tex2D(_MainTex, i.uvMain.xy, float2(0, 0), float2(0, 0));

				return half4(0.15,0.06,0.03, texColor.a < 0.001);
			}
			ENDCG
		}
	}
}
