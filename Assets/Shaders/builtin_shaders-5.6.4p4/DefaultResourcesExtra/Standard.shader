// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

Shader "Standard"
{
    Properties
    {
        _Color("Color", Color) = (1,1,1,1)
        _MainTex("Albedo", 2D) = "white" {}
    }
	SubShader
	{
		Tags { "RenderType"="Opaque"}
		LOD 75
		Blend One SrcAlpha

		//»ù´¡Pass
		Pass
		{
			Tags{"LightMode" = "ForwardBase"}

			Name "ForwardBase"
			Lighting Off
			ZWrite On
			Fog { Mode Off }

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc" 
			struct a2v
			{
				half2 texcoord			: TEXCOORD0;
				float4 vertex			: POSITION;
			};
			struct v2f
			{
				half2 uv			: TEXCOORD0;
				float4 pos			: SV_POSITION;
			};


			half4		_Color;
			sampler2D	_MainTex;
			half4		_MainTex_ST;


			v2f vert (a2v v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex);

				return o;
			}

			fixed4 frag (v2f i) : SV_Target
			{
				fixed4 col = tex2D(_MainTex, i.uv) * _Color;
				return  col;
			}
			ENDCG
		}
	}
}
