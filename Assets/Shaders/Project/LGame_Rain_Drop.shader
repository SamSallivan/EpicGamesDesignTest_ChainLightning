Shader "LGame/Rain/Drop"
{
	Properties
	{
		_Color("Color",Color)=(1,1,1,1)
		_MainTex ("Texture", 2D) = "white" {}
		_HeightStep("Height Step",Range(0.0,1.0))=0.1
		_TexCoordStep("TexCoord Step",Range(0.0,1.0)) = 0.1
	}
	SubShader
	{
		Tags { "RenderType" = "Transparent" }
		LOD 100
		Zwrite Off
		Cull Off
		Blend SrcAlpha OneMinusSrcAlpha
		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			//#pragma multi_compile_instancing
			#include "UnityCG.cginc"
			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv	  : TEXCOORD0;
				half4 color   : COLOR;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct v2f
			{
				float2 uv     : TEXCOORD0;
				float4 vertex : SV_POSITION;
				half4 rain	  : TEXCOOR1;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			fixed4 _Color;
			half _HeightStep;
			half _TexCoordStep;
			v2f vert (appdata v)
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID(v);
				o.vertex = UnityObjectToClipPos(v.vertex);
				half3 wPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				half3 viewDir = UnityWorldSpaceViewDir(wPos);
				half3 forwardDir = normalize(mul((float3x3)unity_CameraToWorld, float3(0, 0, 1)));
				o.rain.x = mul(unity_ObjectToWorld,v.vertex).y;
				o.rain.y = v.color.x;
				o.rain.z = v.uv.y;
				o.rain.w = abs(dot(viewDir,forwardDir));
				o.uv = TRANSFORM_TEX(v.uv + float2(0,v.color.y), _MainTex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				fixed4 col = tex2D(_MainTex, i.uv)*_Color;
				half gradient = smoothstep(0, _HeightStep, i.rain.x) * smoothstep(0,_TexCoordStep, 1.0-abs(i.rain.z-0.5)*2.0) * i.rain.y;
				col.a *= gradient;
				//Near Clip Plane
				col.a *= smoothstep(_ProjectionParams.y, _ProjectionParams.y + 2.0f, i.rain.w);
				return col;
			}
			ENDCG
		}
	}
}
