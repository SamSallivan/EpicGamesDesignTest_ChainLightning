Shader "UI/Transparent Mesh"
{
    Properties
    {
        [PerRendererData]_MainTex("Sprite Texture", 2D) = "white" {}
        _FontTex("Font Texture", 2D) = "white"{}
        _Color("Tint", Color) = (1,1,1,1)
    }

    SubShader
    {
        Tags
        {
            "Queue" = "Transparent"
            "IgnoreProjector" = "True"
            "RenderType" = "Transparent"
            "PreviewType" = "Plane"
            "CanUseSpriteAtlas" = "True"
			"LightMode" = "ForwardBase"
        }

        LOD 100

        Cull Off
        Lighting Off
        ZWrite Off
        ZTest Always
        Blend SrcAlpha OneMinusSrcAlpha

        Pass
        {
            Name "Default"
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 2.0

            #include "UnityCG.cginc"
            #include "UnityUI.cginc"

            struct appdata_t
            {
                float4 vertex    : POSITION;
                fixed4 color     : COLOR;
                float4 texcoord0 : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 vertex   : SV_POSITION;
                fixed4 color : COLOR;
                float3 texcoord0 : TEXCOORD0;
                float3 texcoord1 : TEXCOORD1;
                float4 worldPosition : TEXCOORD2;

                UNITY_VERTEX_OUTPUT_STEREO
            };


            fixed4 _TextureSampleAdd;
            fixed4 _Color;

            v2f vert(appdata_t IN)
            {
                v2f OUT;
                UNITY_SETUP_INSTANCE_ID(IN);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(OUT);
                OUT.worldPosition = IN.vertex;
                OUT.vertex = UnityObjectToClipPos(OUT.worldPosition);

                OUT.texcoord0.xy = IN.texcoord0.xy;
                OUT.texcoord1.xy = IN.texcoord0.zw;
                OUT.texcoord1.z = 2048 * (IN.texcoord0.z + IN.texcoord0.w);
				if (IN.texcoord0.x + IN.texcoord0.y > 0.001)
				{
					OUT.texcoord0.z = 1;
				}
				else
				{
					OUT.texcoord0.z = 0;
				}
                //OUT.texcoord0.z = step(0.001,IN.texcoord0.x+IN.texcoord0.y);
                
                OUT.color = IN.color * _Color;

                return OUT;
            }

            sampler2D _MainTex;
            sampler2D _FontTex;


            fixed4 frag(v2f IN) : SV_Target
            {
                fixed4 color;

                if(IN.texcoord0.z == 0)
                {
                    fixed4 fontColor = 1;
                    fontColor.a = (tex2D(_FontTex, IN.texcoord1) + _TextureSampleAdd).a;
                    color = fontColor;
                }
                else
                {
                    color = (tex2D(_MainTex, IN.texcoord0) + _TextureSampleAdd);
                }
                
				#ifdef UNITY_UI_ALPHACLIP
				        clip(color.a - 0.001);
				#endif

						color *= IN.color;

                return color;
            }
            ENDCG
        }
    }

    SubShader
	{
		Tags
        {
            "Queue" = "Transparent"
            "IgnoreProjector" = "True"
            "RenderType" = "Transparent"
            "PreviewType" = "Plane"
            "CanUseSpriteAtlas" = "True"
			"LightMode" = "ForwardBase"
        }
        LOD 5

        Cull Off
        Lighting Off
        ZWrite Off
        ZTest Always
        Blend One One

		Pass
		{
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
