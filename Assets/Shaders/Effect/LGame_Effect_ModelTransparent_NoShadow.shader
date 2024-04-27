Shader "LGame/Effect/Model Transparent(No Shadow)"
{
	Properties
	{
		[HideInInspector][Enum(UnityEngine.Rendering.BlendMode)] 		_SrcFactor ("SrcFactor()", Float) = 5
		[HideInInspector][Enum(UnityEngine.Rendering.BlendMode)] 		_DstFactor ("DstFactor()", Float) = 10
		[Enum(UnityEngine.Rendering.CullMode)]							_CullMode ("消隐模式(CullMode)", int) = 2
		[Enum(LessEqual,4,Always,8)]									_ZTestMode ("深度测试(ZTest)", int) = 4
		
		_Color	("Color" , Color) = (1,1,1,1)//主颜色
		_MainTex ("Texture", 2D) = "white" {} //主纹理

		_AlphaCtrl("Alpha Control", Range(0,1)) = 1
		_FowBlend("FOW Blend" ,Range(0,1)) = 0	  

		[Enum(OFF,0,ON,1)]_ZWrite("深度开关谨慎使用",int)=0
	}

	//高质量（带动态阴影）																				   
	SubShader
	{
		Tags { "RenderType"="Opaque" "LightMode"="ForwardBase" "Queue"="Transparent" }
		LOD 75

		//基础Pass
		Pass
		{
			Name "ForwardBase"
			ZTest [_ZTestMode]
			Zwrite[_ZWrite]
			Cull [_CullMode]
			Lighting Off
			Fog { Mode Off }
			Blend [_SrcFactor] [_DstFactor]
			CGPROGRAM
			#pragma multi_compile __ _USE_DIRECT_GPU_SKINNING
			#pragma vertex vert
			#pragma fragment frag	

			#include "UnityCG.cginc" 
			#include "Assets/CGInclude/LGameCharacterDgs.cginc" 

			struct appdata
			{
				float4	vertex		: POSITION;
				half2	texcoord	: TEXCOORD0;
#ifdef _USE_DIRECT_GPU_SKINNING
				float4 skinIndices : TEXCOORD2;
				float4 skinWeights : TEXCOORD3;
#endif
			};

			struct v2f
			{
				float4	pos			: SV_POSITION;
				fixed4	col		: COLOR;
				float2	uv			: TEXCOORD0;

			};
			fixed4		_Color;

			sampler2D	_MainTex;
			half4		_MainTex_ST;

	  		half		_AlphaCtrl;
			half		_FowBlend;  
			fixed4		_FogCol;


			v2f vert (appdata v)
			{
#if _USE_DIRECT_GPU_SKINNING
				v.vertex = CalculateGPUSkin_L(v.skinIndices, v.skinWeights, v.vertex);
				v.texcoord.xy = DecompressUV(v.texcoord.xy, _uvBoundData);
#endif
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex);	
				o.col =  lerp(1.0.rrrr , _FogCol , _FowBlend);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				fixed4 col = tex2D(_MainTex, i.uv.xy) * _Color ;
				col.rgb *= i.col.rgb;
				col.a *=  _AlphaCtrl ;
				return  col ;
			}
			ENDCG
		}
		
		
	}

			SubShader
			{
					Tags { "Queue" = "Transparent" "LightMode" = "ForwardBase" "IgnoreProjector" = "True" "RenderType" = "Transparent"}
					LOD 5
					Blend One One
					ZWrite[_ZWriteMode]
					ZTest[_ZTestMode]
					Cull[_CullMode]

						Pass
						{
							CGPROGRAM
							#pragma multi_compile __ _USE_DIRECT_GPU_SKINNING
							#pragma vertex vert
							#pragma fragment fragtest
							//#pragma multi_compile_instancing
							#include "Assets/CGInclude/LGameEffect.cginc" 
							#include "Assets/CGInclude/LGameCharacterDgs.cginc" 

							half4 fragtest(v2f i) : SV_Target
							{
								UNITY_SETUP_INSTANCE_ID(i);

								fixed4 texColor = tex2D(_MainTex, i.uvMain.xy, float2(0, 0), float2(0, 0));

								return half4(0.15,0.06,0.03, texColor.a < 0.001);
							}
							ENDCG
						}
			}
}