Shader "LGame/Effect/Ice"
{
	Properties
	{
		[Header(Ice)]
		_AlphaCtrl("Alpha Ctrl",Range(0,1))=0.8
		_FresnelPower("Fresnel Power" , Float) = 4.5
		_TransmissionColor("Transmission Color" , Color) = (1,1,1,1)
		_GemColor("Gem Color",Color) = (1,1,1,1)
		_SpecularColor("Specular Color",Color) = (1,1,1,1)
		_MainTex("Main Texture", 2D) = "white" {}
		_NormalMap("Normal Map", 2D) = "bump" {}
		_VeinsMap("Veins Map", 2D) = "black" {}
		_CrackMap("Crack Map", 2D) = "black" {}
		_NoiseNormalMap("Noise Normal Map",2D) = "bump"{}
		_ReflectionVectorLerp("Reflection Vector Lerp" ,Range(0,1)) = 0.4
		_Roughness("Roughness" , Range(0,1)) = 0.025
		_Opacity("Opacity" , Range(0,1)) = 0
		_ShadowColor("Shadow Color" , Color) = (0,0,0,0.667)
		_ShadowFalloff("Shadow Falloff" , Range(0.01,1)) = 0.5
		_ShadowStrength("Self Shadow Strength" , Range(0,1)) = 1
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" "PerformanceChecks"="False" }
		LOD 300
		//地面阴影pass
		//UsePass "LGame/StarActor/Standard_Beta/SHADOWPLANE"
		Pass
		{
			Blend SrcAlpha OneMinusSrcAlpha
			//Zwrite Off
			Cull Back
			Name "FORWARD"
			Tags { "LightMode" = "ForwardBase" }
			CGPROGRAM
			#pragma multi_compile_fwdbase
			#pragma vertex vertBase
			#pragma fragment fragBase
			#include "UnityCG.cginc"
			#include "AutoLight.cginc"	
			#include "Lighting.cginc"
			#pragma target 3.0
			//顶点输入结构
			struct VertexInput
			{
				float4 vertex			: POSITION;
				half3 normal			: NORMAL;
				float2 uv				: TEXCOORD0;
				half4 tangent			: TANGENT;			  
			};

			//顶点到片元结构
			struct VertexOutputForwardBase
			{

				float4 pos				: SV_POSITION;
			    float4 uv               : TEXCOORD0;
			    half3 viewDir           : TEXCOORD1;
			    half4 tangentToWorld[3]	: TEXCOORD2; 
			};
			sampler2D _MainTex;
			sampler2D _NormalMap;
			sampler2D _VeinsMap;
			sampler2D _CrackMap;
			sampler2D _NoiseNormalMap;
			half _FresnelPower;
			half _IceBrightness;
			half _ReflectionVectorLerp;
			fixed4 _TransmissionColor;
			fixed4 _GemColor;
			fixed4 _SpecularColor;
			half _Roughness;
			half _Opacity;
			half _AlphaCtrl;
			float4 _CrackMap_ST;
			//顶点着色器									    
			VertexOutputForwardBase vertBase (VertexInput v)
			{
				VertexOutputForwardBase o;
				UNITY_INITIALIZE_OUTPUT(VertexOutputForwardBase , o);
				float4 posWorld = mul(unity_ObjectToWorld, v.vertex);
				o.tangentToWorld[0].w = posWorld.x;
				o.tangentToWorld[1].w = posWorld.y;
				o.tangentToWorld[2].w = posWorld.z;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv.xy = v.uv;
				o.uv.zw = TRANSFORM_TEX(v.uv,_CrackMap);
				o.viewDir = UnityWorldSpaceViewDir(posWorld);
				float3 normalWorld = UnityObjectToWorldNormal(v.normal);
				float3 tangentWorld = UnityObjectToWorldDir(v.tangent.xyz);
				half3 binormalWorld = cross(normalWorld, tangentWorld) * v.tangent.w * unity_WorldTransformParams.w;
				o.tangentToWorld[0].xyz = tangentWorld;
				o.tangentToWorld[1].xyz = binormalWorld;
				o.tangentToWorld[2].xyz = normalWorld;
				return o;
			}
			float3 TransmissionBRDF(float3 L, float3 V, half3 N, float3 H, float3 SubsurfaceColor, float Opacity) {
				float InScatter = pow(saturate(dot(L, -V)), 12) * lerp(3, 0.1, Opacity);
				float NormalContribution = saturate(dot(N, H) * Opacity + 1 - Opacity);
				float BackScatter = NormalContribution /6.283185306;
				return SubsurfaceColor * lerp(BackScatter, 1, InScatter);
			}
			half3 Fresnel(half3 F0, half NoV, half exponent)
			{
				return F0 + (1 - F0) * pow(1 - NoV, exponent);
			}
			//片元着色器
			fixed4 fragBase (VertexOutputForwardBase i) : SV_Target
			{ 
				half3 color = tex2D(_MainTex, i.uv);
				half3 normal = UnpackNormal(tex2D(_NormalMap, i.uv.xy));
				half3 noise = UnpackNormal(tex2D(_NoiseNormalMap, i.uv.xy));
				half3 crack = tex2D(_CrackMap, frac(i.uv.zw));
				half3 N = normalize(i.tangentToWorld[0].xyz * normal.r + i.tangentToWorld[1].xyz * normal.g + i.tangentToWorld[2].xyz * normal.b);
				noise = normalize(i.tangentToWorld[0].xyz * noise.r + i.tangentToWorld[1].xyz * noise.g + i.tangentToWorld[2].xyz * noise.b);
				half3 V = normalize(i.viewDir);
				half3 L = normalize(_WorldSpaceLightPos0.xyz);
				half3 R = normalize(reflect(-V,N));
				half3 H = normalize(L + V);

				half NoL = saturate(dot(N,L));
				half NoH = saturate(dot(N, H));
				half NoV = saturate(dot(N, V));
				half LoH = saturate(dot(L, H));

				half fresnel = Fresnel(0.04, NoV, _FresnelPower);
				half gemFresnel = (sin(fresnel) + 1.0) * 0.5;
				half3 gemColor = (_GemColor.rgb + crack.rgb)*gemFresnel*(1 - fresnel);

				half2 veinsUV = lerp(V, noise+R, _ReflectionVectorLerp).rg;
				half veins = tex2D(_VeinsMap, frac(veinsUV)).r;
				half3 ice = gemColor+veins*0.5;

				color *=lerp( _TransmissionColor.rgb , _GemColor.rgb, NoL);
				half3 specualr = GGXTerm(NoH, _Roughness) *_SpecularColor;// *_LightColor0.rgb;
				half3 transmission = TransmissionBRDF(L, V, N, H, _TransmissionColor, _Opacity);
				return fixed4(ice +color + transmission+ specualr, _AlphaCtrl);
			}														  
			ENDCG
		}					  		

	}

}
