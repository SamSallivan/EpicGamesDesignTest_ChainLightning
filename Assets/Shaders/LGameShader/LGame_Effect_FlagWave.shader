/**************************************************************************************************
 2017-10-12 11:12:57
 @yvanliao





***************************************************************************************************/


Shader "LGame/Effect/FlagWave" {
    Properties {

		[Enum(UnityEngine.Rendering.BlendMode)] 		_SrcFactor ("SrcFactor()", Float) = 5
		[Enum(UnityEngine.Rendering.BlendMode)] 		_DstFactor ("DstFactor()", Float) = 10

		 _MainTex ("Sprite Texture", 2D) = "white" {}
        _Color ("Tint", Color) = (0.07843138,0.3921569,0.7843137,1)
		_MaskTex ("Mask Textrue", 2D) = "white" {}
        _NormalTex ("normal Textrue", 2D) = "bump" {}
		_NormalScale  ("Normal Intensity ", Range(-1, 1)) = 0.3

		_WevaX ("Weva Horizontal" , float) = 0
		_WevaY ("Weva Vertical" , float) = 5
        //_WevaDir ("Weva Direction" , Vector) = (0,0,0,0)
        _WaveIntensity ("Wave Intensity", Range(-0.1, 0.1)) = 0.01
        
		_LightColor("Light Color" , Color) = (1,1,1,1)
		_LightDir("Light Direction(W for Intensity)" , Vector) = (1,1,-1,1)

	   	[PerRendererData] _StencilComp ("Stencil Comparison", Float) = 8
		[PerRendererData] _Stencil ("Stencil ID", Float) = 0
		[PerRendererData] _StencilOp ("Stencil Operation", Float) = 0
		[PerRendererData] _StencilWriteMask ("Stencil Write Mask", Float) = 255
		[PerRendererData] _StencilReadMask ("Stencil Read Mask", Float) = 255
		[PerRendererData] _ColorMask ("Color Mask", Float) = 15
		[Toggle(UNITY_UI_ALPHACLIP)] _UseUIAlphaClip ("Use Alpha Clip", Float) = 0

    }
    SubShader {
		Tags
		{ 
			"Queue"="Transparent" 
			"IgnoreProjector"="True" 
			"RenderType"="Transparent" 
			"PreviewType"="Plane"																												  
			"CanUseSpriteAtlas"="True"
		}

		Stencil
		{
			Ref [_Stencil]
			Comp [_StencilComp]
			Pass [_StencilOp] 
			ReadMask [_StencilReadMask]
			WriteMask [_StencilWriteMask]
		}

		Cull Off
		Lighting Off
		ZWrite Off
		ZTest [unity_GUIZTestMode]
		Blend [_SrcFactor] [_DstFactor]
		ColorMask [_ColorMask]

        Pass {
            Name "Default"
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag


            #include "UnityCG.cginc"
			#include "UnityUI.cginc"
			#pragma multi_compile __ UNITY_UI_ALPHACLIP
            #pragma target 3.0


            fixed4		_Color;
			fixed4		_TextureSampleAdd;
			//float4		_ClipRect;

			sampler2D	_MainTex;

			sampler2D	_MaskTex ;

            sampler2D	_NormalTex;
			half4		_NormalTex_ST;
			half		_NormalScale;

			half		_WevaX;
			half		_WevaY;
			half		_WaveIntensity;

			fixed4		_LightColor;
			half4		_LightDir;


            struct a2v {
                float4 vertex	: POSITION;
                fixed3 normal	: NORMAL;
				fixed4 color	: COLOR;
				float2 texcoord : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
            };
            struct v2f {
                float4 pos		: SV_POSITION;
                float4 uv		: TEXCOORD0;
                fixed3 worldNormal	: TEXCOORD1;						   
				fixed4 color	: COLOR;
				UNITY_VERTEX_OUTPUT_STEREO
            };

            v2f vert (a2v v) {
                v2f o = (v2f)0;
				
                o.uv.xy = v.texcoord ;
				o.uv.zw = TRANSFORM_TEX(v.texcoord, _NormalTex) + frac( _Time.xx * float2(_WevaX , _WevaY));
				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				
				#ifdef UNITY_HALF_TEXEL_OFFSET
					o.vertex.xy += (_ScreenParams.zw-1.0) * float2(-1,1) * o.vertex.w;
				#endif
				o.pos = UnityObjectToClipPos(v.vertex);

				o.color = v.color * _Color;
                return o;
            }
            fixed4 frag(v2f i) : COLOR {

				fixed3 lightDir = normalize(-_LightDir.xyz);

				half3 normalTex = UnpackNormal(tex2D(_NormalTex , i.uv.zw));
				normalTex.xy *= _NormalScale;
				fixed3 normal	= normalize( normalTex);

				fixed mask =  tex2D(_MaskTex , i.uv.xy ) ;
				fixed3 diffse = lerp(1 , saturate(dot(lightDir , normal)) ,mask ) * _LightColor.xyz * _LightDir.w;

				//float4 colorTex = tex2D(_MainTex,i.uv.xy + normal.xy *  _WaveIntensity * mask)  * i.color;
				float2 uv = i.uv.xy * float2(0.5 , 1) -float2(1 , 0) *normal.xy *  _WaveIntensity * mask;
				fixed3 colorTex = (tex2D(_MainTex , uv ).rgb + _TextureSampleAdd.rgb) * i.color;

				uv.x += 0.5;
				fixed alpha = (tex2D(_MainTex , uv ).r + _TextureSampleAdd.a) * i.color.a;
				//alpha *= UnityGet2DClipping(i.uv.xy, _ClipRect);

				#ifdef UNITY_UI_ALPHACLIP
					clip (alpha - 0.001);
				#endif

                colorTex.rgb *= diffse;
                return fixed4(colorTex , alpha);
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}
