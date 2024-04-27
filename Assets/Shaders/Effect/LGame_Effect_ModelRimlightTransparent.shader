
Shader "LGame/Effect/Model Rimlight Transparent"
{
	Properties
	{
		[HideInInspector][Enum(UnityEngine.Rendering.BlendMode)] 		_SrcFactor ("SrcFactor()", Float) = 5
		[HideInInspector][Enum(UnityEngine.Rendering.BlendMode)] 		_DstFactor ("DstFactor()", Float) = 10
		[Enum(UnityEngine.Rendering.CullMode)] _CullMode ("消隐模式(CullMode)", int) = 2
		_Color	("Color" , Color) = (1,1,1,1)//主颜色
		_MainTex ("Texture", 2D) = "white" {} //主纹理

		_RimLightColor("RimLight Color" , Color) = (0,0,0,1) //边缘光颜色
		_RimLighRange("RimLigh Range", Range(0.1,10)) = 1 //边缘光范围
		_RimLighMultipliers ("RimLigh Multipliers", Range(0, 5)) = 1//边缘光强度

		_AlphaCtrl("Alpha control", Range(0,1)) = 1
		_ShadowFalloff("Shadow Falloff" , Range(0.01,1)) = 1//阴影衰减
		[Enum(OFF,0,ON,1)]_ZWrite("深度开关谨慎使用",int)=0
	}

	//高质量（带动态阴影）																				   
	SubShader
	{
		Tags { "RenderType"="Opaque" "LightMode"="ForwardBase" "Queue"="AlphaTest" }
		LOD 75

		//基础Pass
		Pass
		{
			Name "ForwardBase"
			ColorMask RGB
			Zwrite[_ZWrite]
			Lighting Off
			Fog { Mode Off }
			Cull [_CullMode]
			Blend [_SrcFactor] [_DstFactor]
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag	

			#include "UnityCG.cginc" 
			#include "Assets/CGInclude/LGameCG.cginc"
			struct appdata
			{
				float4	vertex		: POSITION;
				half3	normal		: NORMAL;
				half2	texcoord	: TEXCOORD0;
			};

			struct v2f
			{
				float4	pos			: SV_POSITION;
				float2	uv			: TEXCOORD0;
				float3	worldViewDir: TEXCOORD1;
				half3	worldNormal	: NORMAL; 

			};
			fixed4		_Color;

			sampler2D	_MainTex;
			half4		_MainTex_ST;

	  		half		_AlphaCtrl;


			v2f vert (appdata v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex);	 
				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				o.worldViewDir = WorldSpaceViewDir(v.vertex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				half3 worldViewDir = normalize(i.worldViewDir);
				half3 worldNormal = normalize(i.worldNormal);

				half4 mainTex = tex2D(_MainTex, i.uv.xy) * _Color;

				//边缘光
				half fresnel = 1-pow(abs(dot(worldViewDir, worldNormal)), _RimLighRange);
				half3 rimLight = fresnel * _RimLightColor.rgb * _RimLighMultipliers;



				
				half3 col = mainTex +  rimLight;

				return  fixed4( col, _AlphaCtrl* _Color.a) ;
			}
			ENDCG
		}
		
		
	}

}