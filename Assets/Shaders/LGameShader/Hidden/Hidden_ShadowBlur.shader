Shader "Hidden/ShadowBlur" {
	Properties {
		_MainTex ("Base (RGB)", 2D) = "" {}
	}

	CGINCLUDE
	
	#include "UnityCG.cginc"
	
	struct v2f {
		float4 pos : SV_POSITION;
		float2 uv : TEXCOORD0;

		float4 uv01 : TEXCOORD1;
		float4 uv23 : TEXCOORD2;
		float4 uv45 : TEXCOORD3;
	};
	
	float4 offsets;
	half BlurSpreadSize;
	sampler2D _MainTex;
	
	v2f vert (appdata_img v) {
		v2f o;
		o.pos = UnityObjectToClipPos(v.vertex);

		o.uv.xy = v.texcoord.xy;

		o.uv01 =  v.texcoord.xyxy + offsets.xyxy * float4(1,1, -1,-1);
		o.uv23 =  v.texcoord.xyxy + offsets.xyxy * float4(1,1, -1,-1) * 2.0;
		o.uv45 =  v.texcoord.xyxy + offsets.xyxy * float4(1,1, -1,-1) * 3.0;

		return o;
	}
	v2f vert_horizontal (appdata_img v) {
		v2f o;
		o.pos = UnityObjectToClipPos(v.vertex);

		o.uv.xy = v.texcoord.xy;

		o.uv01 =  v.texcoord.xyxy + offsets.x * float4(1,0, -1,0);
		o.uv23 =  v.texcoord.xyxy + offsets.x * float4(1,0, -1,0) * 2.0;
		o.uv45 =  v.texcoord.xyxy + offsets.x * float4(1,0, -1,0) * 3.0;

		return o;
	}
	v2f vert_vertical (appdata_img v) {
		v2f o;
		o.pos = UnityObjectToClipPos(v.vertex);

		o.uv.xy = v.texcoord.xy;

		o.uv01 =  v.texcoord.xyxy + offsets.y* float4(0,1, 0,-1);
		o.uv23 =  v.texcoord.xyxy + offsets.y* float4(0,1, 0,-1) * 2.0;
		o.uv45 =  v.texcoord.xyxy + offsets.y* float4(0,1, 0,-1) * 3.0;

		return o;
	}
	half4 frag (v2f i) : COLOR {
		half4 color = float4 (0,0,0,0);

		color += 0.324 * tex2D (_MainTex, i.uv);
		color += 0.232 * tex2D (_MainTex, i.uv01.xy);
		color += 0.232 * tex2D (_MainTex, i.uv01.zw);
		color += 0.0855 * tex2D (_MainTex, i.uv23.xy);
		color += 0.0855 * tex2D (_MainTex, i.uv23.zw);
		color += 0.0205 * tex2D (_MainTex, i.uv45.xy);
		color += 0.0205 * tex2D (_MainTex, i.uv45.zw);

		return color;
	}
										 
	ENDCG
	
Subshader 
{
	Pass 
	{
		ZTest Always 
		Cull Off 
		ZWrite Off
		Fog { Mode off }
	
		CGPROGRAM
		#pragma fragmentoption ARB_precision_hint_fastest
		#pragma vertex vert_horizontal
		#pragma fragment frag
		ENDCG
	 }
	Pass 
	{
		ZTest Always 
		Cull Off 
		ZWrite Off
		Fog { Mode off }
	
		CGPROGRAM
		#pragma fragmentoption ARB_precision_hint_fastest
		#pragma vertex vert_vertical
		#pragma fragment frag
		ENDCG
	 }
}

Fallback off


} // shader
