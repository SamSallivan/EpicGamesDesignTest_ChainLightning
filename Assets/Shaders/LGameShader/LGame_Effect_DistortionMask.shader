Shader "LGame/Effect/DistortionMask"
{
    Properties
    {
        [Header(GlobalSetting)]
        _DistortionStrength("扭曲强度",Range(0,1))=1
        _NormalMode("用模型顶点法线", range(0,1)) = 0
        [SimpleToggle]_ScaleOnCenter("全局贴图中心缩放", range(0,1)) = 0
        [Header(NormalNoiseTexture)]
        _MainTex("NormalNoise", 2D) = "black" {}
        _MainTexTransform("MainTexTransform",vector)=(0,0,0,0)
        [SimpleToggle]_WrapMode("贴图重复", range(0,1)) = 0
        [Header(MaskTexture)]
        _Mask("Mask", 2D) = "white" {}
        _MaskTransform("MaskTransform",vector)=(0,0,0,0)
        [HideInInspector]_WrapModeS("贴图重复", range(0,1)) = 0//之所以不将这个参数暴露出来，是因为调节时容易产生界限分明的线，和采样有关
        [HideInInspector] _SrcBlend ("__src", Float) = 1.0
        [HideInInspector] _DstBlend ("__dst", Float) = 0.0
    }
        SubShader
    {
        Tags { "RenderType" = "Transparent" "Queue" = "Transparent" "DisableBatching" = "True"}
        LOD 100

        Pass
        {
            Name "FORWARD"
            Tags { "LightMode" = "DistortedObjectPass" }
            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha ,OneMinusDstColor One

            ZTest Off
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma shader_feature _DISTORT_DEBUG_ON
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex               : POSITION;
                float2 uv                   : TEXCOORD0;
                float3 normal               : NORMAL;
                float4 tangent              : TANGENT;
                float4 color                : COLOR;
            };

            struct v2f
            {
                float4 uv                   : TEXCOORD0;
                float4 vertex               : SV_POSITION;
                float3 normalDir            : TEXCOORD1;
                float3 tangentDir           : TEXCOORD2;
                float3 bitangentDir         : TEXCOORD3;
                float4 vertexCol            : TEXCOORD4;
            };

            half                            _DistortionStrength;
            sampler2D                       _MainTex;
            float4                          _MainTex_ST;
            half4                           _MainTexTransform;
            half                            _ScaleOnCenter;
            half                            _WrapMode;
            half                            _WrapModeS;
            half                            _NormalMode;
            sampler2D                       _Mask;
            float4                          _Mask_ST;
            half4                           _MaskTransform;
            inline float2 TransFormUV(float2 argUV, float4 argST)
            {
                float2 result = argUV * argST.xy;
                result += _ScaleOnCenter * (1 - argST.xy) * 0.5;
                return result;
            }
            inline float2 RotateUV(float2 uv,float2 uvRotate)
            {
                float2 outUV;
                outUV = uv - 0.5 * _ScaleOnCenter;
                outUV = float2(    outUV.x * uvRotate.y - outUV.y * uvRotate.x ,
                                outUV.x * uvRotate.x + outUV.y * uvRotate.y );
                return outUV + 0.5 * _ScaleOnCenter;
            }
            inline float2 TransFormUV(float2 argUV,float4 argST , float4 trans)
            {
                float2 result =  RotateUV(argUV , trans.zw)  * argST.xy + argST.zw;
                result += _ScaleOnCenter * (1 - argST.xy)*0.5;
                return result + frac(trans.xy * _Time.y );
            }
            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv.zw  =TransFormUV(v.uv.xy,_Mask_ST,_MaskTransform);
                //o.uv.xy = TransFormUV(v.uv.xy, _MainTex_ST) + frac(_MainTexUVSpeed.xy * _Time.y);
                o.uv.xy = TransFormUV(v.uv.xy,_MainTex_ST,_MainTexTransform);
                o.normalDir = UnityObjectToWorldNormal(v.normal);
                o.tangentDir = normalize(mul(unity_ObjectToWorld, float4(v.tangent.xyz, 0.0)).xyz);
                o.bitangentDir = normalize(cross(o.normalDir, o.tangentDir) * v.tangent.w);
                o.vertexCol = v.color;
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                i.uv = lerp(i.uv, frac(i.uv), float4(_WrapMode, _WrapMode, _WrapModeS, _WrapModeS));
                float4 NormalTex = tex2D(_MainTex, i.uv.xy);
                float3 NormalNoise = UnpackNormal(NormalTex).xyz;
                float3x3 tangentTransform = float3x3(i.tangentDir, i.bitangentDir, i.normalDir);
                //取世界空间法线
                float3 NormalNoiseFini = normalize(mul(NormalNoise, tangentTransform));
                NormalNoiseFini = lerp(NormalNoiseFini, i.normalDir, _NormalMode);
                float3 MSNormalNoiseFini =UnityWorldToObjectDir(NormalNoiseFini);
                //战场向上方向的法线为（0，1，0），故取世界空间法线的xz方向用作扰动，把(-1,1)值映射到（0，0.8）之间
                //half2 DistortNormal =0.8*(NormalNoiseFini.xz*0.5+0.5);
                half2 DistortNormal =0.8*(MSNormalNoiseFini.xz*0.5+0.5);
                half4 Mask = tex2D(_Mask, i.uv.zw);
                half Strength = i.vertexCol.a*Mask.r*_DistortionStrength;
                //因为法线中的0被映射到了0.4，因此mask也需要映射到0.4才能实现蒙版效果
                //因为颜色范围为[0,255],因此必须取一个相乘得整数的映射值，只能选择0.4
                DistortNormal =lerp(half2(0.4,0.4),DistortNormal,Strength);
                //xz方向被存在了输出贴图的rg通道，ba通道设为0
                float4 col = float4(DistortNormal,0,Strength);
                //当开启Debug模式时，传入蒙版作为透明度，反之则传入正常透明度
#if _DISTORT_DEBUG_ON
                NormalTex.a = Mask.r;
                col = NormalTex;
#endif
                return col;
            }
    ENDCG
      }
    }
    CustomEditor"LGameInGameDistortionGUI"
}
