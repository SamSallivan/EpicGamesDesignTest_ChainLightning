Shader "LGame/Effect/CustomFire"
{
    Properties
    {
		_AlphaCtrl("AlphaCtrl",range(0,1)) = 1
        
        [Header(Option)]
		[HideInInspector] _OptionMode("__OptionMode",float) = 0	
		[HideInInspector] _BlendMode ("__BlendMode",float) = 0
        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend ("__src", float) = 1.0
        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlend ("__dst", float) = 0.0
		[Enum(Off, 0, On, 1)] _ZWriteMode ("__ZWriteMode", float) = 0
		[Enum(UnityEngine.Rendering.CullMode)] _CullMode ("__CullMode", float) = 2
		[Enum(Less, 2, LessEqual, 4, Greater, 5, Always, 8)] _ZTestMode ("__ZTestMode", Float) = 2
        [IntRange]_FresnelScale("Fresnel Scale",Range(1,10)) = 1
        [Toggle] _Screenuv("Use Screen UV", Float) = 0

        [Space]
        [hdr]_Color("Color" , Color) = (1,1,1,1)
        _Scale("_Scale" , Range(0,20) )=1
        [Toggle] _Gradient("Use Gradient Texture?" , int) = 0
        _GradientTex("_GradientTex" , 2D) = "white" {}
        _MainTex ("MainTex", 2D) = "white" {}
        

        [Header(Dissove)]
        _DissoveTex("_DissoveTex" , 2D)  = "white" {}
        _Dissolve("Dissolve" , Range(0,1)) = 0.5
        _SmoothRange("_SmoothRange", Range(0.01,0.5)) = 0.5
        _DissolveRange("_DissolveRange" , Range(0.3,3)) = 1

        [Header(HeightTrans)]
        [SimpleToggle]r("_UseHeihtTrans" , int) = 0
        _HeightTrans("_HeightTrans" , Range(-1,1))  = 0
        _HeightTransRange("_HeightTransRange" , Range(0,20))  = 1

		[HideInInspector] _StencilComp("Stencil Comparison", Float) = 8
		[HideInInspector] _Stencil("Stencil ID", Float) = 0
		[HideInInspector] _StencilOp("Stencil Operation", Float) = 0
		[HideInInspector] _StencilWriteMask("Stencil Write Mask", Float) = 255
		[HideInInspector] _StencilReadMask("Stencil Read Mask", Float) = 255

    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
        Blend [_SrcBlend] [_DstBlend]
        ZWrite [_ZWriteMode]
        ZTest [_ZTestMode]
        Cull [_CullMode]
		Stencil
		{
			Ref[_Stencil]
			Comp[_StencilComp]
			Pass[_StencilOp]
			ReadMask[_StencilReadMask]
			WriteMask[_StencilWriteMask]
		}
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma shader_feature __ _SCREENUV_ON
            #pragma shader_feature __ _GRADIENT_ON

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
                float4 color:COLOR;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 uv2 : TEXCOORD1;
				float3 normalDir : TEXCOORD2;
                float3 worldPos: TEXCOORD3;
                float4 pos : SV_POSITION;
                float4 color: TEXCOORD4;
            };

            float4 _Color;
            sampler2D _GradientTex;
            sampler2D _MainTex;
            float4 _MainTex_ST;

            sampler2D _DissoveTex;
            float4 _DissoveTex_ST;
            float _Dissolve;
            float _DissolveRange;
            float _SmoothRange ;

            float _FresnelScale;
            float4 _Vector;
            float _OffsetY;
            float _Scale ;

            int _UseHeihtTrans;
            float _HeightTrans;
            float _HeightTransRange;
            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                float2 uv = v.uv ;
                #if _SCREENUV_ON
                half4 srcPos = ComputeScreenPos(o.pos);
                uv =  srcPos.xy /srcPos.w;
                #endif
                o.uv2.xy = uv * _MainTex_ST.xy + _MainTex_ST.zw * _Time.y;
                o.uv2.zw = uv * _DissoveTex_ST.xy + _DissoveTex_ST.zw * _Time.y;

                o.normalDir = mul(v.normal, (float3x3)unity_WorldToObject);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                o.color  = v.color;
               //o.color = (v.vertex.y - _Down) * (1-v.vertex.y) * _Top;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 normalDir = normalize(i.normalDir)         ;
                float3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos) * float3(1,0,1)); 
                float fresnel =  pow(abs(dot(viewDir,normalDir)),_FresnelScale) ;
        
                fixed heightTrans = saturate(saturate(i.uv.y )* _HeightTransRange + 1 - (1+_HeightTransRange)*_HeightTrans);
                
                fixed noise = tex2D(_DissoveTex, i.uv2.zw).r ;
                fixed fireMask = saturate((1 - i.uv.y) * fresnel);
                fixed dissolveValue = _DissolveRange * fireMask + 1 - (1+_DissolveRange)* _Dissolve;
                dissolveValue = saturate((dissolveValue + dissolveValue * noise ));
                fixed dissolve = smoothstep(0.5 - _SmoothRange,0.5 + _SmoothRange, dissolveValue);
                float mainTex = saturate(tex2D(_MainTex, i.uv2.xy).r * i.color.r *fresnel*_Scale);
                #if _GRADIENT_ON
                float4 col = tex2D(_GradientTex , float2(mainTex * dissolve, 0.5)) * _Color  ;
                #else
                float4 col = mainTex * dissolve *_Color;
                #endif
                col.a *= _UseHeihtTrans? heightTrans:1;
                return col ;
            }
            ENDCG
        }
    }
}                                                                  
                      