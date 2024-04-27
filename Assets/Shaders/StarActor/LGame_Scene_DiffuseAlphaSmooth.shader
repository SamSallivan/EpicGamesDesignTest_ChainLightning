Shader "LGame/Scene/Diffuse AlphaSmooth" {
	Properties 
	{
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_AlphaTex("Alpha", 2D) = "white" {}
		_AlphaCtrl0 ("Alpha Contrl 0", Range(-1,1)) = -0.5		
		_AlphaCtrl1 ("Alpha Contrl 1", Range(-1,1)) = 0.5	
		_Luminance("Luminance", Range(0.0,1.0)) = 0.26
		[HideInInspector]_BrightnessForScene("",Range(0,1)) = 1.0
	}

	CGINCLUDE
		#include "UnityCG.cginc"
		sampler2D	_MainTex;
		sampler2D	_AlphaTex;
		half4		_MainTex_ST;	
		fixed		_AlphaCtrl0;
		fixed		_AlphaCtrl1;
		half		_Luminance;
		half		_BrightnessForScene;
		struct a2v {
			float4 vertex : POSITION;
			float2 uv0 : TEXCOORD0;
			float2 uv1 : TEXCOORD1;
		};
				
		struct v2f 
		{
			float4 pos		: SV_POSITION;
			float4 uv		: TEXCOORD0;
		};
		
		// vertex shader
		v2f vert (a2v v) 
		{
			v2f o = (v2f)0;
			o.pos = UnityObjectToClipPos (v.vertex);
			o.uv.xy = TRANSFORM_TEX(v.uv0, _MainTex);
			o.uv.zw =v.uv1;
			return o;
		}
	ENDCG

	SubShader 
	{ 
		Tags 
		{ 
			"Queue"="Transparent"
			"IgnoreProjector"="False"
			"RenderType"="Transparent" 
		}
		LOD 100
		//ColorMask RGB
		Blend SrcAlpha OneMinusSrcAlpha
		Zwrite Off
		Pass 
		{
			Name "FORWARD"
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag		
			// fragment shader
			fixed4 frag (v2f i) : SV_Target 
			{
				half alpha = tex2D(_AlphaTex, i.uv.zw).rgb;;			
				alpha *=smoothstep(_AlphaCtrl0,_AlphaCtrl1,1.0-i.uv.w);
				fixed3 c = tex2D(_MainTex, i.uv.xy).rgb;
				c *= 1.0 + _Luminance;		
				c *= _BrightnessForScene;
				return fixed4(c, alpha);
			}			
			ENDCG	
		}			
	}
}
