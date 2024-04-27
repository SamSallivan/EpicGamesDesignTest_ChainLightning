Shader "LGame/Effect/StarActor/AlphaRimWithDepth"
{
	Properties
	{
		[Header(Texture)]

		_Color("Color" , Color) = (1,1,1,1)
		_MainTex("Main Texture", 2D) = "white" {}
		_GrayRange("GrayRange", Range(0.0, 1.0)) = 1

		[Header(XYZ is lightDir)]
		_LightDir("_LightDir", Vector) = (0,0,0,0)

		[Header(XYZ is MaskPosition  W is SoftRange)]
		_MaskPositionFix("_MaskPositionFix", Vector) = (0,1.5,0,1)
		_MaskPositionFix2("_MaskPositionFix2", Vector) = (0,1.5,0,1)

		[HDR]_RimlightColor("_RimlightColor", Color) = (1,1,1,1)
		_RimlightMaskRange("_RimlightMaskRange", Range(-0.1, 1.5)) = 0
		_RimlightMaskRange2("_RimlightMaskRange2", Range(-0.1, 1.5)) = 0

		_RimlightSoftRange1("_RimlightSoftRangeMin", Range(0.0, 1.0)) = 0
		_RimlightSoftRange2("_RimlightSoftRangeMax", Range(0.0, 1.0)) = 1

		_RimlightWithRange("_RimlightWithRange", Range(0.0, 1.0)) = 0.6

	}
		SubShader
		{
			Tags{"Queue" = "Geometry+400" "IgnoreProjector" = "True" "RenderType" = "Opaque" }
			Pass {
			ZWrite On
			ColorMask 0
			}
			LOD 300
			Pass
			{
				Tags{"LightMode" = "ForwardBase"}
				 Blend SrcAlpha OneMinusSrcAlpha
				//ColorMask 0

				CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag	
				#include "UnityCG.cginc"
				struct appdata
				{
					float4 vertex	: POSITION;
					float2 uv		: TEXCOORD0;
					float3 normal : NORMAL;

				};
				struct v2f
				{
					float4 pos		: SV_POSITION;
					float4 uv		: TEXCOORD0;
					float3 normalDir : TEXCOORD4;
					float4 posWorld : TEXCOORD7;
				};

				half4		_Color;
				sampler2D	_MainTex;
				float4		_MainTex_ST;
				sampler2D	_EffectTex;
				float4		_EffectTex_ST;
				fixed4		_EffectCol;

				half		_GrayRange;
				float4		_RimlightColor;
				half		_RimlightMaskRange;
				half		_RimlightMaskRange2;

				half		_RimlightSoftRange1, _RimlightSoftRange2;
				half		_RimlightWithRange;
				float4		_LightDir;
				float4		_MaskPositionFix;
				float4		_MaskPositionFix2;

				half3 GetGray(half3 inColor)
				{
					return dot(inColor, fixed3(0.3, 0.6, 0.1));

				}
				v2f vert(appdata v)
				{
					v2f o;
					o.pos = UnityObjectToClipPos(v.vertex);
					float4 srcPos = ComputeScreenPos(o.pos);
					o.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
					//o.uv.zw = srcPos.xy * _EffectTex_ST.xy / srcPos.w + _Time.x * _EffectTex_ST.zw;//half2(_InfoVetor.x , srcPos.y *_InfoVetor.y/srcPos.w) + frac(_Time.x * _InfoVetor.zw);

					o.normalDir = UnityObjectToWorldNormal(v.normal);

					o.posWorld = mul(unity_ObjectToWorld, v.vertex);

					return o;
				}
				fixed4 frag(v2f i) : SV_Target
				{
					fixed4 col = tex2D(_MainTex, i.uv.xy) * _Color;

					half3 worldPos = i.posWorld.rgb;
					half3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));
					half3 worldLightDir =_LightDir.xyz - worldPos;
					//优化操作体验
					_MaskPositionFix.xyz *= 0.1;
					_MaskPositionFix2.xyz *= 0.1;

					float3 worldCenter = float3(unity_ObjectToWorld[0].w + _MaskPositionFix.x, _MaskPositionFix.y, unity_ObjectToWorld[2].w+ _MaskPositionFix.z);
					float3 worldCenter2 = float3(unity_ObjectToWorld[0].w + _MaskPositionFix2.x, _MaskPositionFix2.y, unity_ObjectToWorld[2].w + _MaskPositionFix2.z);

					float3 worldNormal = i.normalDir;

					float3 h = normalize(worldViewDir + worldLightDir);
					half nv = clamp(0, 1, (dot(worldNormal, worldViewDir)));
					half nh = saturate(dot(worldNormal, h));
					//nl = nl * nl * nl * nl * nl;
					//float3 positionDir = worldPos - worldCenter;
					half PRange = distance(worldCenter, worldPos);
					half PRange2 = distance(worldCenter2, worldPos);

					half2 vc = half2(1,1) ;// = saturate(dot(worldCenter - worldPos, worldViewDir));
					half2 softFix = 0.1 * half2(_MaskPositionFix.w, _MaskPositionFix2.w);
					vc = smoothstep(half2(_RimlightMaskRange, _RimlightMaskRange2), half2(_RimlightMaskRange + softFix.x, _RimlightMaskRange2 + softFix.y), half2(PRange, PRange2));
					half maskVC = vc.x * vc.y * smoothstep(_RimlightWithRange, _RimlightWithRange + 0.1, (1 - nv)) * smoothstep(_RimlightSoftRange1, _RimlightSoftRange2 + 0.01, nh);
					float3 result = float3(maskVC * _RimlightColor.rgb) + lerp(GetGray(col.rgb),col.rgb, _GrayRange);
					col.a = col.a + maskVC * _RimlightColor.a;
					return float4(result, col.a);
				}
				ENDCG
			}

		}
}
