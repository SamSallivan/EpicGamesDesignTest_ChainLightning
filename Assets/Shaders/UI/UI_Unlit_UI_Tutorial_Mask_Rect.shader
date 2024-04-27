Shader "UI/Unlit/UI_Tutorial_Mask_Rect"
{
	Properties
	{
		_Color("Color", Color) = (1,1,1,1)
		_ClipRectangle("Rect", Vector) = (0,0,1,1)
		_AllRectangle("AllRectangle", Vector) = (0,0,1,1)

		_MainTex("Base(RGB)", 2D) = "black" {}
		_Speed("序列号",Float) = 30
		_SizeX("列数", Float) = 12
		_SizeY("行数",Float) = 1
		_OpenCus("自定义形状", range(0,1)) = 1

		 _UV("UV",Vector) = (1,1,0,0)
		_Size("SizeRange",Vector ) = (1,1,0,0)
	}
	SubShader
	{
		Tags
		{
			"Queue" = "Transparent"
			"IgnoreProjector" = "True"
			"RenderType" = "Transparent"
			"PreviewType" = "Plane"
			"CanUseSpriteAtlas" = "True"
		}

		Cull Off
		Lighting Off
		ZWrite Off
		ZTest[unity_GUIZTestMode]
		Blend SrcAlpha OneMinusSrcAlpha

		Pass
		{
			Tags { "LightMode" = "ForwardBase" }
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
						
			#include "UnityCG.cginc"
			#include "UnityUI.cginc"

			struct appdata
			{
				float4 vertex   : POSITION;
				float4 color    : COLOR;
				float4 uv:TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct v2f
			{
				float4 vertex   : SV_POSITION;
				fixed4 color : COLOR;
				float4 worldPosition : TEXCOORD1;
				float4 uv : TEXCOORD;
				UNITY_VERTEX_OUTPUT_STEREO
			};

			fixed4 _Color;
			float4 _ClipRectangle;
			float4 _AllRectangle;
			fixed _OpenCus;
			sampler2D _MainTex;
			fixed _Speed;
			fixed _SizeX;
			fixed _SizeY;

			fixed4 _UV;
			float4 _Size;


			inline fixed2 UnityGet2DRectClipping(in float2 position, in float4 clipRect, in float2 uv ) //inline
			{

				//uv = uv * 2 - 1;
				float2 size = _Size.xy;
				uv = uv + (size);
				uv += _AllRectangle.xy /( _AllRectangle.xy / ((clipRect.zw - clipRect.xy)*0.5) )/ _AllRectangle.xy;
				uv = uv - _UV.xy;
				//uv *= size;

				float2 insiderr = _AllRectangle.xy / (clipRect.zw - clipRect.xy);

				uv *= float2(insiderr.x, insiderr.y);
				
				return float2(uv.x , uv.y);

			}

			inline fixed UnityGet2DRectClipping2(in float2 position, in float4 clipRect) //inline
			{
				float2 inside = step(clipRect.xy, position.xy) * step(position.xy, clipRect.zw);
				return step(inside.x * inside.y, 0.5);
			}

			float2 AnimationUV(float2 uv) {

				float col = floor(_Speed / _SizeX);

				float row = floor(_Speed - col * _SizeX);

				float sourceX = 1.0 / _SizeX;
				float sourceY = 1.0 / _SizeY;

				uv.x *= sourceX;
				uv.y *= sourceY;

				uv.x += row * sourceX;
				uv.y = 1 - col * sourceY - uv.y;
				return uv;

			}

			v2f vert(appdata IN)
			{
				v2f OUT;
				UNITY_SETUP_INSTANCE_ID(IN);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(OUT);
				OUT.worldPosition = IN.vertex;
				OUT.vertex = UnityObjectToClipPos(OUT.worldPosition);
				OUT.uv = float4(IN.uv.x, IN.uv.y, IN.uv.z, IN.uv.w);
				OUT.color = IN.color * _Color;
				return OUT;
			}
			
			fixed4 frag(v2f IN) : SV_Target
			{
				fixed4 colorvex = IN.color;

				half maskRange =	UnityGet2DRectClipping2(IN.worldPosition.xy, _ClipRectangle);

				fixed4 uvCul = UnityGet2DRectClipping(IN.worldPosition.xy, _ClipRectangle, IN.uv).rgrr * (1 - maskRange);

				float4 colorMask = tex2D(_MainTex, AnimationUV(clamp(float2(uvCul.r,1- uvCul.g),float2(0,0),float2(1,1))))+ maskRange.rrrr;

				float alpha = 1;

				alpha *= clamp(colorMask.r, 0, 1);//限制下贴图中出现问题的错误

				alpha = lerp(alpha, maskRange, _OpenCus);

				fixed4 color = float4(colorvex.rgb , alpha* colorvex.a);

				return color;
			}
			ENDCG
		}
	}
}
