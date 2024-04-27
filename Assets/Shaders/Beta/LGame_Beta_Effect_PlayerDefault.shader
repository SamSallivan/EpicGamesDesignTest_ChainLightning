Shader "Beta/LGame/Effect/Default" 
{
    Properties
    {
        //美术同学调用
        _EffectAlpha("_EffectAlpha",range(0,1))=1
        //程序同学调用
        [HideInInspector]_AlphaCtrl("_AlphaCtrl",range(0,1)) = 1
        //系统控制区
        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend ("_src(源混合方式)", float) = 5.0
        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlend ("_dst(目标混合方式)", float) = 8.0
        [HideInInspector] _BlendMode ("_BlendMode",float) = 1.0
        [Enum(Off, 0, On, 1)] _ZWriteMode ("_ZWriteMode(是否深度写入)", float) = 1
        [Enum(UnityEngine.Rendering.CullMode)] _CullMode ("_CullMode(裁剪模式)", float) = 2
        [Enum(Less, 2, LessEqual, 4, Greater, 5, Always, 8)] _ZTestMode ("_ZTestMode(深度测试模式)", Float) = 4
        [Enum(True,0,False,1)]_DisableBatching("DisableBatching",float)=0
        [Enum(UnityEngine.Rendering.ColorWriteMask)]_ColorMask("ColorMask",Float)=15
        //Stencil区
        [HideInInspector] [IntRange]_StencilComp("Stencil Comparison", Range(0,255)) = 8
        [HideInInspector] [IntRange]_Stencil("Stencil ID", Range(0,255)) = 0
        [HideInInspector] [IntRange]_StencilOp("Stencil Operation", Range(0,255)) = 0
        [HideInInspector] [IntRange]_StencilWriteMask("Stencil Write Mask", Range(0,255)) = 255
        [HideInInspector] [IntRange]_StencilReadMask("Stencil Read Mask", Range(0,255)) = 255
        //Combine(合并贴图部分:r:Mask,g:rimlight,b:dissolve)
        _CombineTex ("TextureCom", 2D) = "white" {}
        _CombinedWrapMode("_CombinedWrapMode",vector)=(11,11,11,0)
        //Base颜色主要颜色
        _MainTex ("Texture", 2D) = "white" {}
        [HDR]_Color("BaseColor",Color)=(1,1,1,1)
        _BaseColorStrength("_BaseColorStrength",Range(0,1))=0.5
        _MainTexAndFlowLightUVSpeed("_MainTexAndFlowLightUVSpeed",vector)=(0,0,0,0)
        //默认为cos0为1；
        _MainTexRotate("_MainTexRotate",vector)=(1,0,0,0)
        //流光
        _FlowLightTex("_FlowLightTex",2D)="white"{}
        [HDR]_FlowLightColor("_FlowLightColor",Color)=(1,1,1,1)
        [IntRange]_FlowLightMode("_FlowLightMode",Range(0,2))=0
        [IntRange]_FlowLightUVType("_FlowLightUvType",Range(0,2))=0
        _FlowLightStrength("_FlowLightStrength",Range(0,1))=0.5
        //蒙版和次级蒙版
        _MaskTex("_MaskTex",2D)="white"{}
        _SubMaskTex("_SubMaskTex",2D)="white"{}
        _SubMaskTex_Strength("_SubMaskTex_Strength",Range(0,1))=0.5
        _MaskTex_Strength("_MaskTex_Strength",Range(0,1))=0.5
        _MaskAndSubmaskUVSpeed("_MaskAndSubmaskUVSpeed",vector)=(0,0,0,0)
        //边缘光
        _RimLightTex("_RimLightTex",2D)="white"{}
        _RimLightRange("_RimLightRange",Range(0,10))=0.5
        _RimLightMultipler("_RimLightMultipler",Range(0,1))=0.5
        _RimLightNoiseMulipler("_RimLightNoiseMulipler",Range(0,1))=0.5
        _RimLightColor("_RimLightColor",Color)=(1,1,1,1)
        [SimpleToggle]_ReverseRimLight("_ReverseRimLight",Range(0,1))=0
        [IntRange]_RimLightMode("_RimLightMode",Range(0,2))=0
        [IntRange]_RimLightUVType("_RimLightUVType",Range(0,2))=0
        _RimlightUVSpeed("_RimlightUVSpeed",vector)=(0,0,0,0)
        //dissolve
        _DissolveTex("_DissolveTex",2D)="white"{}
        _DissolveValue("DissolveValue",Range(0,1))=0
        _SmoothstepA("_SmoothstepA",Range(0,0.5))=0
        [IntRange]_DissolveUVType("_DissolveUVType",Range(0,2))=0
        _DissolveEdgeColor("_DissolveEdgeColor",Color)=(1,1,1,1)
        _DissolveUVSpeed("_DissolveUVSpeed",vector)=(0,0,0,0)
        //_DissolveEdgeStrength("_DissolveEdgeStrength",Range(0,1))=0.5
        //billboard
        _BillboardMatrix0("_BillboardMatrix0",vector)=(1,0,0)
        _BillboardMatrix1("_BillboardMatrix1",vector)=(0,1,0)
        _BillboardMatrix2("_BillboardMatrix2",vector)=(0,0,1)
        _BillboardRotation("Rotation", vector) = (90,0,0,0)
        _BillboardScale("Scale", vector) = (1,1,1,0)
        //warp
        _WarpTex("_WarpTex",2D)="white"{}
        _WarpIntensity("_WarpIntensity",Range(0,1))=0.5
        //GradientTex
        _GradientTex ("_GradientTex", 2D) = "white" {}
    }
    SubShader
    {
        Tags {"Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" "DisableBatching"="true"}
        ZTest    [_ZTestMode]
        Blend    [_SrcBlend][_DstBlend]
        ZWrite  [_ZWriteMode]
        Cull       [_CullMode]
        ColorMask[_ColorMask]
        Stencil
        {
            Ref[_Stencil]
            Comp[_StencilComp]
            Pass[_StencilOp]
            ReadMask[_StencilReadMask]
            WriteMask[_StencilWriteMask]
        }
        LOD 100
        Pass
        {
            Name "Uber_EffectDefault"
            Tags{"LightMode"="ForwardBase"}
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_instancing
            #pragma shader_feature __ _RIMLIGHT
            #pragma shader_feature __ _BILLBOARD_ON
            #pragma shader_feature __ _MASK_ON
            #pragma shader_feature __ _SUBMASK_ON
            #pragma shader_feature __ _DISSOLVE_ON
            #pragma shader_feature __ _WARP_ON
            #pragma shader_feature __ _FLOWLIGHT
            #pragma shader_feature __ _GRADIENT_ON
            #include "UnityCG.cginc"
            #include "UberEffect.cginc"
            struct appdata
            {
                float4 vertex                   : POSITION;
                float3 normal                   : NORMAL;
                float3 vertexcolor              : COLOR;
                float2 mainuv                   : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 vertex                         : SV_POSITION;
                float2 mainuv                         : TEXCOORD0;
                #if _FLOWLIGHT                        
                   float2 flowlightuv                 :TEXCOORD1;
                #endif                                
                #if _MASK_ON                          
                    float2 maskuv                     :TEXCOORD2;
                    #if _SUBMASK_ON                   
                        float2 submaskuv              :TEXCOORD3;
                    #endif                            
                #endif                                
                #if _RIMLIGHT                         
                    float2 rimlightuv                 :TEXCOORD4;
                    float rimlightstrength            :TEXCOORD5;
                #endif                                
                #if _DISSOLVE_ON                      
                    float2 dissolveuv                 :TEXCOORD6;
                    float  dissolvevsvalue            :TEXCOORD7;
                #endif                                
                #if _WARP_ON                          
                    float2 warpuv                     :TEXCOORD8;
                #endif
                #if defined(LGAME_USEFOW) && _FOW_ON
                    half2 fowuv	                      : TEXCOORD9;
                #endif                               
                float4 vertexCol                      :TEXCOORD10;
                float2 uv                             :TEXCOORD11;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };
            UNITY_INSTANCING_BUFFER_START(VSIB1)
                UNITY_DEFINE_INSTANCED_PROP(float4,_MainTex_ST)
            # define B_MainTex_ST UNITY_ACCESS_INSTANCED_PROP(VSIB1,_MainTex_ST)
                UNITY_DEFINE_INSTANCED_PROP(float4,_FlowLightTex_ST)
            # define B_FlowLightTex_ST UNITY_ACCESS_INSTANCED_PROP(VSIB1,_FlowLightTex_ST)
               UNITY_DEFINE_INSTANCED_PROP(float4,_MaskTex_ST)
            # define B_MaskTex_ST UNITY_ACCESS_INSTANCED_PROP(VSIB1,_MaskTex_ST)
                UNITY_DEFINE_INSTANCED_PROP(float4,_SubMaskTex_ST)
            # define B_SubMaskTex_ST UNITY_ACCESS_INSTANCED_PROP(VSIB1,_SubMaskTex_ST)
                UNITY_DEFINE_INSTANCED_PROP(float4,_RimLightTex_ST)
            # define B_RimLightTex_ST UNITY_ACCESS_INSTANCED_PROP(VSIB1,_RimLightTex_ST)
                UNITY_DEFINE_INSTANCED_PROP(int,_RimLightUVType)
            # define B_RimLightUVType UNITY_ACCESS_INSTANCED_PROP(VSIB1,_RimLightUVType)
                UNITY_DEFINE_INSTANCED_PROP(float4,_DissolveTex_ST)
            # define B_DissolveTex_ST UNITY_ACCESS_INSTANCED_PROP(VSIB1,_DissolveTex_ST)
                UNITY_DEFINE_INSTANCED_PROP(float4,_WarpTex_ST)
            # define B_WarpTex_ST UNITY_ACCESS_INSTANCED_PROP(VSIB1,_WarpTex_ST)
            UNITY_INSTANCING_BUFFER_END(VSIB1)

            UNITY_INSTANCING_BUFFER_START(FSIB1)
                UNITY_DEFINE_INSTANCED_PROP(half,_EffectAlpha)
            # define B_EffectAlpha UNITY_ACCESS_INSTANCED_PROP(FSIB1,_EffectAlpha)
                UNITY_DEFINE_INSTANCED_PROP(half,_AlphaCtrl)
            # define B_AlphaCtrl UNITY_ACCESS_INSTANCED_PROP(FSIB1,_AlphaCtrl)
                UNITY_DEFINE_INSTANCED_PROP(fixed4,_Color)
            # define B_Color UNITY_ACCESS_INSTANCED_PROP(FSIB1,_Color)
                UNITY_DEFINE_INSTANCED_PROP(half,_BaseColorStrength)
            # define B_BaseColorStrength UNITY_ACCESS_INSTANCED_PROP(FSIB1,_BaseColorStrength)
                 UNITY_DEFINE_INSTANCED_PROP(float4,_MainTexAndFlowLightUVSpeed)
            # define B_MainTexAndFlowLightUVSpeed UNITY_ACCESS_INSTANCED_PROP(FSIB1,_MainTexAndFlowLightUVSpeed)
                UNITY_DEFINE_INSTANCED_PROP(float4,_MainTexRotate)
            # define B_MainTexRotate UNITY_ACCESS_INSTANCED_PROP(FSIB1,_MainTexRotate)
                UNITY_DEFINE_INSTANCED_PROP(fixed4,_FlowLightColor)
            # define B_FlowLightColor UNITY_ACCESS_INSTANCED_PROP(FSIB1,_FlowLightColor)
                UNITY_DEFINE_INSTANCED_PROP(int,_FlowLightMode)
            # define B_FlowLightMode UNITY_ACCESS_INSTANCED_PROP(FSIB1,_FlowLightMode)
                UNITY_DEFINE_INSTANCED_PROP(int,_FlowLightUVType)
            # define B_FlowLightUVType UNITY_ACCESS_INSTANCED_PROP(FSIB1,_FlowLightUVType)
            UNITY_INSTANCING_BUFFER_END(FSIB1)

            UNITY_INSTANCING_BUFFER_START(FSIB2)
                UNITY_DEFINE_INSTANCED_PROP(half,_FlowLightStrength)
            # define B_FlowLightStrength UNITY_ACCESS_INSTANCED_PROP(FSIB2,_FlowLightStrength)
                UNITY_DEFINE_INSTANCED_PROP(float4,_MaskAndSubmaskUVSpeed)
            # define B_MaskAndSubmaskUVSpeed UNITY_ACCESS_INSTANCED_PROP(FSIB2,_MaskAndSubmaskUVSpeed)
                UNITY_DEFINE_INSTANCED_PROP(half,_MaskTex_Strength)
            # define B_MaskTex_Strength UNITY_ACCESS_INSTANCED_PROP(FSIB2,_MaskTex_Strength)
                UNITY_DEFINE_INSTANCED_PROP(half,_SubMaskTex_Strength)
            # define B_SubMaskTex_Strength UNITY_ACCESS_INSTANCED_PROP(FSIB2,_SubMaskTex_Strength)
                UNITY_DEFINE_INSTANCED_PROP(fixed4,_RimLightColor)
            # define B_RimLightColor UNITY_ACCESS_INSTANCED_PROP(FSIB2,_RimLightColor)
                UNITY_DEFINE_INSTANCED_PROP(half,_ReverseRimLight)
            # define B_ReverseRimLight UNITY_ACCESS_INSTANCED_PROP(FSIB2,_ReverseRimLight)
                UNITY_DEFINE_INSTANCED_PROP(half,_RimLightRange)
            # define B_RimLightRange UNITY_ACCESS_INSTANCED_PROP(FSIB2,_RimLightRange)
                UNITY_DEFINE_INSTANCED_PROP(half,_RimLightMultipler)
            # define B_RimLightMultipler UNITY_ACCESS_INSTANCED_PROP(FSIB2,_RimLightMultipler)
                UNITY_DEFINE_INSTANCED_PROP(int,_RimLightMode)
            # define B_RimLightMode UNITY_ACCESS_INSTANCED_PROP(FSIB2,_RimLightMode)
                UNITY_DEFINE_INSTANCED_PROP(half,_RimLightNoiseMulipler)
            # define B_RimLightNoiseMulipler UNITY_ACCESS_INSTANCED_PROP(FSIB2,_RimLightNoiseMulipler)
                UNITY_DEFINE_INSTANCED_PROP(float4,_RimlightUVSpeed)
            # define B_RimlightUVSpeed UNITY_ACCESS_INSTANCED_PROP(FSIB2,_RimlightUVSpeed)
                UNITY_DEFINE_INSTANCED_PROP(half,_SmoothstepA)
            # define B_SmoothstepA UNITY_ACCESS_INSTANCED_PROP(FSIB2,_SmoothstepA)
                UNITY_DEFINE_INSTANCED_PROP(half,_DissolveValue)
            # define B_DissolveValue UNITY_ACCESS_INSTANCED_PROP(FSIB2,_DissolveValue)
                UNITY_DEFINE_INSTANCED_PROP(int,_DissolveUVType)
            # define B_DissolveUVType UNITY_ACCESS_INSTANCED_PROP(FSIB2,_DissolveUVType)
            UNITY_INSTANCING_BUFFER_END(FSIB2)

            UNITY_INSTANCING_BUFFER_START(FSIB3)
                UNITY_DEFINE_INSTANCED_PROP(fixed4,_DissolveEdgeColor)
            # define B_DissolveEdgeColor UNITY_ACCESS_INSTANCED_PROP(FSIB2,_DissolveEdgeColor)
                UNITY_DEFINE_INSTANCED_PROP(float4,_DissolveUVSpeed)
            # define B_DissolveUVSpeed UNITY_ACCESS_INSTANCED_PROP(FSIB2,_DissolveUVSpeed)
                UNITY_DEFINE_INSTANCED_PROP(half,_WarpIntensity)
            # define B_WarpIntensity UNITY_ACCESS_INSTANCED_PROP(FSIB2,_WarpIntensity)
            UNITY_INSTANCING_BUFFER_END(FSIB3)
            //blendmode
            half                                        _BlendMode;
            half                                        _SrcBlend;
            half                                        _DstBlend;
            //combine
            sampler2D                                   _CombineTex;
            uint4                                       _CombinedWrapMode;
            //basecolor
            sampler2D                                   _MainTex;
            //之所以要声明在这里是因为maintex一直存在，不会出现丢失变量情况，mask同理
            //流光
            #if _FLOWLIGHT
                sampler2D                               _FlowLightTex;
            #endif
            //mask
            #if _MASK_ON
                sampler2D                               _MaskTex;
            //mask02
                #if _SUBMASK_ON
                    sampler2D                           _SubMaskTex;
                #endif
            #endif
            //rimlight
            #if _RIMLIGHT
                sampler2D                               _RimLightTex;
            #endif
            //dissolve
            #if _DISSOLVE_ON
                sampler2D                               _DissolveTex;
            #endif
            //billboard
            #if _BILLBOARD_ON
                half4                                   _BillboardMatrix0;
                half4                                   _BillboardMatrix1;
                half4                                   _BillboardMatrix2;
            #endif
            //扭曲
            #if _WARP_ON
            sampler2D                                   _WarpTex;
            #endif
          //支持渐变工具
           #if _GRADIENT_ON
           sampler2D                                    _GradientTex; 
           #endif
           #if _FOW_ON
           sampler2D                                    _FOWTexture;
           sampler2D                                    _FOWLastTexture;
           fixed4                                       _FogCol;
           fixed4                                       _FogRangeCol;
           half                                         _FOWBlend;
           half                                         _FOWOpenSpeed;
           half4                                        _FOWParam;
           half                                         _RangeSize;
           half                                         _fow;
           half                                         _FowBrightness;
           #endif
            v2f vert (appdata v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, o);
                UNITY_TRANSFER_INSTANCE_ID(v, o);
                o.mainuv = TRANSFORM_TEX(v.mainuv, _MainTex);
                o.uv = v.mainuv;
                #if _FLOWLIGHT
                    o.flowlightuv=uvManager(v.mainuv,_FlowLightTex,B_FlowLightTex_ST,v.vertex,B_FlowLightUVType);
                #endif
                #if _MASK_ON
                    o.maskuv=TRANSFORM_TEX(v.mainuv,_MaskTex);
                #if _SUBMASK_ON
                    o.submaskuv=TRANSFORM_TEX(v.mainuv,_SubMaskTex);
                #endif
                #endif
                #if _DISSOLVE_ON
                    o.dissolveuv=uvManager(v.mainuv,_DissolveTex,B_DissolveTex_ST,v.vertex,B_DissolveUVType);
                #endif
                #if _WARP_ON
                    o.warpuv=TRANSFORM_TEX(v.mainuv,_WarpTex);
                #endif
                //billboard
                #if _BILLBOARD_ON
                    float3x3 m;
                    m[0] = _BillboardMatrix0.xyz;
                    m[1] = _BillboardMatrix1.xyz;
                    m[2] = _BillboardMatrix2.xyz;
                    //rimlight
                    //这里先反推出模型空间顶点，再用模型空间顶点算裁剪空间顶点，和直接把模型空间顶点当屏幕空间顶点结果完全一样
                    float4 rimlightvertex=mul(mul(m,v.vertex.xyz),UNITY_MATRIX_IT_MV);
                    o.vertex=UnityObjectToClipPos(rimlightvertex);
                #else
                    o.vertex = UnityObjectToClipPos(v.vertex);
                # endif
                #if _RIMLIGHT
                   
                    #if _BILLBOARD_ON
                        fixed3 worldnormal =normalize(UnityObjectToWorldNormal(mul(v.normal,UNITY_MATRIX_IT_MV)));
                        fixed3 worldviewdir = normalize(WorldSpaceViewDir(rimlightvertex));
                    #else
                        fixed3 worldnormal =normalize(UnityObjectToWorldNormal(v.normal));
                        fixed3 worldviewdir = normalize(WorldSpaceViewDir(v.vertex));
                    #endif
                    o.rimlightuv=uvManager(v.mainuv,_RimLightTex,B_RimLightTex_ST,v.vertex,B_RimLightUVType);
                    o.rimlightstrength=rimLight(worldnormal,worldviewdir,B_RimLightRange,B_RimLightMultipler,B_ReverseRimLight);
                # endif
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                half opacity=B_EffectAlpha*B_AlphaCtrl;
                #if _WARP_ON
                    //扭曲(扭曲只控制主贴图)
                    fixed4 var_warptex=tex2D(_WarpTex,i.warpuv, float2(0, 0), float2(0, 0));
                    half2 warp = UnpackNormal(var_warptex).xy;
                    i.mainuv -= warp * B_WarpIntensity;
                # endif
                //主贴图和颜色
                //------------------------------------------------------------------------------------------------------
                i.mainuv=rotateUV(i.mainuv,normalize(B_MainTexRotate.xy));
                fixed4 var_maintex=tex2D(_MainTex, uvAdd(i.mainuv,B_MainTexAndFlowLightUVSpeed.xy));
                fixed3 outcolor=addColorToTexture(B_Color.rgb,var_maintex,B_Color.a*B_BaseColorStrength);
                #if _FLOWLIGHT
                //flowlight(流光)
                    fixed4 var_flowlighttex=tex2D(_FlowLightTex,uvAdd(i.flowlightuv,B_MainTexAndFlowLightUVSpeed.zw));
                    outcolor=colorManager(outcolor,B_FlowLightColor.rgb,var_flowlighttex.g*B_FlowLightColor.a*B_FlowLightStrength,B_FlowLightMode);
                # endif
                #if _MASK_ON
                    //mask和mask02,只有打开第一个mask第二个mask才会生效
                    //合并贴图部分
                    fixed4 var_masktex=sampleMixedTexture(_CombinedWrapMode.x,uvAdd(i.maskuv,B_MaskAndSubmaskUVSpeed.xy),_CombineTex);
                    #if _SUBMASK_ON
                        fixed4 var_submasktex=tex2D(_SubMaskTex,uvAdd(i.submaskuv,B_MaskAndSubmaskUVSpeed.zw));
                        fixed outputmask=lerp(lerp(1,var_masktex.r,B_MaskTex_Strength),var_submasktex.r,B_SubMaskTex_Strength);
                        opacity*=outputmask;
                    #else
                        opacity*=lerp(1,var_masktex.r,B_MaskTex_Strength); 
                    # endif
                #endif
                #if _DISSOLVE_ON
                //溶解dissolve
                //合并贴图部分
                    fixed4 var_dissolvetex=sampleMixedTexture(_CombinedWrapMode.y,uvAdd(i.dissolveuv,B_DissolveUVSpeed.xy),_CombineTex);
                    fixed dissolve=dissolveFunc(B_DissolveValue,B_SmoothstepA,var_dissolvetex.b);
                    //这三行是为了做出硬的溶解颜色边缘，暂时注掉
                    // half edgecolorstrength=clamp(ceil(dissolve-floor(dissolve)),0,1);
                    // outcolor+=edgecolorstrength*_DissolveEdgeColor;
                    // dissolve=ceil(dissolve);
                    outcolor= lerp(B_DissolveEdgeColor,outcolor,dissolve) * dissolve;
                    opacity*=dissolve;
                #endif
                #if _RIMLIGHT
                //rimlight边缘光
                    //边缘光在预乘之后，可以让边缘光不受透明度的影响，使用multiColor或者放在预乘前会重新受到透明度影响
                    //合并贴图部分
                    fixed4 var_rimlighttex=sampleMixedTexture(_CombinedWrapMode.z,uvAdd(i.rimlightuv,B_RimlightUVSpeed.xy),_CombineTex);
                    fixed noiserimlightstrength=lerp(i.rimlightstrength,var_rimlighttex.g*i.rimlightstrength,B_RimLightNoiseMulipler);
                    outcolor=lerp(outcolor,colorManager(outcolor,B_RimLightColor.rgb,B_RimLightColor.a,B_RimLightMode),noiserimlightstrength);
                #endif
                #if _GRADIENT_ON
                    fixed4 gradientCol = tex2D(_GradientTex,i.uv, float2(0, 0), float2(0, 0));
                    outcolor*= gradientCol;
                #endif
                //透明度预乘
                outcolor*=opacity;
                //变量汇总
                fixed4 finalcolor=fixed4(outcolor.r,outcolor.g,outcolor.b,opacity);
                return finalcolor;
            }
            ENDCG
        }
    }
    CustomEditor"LGameSDK.AnimTool.UberEffectGUI"
}
