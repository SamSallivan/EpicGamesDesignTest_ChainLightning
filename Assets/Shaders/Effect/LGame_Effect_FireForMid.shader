Shader "LGame/Effect/FireForMid" {
	Properties{
		[Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend("SrcBlend", float) = 5.0
		[Enum(UnityEngine.Rendering.BlendMode)] _DstBlend("DstBlend", float) = 10.0
		[HDR]_Color("Fire Color",Color)=(1,1,1,1)
		_MainTex("Fire texture", 2D) = "white" {}
		_CombinedTex("Flow", 2D) = "black" {}

		_FlowScale("Flow Value", Range(0, 2)) = 0
		_FlowScrollU("Flow Scroll U" , Float) = 0
		_FlowScrollV("Flow Scroll V" , Float) = 0
		
		[HDR]_SmokeColor("Smoke Color",Color) = (1,1,1,1)
		_SmokeFlowScale("Smoke Flow Value", Range(0, 2)) = 0.25
		_SmokeFlowScrollU("Smoke Flow Scroll U" , Float) = 0
		_SmokeFlowScrollV("Smoke Flow Scroll V" , Float) = 0.375

		_VerticalBillboarding("Vertical Restraints", Range(0,1)) = 1
		_Size("Size",Float)=0.2	
		_ScaleY("Scale Y",Float) =1.0
	}
	SubShader{
		Tags { "Queue" = "Transparent" "LightMode"="ForwardBase" "IgnoreProjector" = "True" "RenderType" = "Transparent" }
		Blend[_SrcBlend][_DstBlend]
		Cull Off 
		ZWrite Off 
		LOD 100
		Pass {
			CGPROGRAM
			#pragma vertex vert  
			#pragma fragment frag  
			#include "UnityCG.cginc"  
			sampler2D _MainTex;
			sampler2D _CombinedTex;
			half _Size;
			half _ScaleY;
			half _FlowScale;
			half _FlowScrollU;
			half _FlowScrollV;
			half _SmokeFlowScale;
			half _SmokeFlowScrollU;
			half _SmokeFlowScrollV;
			half _VerticalBillboarding;
			float4 _MainTex_ST;
			float4 _GlowTex_ST;
			fixed4 _Color;
			fixed4 _SmokeColor;
			struct appdata
			{
				float4 vertex : POSITION;
				float2 texcoord : TEXCOORD0;
			};
		struct v2f {
			float4  pos		: SV_POSITION;
			float4  uv		: TEXCOORD0;//main mask
			float4  smoke_uv: TEXCOORD1;//smoke
		};
		void CalcOrthonormalBasis(float3 dir,out float3 right,out float3 up)
		{
			up = abs(dir.y) > 0.999f ? float3(0,0,1) : float3(0,1,0);
			right = normalize(cross(up,dir));
			up = cross(dir,right);
		}
		float2 RotateUV(float2 uv, half2 uvRotate)
		{
			float2 outUV;
			outUV = uv - half2(0.5, 0.5);
			outUV = float2(cross(outUV.xyx, uvRotate.xyx).z + 0.5, dot(outUV.xy, uvRotate.xy) + 0.5);
			return outUV;
		}
		v2f vert(appdata v)
		{
			v2f o;
			float3  centerOffs = float3(v.texcoord.x-0.5, 0.5-v.texcoord.y , 0)*_Size;
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
			o.uv.xy = TRANSFORM_TEX(v.texcoord.xy, _MainTex);
			o.uv.xy += (1.0f - _MainTex_ST.xy) * 0.5f;
			o.uv.xy = RotateUV(o.uv.xy, float2(1.0f,0.0f));
			o.uv.zw = v.texcoord.xy + frac(_Time.z * float2(_FlowScrollU,_FlowScrollV));
			o.smoke_uv.xy = v.texcoord.xy + frac(_Time.z * float2(_SmokeFlowScrollU, _SmokeFlowScrollV));
			o.smoke_uv.zw = v.texcoord.xy;
			return o;
		}
		fixed4 frag(v2f i) : COLOR
		{
			//Fire Flow
			float2 flow = tex2Dlod(_CombinedTex, float4(frac(i.uv.zw), 0.0f, 0.0f)).aa;
			float2 flowUV = i.uv.xy + (flow.xy - 0.5) *_FlowScale;

			//Smoke Flow
			float2 smokeFlow = tex2Dlod(_CombinedTex, float4(frac(i.smoke_uv.xy), 0.0f, 0.0f)).bb;
			float2 smokeflowUV = i.smoke_uv.zw + (smokeFlow.xy - 0.5) *_SmokeFlowScale;
			//Smoke Mask
			float smokeMask = tex2Dlod(_CombinedTex, float4(i.smoke_uv.zw, 0.0f, 0.0f)).g;
			//Smoke
			float smoke = tex2Dlod(_CombinedTex, float4(smokeflowUV, 0.0f, 0.0f)).r * smokeMask;
			//Fire
			fixed4 fire = tex2Dlod(_MainTex, float4(flowUV,0.0f,0.0f)) * _Color;
			fixed4 result;
			//result = fire;
			result.rgb =  fire.rgb * (1.0- smoke) + smoke * _SmokeColor.rgb;
			result.a = saturate( fire.a + smoke);
			return result;
		}
		ENDCG
		}
	}
}