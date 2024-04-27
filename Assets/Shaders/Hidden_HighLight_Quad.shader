Shader "Hidden/HighLight_Quad" 
{
Category {

	// We must be transparent, so other objects are drawn before this one.
	Tags { "Queue"="Transparent" "RenderType"="Opaque" }
	SubShader {
		Cull off
		ZTest off
		ZWrite off

		Pass {
			Name "BASE"
			Tags { "LightMode" = "Always" }
			
CGPROGRAM
    #include "UnityCG.cginc" 
	#pragma vertex vert
	#pragma fragment frag

	struct appdata_t {
	float4 vertex : POSITION;
	float2 texcoord: TEXCOORD0;
	}; 
  
    struct v2f 
    {  
        float4 vertex : SV_POSITION;  
        float4 uv  : TEXCOORD0;    
		float4 offset[6] :TEXCOORD1;
    };  
      
	fixed4 _HighlightColor;	 
	half _OutlineStrength;
	sampler2D _OriginalTex;
	//sampler2D _DownSampleTex;
	float4 _OriginalTex_TexelSize;
	half _SamplerScale;
	half _DownScale;
    v2f vert(appdata_t v)  
    {  
        v2f o;  
        o.vertex = UnityObjectToClipPos(v.vertex);  
		o.uv=ComputeGrabScreenPos(o.vertex);

		half4 offset =  half4(0,_SamplerScale,_SamplerScale,0)*_OriginalTex_TexelSize.xyxy * _DownScale;

		o.uv.xy/=o.uv.w;

		o.offset[0].xy = o.uv.xy + offset.xy;
		o.offset[1].xy = o.uv.xy - offset.xy;
		o.offset[2].xy = o.uv.xy + offset.xy*2.0;
		o.offset[3].xy = o.uv.xy - offset.xy*2.0;
		o.offset[4].xy = o.uv.xy + offset.xy*3.0;
		o.offset[5].xy = o.uv.xy - offset.xy*3.0;

		o.offset[0].zw = o.uv.xy + offset.zw;
		o.offset[1].zw = o.uv.xy - offset.zw;
		o.offset[2].zw = o.uv.xy + offset.zw*2.0;
		o.offset[3].zw = o.uv.xy - offset.zw*2.0;
		o.offset[4].zw = o.uv.xy + offset.zw*3.0;
		o.offset[5].zw = o.uv.xy - offset.zw*3.0;

        return o;  
    }    
  

    fixed4 frag(v2f i) : SV_Target  
    {  
			
		//i.uv.xy/=i.uv.w;
		fixed edge=0;  

		edge += 0.20 * tex2D(_OriginalTex, i.uv.xy).a;  
		edge += 0.075 * tex2D(_OriginalTex, i.offset[0].xy).a;  
		edge += 0.075 * tex2D(_OriginalTex, i.offset[1].xy).a;  
		edge += 0.05 * tex2D(_OriginalTex, i.offset[2].xy).a;  
		edge += 0.05 * tex2D(_OriginalTex, i.offset[3].xy).a;  
		edge += 0.025 * tex2D(_OriginalTex, i.offset[4].xy).a;  
		edge += 0.025 * tex2D(_OriginalTex, i.offset[5].xy).a; 

		edge += 0.20 * tex2D(_OriginalTex, i.uv.xy).a;  
		edge += 0.075 * tex2D(_OriginalTex, i.offset[0].zw).a;  
		edge += 0.075 * tex2D(_OriginalTex, i.offset[1].zw).a;  
		edge += 0.05 * tex2D(_OriginalTex, i.offset[2].zw).a;  
		edge += 0.05 * tex2D(_OriginalTex, i.offset[3].zw).a;  
		edge += 0.025 * tex2D(_OriginalTex, i.offset[4].zw).a;  
		edge += 0.025 * tex2D(_OriginalTex, i.offset[5].zw).a; 
		
		fixed4 ori= tex2D(_OriginalTex, i.uv.xy);
		half mask= step(0.05 , ori.a)*(1-edge); 
		fixed4 color =lerp(ori,_HighlightColor,mask*_OutlineStrength); 
		color.a=1;
        return color;  
    }  
  
ENDCG
		}
	}

}


}
