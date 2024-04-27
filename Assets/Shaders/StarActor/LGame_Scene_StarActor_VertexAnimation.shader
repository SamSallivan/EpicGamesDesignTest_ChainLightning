Shader "LGame/Scene/StarActor/Vertex Animation" {
	Properties 
	{
		_Color("Color",Color)=(1,1,1,1)
		_MainTex("Main",2D)="white"{}
		_NoiseTex("Noise",2D) = "black"{}
		_MaskTex("Mask",2D) = "black"{}
		_Speed("Speed",Float)=1.0
		_Height("Height",Float) = 1.0
		_Offset("Offset",Float) = 0.0
		[HDR]_GlowColor("Glow Color",Color) = (1,1,1,1)
	}
	SubShader 
	{
		Tags { "Queue"="Geometry"  "RenderType"="Opaque"}

		Pass
		{
			Tags{"LightMode"="Always"}
			LOD 200

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 3.0
			#include "UnityCG.cginc"
			fixed4		_Color;
			fixed4		_GlowColor;
			sampler2D	_MainTex;
			sampler2D	_NoiseTex;
			sampler2D	_MaskTex;
			float4		_MainTex_ST;	
			float4		_NoiseTex_ST;
			float _Speed;
			float _Height;
			float _Offset;
			struct a2v
			{
				float2 uv0		:TEXCOORD0 ;
				float2 uv1		:TEXCOORD1;
				float4 vertex	:POSITION ;
			};
			struct v2f
			{
				float4 pos			:SV_POSITION;
				float4 uv			:TEXCOORD0;
				half4 glow			:TEXCOORD1;	

			};
			v2f vert(a2v v, uint vid : SV_VertexID)
			{
				v2f o;
				float Mask = tex2Dlod(_MaskTex, float4(v.uv1, 0, 0));
				float2 uv = TRANSFORM_TEX(v.uv1, _NoiseTex);
				float Bias = frac(uv.y + _Time.x * _Speed * (1.0- Mask * 0.75));
				float Noise = tex2Dlod(_NoiseTex, float4(uv.x, Bias, 0, 0));
				v.vertex.y += Noise * Mask * _Height;
				v.vertex.y -= _Offset;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv.xy = TRANSFORM_TEX(v.uv0, _MainTex);
				o.glow = Mask * _GlowColor * Noise;
				return o;
			}
			fixed4 frag(v2f i,fixed facing : VFACE) : COLOR
			{
				half4 Color = tex2D(_MainTex,i.uv.xy) * _Color;
				Color.rgb += i.glow.rgb;
				return Color;
			}
			ENDCG
		}	
	}
}
