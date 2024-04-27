Shader "LGame/Scene/FlagAnimation"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color("Color",Color)=(1,1,1,1)
        _MaskTex("Mask",2D)= "white"{}
        _WaveStrength("WaveStrength",Range(0,1))=0.5
        _WaveSpeed("WaveSpeed",Range(0,20))=10
        _StartWavePos("AniStartPos",Range(-15,15))=0.5
        [HideInInspector]_WaveSoftness("WaveSoftness",Range(0,1))=1
        _WaveDirection("WaveDirection",vector)=(0,0,1,0)
        _PowerSize("PowerSize",Range(1,2))=1
        [SimpleToggle]_RandomWave("RandomWave",Range(0,1))=1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            Name "FORWARD"
            Tags { "LightMode" = "ForwardBase" }
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile __ _FOW_ON _FOW_ON_CUSTOM
            #include "UnityCG.cginc"
            #include "Assets/CGInclude/LGameFog.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
#if _FOW_ON || _FOW_ON_CUSTOM
			half2 fowuv		: TEXCOORD2;
#endif
            };

            sampler2D               _MainTex;
            float4                  _MainTex_ST;
            fixed4                  _Color;
            sampler2D               _MaskTex;
            float4                  _MaskTex_ST;
            half                    _WaveStrength;
            half                    _StartWavePos;
            half                    _WaveSoftness;
            float                   _WaveSpeed;
            float4                  _WaveDirection;
            half                    _PowerSize;
            half                    _RandomWave;
            half                    _Brightness;
            
            float RandomGenerator(float wavestrength)
            {
                //乘PI保证值域在0到2PI之间，让变化范围恰好为一个周期，取得世界空间位置并乘0.7，保证位置不同
                return 2*UNITY_PI*frac(0.7*(unity_ObjectToWorld._14+unity_ObjectToWorld._24+unity_ObjectToWorld._34))*wavestrength;
            }
            v2f vert (appdata v)
            {
                v2f o;
                float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                fixed4 mask = tex2Dlod(_MaskTex,float4(o.uv,0,0));//使用texlod
                float windsize = mask.r*smoothstep(_StartWavePos+_WaveSoftness,_StartWavePos-_WaveSoftness,worldPos.y)
                *pow(_WaveStrength,_PowerSize)*(0.5+0.5*sin(2*UNITY_PI*frac(_Time.x*_WaveSpeed)+0.2*worldPos.y+2*mask.g+RandomGenerator(_RandomWave)));
                v.vertex.xyz += normalize(_WaveDirection.xyz)*windsize;
                //Fow Code 
#if _FOW_ON || _FOW_ON_CUSTOM
                o.fowuv = half2 ((worldPos.x - _FOWParam.x) / _FOWParam.z, (worldPos.z - _FOWParam.y) / _FOWParam.w);
#endif
                o.vertex = UnityObjectToClipPos(v.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                col.rgb = _Color.rgb*col.rgb;
                #if _FOW_ON || _FOW_ON_CUSTOM
                    LGameFogApply(col, i.vertex.xyz, i.fowuv); // ApplY Fog
                #endif
                
                col.rgb *= 1.0 + _Brightness;
                return col;
            }
            ENDCG
        }
    }
}
