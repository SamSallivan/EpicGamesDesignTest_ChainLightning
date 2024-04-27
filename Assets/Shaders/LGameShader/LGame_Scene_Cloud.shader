Shader "LGame/Scene/Cloud"
{
	Properties
	{
		_Color("Color",Color)=(1,1,1,1)
		_CloudMap("CloudMap",2D) = "black"{}
		_Speed("Cloud Speed-xy",Vector)=(0,0,0,0)
	}
	SubShader
	{
		Tags { "RenderType"="Transparent" "Queue" = "Transparent" }
		LOD 100
		Zwrite Off
		Blend SrcAlpha OneMinusSrcAlpha
		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float4 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
			};

			sampler2D _CloudMap;
			float4 _CloudMap_ST;
			half4 _Speed;
			fixed4 _Color;
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv.xy = TRANSFORM_TEX(v.uv, _CloudMap);
				o.uv.zw = v.uv;
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				float distance = _Time.y * _Speed.x + _CloudMap_ST.x;
				fixed4 cloud = tex2D(_CloudMap, i.uv.xy + float2(distance,0));
				float temp= floor(i.uv.x + distance)%_CloudMap_ST.x;
				float alpha = cloud.a*saturate(sin(_Time.y*_Speed.y + temp));
				return fixed4(cloud.rgb, alpha);
			}
			ENDCG
		}
	}
}
