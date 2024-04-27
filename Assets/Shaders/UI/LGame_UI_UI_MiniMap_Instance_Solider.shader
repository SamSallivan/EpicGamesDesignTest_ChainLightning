Shader "LGame/UI/UI_MiniMap_Instance_Solider"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
        _OffsetRed ("Offset Red", Vector) = (0, 0, 1, 1)
	}
	SubShader
	{
		Tags
		{ 
			"Queue"="Transparent" 
			"IgnoreProjector"="True" 
			"RenderType"="Transparent" 
			"PreviewType"="Plane"
			"CanUseSpriteAtlas"="True"
		}
        
        Cull Off
		Lighting Off
		ZWrite Off
        ZTest[unity_GUIZTestMode]
		Blend SrcAlpha OneMinusSrcAlpha, Zero OneMinusSrcAlpha

		Pass
		{
			Tags { "LightMode" = "ForwardBase" }
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			//#pragma multi_compile_instancing
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
                //float2 center : TEXCOORD1;
                
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			UNITY_INSTANCING_BUFFER_START(Props)
			UNITY_DEFINE_INSTANCED_PROP(float4, _OffsetRed)
			UNITY_INSTANCING_BUFFER_END(Props)

			sampler2D _MainTex;
			float _Glob_UI_AdjustAlpha;

			v2f vert(appdata v)
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);

				o.vertex = UnityObjectToClipPos(v.vertex);
				float4 uvOffset = UNITY_ACCESS_INSTANCED_PROP(Props, _OffsetRed);
				o.uv = v.uv*uvOffset.zw + uvOffset.xy;
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID(i);
                float4 col;

                col = tex2D(_MainTex, i.uv);
				col.a *= step(0.5, col.a) * _Glob_UI_AdjustAlpha;
                // clip (col.a - 0.5);
                return col;
			}
			ENDCG
		}
	}
}