Shader "LGame/Effect/StarActor/ToonWarp"
{
    Properties
    {
        _Color                                      ("Base_color", Color)                    = (1,1,1,1)
        _MainTex                                    ("Albedo", 2D)                           = "white" {}
        _OutlineStrength                            ("OutLineStrength", Range(0,5))          = 0.5
        _OutlineColor                               ("OutLineColor", Color)                  = (0,0,0,1)

        _WarpTexture ("Warp texture", 2D) = "bump" {}
        _WarpIntensity ("Warp Intensity", Range(0, 0.1)) = 0.05
        _WarpTextureTransform ("Warp Speed", Vector) = (0, 0, 0, 1)

        _BlendMode ("Blend Mode", float) = 0
        _EnableUniqueShadow ("Use UniqueShadow", float) = 0

        [Toggle] _FlowMode ("Use Flow Map Mode?", float) = 0

        _BlendSrc ("BlendSrc", float) = 1
        _BlendDest ("BlendDest", float) = 0
        _LineBlendSrc ("Line Blend Src", float) = 1
        _LineBlendDest ("Line Blend Dest", float) = 0
        _OutlinePushBack ("Outline Z-Fight Correction", float) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
			Name "Default"
			Tags { "LightMode" = "ForwardBase" }
            Blend [_BlendSrc] [_BlendDest]
            
            CGPROGRAM
            #pragma multi_compile __ _FLOWMODE_ON
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            struct appdata
            {
                float4 vertex                   : POSITION;
                float2 uv                       : TEXCOORD0;
            };
        
            struct v2f
            {
                float2 uv                       : TEXCOORD0;
                float4 pos                      : SV_POSITION;
                float2 flowUV                   : TEXCOORD1;
            };
        
            half4                               _Color;
            sampler2D                           _MainTex;
            float4                              _MainTex_ST;
            sampler2D _WarpTexture;
            float4 _WarpTexture_ST;
            float _WarpIntensity;
            float4 _WarpTextureTransform;

            v2f vert (appdata v)
            {
                v2f o;
                UNITY_INITIALIZE_OUTPUT(v2f, o);

                o.pos = UnityObjectToClipPos(v.vertex);

                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                float2 flowUV = v.uv;
                flowUV -= 0.5;
                flowUV = float2(flowUV.x * _WarpTextureTransform.w - flowUV.y * _WarpTextureTransform.z, 
                                flowUV.x * _WarpTextureTransform.z + flowUV.y * _WarpTextureTransform.w);
                flowUV += 0.5;
                flowUV = flowUV * _WarpTexture_ST.xy + _WarpTexture_ST.zw;
                //flowUV += (1 - _WarpTexture_ST.xy) * 0.5;
                //o.flowUV.xy = flowUV + frac(_WarpTextureTransform.xy * _Time.y);
                //o.flowUV.zw = flowUV + frac(_WarpTextureTransform.xy * _Time.y + 0.5);
                o.flowUV = flowUV;

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
            #if _FLOWMODE_ON
                float3 flowDir = tex2D(_WarpTexture, frac(i.flowUV)).xyz;
                flowDir = normalize(flowDir * 2 - 1);
                float2 flow1 = i.uv + flowDir.xy * frac(_Time.y * _WarpTextureTransform.x) * _WarpIntensity;
                float2 flow2 = i.uv + flowDir.xy * frac(_Time.y * _WarpTextureTransform.x + 0.5) * _WarpIntensity;
                half flowLerp = abs(frac(_Time.y * _WarpTextureTransform.x) * 2 - 1);

                fixed4 mainTex = lerp(tex2D(_MainTex, flow1), tex2D(_MainTex, flow2), flowLerp) * _Color;

            #else
                float2 mainTexUV = i.uv;
                float2 flowUV = i.flowUV;
                flowUV += _WarpTextureTransform.xy * _Time.y;
                float3 warpDir = UnpackNormal(tex2Dgrad(_WarpTexture, frac(flowUV), ddx(i.uv), ddy(i.uv))).xyz ;
                mainTexUV += warpDir.xy * _WarpIntensity;
                
                fixed4 mainTex = tex2D(_MainTex, mainTexUV) * _Color;
            #endif

                return mainTex;
            }
            ENDCG
        }
        
        //基础描边Pass
          Pass
        {
            Name "Outline"
            Blend [_LineBlendSrc] [_LineBlendDest]
            Cull Front
            ZTest Less
            Stencil
            {
                Ref 16
                Comp Always
                zFail IncrWrap
            }
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"
            half                        _OutlineStrength;
            sampler2D                   _MainTex;
            fixed4                      _MainTex_ST;
            fixed                       _OutlinePushBack;
            fixed4                      _Color;
            fixed4                      _OutlineColor;
             struct appdata
            {
                float4 vertex               : POSITION;
                //float4 color                : COLOR;
                float2 uv                   : TEXCOORD0;
                float2 uv1                  : TEXCOORD1;
                float3 normal               : NORMAL;
                //float4 tangent              : TANGENT;
            };

            struct v2f
            {
                float2 uv                   : TEXCOORD0;
                float4 vertex               : SV_POSITION;
            };
            v2f vert (appdata v)
            {
                v2f o;
                UNITY_INITIALIZE_OUTPUT(v2f, o);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                half3 normal = normalize(v.normal);
                //float4 tangent = v.tangent;
                //float3 binormal = cross(normal, normalize(tangent.xyz)) * tangent.w;
                //binormal = normalize(binormal);

                half outlineStrength = _OutlineStrength * v.uv1.r;
                
                o.vertex = UnityObjectToClipPos(v.vertex);
                // 顶点色R通道用于软阴影遮罩
                //float3 nOS = tangent.xyz * v.color.w + binormal * v.color.y + normal * v.color.z;
                //float3 offset = mul((float3x3)UNITY_MATRIX_VP, mul((float3x3)UNITY_MATRIX_M, normalize(nOS)));
                float3 offset = mul((float3x3)UNITY_MATRIX_VP, mul((float3x3)UNITY_MATRIX_M, normal));
                o.vertex.xy += normalize(offset.xy) / _ScreenParams.xy * o.vertex.w * outlineStrength * 10;

                #if defined(UNITY_REVERSED_Z)
                o.vertex.z += 1e-6f * _OutlinePushBack;
                #else
                o.vertex.z -= 1e-6f * _OutlinePushBack;
                #endif
                
                return o;
            }
            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);
                col.rgb = GammaToLinearSpace(col.rgb);
                col *= _OutlineColor;
                col.rgb = LinearToGammaSpace(col.rgb);
                col.a *= _Color.a;
                return col;
            }
            ENDCG
        }

    // Pass to render object as a shadow caster
      Pass
		{
			Name "ShadowCaster"
			Tags { "LightMode" = "ShadowCaster" }
			ZTest LEqual
			CGPROGRAM
			#pragma vertex Vert_Shadow
			#pragma fragment Frag_Shadow
			#pragma multi_compile_shadowcaster
			#pragma skip_variants SHADOWS_CUBE
			#pragma shader_feature _TRANSPARENT_SHADOW
			#pragma multi_compile _ _ENABLE_TRANSPARENT_SHADOW
			#include "Assets/CGInclude/LGameStarActorShadowCaster.cginc"				
			ENDCG
		}
     }
     CustomEditor"LGameSDK.AnimTool.LGameStarActorEffectToonGUI"
}

