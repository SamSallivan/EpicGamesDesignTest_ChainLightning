Shader "LGame/StarActor/FlowLight"
{
	Properties
	{
		_Color("Main Color" , Color) = (1,1,1,1)
		_MainTex ("Texture", 2D) = "white" {}
		_BumpMap("Normal Map", 2D) = "bump" {}

		[Space(20)]
		_NoiseTex("Noise Texture" , 2D) = "white" {}
		_Speed("Speed" , Vector) = (0,0,0,0)
		_FlowLightColor("FlowLight Color" , Color) = (1,1,1,1)
		_RimLighIntensity("FlowLight Intensity" , float) = 2

		_RimLightColor("RimLight Color" , Color) = (1,1,1,1)
		
		
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex	: POSITION;
				half3 normal	: NORMAL;
				half4 tangent	: TANGENT;
				float2 uv		: TEXCOORD0;
			};

			struct v2f
			{
				float4 pos				: SV_POSITION;
				float2 uv				: TEXCOORD0;
				float4 noiseuv			: TEXCOORD1;
				half3 eyeVec            : TEXCOORD2;
				half4 tangentToWorld[3]	: TEXCOORD3;    // [3x3:tangentToWorld | 1x3:worldPos]
				
			};

			sampler2D	_MainTex;
			float4		_MainTex_ST;
			sampler2D	_BumpMap;
			fixed4		_Color;
			fixed4		_FlowLightColor;
			fixed4		_RimLightColor;
			float		_RimLighIntensity;

			sampler2D	_NoiseTex;
			float4		_NoiseTex_ST;
			
			half4		_Speed;

			v2f vert (appdata v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);

				//世界空间顶点坐标
				float4 posWorld = mul(unity_ObjectToWorld, v.vertex);
				o.tangentToWorld[0].w = posWorld.x;
				o.tangentToWorld[1].w = posWorld.y;
				o.tangentToWorld[2].w = posWorld.z;

				//世界空间摄像机的方向
				o.eyeVec = normalize(posWorld.xyz - _WorldSpaceCameraPos);

				//切线转世界空间的矩阵
				float3 normalWorld = UnityObjectToWorldNormal(v.normal);
				float3 tangentWorld = UnityObjectToWorldDir(v.tangent.xyz);
				half3 binormalWorld = cross(normalWorld, tangentWorld) * v.tangent.w * unity_WorldTransformParams.w;
				o.tangentToWorld[0].xyz = tangentWorld;
				o.tangentToWorld[1].xyz = binormalWorld;
				o.tangentToWorld[2].xyz = normalWorld;

				o.uv = TRANSFORM_TEX(v.uv, _MainTex);

				o.noiseuv = v.uv.xyxy * _NoiseTex_ST.xyxy + _NoiseTex_ST.zwzw + frac( _Time.x )* _Speed ;
				return o;
			}
			
			half Pow4(half x)
			{
				return x*x * x*x;
			}
			fixed4 frag (v2f i) : SV_Target
			{

				fixed4 col = tex2D(_MainTex, i.uv) * _Color;

				half3 worldViewDir = normalize(half3(i.tangentToWorld[0].w , i.tangentToWorld[1].w , i.tangentToWorld[2].w));

				//计算法线贴图
				half3 normalTangent = UnpackNormal(tex2D (_BumpMap, i.uv.xy));
				half3 normalWorld = normalize(i.tangentToWorld[0].xyz * normalTangent.x + i.tangentToWorld[1].xyz * normalTangent.y + i.tangentToWorld[2].xyz * normalTangent.z); // @TODO: see if we can squeeze this normalize on SM2.0 as well

				//噪音采样
				fixed3 noise = tex2D(_NoiseTex , i.noiseuv.xy ) * tex2D(_NoiseTex , i.noiseuv.zw * 1.3 ) ;

				//菲尼尔
				half fresnel = Pow4(1-saturate(dot(normalize(-i.eyeVec.xyz), normalWorld)));

				//流光
				float3 flowLight = col.rgb * _FlowLightColor.rgb * _FlowLightColor.a * noise * _RimLighIntensity *  (sin(_Time.w)*0.3 + 0.7);

				
				col.rgb = lerp(col.rgb  +  flowLight * flowLight *2 , _RimLightColor.rgb * _RimLightColor.a , fresnel);


				return col;
			}
			ENDCG
		}
	}
}
