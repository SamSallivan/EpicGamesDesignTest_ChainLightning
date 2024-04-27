Shader "LGame/Scene/StarActor/WaterFrontLoD"
{
	Properties
	{
		[Header(Water)]
		_FrontColor("Color",Color) = (1,1,1,1)
		_ReflectionColor("Reflection Color",Color)=(1,1,1,1)
		_FrontNormalMap("Wave Normal",2D) = "bump"{}
		_FrontWaveStrength("Wave Strength",Float) = 1
		_FrontSmallWaveTiling("Small Wave Tiling",Float) = 5
		_FrontHighlightPower("Highlight Power",Float) = 16
		_FrontHighlightStrength("Highlight Strength",Float) = 8
		_FrontHighlightColor("Highlight Color",Color) = (1,1,1,1)
		//xy-wave speed zw-small wave speed
		_FrontSpeed("Wave Speed",Vector) = (1,1,1,1)
		_CubeMap("Environment Refletion",Cube) = "cube"{}
	}
	SubShader
	{
		Tags{ "Queue" = "Transparent" }
		//水-正面
		Cull Back
		Zwrite Off
		Blend SrcAlpha OneMinusSrcAlpha
		Pass
		{
			Tags{"LightMode" = "ForwardBase"}
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
				float4 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
				half3 viewDir:TEXCOORD1;
				half3 lightDir:TEXCOORD2;
				float3 tangentToWorld[3]:TEXCOORD3;

			};
			samplerCUBE _CubeMap;
			sampler2D _FrontNormalMap;
			half _FrontWaveStrength;
			half _FrontHighlightPower;
			half _FrontHighlightStrength;
			half _FrontSmallWaveTiling;
			float4 _FrontNormalMap_ST;
			float4 _FrontSpeed;
			half4 _CubeMap_HDR;
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
				return o;
			}
			fixed4 frag(v2f i) : SV_Target
			{
				half3 smallwavesNormal = UnpackNormal(tex2D(_FrontNormalMap, i.uv.xy * _FrontSmallWaveTiling + frac(_Time.y*_FrontSpeed.zw)));
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
				half3 R = reflect(-V,N);
				half3 H = normalize(L + V);
				half NoV = saturate(dot(N, V));
				half NoH = saturate(dot(N, H));
				half Fresnel = 0.02 + 0.98 * pow(1.0 - NoV, 5.0);
				half3 blinnPhong = pow(NoH, _FrontHighlightPower) * _FrontHighlightStrength * _FrontHighlightColor;
				half4 Cube = texCUBE(_CubeMap, R);
				half3 reflectColor= DecodeHDR(Cube, _CubeMap_HDR)*_ReflectionColor;		
				half3 Specular = (reflectColor + blinnPhong) * Fresnel;
				half3 Water = _FrontColor.rgb + Specular;
				//正面水颜色alpha可以控制透明度
				return fixed4(Water, saturate(_FrontColor.a + Luminance(Water)));
			}
			ENDCG
		}		
	}
}
