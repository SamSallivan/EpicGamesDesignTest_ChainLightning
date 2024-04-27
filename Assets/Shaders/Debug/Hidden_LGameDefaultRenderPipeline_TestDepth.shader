// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Hidden/LGameDefaultRenderPipeline/TestDepth"
{
    SubShader
    {
        Tags { "RenderType"="Opaque" }

	   Pass{
			CGPROGRAM
			#pragma vertex vert  
			#pragma fragment frag  
			#include "UnityCG.cginc"  

			sampler2D _CameraDepthTexture;
			float4	_CameraDepthTexture_ST;

			struct appdata
			{
				float4 vertex : POSITION;
			};

			struct v2f
			{
				float4 scrPos:TEXCOORD1;
				float4 vertex : SV_POSITION;
			};

			v2f vert(appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.scrPos = ComputeScreenPos(o.vertex);
				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				float depthValue = Linear01Depth(tex2Dproj(_CameraDepthTexture,UNITY_PROJ_COORD(i.scrPos)).r);
				return half4(depthValue,depthValue,depthValue,1);
			}
			ENDCG
		}
    }
}
