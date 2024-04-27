Shader "LGame/Effect/Return"
{
	Properties
	{
		_Color	("Color" , Color) = (1,1,1,1)
		_MaskTex("Mask Texture", 2D) = "white" {}
		_RimColor0("RimLight Color 0" , Color) = (0,0,0,1)
		_RimPower0("RimLigh Power 0", Float) = 8
		_RimColor1("RimLight Color 1" , Color) = (0,0,0,1) 
		_RimPower1("RimLigh Power 1", Float) = 8
		[HideInInspector]_AlphaCtrl("AlphaCtrl",range(0,1)) = 1
	}																		   
	SubShader
	{
		Tags { "RenderType"="Transparent"  "Queue"="Transparent" }
		LOD 75
		//画深度
		Pass
		{
			ColorMask 0
			Zwrite On
			Cull Back
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag	
			#include "UnityCG.cginc" 
			struct appdata
			{
				float4	vertex		: POSITION;
			};
			struct v2f
			{
				float4	pos			: SV_POSITION;
				half temp			:TEXCOORD0;
				half4 screenPos		:TEXCOORD1;
			};
			sampler2D	_MaskTex;
			half4		_MaskTex_ST;
			fixed4		_Color;
			v2f vert(appdata v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.screenPos = ComputeScreenPos(o.pos);
				half3 origin = mul(unity_ObjectToWorld, half4(0, 0, 0, 1));
				o.temp = length(UnityWorldSpaceViewDir(origin.xyz));
				return o;
			}
			fixed4 frag(v2f i) : SV_Target
			{
				half2 screenUV = i.screenPos.xy / i.screenPos.w*_ScreenParams.xy / _ScreenParams.x*i.temp;
				half mask = tex2D(_MaskTex, TRANSFORM_TEX(screenUV, _MaskTex));
				mask = step(1.0 - _Color.a, mask);
				clip(mask -0.01);
				return  fixed4(0,0,0,1.0);
			}
			ENDCG
		}
		//画深度 srp
		Pass
		{
			Tags { "LightMode" = "PerZPass" }
			ColorMask 0
			Zwrite On
			Cull Back
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag	
			#include "UnityCG.cginc" 
			struct appdata
			{
				float4	vertex		: POSITION;
			};
			struct v2f
			{
				float4	pos			: SV_POSITION;
				half temp			:TEXCOORD0;
				half4 screenPos		:TEXCOORD1;
			};
			sampler2D	_MaskTex;
			half4		_MaskTex_ST;
			fixed4		_Color;
			v2f vert(appdata v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.screenPos = ComputeScreenPos(o.pos);
				half3 origin = mul(unity_ObjectToWorld, half4(0, 0, 0, 1));
				o.temp = length(UnityWorldSpaceViewDir(origin.xyz));
				return o;
			}
			fixed4 frag(v2f i) : SV_Target
			{
				half2 screenUV = i.screenPos.xy / i.screenPos.w*_ScreenParams.xy / _ScreenParams.x*i.temp;
				half mask = tex2D(_MaskTex, TRANSFORM_TEX(screenUV, _MaskTex));
				mask = step(1.0 - _Color.a, mask);
				clip(mask - 0.01);
				return  fixed4(0,0,0,1.0);
			}
			ENDCG
		}
		Pass
		{
			Tags { "LightMode" = "ForwardBase" }
			Zwrite Off
			Cull Back
			Blend SrcAlpha OneMinusSrcAlpha
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag	

			#include "UnityCG.cginc" 
			struct appdata
			{
				float4	vertex		: POSITION;
				half3	normal		: NORMAL;
				half2	texcoord	: TEXCOORD0;
			};

			struct v2f
			{
				float4	pos			: SV_POSITION;
				half4	viewDir		: TEXCOORD0;
				half3	worldNormal	: TEXCOORD1;
				half4 screenPos		:TEXCOORD2;

			};
			fixed4		_Color;
			sampler2D	_MaskTex;
			half4		_MaskTex_ST;
			half		_RimPower0;
			half		_RimPower1;
			fixed4		_RimColor0;
			fixed4		_RimColor1;
			half        _AlphaCtrl;

			v2f vert (appdata v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				half3 wPos = mul(unity_ObjectToWorld, v.vertex);
				o.viewDir.xyz = UnityWorldSpaceViewDir(wPos);
				o.screenPos = ComputeScreenPos(o.pos);
				half3 origin = mul(unity_ObjectToWorld, half4(0, 0, 0, 1));
				o.viewDir.w = length(UnityWorldSpaceViewDir(origin.xyz));
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				half3 V = normalize(i.viewDir.xyz);
				half3 N = normalize(i.worldNormal);
				half2 screenUV = i.screenPos.xy / i.screenPos.w*_ScreenParams.xy / _ScreenParams.x*i.viewDir.w;
				half mask = tex2D(_MaskTex, TRANSFORM_TEX(screenUV, _MaskTex));
				half OneMinusNoV = saturate(1 - dot(V, N));
				half3 rim = pow(OneMinusNoV, _RimPower0)* _RimColor0.rgb;
				rim += pow(OneMinusNoV, _RimPower1)* _RimColor1.rgb;
				half3 col = rim;
				col += mask * _Color.rgb;
				mask = step(1.0 - _Color.a, mask);
				return  fixed4(col, _Color.a * mask * _AlphaCtrl);
			}
			ENDCG
		}
	}

}