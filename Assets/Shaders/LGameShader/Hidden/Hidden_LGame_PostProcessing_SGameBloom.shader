Shader "Hidden/LGame/PostProcessing/SGameBloom"
{
    Properties
    {
        _BloomSrcTex ("_BloomSrcTex", 2D) = "white" {}
        _BloomSrcTex_TexelSize ("_BloomSrcTex_TexelSize", Vector) = (00.00047,0.00104,2146.00000,964.00000)
        _RenderScaleParam ("_RenderScaleParam", Vector) = (01.00000,1.00000,1.00000,1.00000)
        
        _Params ("_Params", Vector) = (039384248320.00000,1.00000,0.00000,0.00000)
        _Threshold ("_Threshold", Vector) = (00.99000,0.49499,0.99002,0.50504)
        
        // upsample only
        _BloomTex ("_BloomTex", 2D) = "white" {}
        _SampleScale ("_SampleScale", float) = 00.56743
    }
    SubShader
    {
        Cull Off
        Zwrite Off
        ZTest Always

        // per-filter + downsample
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag_Prefilter
            #include "UnityCG.cginc"
            #include "Assets/CGInclude/PostProcessing/SGamePostProcessing.cginc"
            ENDCG
        }
        
        // downsample
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag_downsample
            #include "UnityCG.cginc"
            #include "Assets/CGInclude/PostProcessing/SGamePostProcessing.cginc"
            ENDCG
        }
        
        // upsample
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag_upsample
            #include "UnityCG.cginc"
            #include "Assets/CGInclude/PostProcessing/SGamePostProcessing.cginc"
            ENDCG
        }
    }
}