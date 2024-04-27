Shader "LGame/Scene/PoolSpray"
{
	Properties{
		_Color("Color", Color) = (1,1,1,1)	
		_NormalMap("Normal",2D) = "bump"{}
		_HighlightPower("Highlight Power",Float) = 16
		_HighlightStrength("Highlight Strength",Float) = 8
		_HighlightColor("Highlight Color",Color) = (1,1,1,1)
		_CubeMap("Cube Map (RGB)", CUBE) = "" {}
		_Distort("Distort",Range(0,1)) = 0.5
	}
	SubShader{
		Tags{ "Queue" = "Transparent" }
		GrabPass{ "_BackgroundTexture" }
		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag	
			#include "UnityCG.cginc"
			sampler2D _BackgroundTexture;	
			sampler2D _NormalMap;
			samplerCUBE _CubeMap;
			half _HighlightPower;
			half _HighlightStrength;
			fixed4 _HighlightColor;
			float4 _NormalMap_ST;
			struct appdata
			{
				half4 vertex : POSITION;
				half2 uv : TEXCOORD0;
				half3 normal:NORMAL;
				half4 tangent:TANGENT;
			};
			struct v2f {
				half4 vertex : SV_POSITION;
				half4 uv:TEXCOORD0;
				half3 normal:NORMAL;
				half3 viewDir:TEXCOORD1;
				half3 lightDir:TEXCOORD2;
				half4 screenPos:TEXCOORD3;
				half4 tangentToWorld[3]:TEXCOORD4;
			};

			fixed4 _Color;
			half _Distort;
	//vertex function
	v2f vert(appdata v) {
		v2f o;
		o.vertex = UnityObjectToClipPos(v.vertex);
		o.uv.xy = TRANSFORM_TEX(v.uv, _NormalMap);
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

	fixed4 frag(v2f i) : SV_Target
	{
		half3 normal = UnpackNormal(tex2D(_NormalMap,i.uv));
		half3 N = normalize(i.tangentToWorld[0].xyz * normal.r + i.tangentToWorld[1].xyz * normal.g + i.tangentToWorld[2].xyz * normal.b);
		half3 V = normalize(i.viewDir);
		half3 L = normalize(i.lightDir);
		half3 R = reflect(-V,N);
		half3 H = normalize(L + V);
		half NoH = saturate(dot(N, H));
		half NoV = saturate(dot(N, V));
		half fresnel = 0.02 + 0.98*pow(1 - NoV, 5);
		half3 blinnPhong = pow(NoH, _HighlightPower)*_HighlightStrength*_HighlightColor;
		half3 reflectColor = texCUBE(_CubeMap, R);
		half3 specular = (reflectColor + blinnPhong) * fresnel;

		i.screenPos.xy += N.xy*_Distort;
		half3 background = tex2Dproj(_BackgroundTexture, UNITY_PROJ_COORD(i.screenPos));
		fixed3 col = lerp(background,_Color.rgb + specular, saturate(_Color.a+Luminance(_Color.rgb + specular)));
		return fixed4(col,1);
	}
		ENDCG
	}
	}
}
