Shader "MyUnlit/FragParallaxMap"
{
	Properties
	{
		_Diffuse("Diffuse", Color) = (1,1,1,1)
		_MainTex("Base 2D", 2D) = "white"{}
		_MapTex("MapTex", 2D) = "white"{}

		_LightColor("LightColor", Color) = (1,1,1,1)
		_LightDir("LightDir",Vector) = (-1,-1,-1,0)
		_BumpTex("Normal Map", 2D) = "bump"{}

		_HeightTex("Height Map", 2D) = "black"{}
		_HeightFactor("Height Scale", Range(0,0.05)) = 0.05

		_U_Scale("_U_Scale", Float) = 0
		_V_Scale("_V_Scale", Float) = 0

		[Toggle] _StepHeight("_StepHeight", Float) = 0 //均值采样高度 防止高度图差异比较大的问题

		[HDR]_FoamColor("Foam Speed",Color) = (1,1,1,1)
		[NoScaleOffset]_MaskTex("Mask Texture", 2D) = "white" {}
		_WaveTex("Wave Texture", 2D) = "black" {}
		_FoamTex("Foam Texture", 2D) = "black" {}	
		_WaveSpeed("Wave Speed",Vector) = (0,0,0,0)
		_FoamSpeed("Foam Speed",Vector) = (0,0,0,0)
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

		Pass
		{
			//定义Tags
			CGPROGRAM

			//引入头文件
			#include "UnityCG.cginc"
			//使用vert函数和frag函数
			#pragma vertex vert
			#pragma fragment frag

			#pragma shader_feature __ BUMP_MAP PARALLAS_MAP BUMP_PARALLAS_MAP
#if PARALLAS_MAP || BUMP_PARALLAS_MAP
			#pragma shader_feature  _STEPHEIGHT_ON
#endif
			//定义Properties中的变量
			fixed4 _Diffuse;
			sampler2D _MainTex;
			sampler2D _MapTex;

			sampler2D _BumpTex;
			fixed4 _LightColor;
			float4 _LightDir;

			float _HeightFactor;
			sampler2D _HeightTex;
			float4 _HeightTex_ST;
			float _U_Scale;
			float _V_Scale;
			float4 _LimitMapUVRect;

			//可以自行合并通道
			sampler2D _MaskTex;
			sampler2D _FoamTex;
			sampler2D _WaveTex;
			float4 _FoamTex_ST;
			float4 _WaveTex_ST;
			float2 _WaveSpeed;
			float4 _FoamSpeed;
			fixed4 _FoamColor;
			float _Fade;

			struct appdata {
				float4 vertex : POSITION;
				float4 tangent : TANGENT;
				float3 normal : NORMAL;
				float2 texcoord : TEXCOORD0;
				float2 texcoord1 : TEXCOORD1;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};


			struct v2f
			{
				float4 vertex : SV_POSITION;
				float4 uv : TEXCOORD0;
				float4 uv1 : TEXCOORD1;
				//tangent空间的光线方向
				float3 lightDir : TEXCOORD2;

#if PARALLAS_MAP || BUMP_PARALLAS_MAP
				float3 normalDir : TEXCOORD3;
				float3 tangentDir : TEXCOORD4;
				float3 bitangentDir : TEXCOORD5;
				float3 viewDir : TEXCOORD6;
#endif
			};
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);

				v.normal = normalize(v.normal);
				v.tangent.xyz = normalize(v.tangent.xyz);
				TANGENT_SPACE_ROTATION;
				//计算光线方向
				_LightDir.xyz = normalize(_LightDir.xyz);
				o.lightDir = mul(rotation, _LightDir.xyz);
				//计算观察方向

				o.uv.xy = v.texcoord;
				o.uv.zw = v.texcoord1;

#if PARALLAS_MAP || BUMP_PARALLAS_MAP
				
				o.normalDir = UnityObjectToWorldNormal(v.normal);
				o.tangentDir = mul((float3x3)unity_ObjectToWorld, v.tangent.xyz);
				o.bitangentDir = mul((float3x3)unity_ObjectToWorld, binormal);
				o.viewDir =  mul(unity_ObjectToWorld, v.vertex) - _WorldSpaceCameraPos.xyz;
				//o.viewDir = normalize(o.viewDir);
#endif
				return o;
			}

			float2 steepPallaxMapping(float3 view, float2 uv)
			{
				fixed pallaxRaymarchingMaxStep = 10.0;
				fixed stepSize = 1.0 / pallaxRaymarchingMaxStep;
				float2 uvOffset = 0.0;
				float2 uvDelta = (view.xy / view.z) * (stepSize * _HeightFactor);

				fixed stepHeight = 1.0;
				fixed surfaceHeight = tex2D(_HeightTex, uv).r;

				//探索查找
				for (float i = 1.0;i<=pallaxRaymarchingMaxStep && stepHeight > surfaceHeight;i+=1.0)
				{
					uvOffset -= uvDelta;
					stepHeight -= stepSize;

					surfaceHeight = tex2D(_HeightTex, uv + uvOffset).r;
				}

				float2 deltaUv = uvDelta / 2.0;
				fixed deltaHeight = stepSize / 2.0;

				uvOffset += deltaUv;
				stepHeight += deltaHeight;

				//二分查找
				int numSearches = 5;
				float rate = 0;
				for (int i=0;i<numSearches;++i)
				{
					deltaUv /= 2.0;
					deltaHeight /= 2.0;
					surfaceHeight = tex2D(_HeightTex, uv + uvOffset).r;

					rate = step(stepHeight,surfaceHeight);
					uvOffset += lerp(-deltaUv,deltaUv,rate);
					stepHeight += lerp(-deltaHeight,deltaHeight,rate);
				}
			
				return uvOffset;
			}

			float2 CaculateParallaxUV(v2f i)
			{
				float2 offset = float2(0,0);
#if PARALLAS_MAP || BUMP_PARALLAS_MAP
				i.normalDir = normalize(i.normalDir);
				i.tangentDir = normalize(i.tangentDir);
				i.bitangentDir = normalize(i.bitangentDir);

				float3x3 tangentTransfrom = float3x3(i.tangentDir, i.bitangentDir, i.normalDir);
				float3 viewDir = i.viewDir;
				viewDir = mul(tangentTransfrom, viewDir);
				viewDir = normalize(viewDir);

				float2 uv = i.uv.xy;
	#if _STEPHEIGHT_ON

				offset = steepPallaxMapping(viewDir, uv);
	#else
				float height = tex2D(_HeightTex, uv).r;
				//偏移值 = 切线空间的视线方向.xy（uv空间下的视线方向）* height * 控制系数
				offset = (viewDir.xy / viewDir.z) * height *_HeightFactor;
	#endif
#endif
				return offset;
			}

			float AddSub(float a, float b, float t)
			{
				return  saturate(lerp(a, (b - 1.0f) + (b + a), t));
			}

			fixed3 WaveFrag(float2 mapUV,float4 waveUV)
			{
				fixed  Mask = tex2D(_MaskTex, mapUV).r;
				float2 WaveDisplacement = frac(_WaveSpeed * _Time.x);
				float4 FoamDisplacement = frac(_FoamSpeed * _Time.x);
				fixed Wave = tex2D(_WaveTex, waveUV.zw + WaveDisplacement.xy).r;
				fixed FoamNoise0 = tex2D(_FoamTex, waveUV.xy + FoamDisplacement.xy).r;
				fixed FoamNoise1 = tex2D(_FoamTex, waveUV.xy + FoamDisplacement.zw).r;
				fixed FoamNoise = AddSub(FoamNoise0, FoamNoise1, 1.0 - Wave);
				fixed3 Foam = FoamNoise * _FoamColor * Mask * Wave;

				return Foam;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				float2 uvOffset = CaculateParallaxUV(i);
//#if PARALLAS_MAP || BUMP_PARALLAS_MAP
//				i.uv1.xy += uvOffset;
//				i.uv1.zw += uvOffset;
//#endif
				i.uv.xy += uvOffset;

				uvOffset.x *= _U_Scale;
				uvOffset.y *= _V_Scale;
				i.uv.zw += uvOffset;

				#if BUMP_MAP || BUMP_PARALLAS_MAP
				//直接解出切线空间法线[0,1] to [-1,1]
				float3 tangentNormal = UnpackNormal(tex2D(_BumpTex, i.uv));
				//normalize一下切线空间的光照方向
				float3 tangentLight = normalize(i.lightDir);
				//兰伯特光照
				fixed lambert = saturate(dot(tangentNormal, tangentLight));
				_Diffuse += lambert * _Diffuse * _LightColor;
				#endif
				//进行纹理采样
				fixed4 mainColor = tex2D(_MainTex, i.uv.zw);

#if PARALLAS_MAP || BUMP_PARALLAS_MAP
				fixed4 mapColor = tex2D(_MapTex, i.uv.xy);

				float rate = step(_LimitMapUVRect.x,i.uv.z) * step(i.uv.z,_LimitMapUVRect.z) * step(_LimitMapUVRect.y,i.uv.w) * step(i.uv.w,_LimitMapUVRect.w);
				mainColor = lerp(mapColor,mainColor,rate);

				i.uv1.xy = TRANSFORM_TEX(i.uv.xy, _FoamTex);
				i.uv1.zw = TRANSFORM_TEX(i.uv.xy, _WaveTex);

				mainColor.rgb += WaveFrag(i.uv.xy,i.uv1);
#endif
				return mainColor * _Diffuse;
			}
			ENDCG
		}
	}
	CustomEditor "ParallaxMapShaderEditor"
}
