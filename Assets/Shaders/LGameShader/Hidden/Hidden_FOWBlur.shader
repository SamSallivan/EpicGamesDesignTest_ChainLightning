// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'


Shader "Hidden/FOWBlur" 
{
	Properties 
	{
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_LastTex("Base (RGB)", 2D) = "white" {}
	}
	
	SubShader 
	{
		ZTest Off 
		Cull Off 
		ZWrite Off 
		Blend Off

		// 0
		Pass 
		{ 
		
			CGPROGRAM			
			#pragma vertex vert4Tap
			#pragma fragment fragDownsample
// Disabled by Shader Kit#pragma multi_compile _FOW_OFF _FOWX_ON
			#include "UnityCG.cginc"

			sampler2D		_MainTex;			
			uniform half4	_MainTex_TexelSize;
			sampler2D		_LastTex;	

			uniform half	_EnableBlur;

			struct v2f_tap
			{
				float4 pos : SV_POSITION;
				half2 uv : TEXCOORD0;
				half4 uv12 : TEXCOORD1;
				half4 uv34 : TEXCOORD2;

			};			

			v2f_tap vert4Tap ( appdata_img v )
			{
				v2f_tap o;

				o.pos = UnityObjectToClipPos (v.vertex);
				o.uv = v.texcoord.xy;
		    	o.uv12 = v.texcoord.xyxy + _MainTex_TexelSize.xyxy * half4(1 ,1 ,-1 ,-1);
				o.uv34 = v.texcoord.xyxy + _MainTex_TexelSize.xyxy * half4(1 ,-1 ,-1 ,1);

				return o; 
			}							
			fixed4 fragDownsample ( v2f_tap i ) : SV_Target
			{				
				fixed4 color = 0;
				color.r += tex2D (_MainTex, i.uv);
				if (_EnableBlur > 0)
				{
					color.r += tex2D (_MainTex, i.uv12.xy);
					color.r += tex2D (_MainTex, i.uv12.zw);
					color.r += tex2D (_MainTex, i.uv34.xy);
					color.r += tex2D (_MainTex, i.uv34.zw);
				}

				color.r = color.r * 0.2;
				color.g = tex2D(_LastTex, i.uv).r;

				//#ifdef _FOWX_ON
				//	return color*0.65;
				//#endif

				return color;
			}
			ENDCG 
		}
	}	
	FallBack Off
}
