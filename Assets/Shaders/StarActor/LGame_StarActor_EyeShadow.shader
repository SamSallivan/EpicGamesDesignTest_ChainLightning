Shader "LGame/StarActor/Eye Shadow"
{
	Properties
	{
		_Color("Color", Color) = (1,1,1,1)
		_MainTex("Albedo", 2D) = "white" {}
	}
	SubShader
	{
		Tags{ "RenderType" = "Geometry" "Queue" = "AlphaTest+275" "PerformanceChecks" = "False" }
		LOD 300
		Pass
		{
			Name "FORWARD"
			Tags{ "LightMode" = "ForwardBase" }
			Blend SrcAlpha OneMinusSrcAlpha
			ZWrite Off
			Cull Back
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 3.0
			//#pragma multi_compile __ _USE_DIRECT_GPU_SKINNING
			#include "UnityCG.cginc"
			#include "Assets/CGInclude/LGameCharacterDgs.cginc" 

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv:TEXCOORD0;
#ifdef _USE_DIRECT_GPU_SKINNING
				float4 skinIndices : TEXCOORD2;
				float4 skinWeights : TEXCOORD3;
#endif
			};
			struct v2f
			{
				float4 pos : SV_POSITION;
				float2 uv:TEXCOORD0;
			};
			sampler2D _MainTex;
			float4 _MainTex_ST;
			fixed4 _Color;
			v2f vert(appdata v)
			{
				v2f o;
#if _USE_DIRECT_GPU_SKINNING 

				v.vertex = CalculateGPUSkin_L(v.skinIndices, v.skinWeights, v.vertex);
				v.uv.xy = DecompressUV(v.uv.xy, _uvBoundData);
#endif
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				return o;
			}
			fixed4 frag(v2f i) : SV_Target
			{
				return tex2D(_MainTex, i.uv.xy) * _Color;
			}
			ENDCG
		}		
	}
}
