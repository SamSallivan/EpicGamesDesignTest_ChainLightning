Shader "LGame/Effect/StarActor/Fire Tail"
{
	Properties
	{
		_Color("Color" , Color) = (1,1,1,1)
		_MainTex ("Main Texture", 2D) = "white" {}
		[Space(10)]
		[Header(Screen Flow)]
		[Space(5)]
		_EffectCol("Effect Color" , Color) = (0.4,0.1,0,0)
		_EffectTex ("Effect Texture(Tilling控制缩放, offset控制速度)", 2D) = "white" {}
		[Space(10)]
		[Header(Rim Light)]
		[Space(5)]
		[HDR]_RimLightColor("RimLight Color" , Color) = (1,1,1,1)
		_RimLightRange("RimLight Range", Range(0.1,10)) = 1 
		[Space(10)]
		[Header(Model Flow)]
		[Space(5)]
		[HDR]_FlowColor("Color", Color) = (1,1,1,1)
		_FlowTex("Main Texture", 2D) = "white" {}
		[TexTransform] _FlowTexTransform("MaitTex Transform" , Vector) = (0,0,0,1)

		[Space(5)]
		_MaskTex("Mask Texture", 2D) = "white" {}
		[TexTransform] _MaskTexTransform("MaskTex Transform" , Vector) = (0,0,0,1) 
	}
	SubShader
	{
		Tags {"Queue"="AlphaTest"  "RenderType"="Geometry" }
		LOD 100
		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag	
			#include "UnityCG.cginc"
			#include "Assets/CGInclude/EffectCG.cginc"
			struct appdata
			{
				float4 vertex	: POSITION;
				half3 normal	: NORMAL;
				float2 uv		: TEXCOORD0;
			};
			struct v2f
			{
				float4 pos		: SV_POSITION;
				float4 uv		: TEXCOORD0;
				float4 flowuv	: TEXCOORD1;
				half3 rimlight	: TEXCOORD2;
			};
			fixed4		_Color;
			fixed4		_FlowColor;
			fixed4		_EffectCol;
			fixed4		_RimLightColor;

			sampler2D	_MainTex;
			sampler2D	_MaskTex;
			sampler2D	_FlowTex;
			sampler2D	_EffectTex;

			float4		_MainTex_ST;	
			float4		_MaskTex_ST;
			float4		_FlowTex_ST;
			float4		_EffectTex_ST;

			float4		_FlowTexTransform;
			float4		_MaskTexTransform;

			half		_RimLightRange;


			v2f vert (appdata v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				float4 srcPos = ComputeScreenPos(o.pos);
				o.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
				o.uv.zw =  srcPos.xy *_EffectTex_ST.xy/srcPos.w  + _Time.x * _EffectTex_ST.zw;//half2(_InfoVetor.x , srcPos.y *_InfoVetor.y/srcPos.w) + frac(_Time.x * _InfoVetor.zw);
				half3 normal = UnityObjectToWorldNormal(v.normal);
				half3 viewDir = normalize(WorldSpaceViewDir(v.vertex));
				o.rimlight = pow(1.0 - abs(dot(normal, viewDir)), _RimLightRange)* _RimLightColor.rgb;

				o.flowuv.xy = TransFormUV(v.uv, _FlowTex_ST, 1.0);
				o.flowuv.xy = RotateUV(o.flowuv.xy, _FlowTexTransform.zw);
				o.flowuv.xy += frac(_Time.z* _FlowTexTransform.xy);

				o.flowuv.zw = TransFormUV(v.uv, _MaskTex_ST, 1.0);
				o.flowuv.zw = RotateUV(o.flowuv.zw, _MaskTexTransform.zw);
				o.flowuv.zw += frac(_Time.z * _MaskTexTransform.xy);
				return o;
			}		
			fixed4 frag (v2f i) : SV_Target
			{
				fixed4 col = tex2D(_MainTex, i.uv.xy) * _Color;
				fixed3 effect = tex2D(_EffectTex , frac(i.uv.zw), float2(0, 0), float2(0, 0)) * _EffectCol;

				float2 flowUV = lerp(i.flowuv.xy, frac(i.flowuv.xy) , float2(1.0,1.0));
				fixed4 flow = tex2D(_FlowTex, flowUV.xy, float2(0, 0), float2(0, 0)) * _FlowColor;

				float2 maskUV = lerp(i.flowuv.zw, frac(i.flowuv.zw) , float2(1.0, 1.0));
				fixed mask = tex2D(_MaskTex, maskUV.xy, float2(0, 0), float2(0, 0));

				flow.rgb *= mask.r *flow.a;

				col.rgb += effect;
				col.rgb += i.rimlight;
				col.rgb += flow;
				col.rgb *= col.a; 
				return col;
			}
			ENDCG
		}
		Pass
		{
			Name "ShadowCaster"
			Tags { "LightMode" = "ShadowCaster" }
			ZTest LEqual
			CGPROGRAM
			#pragma multi_compile_shadowcaster
			#pragma skip_variants SHADOWS_CUBE
			#pragma vertex Vert_Shadow
			#pragma fragment Frag_Shadow
			#include "Assets/CGInclude/LGameStarActorShadowCaster.cginc"		
			ENDCG
		}
	}
}
