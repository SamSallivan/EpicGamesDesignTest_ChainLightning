Shader "LGame/Scene/StarActor/Water"
{
	Properties
	{
		[Header(Water Front)]
		_FrontColor("Color",Color) = (1,1,1,1)
		_Environment("Environment Refletion",2D) = ""{}
		_ReflectionColor("Reflection Color",Color) = (1,1,1,1)
		_FrontNormalMap("Wave Normal",2D) = "bump"{}
		_FrontWaveStrength("Wave Strength",Float) = 1
		_FrontSmallWaveTiling("Small Wave Tiling",Float) = 5
		_FrontDistort("Distort",Range(0,1)) = 0.5
		_FrontHighlightPower("Highlight Power",Float) = 16
		_FrontHighlightStrength("Highlight Strength",Float) = 8
		_FrontHighlightColor("Highlight Color",Color) = (1,1,1,1)
		//xy-wave speed zw-small wave speed
		_FrontSpeed("Wave Speed",Vector) = (1,1,1,1)
		[HideInInspector]_HeightfieldNormal("",2D) = "bump"{}
		[Header(Water Back)]
		_BackLightColor("Light Color", Color) = (0.2,0.8,0.9,1)
		_BackDarkColor("Dark Color", Color) = (0.2,0.8,0.9,1)
		_BackNormalMap("Wave Normal",2D) = "bump"{}
		_BackWaveStrength("Wave Strength",Float) = 1
		_BackSmallWaveTiling("Small Wave Tiling",Float) = 5
		_BackSmallWaveStrength("Small Wave Strength",Range(0,1)) = 0.5
		_BackDistort("Distort",Range(0,1)) = 0.5
		_BackHighlightPower("Highlight Power",Float) = 16
		_BackHighlightStrength("Highlight Strength",Float) = 8
		_BackHighlightColor("Highlight Color",Color) = (1,1,1,1)
		//xy-wave speed zw-small wave speed
		_BackSpeed("Wave Speed",Vector) = (1,1,1,1)

	}
	SubShader
	{
		Tags{ "Queue" = "Transparent" }
		GrabPass
		{ 
			"_BackgroundTexture" 
		}
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
				half4 screenPos:TEXCOORD3;
				float3 tangentToWorld[3]:TEXCOORD4;

			};
			sampler2D _Environment;
			half4 _Environtment_TexelSize;
			sampler2D _FrontNormalMap;
			sampler2D _HeightfieldNormal;
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
			v2f vert (appdata v)
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
				o.screenPos = ComputeScreenPos(o.vertex);
				return o;
			}
			fixed4 frag (v2f i) : SV_Target
			{
				half3 smallwavesNormal = UnpackNormal(tex2D(_FrontNormalMap, i.uv.xy*_FrontSmallWaveTiling + frac(_Time.y*_FrontSpeed.zw)));
				//正面水法线相乘
				half3 normal = UnpackNormal(tex2D(_FrontNormalMap,i.uv.xy + frac(_Time.y*_FrontSpeed.xy))) * smallwavesNormal;
				normal.xy *= _FrontWaveStrength;
				//i.uv.zw = 1 - i.uv.zw;
				//half3 rippleNormal = tex2D(_HeightfieldNormal, i.uv.zw) * 2 - 1;
				//normal.xy += rippleNormal.xy;
				normal = normalize(normal);
				half3 N = normalize(i.tangentToWorld[0].xyz * normal.r + i.tangentToWorld[1].xyz * normal.g + i.tangentToWorld[2].xyz * normal.b);
				half3 V = normalize(i.viewDir);
				half3 L = normalize(i.lightDir);
				half3 R = reflect(-V, N);
				half3 H = normalize(L + V);
				half NoV = saturate(dot(N, V));
				half NoH = saturate(dot(N, H));
				half fresnel = 0.02 + 0.98*pow(1 - NoV, 5);
				half3 blinnPhong = pow(NoH, _FrontHighlightPower)*_FrontHighlightStrength*_FrontHighlightColor;
				half3 reflectColor = tex2D(_Environment, (i.screenPos.xy + normal.xy) / i.screenPos.w)*_ReflectionColor;
				half3 specular = (reflectColor + blinnPhong) * fresnel;
				half3 water = _FrontColor.rgb + specular;
#ifdef _ENABLE_GRAB
				float2 refr = normal.xy *_FrontDistort;
				float4 screen = float4(i.screenPos.xy + refr, i.screenPos.zw);
				float sceneZ = LinearEyeDepth(tex2Dproj(_CameraDepthTexture, UNITY_PROJ_COORD(screen)));
				float fragZ = screen.z;
				float mask = step(fragZ, sceneZ);
				float2 refrmasked = refr * mask;
				float4 screen_masked = float4(i.screenPos.xy + refrmasked, i.screenPos.zw);
				half3 background = tex2Dproj(_BackgroundTexture, UNITY_PROJ_COORD(screen_masked));
				//正面水颜色alpha可以控制透明度
				water = lerp(background, water, saturate(_FrontColor.a + Luminance(water)));
				return fixed4(water, 1);
#else
				return fixed4(water, saturate(_FrontColor.a + Luminance(water)));
#endif


			}
			ENDCG
		}
		//Back
		Cull Front
		Blend SrcAlpha OneMinusSrcAlpha
		Pass
		{
			Tags{ "LightMode" = "ForwardBase" }
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag	
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
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
				half3 viewDir:TEXCOORD1;
				half3 lightDir:TEXCOORD2;
				half4 screenPos:TEXCOORD3;
				float4 tangentToWorld[3]:TEXCOORD4;
			};
			sampler2D _BackgroundTexture;
			sampler2D _BackNormalMap;
			sampler2D _CameraDepthTexture;
			half _BackDistort;
			half _BackSmallWaveStrength;
			half _BackWaveStrength;
			half _BackHighlightPower;
			half _BackHighlightStrength;
			half _BackSmallWaveTiling;
			float4 _BackSpeed;
			float4 _BackNormalMap_ST;
			fixed4 	_BackLightColor;
			fixed4 _BackDarkColor;
			fixed4 _BackHighlightColor;
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv.xy = TRANSFORM_TEX(v.uv, _BackNormalMap);
				//TBN
				o.tangentToWorld[2].xyz = UnityObjectToWorldNormal(v.normal);//N
				o.tangentToWorld[0].xyz = UnityObjectToWorldNormal(v.tangent.xyz);//T
				o.tangentToWorld[1].xyz = cross(o.tangentToWorld[2].xyz, o.tangentToWorld[0].xyz)*v.tangent.w*unity_WorldTransformParams.w;//B
				half3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				o.lightDir = UnityWorldSpaceLightDir(worldPos);
				o.viewDir = UnityWorldSpaceViewDir(worldPos);
				o.screenPos = ComputeScreenPos(o.vertex);
				return o;
			}

			fixed4 frag (v2f i) : SV_Target
			{
				half3 smallwavesNormal = UnpackNormal(tex2D(_BackNormalMap, i.uv.xy*_BackSmallWaveTiling + frac(_Time.y*_BackSpeed.zw)));
				//背面法线相加
				half3 normal = UnpackNormal(tex2D(_BackNormalMap,i.uv.xy + frac(_Time.y*_BackSpeed.xy)))+ smallwavesNormal* _BackSmallWaveStrength;
				normal.xy *= _BackWaveStrength;
				normal = normalize(normal);
				half3 N = normalize(i.tangentToWorld[0].xyz * normal.r + i.tangentToWorld[1].xyz * normal.g + i.tangentToWorld[2].xyz * normal.b);
				half3 V = normalize(i.viewDir);
				half3 L = normalize(i.lightDir);
				half3 H = normalize(L + V);
				half NoL = saturate(dot(N, L));
				half NoV = saturate(dot(N, V));
				half NoH = saturate(dot(N, H));
				half fresnel = 0.02 + 0.98*pow(1 - NoV, 5);
				half3 blinnPhong = pow(NoH, _BackHighlightPower)*_BackHighlightStrength*_BackHighlightColor;
				half3 specular = blinnPhong * fresnel;
				fixed3 water = lerp(_BackDarkColor.rgb, _BackLightColor.rgb, NoL*0.5 + 0.5) + specular;
#ifdef _ENABLE_GRAB

				float2 refr = normal.xy *_BackDistort;
				float4 screen = float4(i.screenPos.xy + refr, i.screenPos.zw);
				float sceneZ = LinearEyeDepth(tex2Dproj(_CameraDepthTexture, UNITY_PROJ_COORD(screen)));
				float fragZ = screen.z;
				float mask = step(fragZ, sceneZ);
				float2 refrmasked = refr * mask;
				float4 screen_masked = float4(i.screenPos.xy + refrmasked, i.screenPos.zw);
				half3 background = tex2Dproj(_BackgroundTexture, UNITY_PROJ_COORD(screen_masked));
				water = lerp(background, water, Luminance(water));
				return fixed4(water, 1);
#else		
				return fixed4(water, Luminance(water));				
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
