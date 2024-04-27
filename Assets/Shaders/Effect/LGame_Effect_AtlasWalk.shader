Shader "LGame/Effect/AtlasWalk"
{
    Properties
    {
		_Color("Color", Color) = (1,1,1,1)
        _MainTex ("Texture", 2D) = "white" {}
		_TileX("Tile X",int) = 2
		_TileY("Tile Y",int) = 2
		_Fps("FPS",Float) = 1.0
		[SimpleToggle]_Inverse("Inverse",int)=0.0
	}
		SubShader
		{
			Tags { "RenderType" = "Transparent" "Queue" = "Transparent" }
			LOD 100
			Blend SrcAlpha OneMinusSrcAlpha
			Zwrite Off
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
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
			half _TileX;
			half _TileY;
			half _Fps;
			half _Inverse;
			fixed4 _Color;
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv.xy = v.uv;
                return o;
            }

			fixed4 frag(v2f i) : COLOR
			{
				float2 uv = i.uv.xy;
				float count = _TileX * _TileY;
				//uv.x = floor(_Time.y*_Fps * count)+ _TileX;
				//uv.x = -floor(_Time.y*_Fps * count)+ _TileX-1.0;
				uv.x = floor(_Time.y*_Fps * count)*(1.0-_Inverse*2.0)+ _TileX- _Inverse;
				uv.y = -floor(uv.x / _TileX);
				uv += i.uv.xy;
				uv = frac(uv * 1.0f / float2(_TileX, _TileY));
				fixed4 col = tex2D(_MainTex,uv)*_Color;
				return col;
			}
            ENDCG
        }
    }
}
