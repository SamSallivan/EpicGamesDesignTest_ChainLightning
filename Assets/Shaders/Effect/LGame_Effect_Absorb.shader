// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "LGame/Effect/Absorb"
{
    Properties {
		_Color("Color" , Color) = (1,1,1,1)
        _MaskTex ("遮罩贴图 (R)", 2D) = "gray" {}
		//[ToggleOff] _Activity("使用动画效果 ?", Float) = 1.0	
		_FlowIntensity("偏移强度" , Range(-1, 1)) = 0.2
        _FlowSpeed ("动画速度", float) = 10
    }
 
    SubShader {
		Tags { "Queue" = "Transparent" }

	    GrabPass {"_GrabTexture"}
        Pass 
		{
            Tags { "RenderType"="Opaque" }
			ColorMask RGB
       		Blend SrcAlpha OneMinusSrcAlpha
			ZWrite off
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
			//#pragma shader_feature _ _ACTIVITY_OFF
 
            struct v2f {
                float4 pos		: SV_POSITION;
                fixed2 uv		: TEXCOORD0;
				half4 grabPos	: TEXCOORD1;
				half3 worldPos : TEXCOORD2;   
            };
 
			fixed4		_Color;
            sampler2D	_MaskTex;
			fixed4		_MaskTex_ST;
			sampler2D	_GrabTexture;
            fixed		_FlowSpeed;
			half		_FlowIntensity;
 
            
 
            v2f vert(appdata_tan v) {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;  
				o.grabPos = ComputeGrabScreenPos(o.pos);
                o.uv = TRANSFORM_TEX(v.texcoord, _MaskTex);
                return o;											   
            }
       
            fixed4 frag(v2f i) : COLOR {

                fixed4 c = float4(1,1,1,1);

				half3 canterWorldPos = half3(unity_ObjectToWorld[0].w,unity_ObjectToWorld[1].w,unity_ObjectToWorld[2].w);
				half mask = tex2D(_MaskTex, i.uv).r;
				half2 offset =  normalize(UnityWorldToClipPos( i.worldPos) - UnityWorldToClipPos(canterWorldPos)).xy * half2(1,-1) * mask * _FlowIntensity;

				//#ifndef _ACTIVITY_OFF
				//c = tex2D(_GrabTexture, (i.grabPos.xy + offset * 0.5)/i.grabPos.w);
				//#else
    //            half dif1 = frac(_Time.x * _FlowSpeed + 0.25);
    //            half dif2 = frac(_Time.x * _FlowSpeed + 0.75 );
 
    //            half lerpVal = abs((0.5 - dif1)/0.5) ;

				//half4 bgcolor1 = tex2D(_GrabTexture, (i.grabPos.xy+ offset * dif1) / i.grabPos.w );
 			//    half4 bgcolor2 = tex2D(_GrabTexture, (i.grabPos.xy+ offset * dif2) / i.grabPos.w );

				//c = lerp(bgcolor1, bgcolor2, lerpVal);
				//#endif

				c.a = mask;

                return c * _Color;
            }
 
            ENDCG
        }
    }
    FallBack "Diffuse"
}