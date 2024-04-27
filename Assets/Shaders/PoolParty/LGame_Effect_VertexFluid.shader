Shader "LGame/Effect/VertexFluid" {
	Properties {
		_Color ("Color", Color) = (1,1,1,1)
		_BoundingMax("Bounding Max", Float) = 1.0
		_BoundingMin("Bounding Min", Float) = 1.0
		_NumOfFrames("Number Of Frames", int) = 240
		_Speed("Speed", Float) = 0.33
		_PosTex ("Position Map (RGB)", 2D) = "white" {}
		_NTex ("Normal Map (RGB)", 2D) = "grey" {}
		_HighlightPower("Highlight Power",Float) = 16
		_HighlightStrength("Highlight Strength",Float) = 8
		_HighlightColor("Highlight Color",Color) = (1,1,1,1)
		_CubeMap ("Cube Map (RGB)", CUBE) = "" {}
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
				sampler2D _PosTex;
				sampler2D _NTex;
				samplerCUBE _CubeMap;
				uniform float _BoundingMax;
				uniform float _BoundingMin;
				uniform float _Speed;
				uniform int _NumOfFrames;
				half _HighlightPower;
				half _HighlightStrength;
				fixed4 _HighlightColor;
				struct appdata
				{
					float4 vertex : POSITION;
					float2 texcoord : TEXCOORD0;
					half3 normal:NORMAL;
					half4 tangent:TANGENT;
				};
				struct v2f {
					float4 vertex : SV_POSITION;
					half3 normal:NORMAL;
					half3 viewDir:TEXCOORD0;
					half3 lightDir:TEXCOORD1;
					half4 screenPos:TEXCOORD2;
					float4 tangentToWorld[3]:TEXCOORD3;
				};

			fixed4 _Color;
			float _Timer;
			half _Distort;
			//vertex function
			v2f vert(appdata v) {
				v2f o;
				//calculate uv coordinates
				float timeInFrames = ((ceil(frac(-_Timer * _Speed) * _NumOfFrames)) / _NumOfFrames) + (1.0 / _NumOfFrames);

				//get position, normal and colour from textures
				float4 texturePos = tex2Dlod(_PosTex,float4(v.texcoord.x, (timeInFrames + v.texcoord.y), 0, 0));
				float3 textureN = tex2Dlod(_NTex,float4(v.texcoord.x, (timeInFrames + v.texcoord.y), 0, 0));

				//expand normalised position texture values to world space
				float expand = _BoundingMax - _BoundingMin;
				texturePos.xyz *= expand;
				texturePos.xyz += _BoundingMin;
				texturePos.x *= -1;  //flipped to account for right-handedness of unity
				texturePos.xyz = texturePos.xzy;  //swizzle y and z because textures are exported with z-up
				o.vertex = UnityObjectToClipPos(texturePos);
				//TBN
				o.tangentToWorld[2].xyz = UnityObjectToWorldNormal(v.normal);//N
				o.tangentToWorld[0].xyz = UnityObjectToWorldNormal(v.tangent.xyz);//T
				o.tangentToWorld[1].xyz = cross(o.tangentToWorld[2].xyz, o.tangentToWorld[0].xyz)*v.tangent.w*unity_WorldTransformParams.w;//B

				textureN = textureN.xzy;
				textureN *= 2;
				textureN -= 1;
				textureN.x *= -1;
				o.normal = textureN;
				half3 worldPos = mul(unity_ObjectToWorld, texturePos);
				o.viewDir = UnityWorldSpaceViewDir(worldPos);
				o.lightDir = UnityWorldSpaceLightDir(worldPos);
				o.screenPos = ComputeScreenPos(o.vertex);
				return o;
				}

				fixed4 frag(v2f i) : SV_Target
				{
					half3 normal = normalize(i.normal);
					half3 N = normalize(i.tangentToWorld[0] * normal.r + i.tangentToWorld[1] * normal.g + i.tangentToWorld[2] * normal.b);
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
					fixed3 col =lerp(background,_Color.rgb+ specular, _Color.a*saturate(Luminance(reflectColor.rgb*fresnel)));
					return fixed4(col,1);
				}
				ENDCG
			}
	}
}
