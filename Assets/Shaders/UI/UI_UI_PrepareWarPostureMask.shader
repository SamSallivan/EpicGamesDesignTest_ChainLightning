Shader "UI/UI_PrepareWarPostureMask"
{
    Properties
    {
		[PerRendererData]_MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {      
		Lighting Off
		ZWrite Off
		ZTest[unity_GUIZTestMode]
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
                float4 color : COLOR;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
				fixed4 color : COLOR;
                float4 vertex : SV_POSITION;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
				o.color = v.color;
                o.uv = v.uv;
                return o;
            }

            sampler2D _MainTex;
            fixed4 frag (v2f i) : SV_Target
            {
				float2 uv= i.uv;  
				float4 col = tex2D(_MainTex, uv);
				col.a = 1;
				float len = 0.7;
				float alpha = step(len, uv.x) *(uv.x - len) / (1 - len);
				col = col * i.color;				
				return col * (1 - alpha);
            }
            ENDCG
        }
    }
}
