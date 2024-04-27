Shader "UI/StarActor3DAlpha"
{
    Properties
    {
        _MainTex("Main Texture", 2D) = "white" {}
        _BgTex("Bg Texture", 2D) = "white" {}
		_Color("Tint", Color) = (1, 1, 1, 1)
		_XScale("XScale",float) = 1
		_YScale("YScale",float) = 1

		/*
        _StencilComp("Stencil Comparison", Float) = 8
        _Stencil("Stencil ID", Float) = 0
        _StencilOp("Stencil Operation", Float) = 0
        _StencilWriteMask("Stencil Write Mask", Float) = 255
        _StencilReadMask("Stencil Read Mask", Float) = 255
		*/
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
        }

        Cull Off
        Lighting Off
        ZWrite Off
        ZTest[unity_GUIZTestMode]
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
                float4 vertex   : POSITION;
                float4 color    : COLOR;
                float2 texcoord : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 vertex   : SV_POSITION;
                fixed4 color : COLOR;
                float2 texcoord  : TEXCOORD0;
                float4 worldPosition : TEXCOORD1;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            fixed4 _Color;
                
            v2f vert(appdata_t IN)
            {
                v2f OUT;
                UNITY_SETUP_INSTANCE_ID(IN);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(OUT);
                OUT.worldPosition = IN.vertex;
                OUT.vertex = UnityObjectToClipPos(OUT.worldPosition);

                OUT.texcoord = IN.texcoord;

                OUT.color = IN.color * _Color;
                return OUT;
            }

            sampler2D _MainTex;
            sampler2D _BgTex;
			float _XScale;//当前背景大小与实际贴图的比例缩放值。
			float _YScale;
            fixed4 frag(v2f IN) : SV_Target
            {
                half4 color1 = tex2D(_MainTex, IN.texcoord) * IN.color;

				float2 newUv = IN.texcoord;
				newUv.x = _XScale*(newUv.x - 0.5) + 0.5;
				newUv.y = _YScale*(newUv.y - 0.5) + 0.5;
				half4 color2 = tex2D(_BgTex, newUv)*IN.color;
				return color1 + color2 * (1 - color1.a);
            }
            ENDCG
        }
    }
}