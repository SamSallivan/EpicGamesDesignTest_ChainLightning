Shader "LGame/UI/MetalWater"
{
    Properties
    {
        [PerRendererData] _MainTex ("Sprite Texture", 2D) = "white" {}
		_Strength("Normal Strength", Range(0,1)) = 0.142
		_FlowTileX("Flow Tile X", Float) = 2.69
		_FlowTileY("Flow Tile Y", Float) = 5.46
		_WaveShape("Wave Shape", Vector) = (2.2,0.59,0,0)
		_WaveStrength("Wave Strength", Vector) = (-0.11,-0.27,0,0)
		_FlowSpeed("Speed",Range(-1,1)) = -0.24
		_RampMap("Ramp", 2D) = "" {}
        [HideInInspector]_StencilComp ("Stencil Comparison", Float) = 8
        [HideInInspector]_Stencil ("Stencil ID", Float) = 0
        [HideInInspector]_StencilOp ("Stencil Operation", Float) = 0
        [HideInInspector]_StencilWriteMask ("Stencil Write Mask", Float) = 255
        [HideInInspector]_StencilReadMask ("Stencil Read Mask", Float) = 255

        [HideInInspector]_ColorMask ("Color Mask", Float) = 15

    }
    SubShader
    {
        Tags
        {
            "Queue"="Transparent"
            "IgnoreProjector"="True"
            "RenderType"="Transparent"
            "PreviewType"="Plane"
            "CanUseSpriteAtlas"="True"
        }

        Stencil
        {
            Ref [_Stencil]
            Comp [_StencilComp]
            Pass [_StencilOp]
            ReadMask [_StencilReadMask]
            WriteMask [_StencilWriteMask]
        }

        Cull Off
        Lighting Off
        ZWrite Off
        ZTest [unity_GUIZTestMode]
        Blend SrcAlpha OneMinusSrcAlpha
        ColorMask [_ColorMask]

        Pass
        {
            Name "Default"
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 2.0

            #include "UnityCG.cginc"
            #include "UnityUI.cginc"

            #pragma multi_compile __ UNITY_UI_CLIP_RECT

            struct appdata
            {
                float4 vertex   : POSITION;
                float4 color    : COLOR;
                float2 texcoord : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 vertex   : SV_POSITION;
                fixed4 color    : COLOR;
                float4 uv       : TEXCOORD0;
                float4 worldPosition : TEXCOORD1;
                UNITY_VERTEX_OUTPUT_STEREO
            };
            sampler2D _MainTex;
            fixed4 _TextureSampleAdd;
            float4 _ClipRect;
            float4 _MainTex_ST;
			float4 _WaveShape;
			float4 _WaveStrength;
			float	_FlowTileX;
			float	_FlowTileY;
			float	_FlowSpeed;
			float	_Strength;
            sampler2D _RampMap;
            v2f vert (appdata v)
            {
               v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                o.worldPosition = v.vertex;
                o.vertex = UnityObjectToClipPos(o.worldPosition);
                o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex);   
				o.uv.zw = o.worldPosition.xy;
				o.color = v.color ;
                return o;
            }
			float2 dir(float2 p, float2 freq, float phase)
			{
				float x = dot(p, freq) + phase;
				float sinx, cosx;
				sincos(x, sinx, cosx);
				return float2(-freq.x * sinx, freq.y * cosx);
			}
			float2 wind(float2 p, float t)
			{
				t *= 5.;
				float2 wave = t * _WaveShape;
				float2 dx =_WaveStrength.x * dir(p, float2(0.1, 0.11), wave.x) + _WaveStrength.y * dir(p, float2(-0.12, 0.1), wave.y);
				return dx;
			}
            fixed4 frag (v2f i) : SV_Target
            {
				float2 uv = i.uv.zw;
				//uv.x =abs(0.5 - uv.x) * 2.0;
				//uv.x =sqrt(uv.x);
				float2 p = uv * float2(_FlowTileX, _FlowTileY) * 0.01f;
				float2 dx = wind(p, _Time.y * _FlowSpeed.x);
				//displacement normal
				float3 normal = normalize(float3(-100.0f * dx.xy, 1.));
				//cloth normal modulation
				normal = 1.6 * normal;
				normal.xy *= _Strength;
				normal = normalize(normal);
				float3 col = tex2D(_RampMap, normal.xy * 0.5 + 0.5);
				fixed Alpha = tex2D(_MainTex, i.uv.xy).a * i.color.a;
                #ifdef UNITY_UI_CLIP_RECT
					Alpha *= UnityGet2DClipping(i.worldPosition.xy, _ClipRect);
                #endif
				return fixed4(col, Alpha);
            }
            ENDCG
        }
    }
}
