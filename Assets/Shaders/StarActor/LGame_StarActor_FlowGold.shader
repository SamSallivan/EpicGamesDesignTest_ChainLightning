Shader "LGame/StarActor/FlowGold"
{
    Properties
    {
		_Color("Color", Color) = (1,1,1,1)
		_MainTex("Albedo", 2D) = "white" {}
		_FlowMap("Flow Map",2D) = "black"{}
		_MaskMap("Mask Map",2D) = "white"{}
		_FlowColor("Flow Color",Color) = (1,1,1,1)
		_FlowSpeed("Flow Speed",Float) = 0.0
		_BreatheSpeed("Breathe Speed",Float) = 0.0
		[HDR]_RimColor("Rim Color",Color) = (1,1,1,1)
		_RimMin("Rim Min",Range(0,1)) = 0.0
		_RimPower("Rim Power",Range(0.0,16.0)) = 8.0
	}
		CGINCLUDE
		#include "UnityCG.cginc"
		struct a2v
		{
			half4 vertex			: POSITION;
			half2 uv0				: TEXCOORD0;
			half3 normal			: NORMAL;
			half4 tangent			: TANGENT;
		};
		struct v2f_Mecha
		{
			half4 pos				: SV_POSITION;
			half4 uv				: TEXCOORD0;
			half3 viewDir           : TEXCOORD1;
			half3 normalWorld	: TEXCOORD2;
			half4 detail_uv			: TEXCOORD5;
		};
		sampler2D _MainTex;
		sampler2D _FlowMap;
		sampler2D _MaskMap;
		float4 _FlowMap_ST;
		float4 _MainTex_ST;
		fixed4 _Color;
		fixed4 _RimColor;
		float4 _FlowColor;
		float _FlowSpeed;
		float _BreatheSpeed;
		half _RimPower;
		half _RimMin;
	ENDCG
    SubShader
    {
		Tags{ "RenderType" = "Opaque" "PerformanceChecks" = "False" }
		LOD 300
		Pass
		{
			Stencil {
				Ref 16
				Comp always
				Pass replace
			}
			ColorMask 0
			Cull Back
			ZWrite On
			Offset 1,1
		}
		Pass
		{
			Tags{ "LightMode" = "Always" }
			ZWrite Off
			Cull Back
			Blend SrcAlpha OneMinusSrcAlpha
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 3.0
			v2f_Mecha vert(a2v v)
			{
				v2f_Mecha o;
				UNITY_INITIALIZE_OUTPUT(v2f_Mecha,o);
				float3 posWorld = mul(unity_ObjectToWorld, v.vertex).xyz;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv0, _MainTex).xyxy;
				o.detail_uv = TRANSFORM_TEX(v.uv0, _FlowMap).xyxy;
				o.viewDir.xyz = normalize(UnityWorldSpaceViewDir(posWorld));
				o.normalWorld = UnityObjectToWorldNormal(v.normal);
				return o;
			}
			//片元着色器
			fixed4 frag(v2f_Mecha i) : SV_Target
			{
				half3 viewDir = normalize(i.viewDir.xyz);
				half3 normal = normalize(i.normalWorld);
				half4 color = tex2D(_MainTex,i.uv) * _Color;
				half mask = tex2D(_MaskMap, i.uv).r;
				float3 flow = tex2D(_FlowMap, frac(i.detail_uv.xy + float2(0, _Time.y*+_FlowSpeed)))*_FlowColor;
				//flow *= abs(sin(_Time.y*_BreatheSpeed));
				flow *= (1 - color.a);
				flow *= mask;
				half NoV = saturate(dot(normal, viewDir));
				half3 rim = pow(1.0 - NoV, _RimPower)*_RimColor;
				rim *= _RimMin+abs(sin(_Time.y*_BreatheSpeed))*(1.0- _RimMin);
				color.rgb = flow.rgb + color.rgb + rim;
				color.a = saturate(color.a + Luminance(rim + flow.rgb));
				return color;
			}
			ENDCG
		}
		Pass
		{
			Name "ShadowCaster"
			Tags{ "LightMode" = "ShadowCaster" }
			Fog{ Mode Off }
			ZWrite On ZTest Less Cull Off
			CGPROGRAM
			#pragma vertex vert_shadow
			#pragma fragment frag_shadow
			#pragma multi_compile_shadowcaster
			#pragma skip_variants SHADOWS_CUBE
			#include "UnityCG.cginc"
			struct v2f_shadow
			{
				V2F_SHADOW_CASTER;
			};

			v2f_shadow vert_shadow(appdata_base v)
			{
				v2f_shadow o;
				TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
				return o;
			}
			float4 frag_shadow(v2f_shadow i) : COLOR
			{
				SHADOW_CASTER_FRAGMENT(i)
			}
			ENDCG
		}
    }
}
