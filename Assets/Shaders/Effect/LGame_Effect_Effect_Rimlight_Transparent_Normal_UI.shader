// 仅仅只提供给 在UI相机（正交相机）下，需要实现透视效果的特效使用
Shader "LGame/Effect/Effect_Rimlight_Transparent_Normal_UI"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_NormalMap("Normal Map",2D)="bump"{}
		_RimPower("Rim Power",float)=0
		_RimColor("Rim Color",Color)=(0,0,0,1)
		_ViewDir("View",Vector)=(0,0,0,0)
		[Enum(Zero,0,One,1,SrcAlpha,5,OneMinusSrcAlpha,10)] _SrcFactor ("Source Blend Mode", Float) = 1
        [Enum(Zero,0,One,1,SrcAlpha,5,OneMinusSrcAlpha,10)] _DstFactor ("Dest Blend Mode", Float) = 10
		[Enum(Off,0,On,1)] _ZWrite ("ZWrite", Float) = 0
	}
	SubShader
	{
		Tags {"Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent"}
		LOD 100
		Blend [_SrcFactor] [_DstFactor]
		ZWrite [_ZWrite]

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile __ RectClip_On
			#include "UnityCG.cginc"

		struct a2v {
			half4 uv : TEXCOORD0 ;
			half4 vertex : POSITION ;
			half3 normal:NORMAL;
			half4 tangent:TANGENT;
		};

		struct v2f{
			half4 pos : SV_POSITION ;
			half4 uv : TEXCOORD0  ;	
			half3 wNormal:TECXCOORD1;
			half3 wTangent:TEXCOORD2;
			half3 wBitangent :TEXCOORD3;
			half3 viewDir:TEXCOORD4;
			#if RectClip_On
				float3 worldPos	: TEXCOORD5;
			#endif
		};
			sampler2D _MainTex;
			sampler2D _NormalMap;
			half _RimPower;
			fixed4 _RimColor;
			half4 _ViewDir;
			#if RectClip_On
				float4 _EffectClipRect;
			#endif
			float4x4 _Perspective;
		float Get2DClipping (in float2 position, in float4 clipRect)
		{
			float2 inside = step(clipRect.xy, position.xy) * step(position.xy, clipRect.zw);
			return inside.x * inside.y;
		}
		v2f vert(a2v v)
		{
			v2f o;
			o.uv = v.uv;

			o.pos = mul(UNITY_MATRIX_MV, v.vertex);
			o.pos = mul(_Perspective, o.pos);

			o.wNormal = UnityObjectToWorldNormal(v.normal);
			o.wTangent = UnityObjectToWorldNormal(v.tangent.xyz);
			o.wBitangent = cross(o.wNormal, o.wTangent)*v.tangent.w*unity_WorldTransformParams.w;

			//half3 wPos=mul(unity_ObjectToWorld,v.vertex).xyz;
		//	o.viewDir=normalize(UnityWorldSpaceViewDir(wPos));
			o.viewDir=normalize(_ViewDir.xyz);
			#if RectClip_On
				o.worldPos = mul(unity_ObjectToWorld, float4(v.vertex.xyz,1.0)).xyz;
			#endif

			return o;
		}
		fixed4 frag(v2f i) : COLOR
		{
			half3 tNormal=UnpackNormal(tex2D(_NormalMap,i.uv));
			half3 N=normalize(i.wTangent*tNormal.r+i.wBitangent*tNormal.g+i.wNormal*tNormal.b);
			half3 V=normalize(i.viewDir);
			fixed4 col = tex2D(_MainTex, i.uv);

			half NdotV=1-saturate(dot(N,V));
			fixed3 rim=pow(NdotV,_RimPower)*_RimColor.rgb;
			col.rgb+=rim;
			#if RectClip_On
				col.a *= Get2DClipping(i.worldPos.xy , _EffectClipRect);
			#endif
			return col;
		}
			ENDCG
		}
	}
}
