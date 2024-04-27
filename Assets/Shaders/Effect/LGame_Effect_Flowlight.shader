Shader "LGame/Effect/Flowlight"
{
    Properties
    {
		_Color("Color" , Color) = (1,1,1,1)
        _MainTex ("Texture", 2D) = "white" {}
		_MaskTex("Mask Texture", 2D) = "white" {}
		_FlowlightTex("Flowlight Texture", 2D) = "white" {}
		[hdr]_FlowlightCol("Flowlight Color", Color) = (0,0,0,0)
    }
    SubShader
    {
        Tags {"Queue" = "Transparent" "RenderType"="Transparent" }
        LOD 100
		ZWrite Off
		Blend One OneMinusSrcAlpha
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
                float2 uv		: TEXCOORD0;
				float2 uvMask	: TEXCOORD1;
				float2 uvFlow	: TEXCOORD2;
                float4 vertex	: SV_POSITION;
            };

			fixed4 _Color;
            sampler2D _MainTex;
			sampler2D _MaskTex;
			float4 _MaskTex_ST;
			sampler2D _FlowlightTex;
			float4 _FlowlightTex_ST;
			fixed4 _FlowlightCol;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
				o.uvMask = v.uv * _MaskTex_ST .xy + _MaskTex_ST.zw;
				o.uvFlow = v.uv * _FlowlightTex_ST .xy + _FlowlightTex_ST.zw * _Time.y;
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv) * _Color;
				fixed4 flowlight = tex2D(_FlowlightTex, frac(i.uvFlow)) * tex2D(_MaskTex, i.uvMask) * _FlowlightCol;
				col.rgb += flowlight.rgb * flowlight.a;

                return col ;
            }
            ENDCG
        }
    }
}
