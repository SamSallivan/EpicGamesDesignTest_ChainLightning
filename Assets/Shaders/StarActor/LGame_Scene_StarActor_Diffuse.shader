Shader "LGame/Scene/StarActor/Diffuse"
{
    Properties
    {
		_MainTex("Base (RGB)", 2D) = "white" {}
		_Luminance("Luminance", Range(0.0,1.0)) = 0.26
		[HideInInspector]_BrightnessForScene("",Range(0,1)) = 1.0
    }   
    SubShader
    {
        Tags { "Queue" = "Geometry" "RenderType" = "Opaque" }
		Stencil {
			Ref 0
			Comp always
			Pass replace
		}
        Pass
        {
            Name "FORWARD"
            Tags { "LightMode" = "ForwardBase" }          
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
			#include "UnityCG.cginc"
			struct a2v
			{
				float4 vertex: POSITION;
				half2 uv: TEXCOORD0;
			};
			struct v2f
			{
				float4 pos: SV_POSITION;
				half2 uv: TEXCOORD0;
			};
			sampler2D	_MainTex;
			half4		_MainTex_ST;
			half		_Luminance;
			half		_BrightnessForScene;
			// vertex shader
			v2f vert(a2v v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
				return o;
			}
            // fragment shader
			fixed4 frag(v2f i) : SV_Target
			{
				fixed4 col = tex2D(_MainTex, i.uv);
				col.rgb *=(1.0 + _Luminance);
				col.rgb *= _BrightnessForScene;
                return col;
            }
            ENDCG
            
        }
    }
}
