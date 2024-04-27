Shader "LGame/StarActor/Toon"
{
    Properties
    {
        _Color                                      ("Base_color", Color)                    = (1,1,1,1)
        _MainTex                                    ("Albedo", 2D)                           = "white" {}
        _MatPropertyTexture                         ("Smoothness/Metallic/Occlusion", 2D)    = "white" {}
        _ToonCombined                               ("Toon atlas", 2D)                       = "white" {}
        _ToonTextureIndent                          ("Toon atlas indent", int)               = 0
        [hdr]_MidtoneColor                          ("Midtone Color", Color)                 = (0.9,0.53,0.5,1)
        //_MidtoneTexture                             ("Midtone Texture", 2D)                  = "white" {}
        _Subsurface                                 ("subsurface", Range(0,1)) = 0.2
        _CoreShadowColor                            ("Core Shadow Color", Color)             = (0.72,0.64,0.72,1)
        //_CoreShadowTexture                          ("Core Shadow Texture", 2D)              = "white" {}
        _MidtoneRampTexture                         ("Shadow Ramp", 2D)                      = "white" {}
        _Smoothness                                 ("Smoothness", Range(0,1))               = 0.5
        _SmoothnessThreshold                        ("Smoothness softness", Range(0,1))      = 0
        _UseSmoothnessTexure                        ("UseSmoothness", Range(0,1))            = 0
        [hdr]_HighlightColor                        ("Highlight Color", Color)               = (0.8, 0.8, 0.8, 1)
        //_HighlightTexture                           ("Highlight Color Texture", 2D)          = "white" {}
        //_HighlightRampTexture                       ("HighlightRamp", 2D)                    = "black" {}
        _NormalTexture                              ("NormalMap", 2D)                        = "bump" {}
        _NormalStrength                             ("NormalStrength", Range(0,1))           = 0.5
        //_EmissionTexture                            ("EmissionTex", 2D)                      = "white"{}
        [HDR]_EmissionColor                         ("EmissionColor", Color)                 = (0,0,0,1)
        _RimlightRange                              ("RimlightRange", Range(0.01, 1))        = 1
        _RimlightStrength                           ("RimlightStrength", Range(0.01,0.5))    = 0.01
        _RimlightColor                              ("RimlightColor", Color)                 = (1,1,1,1)
        _OutlineStrength                            ("OutLineStrength", Range(0,5))          = 0.5
        _OutlineColor                               ("OutLineColor", Color)                  = (0,0,0,1)
        _ShadowOutlineStrength                      ("Shadow_Outline_Strength", Range(0,1))  = 0.5
        _ShadowStrength                             ("Self Shadow Strength", Range(0,1))          = 1
        
        [Enum(UnityEngine.Rendering.BlendMode)] _BlendSrc ("BlendSrc", float)                = 1
        [Enum(UnityEngine.Rendering.BlendMode)] _BlendDest ("BlendDest", float)              = 0
        [Enum(UnityEngine.Rendering.BlendMode)] _LineBlendSrc ("Outline BlendSrc", float)    = 1
        [Enum(UnityEngine.Rendering.BlendMode)] _LineBlendDest ("OutlineBlendDest", float)   = 0
        _BlendMode ("BlendMode", float) = 0
        _EnableUniqueShadow ("Shadow Mode", float) = 0

        _HighlightOffset ("Highlight Offset", Vector) = (0,0,0,0)
        _GradientOffset ("Gradient starting point offset", Vector) = (1,1,0,0)
        _DirLight ("Rimlight Dir", Vector) = (-1,0,0,1)
        _OutlinePushBack ("Outline Z-Fight Correction", float) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue" = "AlphaTest" "PerformanceChecks" = "False" }
        LOD 300

        Pass
        {
            Name "FORWARD"
            Tags { "LightMode" = "ForwardBase" }
            Blend [_BlendSrc] [_BlendDest]
            Stencil 
            {
                Ref 16
                Comp always
                Pass replace
            }
            CGPROGRAM
			#pragma target 3.0
			#pragma multi_compile_fwdbase nolightmap nodirlightmap nodynlightmap novertexlight noshadowmask  
			#pragma skip_variants LIGHTMAP_SHADOW_MIXING LIGHTPROBE_SH SPOT DIRECTIONAL_COOKIE POINT_COOKIE SHADOWS_CUBE
            #pragma multi_compile _ _HARD_SHADOW _SOFT_SHADOW
			#pragma multi_compile _ _FASTEST_QUALITY
            #pragma multi_compile __ _ENABLE_HIGHLIGHT
            #pragma multi_compile __ _ENABLE_RIMLIGHT
            #pragma vertex vert
            #pragma fragment frag
            #include "Assets/CGInclude/LGameStarActorShadow.cginc"
            #include "Assets/CGInclude/LGameStarActorEffect.cginc"
            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"
            struct appdata_Toon
            {
                float4 vertex                   : POSITION;
                float2 uv                       : TEXCOORD0;
                float3 normal                   : NORMAL;
                float4 tangent                  : TANGENT;
            };
        
            struct v2f_Toon
            {
                float2 uv                       : TEXCOORD0;
                float4 pos                      : SV_POSITION;
                LGAME_STARACTOR_SHADOW_COORDS(1)
                float3 worldPos                 : TEXCOORD3;
                float4 tangentToWorld[3]	: TEXCOORD4;
                LGAME_STARACTOR_EFFECT_STRUCT(7)
            };
        
            half4                               _Color;
            sampler2D                           _MainTex;
            float4                              _MainTex_ST;
            sampler2D                           _ToonCombined;
            fixed4                              _ToonCombined_TexelSize;
            half                                _ToonTextureIndent;
            sampler2D                           _MatPropertyTexture;
            //sampler2D                           _OcclusionTexture;
            fixed4                              _MidtoneColor;
            //sampler2D                           _MidtoneTexture;
            fixed                               _Subsurface;
            fixed4                              _CoreShadowColor;
            //sampler2D                           _CoreShadowTexture;
            sampler2D                           _MidtoneRampTexture;
            fixed4                              _GradientOffset;
            half                                _Smoothness;
        #if _ENABLE_HIGHLIGHT
            half                                _SmoothnessThreshold;
            //sampler2D                           _SmoothnessTexure;
            half                                _UseSmoothnessTexure;
            fixed4                              _HighlightColor;
            //sampler2D                           _HighlightTexture;
            float4                              _HighlightOffset;
        #endif // _ENABLE_HIGHLIGHT
            //sampler2D                           _HighlightRampTexture;
            sampler2D                           _NormalTexture;
            half                                _NormalStrength;
        #if _ENABLE_RIMLIGHT
            half                                _RimlightRange;
            half                                _RimlightStrength;
            fixed4                              _RimlightColor;
            fixed4                              _DirLight;
        #endif // _ENABLE_RIMLIGHT
            //sampler2D                           _EmissionTexture;
            fixed4                              _EmissionColor;


            v2f_Toon vert (appdata_Toon v)
            {
                v2f_Toon o;
                UNITY_INITIALIZE_OUTPUT(v2f_Toon, o);

                o.pos = UnityObjectToClipPos(v.vertex);

                float3 worldNormal = UnityObjectToWorldNormal(v.normal);
                float4 worldTangent = float4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);
                half sign = worldTangent.w * unity_WorldTransformParams.w;
                half3 binormal = cross(worldNormal, worldTangent) * sign;

                o.tangentToWorld[2].xyz = worldNormal;
                o.tangentToWorld[0].xyz = worldTangent;
                o.tangentToWorld[1].xyz = binormal;

                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                float3 posWorld = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.worldPos = posWorld;
                
                LGAME_STARACTOR_EFFECT_VERTEX(o)
                LGAME_STARACTOR_TRNASFER_SHADOW(o);
                return o;
            }

            fixed3 gradient_3keys (fixed3 c1, fixed3 c2, fixed3 c3, half3 keys, float sample_value)
            {
                half3 color_left    = lerp(c1, c2, smoothstep(keys.x, keys.y, sample_value));
                half3 color_right   = lerp(c2, c3, smoothstep(keys.y, keys.z, sample_value));
                return sample_value < keys.y ? color_left : color_right;
            }

            fixed3 stepped_3keys (fixed3 c1, fixed3 c2, fixed3 c3, half2 keys, float sample) 
            {
                return sample < keys.x ? c1 : sample > keys.y ? c3 : c2;
            }

            fixed4 tex2DLinear(sampler2D tex, float2 uv)
            {
                fixed4 color = tex2D(tex, uv);
                color.rgb = GammaToLinearSpace(color.rgb);
                return color;
            }

            float2 get_uv_atlas4(float2 uv, fixed2 pos)
            {
                //return float2(uv.x * 0.5 + 0.5 * pos.x, uv.y * 0.5 + 0.5 * pos.y);
                float scale = 0.5 - 2 * _ToonTextureIndent * _ToonCombined_TexelSize.x;
                float u = _ToonTextureIndent * _ToonCombined_TexelSize.x + uv.x * scale + 0.5 * pos.x;
                float v = _ToonTextureIndent * _ToonCombined_TexelSize.y + uv.y * scale + 0.5 * pos.y;
                return float2(u, v);
            }

            fixed4 frag (v2f_Toon i) : SV_Target
            {
                LGAME_STARACTOR_EFFECT_FRAGMENT_BEGIN(i)
                // normal mapping
                fixed4 tNormal = tex2D(_NormalTexture, i.uv);
                fixed3 tangentNormal = UnpackNormalWithScale(tNormal, _NormalStrength);
                fixed3 worldNormal = i.tangentToWorld[0].xyz * tangentNormal.x
                    + i.tangentToWorld[1].xyz * tangentNormal.y
                    + i.tangentToWorld[2].xyz * tangentNormal.z;
                worldNormal = Unity_SafeNormalize(worldNormal);

                // directions
                half3 lightDir = Unity_SafeNormalize(UnityWorldSpaceLightDir(i.worldPos));
                half3 worldView = Unity_SafeNormalize(UnityWorldSpaceViewDir(i.worldPos));
                half fresnel = 1 - saturate(dot(worldNormal, worldView));
                
                //贴图准备
                fixed4 mainTex = tex2DLinear(_MainTex, i.uv) * _Color;
                fixed occlusion = tex2D(_MatPropertyTexture, i.uv).b;
                //fixed3 emission = tex2DLinear(_EmissionTexture, i.uv).xyz;
                fixed3 emission = tex2DLinear(_ToonCombined, get_uv_atlas4(i.uv, fixed2(1,0))).xyz;

                fixed midtoneMask = tex2D(_MatPropertyTexture, i.uv).a * _Subsurface;

            #if _ENABLE_HIGHLIGHT
                //fixed smoothness = tex2D(_SmoothnessTexure, i.uv).r;
                fixed smoothness = tex2D(_MatPropertyTexture, i.uv).r;
                //fixed3 highlightColor = tex2D(_HighlightTexture, i.uv).rgb * _HighlightColor.rgb;
                fixed3 highlightColor = tex2D(_ToonCombined, get_uv_atlas4(i.uv, fixed2(0,0))).rgb * _HighlightColor.rgb;
                fixed sdf = tex2D(_MatPropertyTexture, i.uv).g;
            #else
                fixed smoothness = _Smoothness;
            #endif
            
                fixed gradient = saturate((i.worldPos.y - unity_ObjectToWorld._m13 + _GradientOffset.x) * _GradientOffset.y);
                
                // diffuse
                fixed NdotL = dot(worldNormal, lightDir);
                fixed halfLambert = NdotL * 0.5 + 0.5;

                // shadow mapping
	            LGAME_STARACTOR_LIGHT_ATTENUATION(shadow, i, i.worldPos, NdotL);

                // 素描关系remap 
                half rampY = saturate(fresnel / (1.01 - midtoneMask) + midtoneMask);
                half illuminance = saturate(tex2D(_MidtoneRampTexture, half2(halfLambert * shadow * occlusion, rampY)).r);

                // tone mapping
                _LightColor0.rgb = GammaToLinearSpace(_LightColor0.rgb);
                fixed3 lutCenter = tex2DLinear(_ToonCombined, get_uv_atlas4(i.uv, fixed2(1,1))).xyz;
                lutCenter *= _MidtoneColor * _LightColor0 * mainTex.rgb;
                fixed3 lutDark = tex2DLinear(_ToonCombined, get_uv_atlas4(i.uv, fixed2(0,1))).xyz;
                lutDark = (lutDark + half3(0.5h, 0.5h, 0.5h)) * _CoreShadowColor.rgb * mainTex.rgb * min(_LightColor0, fixed3(1,1,1));
                fixed3 lutLight = mainTex.rgb * _LightColor0;
                lutLight = lerp(lutDark, lutLight, occlusion);
                fixed3 lutControl = gradient_3keys(lutDark * (1 - illuminance), lutCenter, lutLight, half3(0.1, 0.5, 0.9), illuminance);
                fixed3 two_step_gradient = lerp(lutDark, lutLight, illuminance);
                lutControl = lerp(two_step_gradient, lutControl, midtoneMask);

                // diffuse term
                half3 diffuseColor = lutControl;

                //Emission
                half3 emissionColor = emission * _EmissionColor.xyz;

            #if _ENABLE_RIMLIGHT
                //rimlight
                half3 rimlightColor = smoothstep(0.5 - _RimlightStrength, 0.5 + _RimlightStrength, 
                                      (_RimlightRange * gradient) * pow(fresnel, 1 / max(1e-4f, _RimlightRange * gradient))
                           ) * _RimlightColor;
                rimlightColor *= saturate(dot(Unity_SafeNormalize(mul(UNITY_MATRIX_V, worldNormal)), Unity_SafeNormalize(_DirLight.xyz)));
                rimlightColor *= illuminance * occlusion;
            #endif // _ENABLE_RIMLIGHT

            #if _ENABLE_HIGHLIGHT
                //specular term
                half3 halfDir = normalize(worldView + lightDir);
                half nh = saturate(dot(worldNormal, halfDir));
                
                half spec = 0;
                if (any(_UseSmoothnessTexure))
                {
                    spec += smoothstep((1 - _SmoothnessThreshold) * 0.5, _SmoothnessThreshold + (1 - _SmoothnessThreshold) * 0.5, sdf * nh * NdotL);
                }
                else {
                    smoothness = _Smoothness;
                }

                worldNormal.x -= _HighlightOffset.z;
                worldNormal.y -= _HighlightOffset.w;
                worldNormal.z = sqrt(1 - worldNormal.x * worldNormal.x - worldNormal.y * worldNormal.y) * sign(worldNormal.z);
                nh = saturate(dot(worldNormal, halfDir));
                NdotL = saturate(dot(worldNormal, lightDir));

                spec += smoothness * stepped_3keys(fixed3(0,0,0), fixed3(0.25, 0.25, 0.25), fixed3(1,1,1),
                                      half2(smoothness + _HighlightOffset.x, 0.5 + 0.45 * smoothness + _HighlightOffset.y), saturate(nh * NdotL)).r;

                spec *= illuminance;
                spec = saturate(spec);
            #endif // _ENABLE_HIGHLIGHT

                // composite
                fixed4 col = fixed4(0, 0, 0, 1);
                col.rgb = diffuseColor + emissionColor;
                col.a = mainTex.a * _Color.a;

            #if _ENABLE_RIMLIGHT
                col.rgb += rimlightColor;
            #endif // _ENABLE_RIMLIGHT

                col.rgb = LinearToGammaSpace(col.rgb);

            #if _ENABLE_HIGHLIGHT
                col.rgb += highlightColor * spec;
                col.a = max(col.a, spec);
            #endif // _ENABLE_HIGHLIGHT
                
                col = saturate(col);
                LGAME_STARACTOR_EFFECT_FRAGMENT_END(i,col)
                return col;
            }
            ENDCG
        }
        
        /* Forward add 暂时不启用
        Pass
        {
            Name "FORWARD ADD"
            Tags { "LightMode" = "ForwardAdd" }
            Cull Back
            Blend SrcAlpha One
			ZWrite Off
            ZTest LEqual
            CGPROGRAM
            #pragma multi_compile_fwdadd nolightmap nodirlightmap nodynlightmap novertexlight noshadowmask  
			#pragma skip_variants LIGHTMAP_SHADOW_MIXING SHADOWS_SCREEN LIGHTPROBE_SH SPOT DIRECTIONAL_COOKIE POINT_COOKIE SHADOWS_CUBE
			#pragma vertex vert_add
			#pragma fragment frag_add
			#include "Assets/CGInclude/LGameStarActorCG.cginc"
            ENDCG
        } */
        
        //基础描边Pass
          Pass
        {
            Name "OUTLINE"
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
            fixed4                      _Color;
            fixed4                      _OutlineColor;
            fixed                       _OutlinePushBack;
            half                        _ShadowOutlineStrength;
             struct appdata
            {
                float4 vertex               : POSITION;
                //float4 vertexColor          : COLOR;
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
                half3 lightDir = normalize(ObjSpaceLightDir(v.vertex));
                half3 normal = normalize(v.normal);
                //float4 tangent = v.tangent;
                //float3 binormal = cross(normal, normalize(tangent.xyz)) * tangent.w;
                //binormal = normalize(binormal);
                
                half lambert = smoothstep(-0.5, -1, dot(lightDir, normal));
                half shadowOutline = _ShadowOutlineStrength * lambert;

                half outlineStrength = (_OutlineStrength + shadowOutline) * v.uv1.r;

                o.vertex = UnityObjectToClipPos(v.vertex);
                // 顶点色R通道用于软阴影遮罩
                //float3 nOS = tangent.xyz * v.vertexColor.w + binormal * v.vertexColor.y + normal * v.vertexColor.z;
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
     //CustomEditor"LGameSDK.AnimTool.LGameStarActorToonShaderGUI"
     CustomEditor "CustomShaderGUI.LGameStarActorToonShaderGUI"
}

