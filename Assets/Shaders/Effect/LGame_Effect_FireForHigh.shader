Shader "LGame/Effect/FireForHigh" {
	Properties{
	[Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend("SrcBlend", float) = 5.0
	[Enum(UnityEngine.Rendering.BlendMode)] _DstBlend("DstBlend", float) = 1.0
	[HDR]_Color("Glow Color",Color) = (1,1,1,1)
	_GlowTex("Glow texture", 2D) = "black" {}
	_StarTex("Star texture", 2D) = "black" {}
	_TileX("Tile X",int) = 4
	_TileY("Tile Y",int) = 4
	_Speed("Speed",Float) = 0.2
	_VerticalBillboarding("Vertical Restraints", Range(0,1)) = 1
	_Size("Size",Float) = 0.2
	_ScaleY("Scale Y",Float) = 1.0
	}
	SubShader{
		Tags { "Queue" = "Transparent" "LightMode" = "ForwardBase" "IgnoreProjector" = "True" "RenderType" = "Transparent" }
		Blend[_SrcBlend][_DstBlend]
		Cull Off
		ZWrite Off
		LOD 100
		Pass {
			CGPROGRAM
			#pragma vertex vert  
			#pragma fragment frag  
			#include "UnityCG.cginc"  
			sampler2D _GlowTex;
			sampler2D _StarTex;
			half _Size;
			half _ScaleY;
			half _TileX;
			half _TileY;
			half _Speed;
			half _VerticalBillboarding;
			float4 _GlowTex_ST;
			float4 _StarTex_ST;
			fixed4 _Color;
			struct appdata
			{
				float4 vertex : POSITION;
				float2 texcoord : TEXCOORD0;
			};
			struct v2f {
				float4  pos		: SV_POSITION;
				float4  uv		: TEXCOORD0;//main mask
				float3  data: TEXCOORD1;//glow/star
			};
			void CalcOrthonormalBasis(float3 dir,out float3 right,out float3 up)
			{
				up = abs(dir.y) > 0.999f ? float3(0,0,1) : float3(0,1,0);
				right = normalize(cross(up,dir));
				up = cross(dir,right);
			}
			v2f vert(appdata v)
			{
				v2f o;
				float3  centerOffs = float3(v.texcoord.x - 0.5, 0.5 - v.texcoord.y , 0)*_Size;
				float3  centerLocal = v.vertex.xyz + centerOffs.xyz;
				float3  localDir = ObjSpaceViewDir(float4(centerLocal,1));
				localDir.y = localDir.y * _VerticalBillboarding;
				float3  rightLocal;
				float3  upLocal;
				CalcOrthonormalBasis(normalize(localDir) ,rightLocal,upLocal);
				float3  BBLocalPos = centerLocal - (rightLocal * centerOffs.x + upLocal * centerOffs.y);
				float3 center = rightLocal * (v.texcoord.x - 0.5) - upLocal * v.texcoord.y;
				float scaleY = center.y * _Size * _ScaleY;
				BBLocalPos.y = BBLocalPos.y - scaleY;
				o.pos = UnityObjectToClipPos(float4(BBLocalPos, 1.0));
				o.uv.xy = TRANSFORM_TEX(v.texcoord.xy, _GlowTex);
				o.uv.xy += (1 - _GlowTex_ST.xy)*0.5;
				o.uv.zw = TRANSFORM_TEX(v.texcoord.xy, _StarTex);
				float count = _TileX * _TileY;
				float offset = _Time.y * _Speed;
				o.data.x = offset * count;
				o.data.yz = 1.0f / float2(_TileX, _TileY);
				return o;
			}
			fixed4 frag(v2f i) : COLOR
			{
				float2 uv = i.uv.zw;
				uv.x = floor(i.data.x);
				uv.y = -floor(uv.x/_TileX);
				uv += i.uv.zw;
				uv = frac(uv *i.data.yz);
				fixed4 glow = tex2Dlod(_GlowTex, float4(i.uv.xy, 0.0f, 0.0f)) * _Color;
				fixed4 star = tex2Dlod(_StarTex, float4(uv, 0.0f, 0.0f));
				fixed4 result;
				result.rgb = star.rgb + glow.rgb;
				result.a = saturate(star.a+glow.a);
				return result;
			}
			ENDCG
			}
	}
}