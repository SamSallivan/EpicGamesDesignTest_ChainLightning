Shader "LGame/Effect/Glove"
{
    Properties
    {
		_Color("Color",Color) = (1,1,1,1)
        _MainTex ("Texture", 2D) = "white" {}
		_GlowColor("Glow Color",Color) = (1,1,1,1)
		_GlowTex("Glow Texture",2D) = "black"{}
		_GlintColor("Glint Color",Color) = (1,1,1,1)
		_GlintSpeed("Glint Speed",Float) = 0.0
		_GlowSpeed("Glow Speed",Float)=0.0
        [HideInInspector]_AlphaCtrl("AlphaCtrl",Float) = 1.0

	}
	SubShader
	{
		//Tags { "RenderType" = "Opaque" }
          Tags { "LightMode" = "ForwardBase" "Queue" = "Transparent" "RenderType" = "Transparent"  }

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
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
			sampler2D _GlowTex;
			fixed4 _Color;
			fixed4 _GlowColor;
			fixed4 _GlintColor;
			half _GlowSpeed;
			half _GlintSpeed;
            float4 _MainTex_ST;
			float4 _GlowTex_ST;
            half _AlphaCtrl;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
				o.uv.zw = TRANSFORM_TEX(v.uv, _GlowTex)+half2(0,_Time.y*_GlowSpeed);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                // sample the texture
                fixed4 color = float4(_Color.rgb,_Color.a * _AlphaCtrl);
				fixed4 col = tex2D(_MainTex, i.uv.xy)* color;
				col.rgb += _GlintColor *abs(sin(_Time.y*_GlintSpeed));
				fixed4 glow = tex2D(_GlowTex, frac(i.uv.zw))*_GlowColor;
				col += glow;
                return col;
            }
            ENDCG
        }
    }
}
