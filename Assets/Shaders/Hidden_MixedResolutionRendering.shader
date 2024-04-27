Shader "Hidden/MixedResolutionRendering"
{
    
	Properties 
    {
		_MainTex ("Base (RGB)", 2D) = "white" {}
	}

    CGINCLUDE

        #include "UnityCG.cginc"
        // #pragma target 5.0
        
        struct a2v 
        {
            float4 vertex : POSITION;
            float2 texcoord : TEXCOORD0;
        };    

        struct v2f 
        {
            float4 pos : SV_POSITION;
            float2 uv : TEXCOORD0;
            float4 uv1 : TEXCOORD1;   
            float4 uv2 : TEXCOORD2;     
        };

        sampler2D _MainTex;
        sampler2D _LowResolutionTexture;
	    sampler2D _CameraDepthTexture;
        sampler2D _CameraDepthTextureLow;
        float4 _CameraDepthTexture_TexelSize;
        float4 _CameraDepthTextureLow_TexelSize;

        /// <summary>
        /// Pass: downsample depth
        /// </summary>
        v2f DownSampleDepthVert(a2v v)
        {
            v2f o;
            o.pos = UnityObjectToClipPos(v.vertex);
            o.uv = v.texcoord;
            
            // uv00
            o.uv1.xy = v.texcoord - 0.5 * _CameraDepthTexture_TexelSize.xy;
            // uv10
            o.uv1.zw = o.uv1.xy + float2(_CameraDepthTexture_TexelSize.x, 0);
            // uv01
            o.uv2.xy = o.uv1.xy + float2(0, _CameraDepthTexture_TexelSize.y);
            // uv11
            o.uv2.zw = o.uv1.xy + _CameraDepthTexture_TexelSize.xy;

            return o;
        }

        float DownSampleDepthFrag(v2f i) : SV_Depth 
        {
            float d1 = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv1.xy);
            float d2 = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv1.zw);
            float d3 = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv2.xy);
            float d4 = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv2.zw);

            float minDepth = min(min(d1, d2), min(d3, d4));
            float maxDepth = max(max(d1, d2), max(d3, d4));

            float chessboard = floor(i.pos.x) + floor(i.pos.y);
            chessboard = frac(chessboard * 0.5);
            chessboard *= 2;

            // todo: remove if
            return chessboard > 0.5 ? maxDepth : minDepth;
        }

        /// <summary>
        /// Pass: upsample and composite
        /// </summary>
        void updateNearestSample(float depthLowRes, float depthFullRes, float2 uv, inout float minDist, inout float2 nearestUV)
        {
            float depthDelta = abs(depthLowRes - depthFullRes);
            if (depthDelta < minDist)
            {
                minDist = depthDelta;
                nearestUV = uv;
            }
        }

        // Jansen, Jon & Bavoil, Louis. 2011. Fast rendering of opacity-mapped particles using DirectX 11 tessellation and mixed resolutions. 
        fixed4 NearestUpsample(v2f i)
        {
            // sample depth
            float z   = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv));
            float z00 = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTextureLow, i.uv1.xy));
            float z10 = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTextureLow, i.uv1.zw));
            float z01 = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTextureLow, i.uv2.xy));
            float z11 = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTextureLow, i.uv2.zw));

            // find closest depth to the full res depth
            float  minDist = 1.e8f;
            float2 nearestUV = i.uv1.xy;
            updateNearestSample(z00, z, i.uv1.xy, minDist, nearestUV);
            updateNearestSample(z10, z, i.uv1.zw, minDist, nearestUV);
            updateNearestSample(z01, z, i.uv2.xy, minDist, nearestUV);
            updateNearestSample(z11, z, i.uv2.zw, minDist, nearestUV);

            return tex2D(_LowResolutionTexture, nearestUV);
        }

        v2f CompositeVert(a2v v)
        {
            v2f o;
            o.pos = UnityObjectToClipPos(v.vertex);
            o.uv = v.texcoord;
            
            // uv00
            o.uv1.xy = v.texcoord - 0.5 * _CameraDepthTextureLow_TexelSize.xy;
            // uv10
            o.uv1.zw = o.uv1.xy + float2(_CameraDepthTextureLow_TexelSize.x, 0);
            // uv01
            o.uv2.xy = o.uv1.xy + float2(0, _CameraDepthTextureLow_TexelSize.y);
            // uv11
            o.uv2.zw = o.uv1.xy + _CameraDepthTextureLow_TexelSize.xy;

            return o;
        }
        
        fixed4 CompositeFrag(v2f i) : SV_Target 
        {
            return NearestUpsample(i);
        }
    ENDCG
    
	SubShader 
    {
	    // 0 - DownSample Depth
        Pass
        {
            Cull Off ZWrite On ZTest Always

            CGPROGRAM

                #pragma vertex DownSampleDepthVert 
                #pragma fragment DownSampleDepthFrag

            ENDCG
        }

        // 1 - Composite
        Pass
        {
            Cull Off ZWrite Off ZTest Always
			Blend One SrcAlpha

            CGPROGRAM

                #pragma vertex CompositeVert
                #pragma fragment CompositeFrag

            ENDCG
        }
    }
}
