Shader "LGame/Effect/Effect_DaoGuang"
{
	Properties
	{
		_LineTex("Line Tex",2D)="white"{}
		_RectTex ("Rect Texture", 2D) = "white" {}
		_RectMaskTex("Rect Mask",2D)="white"{}

		_PolyTex("Poly Tex",2D)="white"{}
		_PolyLineTex("Poly Line Tex",2D)="white"{}

		_NoiseTex1("Noise Tex 1",2D)="white"{}

		_RectSpeed("Rect Speed",float)=0
		_PolySpeed("Poly Speed",float)=0

		_Noise1Speed("Noise 1 Speed",float)=0
		_Noise2Speed("Noise 2 Speed",float)=0

		_PolyTile("Poly Tile",float)=1
		_ColorEdge("Color Edge",Color)=(0,0,0,1)
		_ColorPoly("Color Poly",Color)=(0,0,0,1)
	}
	SubShader
	{
		Tags { "RenderType"="Transpaernt" "Queue"="Transparent" }
		LOD 100
		Cull Off
		Zwrite Off
		Blend SrcAlpha One
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
				float4 color:COLOR;
			};

			struct v2f
			{

				float4 uv0:TEXCOORD0;
				float4 uv : TEXCOORD1;
				float4 color:COLOR;
				float4 vertex : SV_POSITION;
			};
			sampler2D _LineTex;
			sampler2D _RectTex;
			sampler2D _RectMaskTex;

			sampler2D _PolyTex;
			sampler2D _PolyLineTex;

			sampler2D _NoiseTex1;

			float4 _PolyTex_ST;
			float4 _RectTex_ST;
			float4 _NoiseTex1_ST;
			half _RectSpeed;
			half _PolySpeed;
			half _Noise1Speed;
			half _Noise2Speed;
			half _PolyTile;
			fixed4 _ColorEdge;
			fixed4 _ColorPoly;
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv0.xy=v.uv;
				o.uv0.zw=TRANSFORM_TEX(v.uv,_NoiseTex1);
				o.uv.xy=TRANSFORM_TEX(v.uv,_RectTex);;
				o.uv.zw=TRANSFORM_TEX(v.uv,_PolyTex);
				o.color=v.color;
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				// sample the texture
				fixed lineCol = tex2D(_LineTex, i.uv0).r;
				fixed rectCol=tex2D(_RectTex, i.uv+half2(_RectSpeed*_Time.y,0)).r;
				fixed rectMaskCol=tex2D(_RectMaskTex, i.uv+half2(_RectSpeed*_Time.y,0)).r;

				fixed polyCol=tex2D(_PolyTex,i.uv.zw+half2(_PolySpeed*_Time.y,0)).r;
				fixed polyLineCol=tex2D(_PolyLineTex,i.uv.zw+half2(_PolySpeed*_Time.y,0)).r;
				fixed polyTile=tex2D(_PolyTex,(i.uv.zw+half2(_PolySpeed*_Time.y,0))*_PolyTile).r;

				fixed noise1=tex2D(_NoiseTex1, i.uv0.xy+half2(_Noise1Speed*_Time.y,0)).r;
				fixed noise2=tex2D(_NoiseTex1, i.uv0.zw+half2(_Noise2Speed*_Time.y,0)).r;
				fixed noise3=tex2D(_NoiseTex1, i.uv0.zw+half2(0,_Noise2Speed*_Time.y)).r;
				fixed4 edge=lerp(0.0.rrrr,_ColorEdge,max(lineCol,rectCol));
				fixed4 poly=
				polyCol*rectMaskCol*(1-rectCol)*(1-lineCol)*min(noise1+0.2,1)
				+polyLineCol*rectMaskCol*(1-lineCol)*(1-rectCol)*(1-polyCol)*(noise1+noise2)*min(noise2+0.2,1)
				+polyTile*rectMaskCol*(1-lineCol)*(1-rectCol)*(1-polyCol)*(1-polyLineCol)*(noise2+noise1)*noise3*noise2*2;

				poly.rgb*=_ColorPoly.rgb;
				fixed4 col=poly+edge;
				col.a*=i.color.a;
				return col;
			}
			ENDCG
		}
	}
}
