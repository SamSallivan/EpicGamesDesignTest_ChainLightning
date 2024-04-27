Shader "Hidden/RippleProcessing"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
	}
	SubShader
	{
		// No culling or depth
		Cull Off ZWrite Off ZTest Always
		//HeightSim
		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
			};
			sampler2D _PreviousHeight1;
			sampler2D _PreviousHeight2;
			half _Dampening;
			half _TravelSpeed;
			half _TexelSize;
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				return o;
			}		
			fixed4 frag (v2f i) : SV_Target
			{
				half neighbor = tex2D(_PreviousHeight1, i.uv+ _TexelSize*half2(-1,0)).r;
				neighbor += tex2D(_PreviousHeight1, i.uv+ _TexelSize*half2(1,0)).r;
				neighbor += tex2D(_PreviousHeight1, i.uv+ _TexelSize*half2(0,-1)).r;
				neighbor += tex2D(_PreviousHeight1, i.uv+ _TexelSize*half2(0,1)).r;
				half4 previousHeight1=tex2D(_PreviousHeight1, i.uv)*4.0;
				previousHeight1=((neighbor-previousHeight1)*_TravelSpeed+previousHeight1)*0.5;
				half previousHeight2=tex2D(_PreviousHeight2, i.uv).r ;
				half4 result=(previousHeight1-previousHeight2)*_Dampening;
				return result;
			}
			ENDCG
		}
		//Compute Normal
		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
			};

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				return o;
			}
			
			sampler2D _Heightfield;
			half _TexelSize;
			half _HeightScale;
			fixed4 frag (v2f i) : SV_Target
			{	
				half v1_x = tex2D(_Heightfield, i.uv+ _TexelSize*half2(1,0)).r;
				half v2_x = tex2D(_Heightfield, i.uv+ _TexelSize*half2(-1,0)).r;
				half v1_y = tex2D(_Heightfield, i.uv+ _TexelSize*half2(0,1)).r;
				half v2_y = tex2D(_Heightfield, i.uv+ _TexelSize*half2(0,-1)).r;
				half2 temp=(half2(v1_x,v1_y)-half2(v2_x,v2_y));
				half3 dirY=half3(0, _TexelSize*2.0, temp.y);
				half3 dirX=half3(_TexelSize*2.0,0, temp.x);
				//Remap from 0 to 1
				half3 result=normalize(cross(dirX,dirY))*0.5+0.5;
				return half4(result, 1);
			}
			ENDCG
		}
		//Force Splat
		Blend SrcAlpha One
		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
			};

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				return o;
			}
			float3 _ForcePosition;
			float _ForceStrength;
			float _ForceSize;
			fixed4 frag (v2f i) : SV_Target
			{
				//Remap from 0 to 1
				half result=(saturate(_ForceSize-length(i.uv- _ForcePosition.xz- float2(0.5,0.5)))/_ForceSize)*_ForceStrength;
				return result;
			}
			ENDCG
		}

	}
}
