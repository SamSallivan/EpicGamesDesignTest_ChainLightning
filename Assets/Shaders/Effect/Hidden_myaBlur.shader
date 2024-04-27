Shader "Hidden/myaBlur"
{
	Properties 
	{
		_MainTex ("Base (RGB)", 2D) = "" {}
	}

	CGINCLUDE
	
	#include "UnityCG.cginc"
	
	struct v2f {
		float4 pos : POSITION;
		float2 uv : TEXCOORD0;

		float4 uv01 : TEXCOORD1;
		float4 uv23 : TEXCOORD2;
		float4 uv45 : TEXCOORD3;
	};
	
	float4 offsets;
	
	sampler2D _MainTex;
	float4 _MainTex_ST;
	float2 _MainTex_TexelSize;

	v2f vert (appdata_img v) {
		v2f o;
		o.pos = UnityObjectToClipPos(v.vertex);

		o.uv.xy = v.texcoord.xy;

		o.uv01 =  v.texcoord.xyxy + offsets.xyxy * 3 * float4(1,1, -1,-1);
		o.uv23 =  v.texcoord.xyxy + offsets.xyxy * 3 * float4(1,1, -1,-1) * 2.0;
		o.uv45 =  v.texcoord.xyxy + offsets.xyxy * 3 * float4(1,1, -1,-1) * 3.0;
		return o;
	}
	
	half4 frag (v2f i) : SV_Target {
		half4 color = float4 (0,0,0,0);

		color += 0.40 * tex2D (_MainTex, i.uv).r;
		color += 0.15 * tex2D (_MainTex, i.uv01.xy).r;
		color += 0.15 * tex2D (_MainTex, i.uv01.zw).r;
		color += 0.10 * tex2D (_MainTex, i.uv23.xy).r;
		color += 0.10 * tex2D (_MainTex, i.uv23.zw).r;
		color += 0.05 * tex2D (_MainTex, i.uv45.xy).r;
		color += 0.05 * tex2D (_MainTex, i.uv45.zw).r;

		return color;
	}

	struct v2f_box {
		float4 pos : POSITION;
		float4 uv01 : TEXCOORD0;
		float4 uv23 : TEXCOORD1;
		float4 uv45 : TEXCOORD2;
		float4 uv67 : TEXCOORD3;
	};

	v2f_box vert_box (appdata_img v) {
		v2f_box o;
		o.pos = UnityObjectToClipPos(v.vertex);


		o.uv01 =  v.texcoord.xyxy + 3 * offsets.x  * float4(1,1, -1,-1);
		o.uv23 =  v.texcoord.xyxy + 3 * offsets.x  * float4(1,-1, -1,1);
		o.uv45 =  v.texcoord.xyxy + 3 * offsets.x  * float4(1,0, -1,0);
		o.uv67 =  v.texcoord.xyxy + 3 * offsets.x  * float4(0,1, 0,-1);

		return o;
	}
	
	half4 frag_box (v2f_box i) : SV_Target 
	{
		half4 color = float4 (0,0,0,0);

		color += 1 - step(0.1 ,tex2D(_MainTex, i.uv01.xy).a );
		color += 1 - step(0.1 ,tex2D(_MainTex, i.uv01.zw).a );
		color += 1 - step(0.1 ,tex2D(_MainTex, i.uv23.xy).a );
		color += 1 - step(0.1 ,tex2D(_MainTex, i.uv23.zw).a );

		color += 1 - step(0.1 ,tex2D(_MainTex, i.uv45.xy).a );
		color += 1 - step(0.1 ,tex2D(_MainTex, i.uv45.zw).a );
		color += 1 - step(0.1 ,tex2D(_MainTex, i.uv67.xy).a );
		color += 1 - step(0.1 ,tex2D(_MainTex, i.uv67.zw).a );
		
		return color/8;
	}
													 

	struct v2f_cut {
		float4 pos : POSITION;
		float2 uv : TEXCOORD0;
	};

	v2f_cut vert_cut (appdata_img v) {
		v2f_cut o;
		o.pos = UnityObjectToClipPos(v.vertex);
		o.uv =  v.texcoord.xy;
		return o;
	}
	
	half4 frag_cut (v2f_cut i) : SV_Target 
	{
		return 1 -step(0.01  , tex2D(_MainTex, i.uv).a);
	}
		

	ENDCG
	
	Subshader {
	 Pass 
	 {
		  ZTest Always Cull Off ZWrite Off
		  Fog { Mode off }
	
	      CGPROGRAM
	      #pragma fragmentoption ARB_precision_hint_fastest
	      #pragma vertex vert
	      #pragma fragment frag
	      ENDCG
	  }

	 Pass 
	 {
		  ZTest Always Cull Off ZWrite Off
		  Fog { Mode off }
	
	      CGPROGRAM
	      #pragma fragmentoption ARB_precision_hint_fastest
	      #pragma vertex vert_box
	      #pragma fragment frag_box
	      ENDCG
	  }
	 Pass 
	 {
		  ZTest Always Cull Off ZWrite Off
		  Fog { Mode off }
	
	      CGPROGRAM
	      #pragma fragmentoption ARB_precision_hint_fastest
	      #pragma vertex vert_cut
	      #pragma fragment frag_cut
	      ENDCG
	  }
	}
	Fallback off
} // shader