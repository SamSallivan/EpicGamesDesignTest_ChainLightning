//ShadowGun Sample
Shader "LGame/Rain/Ripple" {
	Properties{
		_Color("Color",Color)=(1,1,1,1)
		_MainTex("Base texture", 2D) = "white" {}
		_Scale("Scale",Vector)=(1,1,1)
	}
	SubShader{
		Tags { "Queue" = "Transparent" "IgnoreProjector" = "True" "RenderType" = "Transparent" }
		Blend SrcAlpha OneMinusSrcAlpha
		Cull Off 
		ZWrite Off 
		LOD 100
		Pass {
			CGPROGRAM
			#pragma vertex vert  
			#pragma fragment frag  
			//#pragma multi_compile_instancing
			#include "UnityCG.cginc"  
			sampler2D _MainTex;
			float _Offset;
			half3 _Scale;
			fixed4 _Color;
			struct v2f {
				float4  pos : SV_POSITION;
				float3  uv  : TEXCOORD0;//z is used for alpha
			};
			float rand(float co) {
				return frac(sin(dot(co.xx, float2(12.9898, 78.233))) * 43758.5453);
			}
			v2f vert(appdata_full v)
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID(v);
				o.uv.xy = v.texcoord.xy;
				float3  centerOffs = float3(0.5 - float2(v.texcoord.x, v.texcoord.y), 0);
				float temp = _Offset + v.color.r;
				centerOffs.xy = centerOffs.xy* _Scale * frac(temp);
				float rand_scale = max(0.5,rand(floor(temp)*v.color));
				float3  scale = float3(centerOffs.x, 0, centerOffs.y) * rand_scale;
				o.pos = UnityObjectToClipPos(float4(v.vertex.xyz+scale,1));
				o.uv.z = saturate(1.25-frac(_Offset + v.color.r));
				return o;
			}
			fixed4 frag(v2f i) : COLOR
			{		
				fixed4 col = tex2D(_MainTex,i.uv.xy)*_Color*i.uv.z;
				return col;
			}
			ENDCG
		}
	}
}