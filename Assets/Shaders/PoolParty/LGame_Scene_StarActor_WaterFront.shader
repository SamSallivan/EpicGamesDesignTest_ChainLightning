Shader "LGame/Scene/StarActor/WaterFront"
{
	Properties
	{
		[Header(Water)]
		_FrontColor("Color",Color) = (1,1,1,1)
		_ReflectionColor("Reflection Color",Color)=(1,1,1,1)
		_FrontNormalMap("Wave Normal",2D) = "bump"{}
		_FrontWaveStrength("Wave Strength",Float) = 1
		_FrontSmallWaveTiling("Small Wave Tiling",Float) = 5
		_FrontDistort("Distort",Range(0,1)) = 0.5
		_FrontHighlightPower("Highlight Power",Float) = 16
		_FrontHighlightStrength("Highlight Strength",Float) = 8
		_FrontHighlightColor("Highlight Color",Color) = (1,1,1,1)
		//xy-wave speed zw-small wave speed
		_FrontSpeed("Wave Speed",Vector) = (1,1,1,1)
		//[HideInInspector]_HeightfieldNormal("",2D) = "bump"{}
		_Environment("Environment Refletion",2D) = ""{}
	}
	SubShader
	{
		Tags{ "Queue" = "Transparent" }
		GrabPass{ "_BackgroundTexture" }
		//水-正面
		Cull Back
		Blend SrcAlpha OneMinusSrcAlpha
		Pass
		{

			Tags{"LightMode" = "ForwardBase"}
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag	
			#pragma multi_compile _ _ENABLE_GRAB
			#include "UnityCG.cginc"
			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				half3 normal:NORMAL;
				half4 tangent:TANGENT;
			};

			struct v2f
			{
				float4 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
				half3 viewDir:TEXCOORD1;
				half3 lightDir:TEXCOORD2;
				half4 ScreenPos		:TEXCOORD3;
				float3 tangentToWorld[3]:TEXCOORD4;

			};
			sampler2D	_Environment;
			half4 _Environtment_TexelSize;
			sampler2D _FrontNormalMap;
			//sampler2D _HeightfieldNormal;
			sampler2D _BackgroundTexture;
			sampler2D _CameraDepthTexture;
			half _FrontDistort;
			half _FrontWaveStrength;
			half _FrontHighlightPower;
			half _FrontHighlightStrength;
			half _FrontSmallWaveTiling;
			float4 _FrontNormalMap_ST;
			float4 _FrontSpeed;
			fixed4 _FrontColor;
			fixed4 _ReflectionColor;
			fixed4 _FrontHighlightColor;
			v2f vert(appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv.xy = TRANSFORM_TEX(v.uv, _FrontNormalMap);
				o.uv.zw = v.uv;
				//TBN
				o.tangentToWorld[2].xyz = UnityObjectToWorldNormal(v.normal);//N
				o.tangentToWorld[0].xyz = UnityObjectToWorldNormal(v.tangent.xyz);//T
				o.tangentToWorld[1].xyz = cross(o.tangentToWorld[2].xyz, o.tangentToWorld[0].xyz)*v.tangent.w*unity_WorldTransformParams.w;//B
				half3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				o.lightDir = UnityWorldSpaceLightDir(worldPos);
				o.viewDir = UnityWorldSpaceViewDir(worldPos);
				o.ScreenPos = ComputeScreenPos(o.vertex);
				return o;
			}
			fixed4 frag(v2f i) : SV_Target
			{
				half3 smallwavesNormal = UnpackNormal(tex2D(_FrontNormalMap, i.uv.xy*_FrontSmallWaveTiling + frac(_Time.y*_FrontSpeed.zw)));
				//正面水法线相乘
				half3 Normal = UnpackNormal(tex2D(_FrontNormalMap,i.uv.xy + frac(_Time.y*_FrontSpeed.xy))) * smallwavesNormal;
				Normal.xy *= _FrontWaveStrength;

				//i.uv.zw = 1.0 - i.uv.zw;
				//half3 rippleNormal = tex2D(_HeightfieldNormal, i.uv.zw) * 2.0 - 1.0;
				//Normal.xy += rippleNormal.xy;
				Normal = normalize(Normal);
				half3 N = normalize(i.tangentToWorld[0].xyz * Normal.r + i.tangentToWorld[1].xyz * Normal.g + i.tangentToWorld[2].xyz * Normal.b);
				half3 V = normalize(i.viewDir);
				half3 L = normalize(i.lightDir);
				half3 R = reflect(-V, N);
				half3 H = normalize(L + V);
				half NoV = saturate(dot(N, V));
				half NoH = saturate(dot(N, H));
				half Fresnel = 0.02 + 0.98 * pow(1.0 - NoV, 5.0);
				half3 blinnPhong = pow(NoH, _FrontHighlightPower) * _FrontHighlightStrength * _FrontHighlightColor;
				half3 reflectColor = tex2D(_Environment, (i.ScreenPos.xy + N.xz) / i.ScreenPos.w) * _ReflectionColor;
				half3 Specular = (reflectColor + blinnPhong) * Fresnel;
				half3 Water = _FrontColor.rgb + Specular;
#ifdef _ENABLE_GRAB
				float2 refr = Normal.xy *_FrontDistort;
				float4 screen = float4(i.ScreenPos.xy + refr, i.ScreenPos.zw);
				float sceneZ = LinearEyeDepth(tex2Dproj(_CameraDepthTexture, UNITY_PROJ_COORD(screen)));
				float fragZ = screen.z;
				float mask = step(fragZ, sceneZ);
				float2 refrmasked = refr * mask;
				float4 screen_masked = float4(i.ScreenPos.xy + refrmasked, i.ScreenPos.zw);
				half3 background = tex2Dproj(_BackgroundTexture, UNITY_PROJ_COORD(screen_masked));		
				//正面水颜色alpha可以控制透明度
				Water = lerp(background, Water, saturate(_FrontColor.a + Luminance(Water)));
				return fixed4(Water, 1.0);
#else
				return fixed4(Water, saturate(_FrontColor.a + Luminance(Water)));
#endif



			}
			ENDCG
		}
		Pass
		{
			Tags{ "LightMode" = "ShadowCaster" }
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_shadowcaster
			#include "UnityCG.cginc"

			struct v2f {
				V2F_SHADOW_CASTER;
			};

			v2f vert(appdata_base v)
			{
				v2f o;
				TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
				return o;
			}

			float4 frag(v2f i) : SV_Target
			{
				SHADOW_CASTER_FRAGMENT(i)
			}
			ENDCG
		}
	}
}
