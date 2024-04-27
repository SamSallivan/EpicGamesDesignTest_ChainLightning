Shader "Custom/Stencil/MaskIncr" {
	SubShader{
		Tags { "RenderType" = "Transparent" "Queue" = "Transparent"}

		Cull Off
		Lighting Off
		ZWrite Off
		//Blend Off
		ColorMask 0

		Pass {
			Stencil {
				Ref 1
				Comp always
				Pass IncrSat
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
				return half4(0,1,1,1);
			}
			ENDCG
		}
	}
}
