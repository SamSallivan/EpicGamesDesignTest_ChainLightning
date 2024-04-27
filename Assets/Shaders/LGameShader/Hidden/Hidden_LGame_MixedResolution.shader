Shader "Hidden/LGame_MixedResolution"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
		_LowResTex("LowResTex", 2D) = "white"{}
        _DepthTexParam ("DepthTexParam", vector) = (0, 0, 0, 0)
        __ZBufferParams2("ZBufferParams2", vector) = (0, 0, 0, 0)
    }
    SubShader
    {
        CGINCLUDE
        uniform float4 _ZBufferParams2;
        // Z buffer to linear 0..1 depth
        inline float Linear01Depth2( float z )
        {
            return 1.0 / (_ZBufferParams2.x * z + _ZBufferParams2.y);
        }
        // Z buffer to linear depth
        inline float LinearEyeDepth2( float z )
        {
            return 1.0 / (_ZBufferParams2.z * z + _ZBufferParams2.w);
        }

        inline float EyeDepth2DepthBuffer(float z)
        {
            return (1.0 / z * _ZBufferParams2.z ) - _ZBufferParams2.w / _ZBufferParams2.z;
        }
        ENDCG

        Pass    //0
        {
            Cull Off 
            ZWrite On 
            ZTest off
            ColorMask 0
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                half2 uv : TEXCOORD0;
            };

            struct v2f
            {
                half2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };
            sampler2D _MainTex;
            half4 _DepthTexParam;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }
            #define depthWidthHeight _DepthTexParam.xy
            #define depthOffsetU _DepthTexParam.z
            #define depthOffsetV _DepthTexParam.w
      
            float frag (v2f i) : SV_Depth
            {
                return SAMPLE_DEPTH_TEXTURE(_MainTex, i.uv);
            }
            ENDCG
        }
  
        Pass    //1
        {
            Cull Off 
            ZWrite On 
            ZTest off
            ColorMask 0
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                half2 uv : TEXCOORD0;
            };

            struct v2f
            {
                half2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };
            sampler2D _MainTex;
            half4 _DepthTexParam;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }
            #define depthWidthHeight _DepthTexParam.xy
            #define depthOffsetU _DepthTexParam.z
            #define depthOffsetV _DepthTexParam.w

            inline half DitherIndexValue(half2 ditherUV) {
                float DitherIndexMatrix4x4[16] = {0.0,  8.0/ 16.0,  2.0/ 16.0,  10.0/ 16.0,
                                     12.0/ 16.0, 4.0/ 16.0,  14.0/ 16.0, 6.0/ 16.0,
                                     3.0/ 16.0,  11.0/ 16.0, 1.0/ 16.0,  9.0/ 16.0,
                                     15.0/ 16.0, 7.0/ 16.0,  13.0/ 16.0, 5.0/ 16.0};

                int2 xy = int2(fmod(ditherUV.xy, half2(4.0, 4.0)));
                return DitherIndexMatrix4x4[(xy.x + xy.y * 4)];
            }
      
            float frag (v2f i) : SV_Depth
            {
                float depthOffset = (DitherIndexValue(i.uv * depthWidthHeight) - 0.5) * 1.4;
                float viewSpaceDepth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_MainTex, i.uv));
                viewSpaceDepth += depthOffset;
                return EyeDepth2DepthBuffer(viewSpaceDepth);
            }
            ENDCG
        }
		
		Pass	//2
        {
			Cull Off 
			ZWrite Off 
			ZTest off
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

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            sampler2D _MainTex;
			sampler2D _LowResTex;

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 mainCol = tex2D(_MainTex, i.uv);
				fixed4 particleCol = tex2D(_LowResTex, i.uv);
				fixed3 col = particleCol.rgb + particleCol.a * mainCol.rgb;
                return fixed4(col.rgb, 1.0);
            }
            ENDCG
        }
    }
}
