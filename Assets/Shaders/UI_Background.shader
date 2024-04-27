Shader "UI/Background"
{
    Properties
    {
        _MainTex ("Base (RGB)", 2D) = "white" {}
    }

    SubShader 
    {
        Tags { "RenderType"="Background" "IgnoreProjector" = "True" "Queue" = "Background" "LightMode" = "ForwardBase"}
        LOD 100

        Pass
		{
            Lighting Off
            Fog { Mode Off }
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            sampler2D _MainTex;

            struct appdata
            {
                half4 vertex : POSITION;
                half2 texcoord : TEXCOORD0;
            };

            struct v2f 
            {
                half4 pos	: SV_POSITION;
                half2 uv	: TEXCOORD0;
            };

            v2f vert (appdata v)
            {	
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.texcoord;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                return tex2D(_MainTex , i.uv);
            }
            ENDCG
        }
    }

    SubShader
	{
		Tags { "RenderType"="Background" "IgnoreProjector" = "True" "Queue" = "Background" "LightMode" = "ForwardBase"}
        LOD 5

		Pass
		{
            Lighting Off
            Fog { Mode Off }
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            struct appdata_t
            {
                float4 vertex    : POSITION;
            };

            float4 vert(appdata_t IN) : SV_POSITION
            {
                return UnityObjectToClipPos(IN.vertex);
            }
			
			fixed4 frag () : SV_Target
			{
				return fixed4(0.15, 0.06, 0.03, 0);
			}
			ENDCG
		}
	}
}