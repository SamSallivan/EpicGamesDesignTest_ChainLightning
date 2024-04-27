Shader "LGame/UI/LGame_UI_HP_Instance_Solider"
{
	Properties
	{
		_MainTex("Texture", 2D) = "white" {}
	}
		SubShader
	{
		Tags
		{
			"Queue" = "Transparent"
			"IgnoreProjector" = "True"
			"RenderType" = "Transparent"
			"PreviewType" = "Plane"
			"CanUseSpriteAtlas" = "True"
		}

		Cull Off
		Lighting Off
		ZWrite Off
		ZTest[unity_GUIZTestMode]
		Blend SrcAlpha OneMinusSrcAlpha

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
				half2 uv : TEXCOORD0;
				half4 color : COLOR0;
				half4 color1 : COLOR1;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			UNITY_INSTANCING_BUFFER_START(PropPara)
			UNITY_DEFINE_INSTANCED_PROP(float4x4, _i_para_0)
			UNITY_DEFINE_INSTANCED_PROP(float4x4, _i_para_1)
			UNITY_INSTANCING_BUFFER_END(PropPara)


			UNITY_INSTANCING_BUFFER_START(PropsUV)
			UNITY_DEFINE_INSTANCED_PROP(float4x4, _i_para_2)
			UNITY_DEFINE_INSTANCED_PROP(float4x4, _i_para_3)
			UNITY_INSTANCING_BUFFER_END(PropsUV)

			UNITY_INSTANCING_BUFFER_START(PropsColor)
			UNITY_DEFINE_INSTANCED_PROP(float4x4, _i_para_4)
			UNITY_INSTANCING_BUFFER_END(PropsColor)

			sampler2D _MainTex;

			v2f vert(appdata v)
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v , o);

				fixed idx = floor(v.vertex.z + 0.5);
				fixed idx_1 = fmod(idx, 4);

				float4 data = lerp(UNITY_ACCESS_INSTANCED_PROP(PropPara, _i_para_0)[idx_1], UNITY_ACCESS_INSTANCED_PROP(PropPara, _i_para_1)[idx_1], step(4, idx)); 
				float4 uv = lerp(UNITY_ACCESS_INSTANCED_PROP(PropsUV, _i_para_2)[idx_1], UNITY_ACCESS_INSTANCED_PROP(PropsUV, _i_para_3)[idx_1], step(4, idx));

				o.vertex = UnityObjectToClipPos(v.vertex+ half3(data.z,0,0));
				o.uv = v.uv*uv.zw + uv.xy;
				o.color = data;
				o.color1 = lerp(half4(1, 1, 1, 1), UNITY_ACCESS_INSTANCED_PROP(PropsColor, _i_para_4)[abs(data.w)], step(0, data.w));
				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID(i);
				half4 col = tex2D(_MainTex, i.uv);
				col.rgb = col.rgb*i.color1.rgb;
				col.a = col.a* i.color.x*step(i.uv.x, i.color.y);
				return col;
			}
			ENDCG
		}
	}
}
