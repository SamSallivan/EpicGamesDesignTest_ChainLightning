// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "LGame/Scene/StarActor/CullMesh"
{		
	SubShader
	{
		Tags { "Queue" = "AlphaTest+50" }
		Pass
		{
			ZTest Always
			ZWrite On
			Blend Zero One 

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			float _depth;

			float4 vert(float4 v : POSITION) : SV_POSITION
			{
				return UnityObjectToClipPos(v);
			}

			fixed4 frag(): SV_TARGET
			{
				return fixed4(1, 1, 1, 0);
			}
			ENDCG
		}
	}
}