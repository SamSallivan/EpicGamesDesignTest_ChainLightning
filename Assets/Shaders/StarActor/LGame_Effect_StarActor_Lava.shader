Shader "LGame/Effect/StarActor/Lava"
{
	Properties
	{
		[Header(Texture)]
		_Color("Color",Color) = (1,1,1,1)
		_MainTex("Main",2D) = "white"{}
		_MaskMap("Mask",2D) = "white"{}
		[Header(Motion)]
		[HDR]_GlowColor("Glow Color",Color) = (1,1,1,1)
		_Scale("Scale",Float) = 1.0
		_Speed("Speed",Float) = 1.0
		_Height("Height",Float) = 1.0
		_Offset("Offset",Float) = 0.0
		_Cycle("Cycle",Float)=8.0
		_PeakPosition("Peak Position",Vector) = (0.5,0.5,0,0)
		[Header(Mask)]
		_MinX("Min X",Range(0.0,1.0)) = 0.05
		_MaxX("Max X",Range(0.0,1.0)) = 0.95
		_MinY("Min Y",Range(0.0,1.0)) = 0.05
		_MaxY("Max Y",Range(0.0,1.0)) = 0.95
		[Enum(Off,0,Front,1,Back,2)]_CullMode("Cull Mode",Float)=1
	}
		SubShader
		{
			Tags { "Queue" = "Transparent"  "RenderType" = "Transparent"}
			Pass
			{
				Tags{"LightMode" = "Always"}
				LOD 200
				Cull [_CullMode]
				Blend SrcAlpha OneMinusSrcAlpha
				Zwrite On
				CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag
				#pragma target 3.0
				#include "UnityCG.cginc"
				fixed4		_Color;
				fixed4		_GlowColor;
				sampler2D	_MainTex;
				sampler2D	_MaskMap;
				float4		_MainTex_ST;
				float2		_PeakPosition;
				float _Cycle;
				float _Scale;
				float _Speed;
				float _Height;
				float _Offset;
				float _MinX;
				float _MaxX;
				float _MinY;
				float _MaxY;
				struct a2v
				{
					float2 uv		:TEXCOORD0;
					float4 vertex	:POSITION;
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
					float Mask = step(_MinX, v.uv.x) * step(v.uv.x,_MaxX) * step(_MinY, v.uv.y) * step(v.uv.y,_MaxY);
					float Distance = 1.0- saturate(length(v.uv - _PeakPosition) * _Scale);
					float2 FlowUV = frac(v.uv + _Time.y * _Speed);
					float BiasX = abs(sin(Distance + FlowUV.x * _Cycle));
					float BiasY = abs(sin(Distance + FlowUV.y * _Cycle));
					v.vertex.y += BiasX * BiasY * _Height *  Distance * Mask;
					v.vertex.y -= _Offset;
					o.pos = UnityObjectToClipPos(v.vertex);
					o.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
					o.uv.zw = v.uv;
					o.glow = _GlowColor * Distance;
					return o;
				}
				fixed4 frag(v2f i,fixed facing : VFACE) : COLOR
				{
					half4 Color = tex2D(_MainTex,i.uv.xy) * _Color;
					half Mask = tex2D(_MaskMap, i.uv.zw).r;
					Color.rgb += i.glow.rgb;
					Color.a = Mask;
					return Color;
				}
				ENDCG
			}		
		}
}
