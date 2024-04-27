Shader "LGame/Effect/MainTextureOffset/CustomData"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color ("Color",color)=(1,1,1,1)
        _OffsetColor("OffsetColor",color)=(1,1,1,1)
        _OffsetColorLerp("OffsetColorlerp",Range(0,1))=0
        _MaskTex("MaskTex",2D) = "white" {}
        _AlphaCtrl("AlphaCtrl",Range(0,1))=1
        [HideInInspector]_BlendMode("BlendMode",int) = 0
		[HideInInspector][Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend ("__src", float) = 5.0
        [HideInInspector][Enum(UnityEngine.Rendering.BlendMode)] _DstBlend ("__dst", float) = 10.0
        [SimpleToggle] _UseCustomData("Use Custom Data", Float) = 0
    }
    SubShader
    {
        Tags {"LightMode" = "ForwardBase" "Queue"="Transparent" "RenderType"="Transparent"}
        LOD 100
        Blend  [_SrcBlend] [_DstBlend]
        ZWrite Off
        ZTest LEqual
        Cull Off
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_instancing
            #include "UnityCG.cginc"
            #include "Assets/CGInclude/LGameFog.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float4 uv : TEXCOORD0;
                half4 color :COLOR;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float2 maskuv :TEXCOORD1;
                half2 customData :TEXCOORD2;
                half4 color :TEXCOORD3;
            #if defined(LGAME_USEFOW) && (_FOW_ON || _FOW_ON_CUSTOM)
                half2 fowuv	: TEXCOORD4;
            #endif
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };
            // Instance Buffer for VS
            UNITY_INSTANCING_BUFFER_START(VSIB1)
                UNITY_DEFINE_INSTANCED_PROP(fixed4, _OffsetColor)
	        #   define B_OffsetColor UNITY_ACCESS_INSTANCED_PROP(VSIB1,_OffsetColor)
		        UNITY_DEFINE_INSTANCED_PROP(half, _OffsetColorLerp)
	        #   define B_OffsetColorLerp UNITY_ACCESS_INSTANCED_PROP(VSIB1,_OffsetColorLerp)
                UNITY_DEFINE_INSTANCED_PROP(half, _UseCustomData)
	        #	define B_UseCustomData UNITY_ACCESS_INSTANCED_PROP(FSIB,_UseCustomData)
                 UNITY_DEFINE_INSTANCED_PROP(float4, _MainTex_ST)
	        #	define B_MainTex_ST UNITY_ACCESS_INSTANCED_PROP(FSIB,_MainTex_ST)
                UNITY_DEFINE_INSTANCED_PROP(float4, _MaskTex_ST)
	        #	define B_MaskTex_ST UNITY_ACCESS_INSTANCED_PROP(FSIB,_MaskTex_ST)
            UNITY_INSTANCING_BUFFER_END(VSIB1)

            // Instance Buffer for FS
            UNITY_INSTANCING_BUFFER_START(FSIB)
                UNITY_DEFINE_INSTANCED_PROP(half, _AlphaCtrl)
	        #   define B_AlphaCtrl UNITY_ACCESS_INSTANCED_PROP(FSIB,_AlphaCtrl)
            UNITY_DEFINE_INSTANCED_PROP(fixed4, _Color)
	        #   define B_Color UNITY_ACCESS_INSTANCED_PROP(FSIB, _Color)
            UNITY_INSTANCING_BUFFER_END(FSIB)

            sampler2D _MainTex;
            sampler2D _MaskTex;
            float _BlendMode;
            v2f vert (appdata v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, o);
                UNITY_TRANSFER_INSTANCE_ID(v, o);
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.customData.xy = v.uv.zw;
                o.uv = v.uv.xy*B_MainTex_ST.xy +lerp(B_MainTex_ST.zw,o.customData.xy,B_UseCustomData);
                o.maskuv = TRANSFORM_TEX(v.uv.xy,_MaskTex);
                o.color.rgb = lerp(v.color.rgb,B_OffsetColor.rgb,B_OffsetColorLerp);
                o.color.a = v.color.a;
            #if defined(LGAME_USEFOW) && (_FOW_ON || _FOW_ON_CUSTOM)
                float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.fowuv = half2 ((worldPos.x -_FOWParam.x)/_FOWParam.z, (worldPos.z -_FOWParam.y)/_FOWParam.w);
            #endif
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                col *= i.color;
                col.rgb *= B_Color.rgb;
                fixed4 mask = tex2D(_MaskTex ,i.maskuv);
                col *= mask.r;
             #if defined(LGAME_USEFOW) && (_FOW_ON || _FOW_ON_CUSTOM)
    		    LGameFogApply(col, i.vertex.xyz, i.fowuv); // 暂定用 i.pos, 需对齐测试效果
            #endif
                col *= B_AlphaCtrl;
                return col;
            }
            ENDCG
        }
    }
    CustomEditor "LGameNPCGpuSkinnedEffectGUI"
}
