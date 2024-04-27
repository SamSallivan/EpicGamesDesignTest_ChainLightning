Shader "LGame/Rain/Spray" {
	Properties{
		_Color("Color",Color)=(1,1,1,1)
		_MainTex("Base texture", 2D) = "white" {}
		_VerticalBillboarding("Vertical Restraints", Range(0,1)) = 1
		_TileX("Tile X",int) = 2
		_TileY("Tile Y",int) = 2
		_Scale("Scale",Vector) = (1,1,1)
		_Size("Size",Float)=0.2
	}
	SubShader{
		Tags { "Queue" = "Transparent" "IgnoreProjector" = "True" "RenderType" = "Transparent" }
		Blend SrcAlpha OneMinusSrcAlpha
		Cull Off 
		ZWrite Off 
		LOD 100
		Pass {
			CGPROGRAM
			#pragma vertex vert  
			#pragma fragment frag  
			//#pragma multi_compile_instancing
			#include "UnityCG.cginc"  
			sampler2D _MainTex;
			float _TileX;
			float _TileY;
			float _Offset;
			float _Size;
			float3 _Scale;
			float _VerticalBillboarding;
			fixed4 _Color;
		struct v2f {
			float4  pos		: SV_POSITION;
			float4  uv		: TEXCOORD0;
			float4  spray	: TEXCOOR1;
		};
		void CalcOrthonormalBasis(float3 dir,out float3 right,out float3 up)
		{
			up = abs(dir.y) > 0.999f ? float3(0,0,1) : float3(0,1,0);
			right = normalize(cross(up,dir));
			up = cross(dir,right);
		}
		float rand(float co) {
			return frac(sin(dot(co.xx, float2(12.9898, 78.233))) * 43758.5453);
		}
		v2f vert(appdata_full v)
		{
			v2f o;
			UNITY_SETUP_INSTANCE_ID(v);
			float3  centerOffs = float3(v.texcoord.x-0.5, 0.5-v.texcoord.y , 0)*_Size;
			float3  centerLocal = v.vertex.xyz + centerOffs.xyz;
			float3  localDir = ObjSpaceViewDir(float4(centerLocal,1));
			localDir.y = localDir.y * _VerticalBillboarding;
			float3  rightLocal;
			float3  upLocal;
			CalcOrthonormalBasis(normalize(localDir) ,rightLocal,upLocal);
			float3  BBLocalPos = centerLocal - (rightLocal * centerOffs.x + upLocal * centerOffs.y);
			//理想的缩放机制：序列帧播放的第一帧&最后一帧，scale为0，最小
			//序列帧动画每延后一帧，scale动画的偏移为1/序列帧动画数量
			float bias = floor(v.color.r*32.0);
			float count = _TileX * _TileY;
			float3 center = rightLocal * (v.texcoord.x - 0.5) -upLocal * v.texcoord.y;
			float offset = _Offset + bias / count;
			float temp = frac(offset);
			float seed = step(0.5,frac(offset*0.5));
			float alpha = saturate(1.25 - temp);
			float rand_scale = rand(floor(offset)*v.color);
			float3 scale = center * _Size * _Scale* temp *rand_scale;

			o.uv.xy = v.texcoord.xy;
			o.pos = UnityObjectToClipPos(float4(BBLocalPos-scale,1.0));
			o.uv.zw = seed*alpha;
			o.spray.x = _Offset * count;
			o.spray.yz = 1.0f/ float2(_TileX, _TileY);
			o.spray.w = bias;
			return o;
		}
			fixed4 frag(v2f i) : COLOR
			{
				float2 uv = i.uv.xy;
				uv.x = floor(i.spray.x)+i.spray.w;
				uv.y = -floor(uv.x/_TileX);
				uv += i.uv.xy;
				uv = frac(uv *i.spray.yz);
				fixed4 col = tex2D(_MainTex,uv)*_Color;
				col.a *= i.uv.z;
				return col;
			}
			ENDCG
		}
	}
}