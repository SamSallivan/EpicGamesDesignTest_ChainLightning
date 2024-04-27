// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'


Shader "Hidden/MyUnlit_GlowVob_FastBlur" {
	Properties {
		_MainTex ("Base (RGB)", 2D) = "white" {}
	}
	
	CGINCLUDE

		#include "UnityCG.cginc"

		sampler2D _MainTex;
				
		uniform half4 _MainTex_TexelSize;
		uniform half4 _Parameter;
		
		struct v2f_withBlurCoords8 
		{
			float4 pos : SV_POSITION;
			half4 uv : TEXCOORD0;
			half2 offs : TEXCOORD1;
		};	

		v2f_withBlurCoords8 vert4ChangeAlpha_Pos (appdata_img v)
		{
			//_MainTex_TexelSize.xy = half2(1.0f/128f,1.0f/128f) ;
			v2f_withBlurCoords8 o;
			float4 pos = v.vertex;
			pos.xy += _Parameter.zw;
			o.pos = UnityObjectToClipPos (pos);
			o.uv = half4(v.texcoord.xy,1,1);

			return o; 
		}

		fixed4 frag4ChangeAlpha_Pos ( v2f_withBlurCoords8 i ) : SV_Target
		{
			fixed4 color = tex2D(_MainTex, i.uv);
			color.rgb *= _Parameter.y;
			return color;
		}

		static const half4 curve4[7] = { half4(0.0205,0.0205,0.0205,0.0205), half4(0.0855,0.0855,0.0855,0.0855), half4(0.232,0.232,0.232,0.232),
			half4(0.324,0.324,0.324,0.324), half4(0.232,0.232,0.232,0.232), half4(0.0855,0.0855,0.0855,0.0855), half4(0.0205,0.0205,0.0205,0.0205) };

		v2f_withBlurCoords8 vertBlurHorizontal (appdata_img v)
		{
			//_MainTex_TexelSize.xy = half2(1.0f/128f,1.0f/128f) ;
			v2f_withBlurCoords8 o;
			o.pos = UnityObjectToClipPos (v.vertex);
			
			o.uv = half4(v.texcoord.xy,1,1);
			o.offs = _MainTex_TexelSize.xy * half2(1.0, 0.0) * _Parameter.x;

			return o; 
		}
		
		v2f_withBlurCoords8 vertBlurVertical (appdata_img v)
		{
			//_MainTex_TexelSize.xy = half2(1.0f/128f,1.0f/128f) ;
			v2f_withBlurCoords8 o;
			o.pos = UnityObjectToClipPos (v.vertex);
			
			o.uv = half4(v.texcoord.xy,1,1);
			o.offs = _MainTex_TexelSize.xy * half2(0.0, 1.0) * _Parameter.x;
			 
			return o; 
		}	

		fixed4 fragBlur8 ( v2f_withBlurCoords8 i ) : SV_Target
		{
			half2 uv = i.uv.xy; 
			half2 netFilterWidth = i.offs;  

			//netFilterWidth = half2(0.1f,0.0f);

			half2 coords = uv - netFilterWidth * 3.0;  
			
			fixed4 color = 0;
  			for( int l = 0; l < 7; l++ )  
  			{   
				fixed4 tap = tex2D(_MainTex, coords);
				color += tap * curve4[l];
				coords += netFilterWidth;
  			}
			return color;
		}
					
	ENDCG
	
	SubShader {
	  ZTest Off Cull Off ZWrite Off
	  Fog { Mode off }  

	// 0
	Pass { 
	
		Blend One OneMinusSrcAlpha

		CGPROGRAM
		
		#pragma vertex vert4ChangeAlpha_Pos
		#pragma fragment frag4ChangeAlpha_Pos
		#pragma fragmentoption ARB_precision_hint_fastest 
		
		ENDCG
		 
		}

	// 1
	Pass {

		Blend Off
		
		CGPROGRAM 
		
		#pragma vertex vertBlurVertical
		#pragma fragment fragBlur8
		#pragma fragmentoption ARB_precision_hint_fastest 
		
		ENDCG 
		}	
		
	// 2
	Pass {		

		Blend Off
				
		CGPROGRAM
		
		#pragma vertex vertBlurHorizontal
		#pragma fragment fragBlur8
		#pragma fragmentoption ARB_precision_hint_fastest 
		
		ENDCG
		}	
	}	

	FallBack Off
}
