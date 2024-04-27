Shader "UI/StarActor3D"
{
    Properties
    {
        _MainTex("Main Texture", 2D) = "white" {}
        _Color("Tint", Color) = (1, 1, 1, 1)

		_BorderBlend("Border Blend Range", Vector) = (0, 0, 0, 0)
		_BorderBlendAlpha("Border Blend Alpha Range", vector) = (0,0,0,0)

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

			#pragma multi_compile __ SOFT_CLIP

            #include "UnityCG.cginc"
            #include "UnityUI.cginc"
			#include "Assets/CGInclude/LGameSysUI.cginc"
            
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
			float4 _ClipRect;

#ifdef SOFT_CLIP
			half4 _BorderBlend;
			float4 _BorderBlendAlpha;
#endif
                
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
                
            fixed4 frag(v2f IN) : SV_Target
            {
                half4 color = tex2D(_MainTex, IN.texcoord) * IN.color;
				color.a = 1;

#ifdef SOFT_CLIP
				color.a *= LGameGetSoft2DClippingEx(IN.worldPosition, _ClipRect, _BorderBlend, _BorderBlendAlpha);

#endif

                return color;
            }
            ENDCG
        }
    }
}