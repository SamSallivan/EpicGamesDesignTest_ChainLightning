Shader "LGame/Effect/SimpleBillboard"
{
    Properties
    {

		[hdr]_MainCol("Main Color" , Color) = (1,1,1,1)
		
        _MainTex ("Texture", 2D) = "white" {}
		_Scale("Scale" , float) = 1

		[Space(10)]
		[DoubleLine] 
		[Toggle]_Breathing("Breathing Light(呼吸灯)", Float) = 0
		_Speed("Speed（呼吸灯频率）" , float) = 1
		[hdr]_SubCol("Sub Color" , Color) = (1,1,1,1)
		[DoubleLine] 
		[Header(Option)]
		[Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend ("Blend SRC(源)", float) = 1.0
        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlend ("Blend DST（目标）", float) = 0.0
		[Enum(Off, 0, On, 1)] _ZWriteMode ("ZWriteMode（深度写入）", float) = 0
		[Enum(UnityEngine.Rendering.CullMode)] _CullMode ("CullMode（剔除模式）", float) = 2
		[Enum(Less, 2, Greater, 5 ,Always , 8)] _ZTestMode ("ZTestMode（深度测试模式）", Float) = 2
		
		_AlphaCtrl("AlphaCtrl(全局透明度)",range(0,1)) = 1


    }
    SubShader
    {
        Tags {"DisableBatching" = "True" "RenderType"="Opaque" }
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
			#pragma shader_feature __ _BREATHING_ON 		

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv		: TEXCOORD0;
                float4 vertex	: SV_POSITION;
				#if  _BREATHING_ON
					fixed4 col	: COLOR;
				#endif 
            };

            sampler2D		_MainTex;
            float4			_MainTex_ST;

			fixed4			_MainCol;
			half			_Scale;

			#if  _BREATHING_ON
				fixed4		_SubCol;
				half		_Speed;
			#endif

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);

				half3 center =  UnityWorldToViewPos(unity_ObjectToWorld._14_24_34) ;
				half3 viewPos =  v.vertex.xyz * _Scale;
				viewPos.z *= 0;

				o.vertex = mul(UNITY_MATRIX_P , half4(viewPos + center, 1) );

                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

				#if  _BREATHING_ON
					o.col = sin(_Time.y * _Speed)  *0.5 + 0.5;
				#endif 

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv) ;
				#if  _BREATHING_ON
					col *= lerp(_MainCol , _SubCol, i.col);
				#else
					col *= _MainCol;
				#endif 
                return col;
            }
            ENDCG
        }
    }
}
