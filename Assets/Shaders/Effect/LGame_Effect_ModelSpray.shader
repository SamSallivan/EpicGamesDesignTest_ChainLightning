
Shader "LGame/Effect/Model Spray"
{
	Properties
	{
		[Enum(UnityEngine.Rendering.CullMode)] _CullMode ("消隐模式(CullMode)", int) = 2
		_Color	("Color" , Color) = (1,1,1,1)//主颜色
		_MainTex ("Texture", 2D) = "white" {} //主纹理
		[SimpleToggle]_RepeatMode("Repeat Mode",Float) = 0
		_BumpMap("Normalmap", 2D) = "bump" {}
		_BumpAmt("Distortion", range(0,1)) = 0.5
		_TintAmt("Tint Amount", Range(0,1)) = 0.1
		_RimLightColor("RimLight Color" , Color) = (0,0,0,1) //边缘光颜色
		_RimLighRange("RimLigh Range", Range(0.1,10)) = 1 //边缘光范围
		_RimLighMultipliers ("RimLigh Multipliers", Range(0, 5)) = 1//边缘光强度
		_SpecularColor("Specular Color",Color) = (1,1,1,1)
		_SpecularShinness("Specular Shinness",Float) = 128
		_ShadowFalloff("Shadow Falloff" , Range(0.01,1)) = 1//阴影衰减
	}

	//高质量（带动态阴影）																				   
	SubShader
	{
		Tags { "RenderType"="Opaque" "LightMode"="ForwardBase" "Queue"="Transparent" }
		GrabPass{"_BackgroundTexture "}
		//基础Pass
		Pass
		{
			Name "ForwardBase"
			Lighting Off
			Fog { Mode Off }
			Cull [_CullMode]
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
				fixed4 color : COLOR;
			};

			struct v2f
			{
				float4	pos			: SV_POSITION;
				float4	uv			: TEXCOORD0;
				float3	viewDir: TEXCOORD1;
				half3	worldNormal	: TEXCOORD2;
				half4	screenPos	: TEXCOORD3;
				half3	lightDir	: TEXCOORD4;
				fixed4 color : COLOR;

			};
			fixed4		_Color;
			sampler2D _MainTex;
			sampler2D _BackgroundTexture;
			sampler2D _BumpMap;
			half4 _MainTex_ST;
			half _RepeatMode;
			float _BumpAmt;
			half _TintAmt;
			float4 _BumpMap_ST;
			fixed4 _SpecularColor;
			half _SpecularShinness;
			v2f vert (appdata v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex);	 
				o.uv.zw = TRANSFORM_TEX(v.texcoord, _BumpMap);
				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				half3 wPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				o.viewDir = UnityWorldSpaceViewDir(wPos);
				o.screenPos = ComputeGrabScreenPos(o.pos);
				o.lightDir = UnityWorldSpaceLightDir(wPos);
				o.color = v.color;
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{ 
				half3 V = normalize(i.viewDir);
				half3 N = normalize(i.worldNormal);
				half3 R = reflect(-V, N);
				half VoR = saturate(dot(V, R));
				i.uv.xy = lerp(i.uv.xy, frac(i.uv.xy), _RepeatMode);
				half4 mainTex = tex2D(_MainTex, i.uv.xy) * _Color;
				half2 bump = UnpackNormal(tex2D(_BumpMap, i.uv.zw)).rg;
				float2 offset = bump * _BumpAmt *i.color.a;
				i.screenPos.xy = offset * i.screenPos.z + i.screenPos.xy;
				fixed4 grab = tex2Dproj(_BackgroundTexture, UNITY_PROJ_COORD(i.screenPos));
				fixed3 specular = _SpecularColor * pow(VoR, _SpecularShinness);
				half rim = 1-pow(abs(dot(V, N)), _RimLighRange);
				half3 rimLight = rim * _RimLightColor.rgb * _RimLighMultipliers;
				half3 col= lerp(grab, mainTex, _TintAmt*i.color.a)*i.color.rgb+  rimLight*i.color.a+specular*i.color.a;
				return  fixed4(col, 1) ;
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
							#pragma vertex vert
							#pragma fragment fragtest
							//#pragma multi_compile_instancing
							#include "Assets/CGInclude/LGameEffect.cginc" 

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