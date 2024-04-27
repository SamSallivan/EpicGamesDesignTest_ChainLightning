/**************************************************************************************************
 2017-10-12 11:12:57
 @yvanliao





***************************************************************************************************/


Shader "LGame/Effect/FlagWaveMask" {
    Properties {

		[Enum(UnityEngine.Rendering.BlendMode)] 		_SrcFactor ("SrcFactor()", Float) = 5
		[Enum(UnityEngine.Rendering.BlendMode)] 		_DstFactor ("DstFactor()", Float) = 10

		 _MainTex ("Sprite Texture", 2D) = "white" {}
        _Color ("Tint", Color) = (0.07843138,0.3921569,0.7843137,1)
		_WaveMaskTex ("WaveMask Textrue", 2D) = "white" {}
        _NormalTex ("normal Textrue", 2D) = "bump" {}
		_NormalScale  ("Normal Intensity ", Range(-1, 1)) = 0.3
		_ShadowColor("Shadow Color",Color)=(0,0,0,1)
		_ShadowStrength("Shadow Strength",Range(0,1)) =0.5
		_WevaX ("Weva Horizontal" , float) = 0
		_WevaY ("Weva Vertical" , float) = 5
        _WaveIntensity ("Wave Intensity", Range(-0.1, 0.1)) = 0.01    
		_LightColor("Light Color" , Color) = (1,1,1,1)
		_LightDir("Light Direction(W for Intensity)" , Vector) = (1,1,-1,1)
		_MaskTex("Alpha Mask Texture",2D)="white"{}
	   	[PerRendererData] _StencilComp ("Stencil Comparison", Float) = 8
		[PerRendererData] _Stencil ("Stencil ID", Float) = 0
		[PerRendererData] _StencilOp ("Stencil Operation", Float) = 0
		[PerRendererData] _StencilWriteMask ("Stencil Write Mask", Float) = 255
		[PerRendererData] _StencilReadMask ("Stencil Read Mask", Float) = 255
		[PerRendererData] _ColorMask ("Color Mask", Float) = 15
		[Toggle(UNITY_UI_ALPHACLIP)] _UseUIAlphaClip ("Use Alpha Clip", Float) = 0
		[Toggle]_CardClip("Card Clip",Float) = 0
    }
    SubShader {
		Tags
		{ 
			"Queue"="Transparent" 
			"IgnoreProjector"="True" 
			"RenderType"="Transparent" 
			"PreviewType"="Plane"																												  
			"CanUseSpriteAtlas"="True"
			"LightMode"="ForwardBase"
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
			#pragma shader_feature _CARDCLIP_ON
			#pragma multi_compile __ RectClip_On
            #pragma target 3.0


            fixed4		_Color;
			fixed4		_TextureSampleAdd;

			sampler2D	_MainTex;
			float4 _MainTex_ST;
			sampler2D	_WaveMaskTex ;

            sampler2D	_NormalTex;
			half4		_NormalTex_ST;
			half		_NormalScale;

			half		_WevaX;
			half		_WevaY;
			half		_WaveIntensity;
			half		_ShadowStrength;
			fixed4		_LightColor;
			fixed4      _ShadowColor;
			half4		_LightDir;

			sampler2D _MaskTex;
			float4 _MaskTex_ST;
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
				float2 uvMask   : TEXCOORD1;
                fixed3 worldNormal	: TEXCOORD2;	
				#if _CARDCLIP_ON
					float4 screenPos:TEXCOORD3;
					float4 pivot:TEXCOORD4;
				#endif
				#if RectClip_On
					float3 worldPos	: TEXCOORD5;
				#endif
				fixed4 color	: COLOR;
				UNITY_VERTEX_OUTPUT_STEREO
            };
			#if _CARDCLIP_ON
				float4 _Piovt;
			#endif
			#if RectClip_On
				float4 _EffectClipRect;
			#endif
			half CardClip(half4 pos)
			{
				//¹Ì¶¨¿í¸ß200*328
				half4 range = half4(pos.x - 100.0, pos.x + 100.0, pos.y-164.0, pos.y+164.0);
				return (range.x < pos.z) && (pos.z < range.y) && (range.z < pos.w) && (pos.w < range.w);
			}
			inline float Get2DClipping(in float2 position, in float4 clipRect)
			{
				float2 inside = step(clipRect.xy, position.xy) * step(position.xy, clipRect.zw);
				return inside.x * inside.y;
			}

            v2f vert (a2v v) {
                v2f o = (v2f)0;
				
                o.uv.xy =  TRANSFORM_TEX(v.texcoord, _MainTex) ;
				o.uv.zw = TRANSFORM_TEX(v.texcoord, _NormalTex) + frac( _Time.xx * float2(_WevaX , _WevaY));
				o.uvMask=TRANSFORM_TEX(v.texcoord, _MaskTex);
				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				
				#ifdef UNITY_HALF_TEXEL_OFFSET
					o.vertex.xy += (_ScreenParams.zw-1.0) * float2(-1,1) * o.vertex.w;
				#endif
				o.pos = UnityObjectToClipPos(v.vertex);

				o.color = v.color * _Color;

				#if _CARDCLIP_ON
					o.pivot = ComputeScreenPos(mul(UNITY_MATRIX_VP, half4(_Piovt.xyz, 1)));
					o.screenPos = ComputeScreenPos(o.pos);
				#endif
				#if RectClip_On
					o.worldPos = mul(unity_ObjectToWorld, float4(v.vertex.xyz, 1.0)).xyz;
				#endif
                return o;
            }
            fixed4 frag(v2f i) : COLOR {

				fixed3 lightDir = normalize(-_LightDir.xyz);

				half3 normalTex = UnpackNormal(tex2D(_NormalTex , i.uv.zw));
				normalTex.xy *= _NormalScale;
				fixed3 normal	= normalize( normalTex);

				fixed waveMask =  tex2D(_WaveMaskTex , i.uv.xy ) ;
				fixed3 diffuse = lerp(1, saturate(dot(lightDir, normal)), waveMask);

				diffuse = lerp(_ShadowColor.xyz, _LightColor.xyz, diffuse*_ShadowStrength +(1-_ShadowStrength))* _LightDir.w;
				float2 uv = i.uv.xy -float2(1 , 0) *normal.xy *  _WaveIntensity * waveMask;
				fixed4 colorTex = tex2D(_MainTex , uv )* i.color;
				half alphaMask=tex2D(_MaskTex,i.uvMask).r;

				#ifdef UNITY_UI_ALPHACLIP
					clip (colorTex.a - 0.001);
				#endif

                colorTex.rgb *= diffuse;
				colorTex.a*=alphaMask;
				#if _CARDCLIP_ON
					i.pivot.xy = i.pivot.xy / i.pivot.zw;
					i.screenPos.xy = i.screenPos.xy / i.screenPos.zw;
					colorTex.a *= CardClip(half4(i.pivot.xy, i.screenPos.xy)*_ScreenParams.xyxy);
				#endif
#if RectClip_On
					colorTex.a *= Get2DClipping(i.worldPos.xy, _EffectClipRect);
#endif	
                return colorTex;
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}
