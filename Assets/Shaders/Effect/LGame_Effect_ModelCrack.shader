Shader "LGame/Effect/Model_Crack"
{
    Properties
    {
        [HideInInspector] _OptionMode("__OptionMode",float) = 1	
        [HideInInspector] _StencilMode("__StencilMode",float) = 1	
        [Enum(Off, 0, On, 1)]_ZWriteMode ("__ZWriteMode", float) = 1
		[Enum(UnityEngine.Rendering.CullMode)]_CullMode ("__CullMode", float) = 2
		[Enum(UnityEngine.Rendering.CompareFunction)]_ZTestMode ("__ZTestMode", Float) = 4

        [hdr]_MainColor("Main Color" , Color) = (1,1,1,1)//染色	
        _MainTex("Main Texture(RGBA)", 2D) = "white" {} //主纹理

        _ShadowInt("Shadow Intensity", Range(0,1)) = 0

        _NormTex ("Normal Texture", 2D) = "bump" {} 

        [HideInInspector] _CrackLayer ("Crack Layer", Float) = 0.0
		[Enum(UnityEngine.Rendering.CompareFunction)]_StencilComp("Stencil Comparison", Float) = 8
		_Stencil("Stencil ID", Float) = 0
		[Enum(UnityEngine.Rendering.StencilOp)]_StencilOp("Stencil Operation", Float) = 0
		[Enum(UnityEngine.Rendering.ColorWriteMask)]_ColorWriteMask("Color Mask", float) = 1
    }
    SubShader
    {
		Tags { "RenderType"="AlphaTest" "Queue"="AlphaTest" }
        LOD 75

        Pass
        {
			Stencil
			{
				Ref[_Stencil]
				Comp[_StencilComp]
				Pass[_StencilOp]
			}

            Cull [_CullMode]
			ZWrite [_ZWriteMode]
			ZTest [_ZTestMode]
			ColorMask [_ColorWriteMask]

			CGPROGRAM
			#pragma target 3.0

            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "AutoLight.cginc" 
            #include "Lighting.cginc" 

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv0 : TEXCOORD0;
                float4 normal : NORMAL;
                float4 tangent : TANGENT;
            };

            struct v2f
            {
                float2 uv0 : TEXCOORD0;
                float4 pos : SV_POSITION;
                float3 nDirWS : TEXCOORD1;
                float3 tDirWS : TEXCOORD2;
                float3 bDirWS : TEXCOORD3;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _MainColor;
            sampler2D _NormTex;
            float _ShadowInt;

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv0 = TRANSFORM_TEX(v.uv0, _MainTex);
                o.nDirWS = UnityObjectToWorldNormal(v.normal);
                o.tDirWS = normalize(mul(unity_ObjectToWorld, float4(v.tangent.xyz, 0.0)).xyz);
                o.bDirWS = normalize(cross(o.nDirWS, o.tDirWS) * v.tangent.w);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                //法线贴图采样
                float3 nDirTS = UnpackNormal (tex2D(_NormTex , i.uv0)).rgb;
                
                float3x3 TBN = float3x3 (i.tDirWS , i.bDirWS , i.nDirWS);
                //法线世界方向
                float3 nDirWS = normalize (mul (nDirTS , TBN));

                float3 lDirWS = _WorldSpaceLightPos0.xyz;

                float ndotl = dot (nDirWS , lDirWS); 
                fixed4 mainCol = tex2D(_MainTex, i.uv0);
                fixed4 baseCol = mainCol * _MainColor;
                float halfLambert = max (0.0 , (ndotl*0.5 + 0.5));
                baseCol *= min(1,halfLambert + _ShadowInt);
                return baseCol;
            }
            ENDCG
        }
    }
    CustomEditor"LGameSDK.AnimTool.LGameModelCrackGUI"
}
