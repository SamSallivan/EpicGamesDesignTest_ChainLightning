Shader "LGame/Effect/ScreenInterference"
{
	Properties
	{
		_Color("Color" , Color) = (1,1,1,1)
		_MainTex ("Main Texture", 2D) = "white" {}
		_EffectTex ("Effect Texture(Tilling控制缩放, offset控制速度)", 2D) = "white" {}
		_EffectCol("Effect Color" , Color) = (0.4,0.1,0,0)


	}
	SubShader
	{
		Tags {"Queue"="AlphaTest"  "RenderType"="Transparent" }
		LOD 100
		Pass
		{
			Blend One Zero
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex	: POSITION;
				float2 uv		: TEXCOORD0;
			};

			struct v2f
			{
				float4 pos		: SV_POSITION;
				float4 uv		: TEXCOORD0;
			};
			half4		_Color;

			sampler2D	_MainTex;
			float4		_MainTex_ST;
			
			sampler2D	_EffectTex;
			float4		_EffectTex_ST;
			fixed4		_EffectCol;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				float4 srcPos = ComputeScreenPos(o.pos);
				o.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
				o.uv.zw =  srcPos.xy *_EffectTex_ST.xy/srcPos.w  + _Time.x * _EffectTex_ST.zw;//half2(_InfoVetor.x , srcPos.y *_InfoVetor.y/srcPos.w) + frac(_Time.x * _InfoVetor.zw);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				fixed4 col = tex2D(_MainTex, i.uv.xy) * _Color;
				fixed3 effect = tex2Dlod(_EffectTex , float4(frac(i.uv.zw),0,0))	* _EffectCol; 
				col.rgb += effect;
				col.rgb *= col.a; 
				return col;
			}
			ENDCG
		}
	}
}
