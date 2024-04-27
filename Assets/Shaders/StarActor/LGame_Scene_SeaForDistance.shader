Shader "LGame/Scene/SeaForDistance"
{
	Properties
	{
		_NormalMap("Normal",2D) = "bump"{}
		_WaveStrength("Wave Strength",Float) = 1
		_MainTex ("Texture", 2D) = "white" {}
		_CausticTex("Caustic",2D) = "white"{}
		_FoamTex("Foam",2D) = "white"{}
		_Speed("Speed-normal_xy/caustic_z/foam_w",Vector) = (1,1,1,1)
		_AlphaCtrl0("Alpha Ctrl 0" ,Range(0,1))=0.1
		_AlphaCtrl1("Alpha Ctrl 1" ,Range(0,1)) = 0.3
	}
	SubShader
	{
		Tags { "RenderType"="Transparent" "Queue"="Transparent" }
		LOD 100
		Zwrite Off
		Blend SrcAlpha OneMinusSrcAlpha
		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float4 uv : TEXCOORD0;
				float4 uv1 : TEXCOORD1;
				float4 vertex : SV_POSITION;
			};
			float4 _Speed;
			sampler2D _NormalMap;
			sampler2D _FoamTex;
			sampler2D _CausticTex;
			float4 _NormalMap_ST;
			float4 _FoamTex_ST;
			float4 _CausticTex_ST;
			sampler2D _MainTex;
			float4 _MainTex_ST;
			float _WaveStrength;
			half _AlphaCtrl0;
			half _AlphaCtrl1;
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
				o.uv.zw = TRANSFORM_TEX(v.uv, _NormalMap);
				o.uv1.xy = TRANSFORM_TEX(v.uv, _FoamTex);
				o.uv1.zw = TRANSFORM_TEX(v.uv, _CausticTex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				float alpha = smoothstep(_AlphaCtrl0, _AlphaCtrl1,1 - i.uv.y);
				float2 normal0 = UnpackNormal(tex2D(_NormalMap, i.uv.zw + _Time.y*float2(_Speed.x,0))).rg;
				float2 normal1 = UnpackNormal(tex2D(_NormalMap, i.uv.zw + _Time.y*float2(0,_Speed.y))).rg;
				float2 normal = normal0 * normal1;
				normal.xy *= _WaveStrength;

				half forward = 1.0 - i.uv.y;

				fixed3 col = tex2D(_MainTex, i.uv.xy + normal* forward);
				float foam_base = tex2D(_FoamTex, i.uv1.xy + float2(0, _Time.y*_Speed.w)).r;
				float foam_distort = tex2D(_FoamTex, i.uv1.xy + float2(0, _Time.y*_Speed.w) + normal).r;
				fixed tap = (1.0 - pow(1.0 - alpha, 8.0));
				fixed foam = lerp(foam_base, foam_distort * tap, i.uv.y);

				float caustic = tex2D(_CausticTex, i.uv1.zw + float2(0,_Time.y*_Speed.z) + float2(0, normal.y)).r;

				col += caustic * i.uv.y * 0.5;
				col = saturate(col + foam);
				alpha = saturate(alpha + Luminance(foam));
				return fixed4(saturate(col.rgb), alpha);
			}
			ENDCG
		}
	}
}
