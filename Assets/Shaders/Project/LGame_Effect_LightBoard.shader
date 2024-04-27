Shader "LGame/Effect/LightBoard" {
	Properties{
		_Color("Color",Color)=(1,1,1,1)
		_MainTex("Base texture", 2D) = "white" {}
		_TileX("Tile X",int) = 2
		_TileY("Tile Y",int) = 2
		_Speed("Glint Speed",Float)= 1.0
		_StillRange("Still",Float)=0.5
	}
	SubShader{
		Tags { "Queue" = "Transparent" "IgnoreProjector" = "True" "RenderType" = "Transparent" }
		Blend SrcAlpha OneMinusSrcAlpha
		Cull Off 
		ZWrite Off 
		LOD 100
		Pass {
			CGPROGRAM
			#pragma vertex vert  
			#pragma fragment frag  
			#include "UnityCG.cginc"  
			sampler2D _MainTex;
			float _TileX;
			float _TileY;
			float _Offset;
			float _Speed;
			float _StillRange;
			fixed4 _Color;
		struct v2f {
			float4  pos		: SV_POSITION;
			float2  uv		: TEXCOORD0;
		};
		v2f vert(appdata_full v)
		{
			v2f o;
			o.uv.xy = v.texcoord.xy;
			o.pos = UnityObjectToClipPos(v.vertex);
			return o;
		}
			fixed4 frag(v2f i) : COLOR
			{
				float2 uv = i.uv.xy;
				float2 m = 1.0f / float2(_TileX, _TileY);
				float count = _TileX * _TileY;
				float scale = 1.0f / _StillRange;
				float offset = _Time.y*_Speed;
				uv.x = floor(offset * count * scale) + _TileX;
				uv.y = -floor(uv.x / _TileX);
				uv += i.uv.xy;
				uv = frac(uv * m);
				fixed4 col = tex2D(_MainTex, frac(i.uv.xy*m - float2(0.0f, m.y)));
				fixed4 seq = tex2D(_MainTex,uv);
				col = lerp(col, seq, step(1.0f - _StillRange, frac(offset)))*_Color;
				return col;
			}
			ENDCG
		}
	}
}