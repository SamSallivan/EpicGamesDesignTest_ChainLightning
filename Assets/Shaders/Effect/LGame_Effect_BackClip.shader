Shader "LGame/Effect/BackClip"
{
    Properties
    {
        _AlphaCtrl("AlphaCtrl",range(0,1)) = 1

        [HideInInspector] _OptionMode("__OptionMode",float) = 0	
		[HideInInspector] _BlendMode ("__BlendMode",float) = 0
        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend ("__src", float) = 1.0
        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlend ("__dst", float) = 0.0
		[Enum(Off, 0, On, 1)] _ZWriteMode ("__ZWriteMode", float) = 0
		[Enum(UnityEngine.Rendering.CullMode)] _CullMode ("__CullMode", float) = 2
		[Enum(Less, 2, LessEqual, 4, Greater, 5, Always, 8)] _ZTestMode ("__ZTestMode", Float) = 2

        [SimpleToggle] _ScaleOnCenter("Scale On Center", Float) = 1

        [hdr]_Color ("Main Color" , color) = (1,1,1,1)
        _MainTex ("Main Texture", 2D) = "white" {}
		_MainTexTransform ("MainTexTransform" , vector) = (0,0,0,1)
        
        _MaskTex ("Mask Texture(R channel)", 2D) = "white" {}
		_MaskTexTransform ("Mask Transform" , vector) = (0,0,0,1)
        [SimpleToggle] _MaskUseWarp ("Mask Use Warp", float) = 0

        _WarpTex ("Warp Texture(R channel)", 2D) = "white" {}
        _WarpTexTransform ("Warp Transform", vector) = (0,0,0,1)
        _WarpIntensity   ("Warp Intensity", Range(0,1)) = 0

        _DissolveTex ("Dissolve Texture(R channel)", 2D) = "white" {}
        _DissolveTexTransform ("Dissolve Transform", vector) = (0,0,0,1)
        [SimpleToggle] _UseCustomData("Use Custom Data", Float) = 0
        _DissolveValue ("Dissolve Value", range(0.001,1.5)) = 0.001
        _DissolveRangeSize ("Dissolve Range Size", range(0.05,1)) = 0.05

        [SimpleToggle] _useBackClip ("Use Back Clip", float) = 0
        _collisionVector ("Collision Vector" , vector) = (0,0,1,0)
        _collisionWSPos ("Collision WorldSpace Position" , vector) = (0,0,0,0)
        [SimpleToggle] _isReverse ("Is Reverse" , float) = 0
        [SimpleToggle] _TimeScale("Time Scale", Float) = 1
        
    }
    SubShader
    {
        Tags{"Queue" = "Transparent"  "IgnoreProjection" = "True" "RenderType" = "Transparent" }
        LOD 100

        Blend [_SrcBlend] [_DstBlend]
        ZWrite [_ZWriteMode]
        ZTest [_ZTestMode]
        Cull [_CullMode]

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma shader_feature __ _MASK_ON
			#pragma shader_feature __ _DISSOLVE_ON
			#pragma shader_feature __ _WARP_ON
            #pragma multi_compile_instancing 

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                fixed4 color : COLOR;
                float4 uv : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                fixed4 vertexCol : COLOR;
                float4 uvMain : TEXCOORD0;
                float4 posWS : TEXCOORD1;
                float4 uvMaskAWarp : TEXCOORD2;
                float4 uvDiss : TEXCOORD3;
                half4 customData : TEXCOORD4;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            // 拆分VS和FS使用的Instance Buffer
	        // 在Adreno510上VS和FS复用Instance Buffer会造成花屏
	        // 光栅化后的像素和最终的Frame Buffer显示不同
	        // VS使用的Instance Buffer
            UNITY_INSTANCING_BUFFER_START(VSIB)

                UNITY_DEFINE_INSTANCED_PROP(float4, _MainTex_ST)
	        #   define B_MainTex_ST UNITY_ACCESS_INSTANCED_PROP(VSIB,_MainTex_ST)

                UNITY_DEFINE_INSTANCED_PROP(half4, _MainTexTransform)
	        #	define B_MainTexTransform UNITY_ACCESS_INSTANCED_PROP(VSIB,_MainTexTransform)

            	UNITY_DEFINE_INSTANCED_PROP(fixed, _ScaleOnCenter)
	        #	define B_ScaleOnCenter UNITY_ACCESS_INSTANCED_PROP(VSIB,_ScaleOnCenter)

            	UNITY_DEFINE_INSTANCED_PROP(float4, _MaskTex_ST)
	        #	define B_MaskTex_ST UNITY_ACCESS_INSTANCED_PROP(VSIB,_MaskTex_ST)

		        UNITY_DEFINE_INSTANCED_PROP(half4, _MaskTexTransform)
	        #	define B_MaskTexTransform UNITY_ACCESS_INSTANCED_PROP(VSIB,_MaskTexTransform)

                UNITY_DEFINE_INSTANCED_PROP(float4, _WarpTex_ST)
	        #	define B_WarpTex_ST UNITY_ACCESS_INSTANCED_PROP(VSIB,_WarpTex_ST)

                UNITY_DEFINE_INSTANCED_PROP(half4, _WarpTexTransform)
	        #	define B_WarpTexTransform UNITY_ACCESS_INSTANCED_PROP(VSIB,_WarpTexTransform)

                UNITY_DEFINE_INSTANCED_PROP(float4, _DissolveTex_ST)
	        #	define B_DissolveTex_ST UNITY_ACCESS_INSTANCED_PROP(VSIB,_DissolveTex_ST)

                UNITY_DEFINE_INSTANCED_PROP(half4, _DissolveTexTransform)
	        #	define B_DissolveTexTransform UNITY_ACCESS_INSTANCED_PROP(VSIB,_DissolveTexTransform)

            UNITY_INSTANCING_BUFFER_END(VSIB)

            	// FS使用的Instance Buffer
	        UNITY_INSTANCING_BUFFER_START(FSIB)

                UNITY_DEFINE_INSTANCED_PROP(half, _AlphaCtrl)
	        #   define B_AlphaCtrl UNITY_ACCESS_INSTANCED_PROP(FSIB,_AlphaCtrl)

		        UNITY_DEFINE_INSTANCED_PROP(fixed4, _Color)
	        #   define B_Color UNITY_ACCESS_INSTANCED_PROP(FSIB,_Color)

                UNITY_DEFINE_INSTANCED_PROP(half, _MaskUseWarp)
	        #   define B_MaskUseWarp UNITY_ACCESS_INSTANCED_PROP(FSIB,_MaskUseWarp)

                UNITY_DEFINE_INSTANCED_PROP(half, _WarpIntensity  )
	        #   define B_WarpIntensity   UNITY_ACCESS_INSTANCED_PROP(FSIB,_WarpIntensity  )

                UNITY_DEFINE_INSTANCED_PROP(half, _UseCustomData)
	        #   define B_UseCustomData UNITY_ACCESS_INSTANCED_PROP(FSIB,_UseCustomData)

                UNITY_DEFINE_INSTANCED_PROP(half, _DissolveValue)
	        #   define B_DissolveValue UNITY_ACCESS_INSTANCED_PROP(FSIB,_DissolveValue)

                UNITY_DEFINE_INSTANCED_PROP(half, _DissolveRangeSize)
	        #   define B_DissolveRangeSize UNITY_ACCESS_INSTANCED_PROP(FSIB,_DissolveRangeSize)

                UNITY_DEFINE_INSTANCED_PROP(half, _useBackClip)
	        #   define B_useBackClip UNITY_ACCESS_INSTANCED_PROP(FSIB,_useBackClip)

                UNITY_DEFINE_INSTANCED_PROP(float4, _collisionVector)
	        #   define B_collisionVector UNITY_ACCESS_INSTANCED_PROP(FSIB,_collisionVector)

                UNITY_DEFINE_INSTANCED_PROP(float4, _collisionWSPos)
	        #   define B_collisionWSPos UNITY_ACCESS_INSTANCED_PROP(FSIB,_collisionWSPos)

                UNITY_DEFINE_INSTANCED_PROP(half, _isReverse)
	        #   define B_isReverse UNITY_ACCESS_INSTANCED_PROP(FSIB,_isReverse)

            UNITY_INSTANCING_BUFFER_END(FSIB)



            sampler2D _MainTex;
            fixed _TimeScale;

            #if _MASK_ON
                sampler2D _MaskTex;
            #endif

            #if _WARP_ON
                sampler2D _WarpTex;
            #endif

            #if _DISSOLVE_ON
                sampler2D _DissolveTex;
            #endif

            inline float2 RotateUV(float2 uv,float2 uvRotate)
            {
                float2 outUV;
                outUV = uv - 0.5 * B_ScaleOnCenter;
                outUV = float2(	outUV.x * uvRotate.y - outUV.y * uvRotate.x ,
                                outUV.x * uvRotate.x + outUV.y * uvRotate.y );
                return outUV + 0.5 * B_ScaleOnCenter;
            }

            inline float2 TransFormUV(float2 argUV,float4 argST , float4 trans)
            {
                float2 result =  RotateUV(argUV , trans.zw)  * argST.xy + argST.zw;
                result += B_ScaleOnCenter * (1 - argST.xy)*0.5;
                return result + frac(trans.xy * _TimeScale * _Time.y);
            }


            v2f vert (appdata v)
            {
                v2f o;

                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, o);
                UNITY_TRANSFER_INSTANCE_ID(v, o);

                o.vertexCol = v.color;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.posWS = mul(unity_ObjectToWorld, v.vertex);
                o.uvMain.xy = TransFormUV(v.uv.xy, B_MainTex_ST, B_MainTexTransform);
                #if _MASK_ON
                    o.uvMaskAWarp.xy = TransFormUV(v.uv.xy, B_MaskTex_ST, B_MaskTexTransform);
                #endif
                #if _WARP_ON
                    o.uvMaskAWarp.zw = TransFormUV(v.uv.xy, B_WarpTex_ST, B_WarpTexTransform);
                #endif
                #if _DISSOLVE_ON
                    o.uvDiss.xy = TransFormUV(v.uv.xy, B_DissolveTex_ST, B_DissolveTexTransform);
                    o.customData.xy = v.uv.zw;
                #endif
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);
                // float2 uvMask = i.uvMaskAWarp.xy;

                #if _WARP_ON
                    fixed4 warpVal = tex2D(_WarpTex, i.uvMaskAWarp.zw) * B_WarpIntensity  ;
                    i.uvMain.xy += warpVal.r;
                    i.uvMaskAWarp.xy = lerp(i.uvMaskAWarp.xy, i.uvMaskAWarp.xy + warpVal.r, B_MaskUseWarp);
                    i.uvDiss.xy += warpVal.r;
                #endif

                fixed4 col = tex2D(_MainTex, i.uvMain.xy);
                col *= B_Color;
                fixed4 result = col;
                
                #if _MASK_ON
                    fixed4 maskVal = tex2D(_MaskTex,i.uvMaskAWarp.xy);
                    result *= maskVal.r;
                #endif

                #if _DISSOLVE_ON

                    fixed4 dissCol = tex2D(_DissolveTex, i.uvDiss.xy);
                    half DissInt = lerp(B_DissolveValue,i.customData.x,B_UseCustomData);
                    half DissVal = smoothstep(DissInt - B_DissolveRangeSize,DissInt,dissCol.r);
                    result *= DissVal;
                #endif

                //计算裁切部分(这里看性能其实可以通过加开关减少一个Lerp，但是会增加新的变体)
                float k = -B_collisionVector.x / B_collisionVector.z;
                float b = B_collisionWSPos.z - k * B_collisionWSPos.x; 
                float signal = clamp(sign((i.posWS.x*k+b)-i.posWS.z),0,1);
                signal = lerp(signal,1-signal,B_isReverse);
                result.a = lerp(result.a,result.a*signal,B_useBackClip);

                //clip(signal);
                result *= i.vertexCol;
                result*= B_AlphaCtrl;
                
                return result;
            }
            ENDCG
        }
    }
    CustomEditor"LGameSDK.AnimTool.LGameEffectBackClip"
}
