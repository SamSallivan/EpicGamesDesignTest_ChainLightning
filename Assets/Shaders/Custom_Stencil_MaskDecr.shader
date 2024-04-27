Shader "Custom/Stencil/MaskDecr" {
	SubShader{

		Cull Off
		Lighting Off
		ZWrite Off
		//Blend Off
		ColorMask 0
		Tags { "RenderType" = "Transparent" "Queue" = "Transparent"}
		Pass {
			Stencil {
				Ref 1
				Comp always
				Pass DecrSat
			}

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			struct appdata {
				float4 vertex : POSITION;
			};
			struct v2f {
				float4 pos : SV_POSITION;
			};
			v2f vert(appdata v) {
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				return o;
			}
			half4 frag(v2f i) : SV_Target {
				return half4(1,0,0,1);
			}
			ENDCG
		}
	}
}
