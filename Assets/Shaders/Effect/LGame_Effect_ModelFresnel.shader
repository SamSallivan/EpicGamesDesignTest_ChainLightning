Shader "LGame/Effect/ModelFresnel"
{
    Properties
    {
        [HideInInspector] _FirstSet("First Set" , int) = 1
    	_AlphaCtrl("AlphaCtrl",range(0,1)) = 1

        [HideInInspector] _OptionMode("__OptionMode",float) = 0	
		[HideInInspector] _BlendMode ("__BlendMode",float) = 0
        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend ("__src", float) = 1.0
        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlend ("__dst", float) = 0.0
		[Enum(Off, 0, On, 1)] _ZWriteMode ("__ZWriteMode", float) = 0
		[Enum(UnityEngine.Rendering.CullMode)] _CullMode ("__CullMode", float) = 2
		[Enum(Less, 2, LessEqual, 4, Greater, 5, Always, 8)] _ZTestMode ("__ZTestMode", Float) = 2

        [Toggle] _ScaleOnCenter("Scale On Center", Float) = 1

		[hdr]_Color ("Main Color" , color) = (1,1,1,1)
        _MainTex ("Main Texture", 2D) = "white" {}
		_MainTexTransform ("MainTexTransform" , vector) = (0,0,0,1)
        

        _MaskTex ("Mask Texture(R channel)", 2D) = "white" {}
		_MaskTexTransform ("Mask Transform" , vector) = (0,0,0,1)

        _FresnelColor("Fresnel Color", color) = (1,1,1,1)
        _FresnelMinValue("Fresnel Min Value", Range(-0.8,0.2)) = 0

        _RimColor("Rim Color", color) = (1,1,1,1)
        _RimLightValue("Rim Light Value", range(0.5,0.99)) = 0.9
        _RimValueSmooth("Rim Value Smooth", range(0.01,0.5)) = 0.05

    }

    SubShader
    {
        Tags {"Queue"="Transparent" "RenderType"="Transparent"  }
        
        Blend [_SrcBlend] [_DstBlend]
        ZWrite [_ZWriteMode]
        ZTest [_ZTestMode]
        Cull [_CullMode]

        Pass
        {
            //Name "Always"
            Tags { "LightMode" = "PerZPass" }
            ZWrite on
            ColorMask 0
        }

        Pass
        {
            Name "ForwardBase"
            Tags { "LightMode" = "ForwardBase" }
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_instancing 

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float4 normal : NORMAL;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                half4 pos : SV_POSITION;
                float4 uvMain : TEXCOORD0;
                float3 nDirWS : TEXCOORD1;
                float4 posWS : TEXCOORD2; 
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };
            // 拆分VS和FS使用的Instance Buffer
	        // 在Adreno510上VS和FS复用Instance Buffer会造成花屏
	        // 光栅化后的像素和最终的Frame Buffer显示不同
	        // VS使用的Instance Buffer
	        UNITY_INSTANCING_BUFFER_START(VSIB)

            	UNITY_DEFINE_INSTANCED_PROP(half4, _MainTex_ST)
	        #   define B_MainTex_ST UNITY_ACCESS_INSTANCED_PROP(VSIB,_MainTex_ST)

		        UNITY_DEFINE_INSTANCED_PROP(half4, _MainTexTransform)
	        #	define B_MainTexTransform UNITY_ACCESS_INSTANCED_PROP(VSIB,_MainTexTransform)

            	UNITY_DEFINE_INSTANCED_PROP(fixed, _ScaleOnCenter)
	        #	define B_ScaleOnCenter UNITY_ACCESS_INSTANCED_PROP(VSIB,_ScaleOnCenter)

            	UNITY_DEFINE_INSTANCED_PROP(half4, _MaskTex_ST)
	        #	define B_MaskTex_ST UNITY_ACCESS_INSTANCED_PROP(VSIB,_MaskTex_ST)

		        UNITY_DEFINE_INSTANCED_PROP(half4, _MaskTexTransform)
	        #	define B_MaskTexTransform UNITY_ACCESS_INSTANCED_PROP(VSIB,_MaskTexTransform)

            UNITY_INSTANCING_BUFFER_END(VSIB)

            	// FS使用的Instance Buffer
	        UNITY_INSTANCING_BUFFER_START(FSIB)

		        UNITY_DEFINE_INSTANCED_PROP(half, _AlphaCtrl)
	        #   define B_AlphaCtrl UNITY_ACCESS_INSTANCED_PROP(FSIB,_AlphaCtrl)

		        UNITY_DEFINE_INSTANCED_PROP(fixed4, _Color)
	        #   define B_Color UNITY_ACCESS_INSTANCED_PROP(FSIB,_Color)

                UNITY_DEFINE_INSTANCED_PROP(fixed4, _FresnelColor)
	        #   define B_FresnelColor UNITY_ACCESS_INSTANCED_PROP(FSIB,_FresnelColor)

                UNITY_DEFINE_INSTANCED_PROP(fixed4, _RimColor)
	        #   define B_RimColor UNITY_ACCESS_INSTANCED_PROP(FSIB,_RimColor)

                UNITY_DEFINE_INSTANCED_PROP(half, _FresnelMinValue)
	        #   define B_FresnelMinValue UNITY_ACCESS_INSTANCED_PROP(FSIB,_FresnelMinValue)

                UNITY_DEFINE_INSTANCED_PROP(half, _RimLightValue)
	        #   define B_RimLightValue UNITY_ACCESS_INSTANCED_PROP(FSIB,_RimLightValue)

                UNITY_DEFINE_INSTANCED_PROP(half, _RimValueSmooth)
	        #   define B_RimValueSmooth UNITY_ACCESS_INSTANCED_PROP(FSIB,_RimValueSmooth)

            UNITY_INSTANCING_BUFFER_END(FSIB)

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
                return result + frac(trans.xy * _Time.y);
            }

            sampler2D _MainTex;
            sampler2D _MaskTex;

            v2f vert (appdata v)
            {
                v2f o;

                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, o);
                UNITY_TRANSFER_INSTANCE_ID(v, o);

                o.pos = UnityObjectToClipPos(v.vertex);
                o.nDirWS = UnityObjectToWorldNormal(v.normal);
                o.posWS = mul(unity_ObjectToWorld, v.vertex);
                o.uvMain.xy = TransFormUV(v.uv.xy, B_MainTex_ST, B_MainTexTransform);
                o.uvMain.zw = TransFormUV(v.uv.xy, B_MaskTex_ST, B_MaskTexTransform);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);
                float3 vDirWS = normalize ( _WorldSpaceCameraPos.xyz - i.posWS.xyz);
                half ndotv = 1 - max(0,dot(i.nDirWS,vDirWS));

                half rimLight = smoothstep(B_RimLightValue,B_RimLightValue+B_RimValueSmooth,ndotv) * B_RimColor.a;
                half3 rimCol = rimLight * B_RimColor.rgb;
                half rimMask = 1 - rimLight;

                half fresnel = smoothstep(B_FresnelMinValue,1,ndotv) * B_FresnelColor.a;
                half3 fresnelCol =  (fresnel * B_FresnelColor.rgb) * rimMask ;
                fixed3 finalRGB = rimCol + fresnelCol;
                half finalAlpha = saturate(rimLight + fresnel);

                fixed4 baseTex = tex2D(_MainTex, i.uvMain.xy);
                baseTex.rgb *= (1 - finalAlpha) * B_Color.a;
                baseTex.a *= (1 - finalAlpha) * B_Color.a;

                fixed4 maskTex = tex2D(_MaskTex, i.uvMain.zw);

                finalRGB = finalRGB + baseTex.rgb;
                finalAlpha =finalAlpha + baseTex.a;
                fixed4 col = fixed4(finalRGB,finalAlpha) * maskTex.r;

                return col * B_AlphaCtrl;
            }
            ENDCG
        }
    }

    CustomEditor"LGameSDK.AnimTool.LGameEffectModelFresnel"
}
