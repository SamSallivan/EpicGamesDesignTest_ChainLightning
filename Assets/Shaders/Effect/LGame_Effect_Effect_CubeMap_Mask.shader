Shader "LGame/Effect/Effect_CubeMap_Mask"
{
	Properties
	{
		_Color("Color",Color)=(1,1,1,1)
		_MainTex ("Texture", 2D) = "white" {}
		_MaskTex("Mask",2D)="white"{}
		_Cube("Cube",Cube)=""{}
		_RotationXZ("Rotation XZ",Range(0,360))=0
		_RotationYZ("Rotation YZ",Range(0,360)) = 0
		[Toggle(Gray_On)]
		_Gray_On("Gray_On", Float) = 0
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100
		Blend SrcAlpha OneMinusSrcAlpha

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
	
			#include "UnityCG.cginc"

			#pragma shader_feature RectClip_On
			#pragma shader_feature Gray_On

			struct appdata
			{
				half4 vertex : POSITION;
				half2 uv : TEXCOORD0;
				half3 normal:NORMAL;
			};

			struct v2f
			{
				half2 uv : TEXCOORD0;
				half4 vertex : SV_POSITION;
				half3 wNormal:TEXCOORD1;
				float3 wPos:TEXCOORD2;
			};
#if RectClip_On
			float4 _EffectClipRect;
#endif
			sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _MaskTex;
			samplerCUBE _Cube;
			fixed4 _Color;
			half _RotationXZ;
			half _RotationYZ;
		half3 RotateAroundYInDegrees (half3 R, half degrees)
        {
            half alpha = degrees * UNITY_PI / 180.0;
            half sina, cosa;
            sincos(alpha, sina, cosa);
            half2x2 m = half2x2(cosa, -sina, sina, cosa);
            return half3(mul(m, R.xz), R.y).xzy;
        }
        half3 RotateAroundXInDegrees (half3 R, half degrees)
        {
            half alpha = degrees * UNITY_PI / 180.0;
            half sina, cosa;
            sincos(alpha, sina, cosa);
            half2x2 m = half2x2(cosa, -sina, sina, cosa);
            return half3(mul(m, R.yz), R.x).zxy;
        }
		inline float Get2DClipping(in float2 position, in float4 clipRect)
		{
			float2 inside = step(clipRect.xy, position.xy) * step(position.xy, clipRect.zw);
			return inside.x * inside.y;
		}
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.wNormal=UnityObjectToWorldNormal(v.normal);
				o.wPos=mul(unity_ObjectToWorld,v.vertex).xyz;
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				// sample the texture
				half3 E=-normalize(UnityWorldSpaceViewDir(i.wPos));
				half3 N=normalize(i.wNormal);
				half3 R=reflect(E,N);
				R=RotateAroundYInDegrees(R,_RotationXZ);
				R=RotateAroundXInDegrees(R,_RotationYZ);
				fixed4 col = tex2D(_MainTex, i.uv);
				col.rgb*=_Color.rgb;
				fixed mask=tex2D(_MaskTex,i.uv);
				fixed3 reflection=texCUBE(_Cube,R).xyz;
				// apply fog
				col.rgb=lerp(col.rgb,col.rgb*reflection,mask);
#if Gray_On
				col.rgb = Luminance(col.rgb);
#endif

#if RectClip_On
				col.a *= Get2DClipping(i.wPos.xy, _EffectClipRect);
#endif	
				return col;
			}
			ENDCG
		}
	}
}
