Shader "LGame/Effect/PathRecorderTrail"
{
	Properties
	{
		[Toggle] _WrapMode("Custom WrapMode", Float) = 0
		[Toggle] _ScreenUV("Screen Space Mode", Float) = 0
		[SimpleToggle] _ScaleOnCenter("Scale On Center", Float) = 1
		[HideInInspector]_OffsetColor ("OffsetColor", Color) = (0,0,0,0) 
		[HideInInspector]_OffsetColorLerp ("OffsetColor", Float) = 0
		
		_AlphaCtrl("Alpha Ctrl",range(0,1)) = 1
		[hdr]_Color("Color",Color)= (1,1,1,1)
		_MainTex ("Main Texture", 2D) = "white" {}
		_MainTexTransform ("MainTex Transform" , vector) = (0,0,0,1)
		[SimpleToggle] _MainTexUvMode("Main Texture UV Mode", Float) = 0
		_MainWrapMode ("Main UV WrapMode" , vector) = (1,1,1,1)
		//添加亮度乘数，默认值为1，保证现有资源不受影响
		_Multiplier("_Multiplier",Range(1,20))=1
		
		_MaskTex ("Mask Texture", 2D) = "white" {}
		_MaskTexTransform ("Mask Transform" , vector) = (0,0,0,1)
		[SimpleToggle] _MaskTexUvMode("Mask Tex UV Mode", Float) = 0
		
		_DissolveTex("Dissolve Texture", 2D) = "white" {}
		_DissolveTexTransform ("DissolveTex Transform" , vector) = (0,0,0,1)
		[SimpleToggle] _DissolveTexUvMode("Dissolve Tex UV Mode", Float) = 0
		[SimpleToggle] _UseCustomData("Use Custom Data", Float) = 0
		_DissolveValue("Dissolve", range(0,1)) = 0
		_DissolveRangeSize ("Dissolve Range Size", range(0.01,0.5)) = 0.1
		[hdr]_DissolveRangeCol ("Dissolve Range Color" , color) = (1,1,1,1)
		
		_WarpTex("Warp Texture", 2D) = "bump" {}
		_WarpTexTransform ("Warp Tex Transform" , Vector) = (0,0,0,1)
		[SimpleToggle] _WarpTexUvMode("Warp Tex UV Mode", Float) = 0
		_WarpIntensity("Warp Intensity" , range(0,1)) = 1
		_SubWrapMode ("Sub UV WrapMode" , vector) = (1,1,1,1)
		
		_GradientTex("Gradient Texture", 2D) = "white" {}
		
		_Size("Size",float) = 1
		_Interval("Interval",float) = 0.2
		[HideInInspector]_Segment("Segment" , int) = 9
		
		[SimpleToggle] _TimeScale("Time Scale", Float) = 1
	}
	
	SubShader
	{
		Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" }
		
		Cull off
		ZWrite off
		Pass
		{
			Tags { "LightMode"="ForwardBase" }
			Blend SrcAlpha OneMinusSrcAlpha
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#pragma shader_feature __ _MASK_ON
			#pragma shader_feature __ _DISSOLVE_ON
			#pragma shader_feature __ _WARP_ON
			#pragma shader_feature __ _WRAPMODE_ON
			#pragma shader_feature __ _SCREENUV_ON
			#pragma shader_feature __ _GRADIENT_ON
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				half4 color	: COLOR;
				float4 uv : TEXCOORD0;
			};

			struct v2f
			{
				half4 vertexCol : COLOR;
				float4 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
				float4 uvSub : TEXCOORD1;
			#if defined(LGAME_USEFOW) && _FOW_ON
				half2 fowuv : TEXCOORD2;
			#endif
				half2 customData :TEXCOORD3;
			};
			

			sampler2D _MainTex;
			float4 _MainTex_ST;
			float _Size;
			float _Interval;
			fixed4 _Color;
			uniform float4 _linePoints[100];
			uniform half _lineWidths[100];
			uniform int _Segment;

			sampler2D _MaskTex;
			sampler2D _DissolveTex;
			sampler2D _WarpTex;
			
		#if _GRADIENT_ON
			sampler2D _GradientTex;
		#endif
			
		#if _FOW_ON
		    sampler2D	_FOWTexture;
		    sampler2D	_FOWLastTexture;
		    fixed4		_FogCol;
		    fixed4		_FogRangeCol;
		    half		_FOWBlend;
		    half		_FOWOpenSpeed;
		    half4		_FOWParam;
		    half		_RangeSize;
		    half		_fow;
		#endif
		    half		_FowBrightness;
		    fixed       _TimeScale;

			fixed4 _OffsetColor;
			fixed _OffsetColorLerp;
	        fixed _ScaleOnCenter;
			half4 _MainTexTransform;
			fixed _MainTexUvMode;
			half4 _MaskTex_ST;
			half4 _MaskTexTransform;
			fixed _MaskTexUvMode;
			half4 _DissolveTex_ST;
			half4 _DissolveTexTransform;
    		fixed _DissolveTexUvMode;
			half4 _WarpTex_ST;
			half4 _WarpTexTransform;
			fixed _WarpTexUvMode;
	        half _Multiplier; //添加亮度控制
			half _AlphaCtrl;
			fixed4 _MainWrapMode;
			fixed4 _SubWrapMode;
			half _DissolveValue;
			half _DissolveRangeSize;
			fixed4 _DissolveRangeCol;
			half _WarpIntensity;
			half _FowBlend;
	        half _UseCustomData;

			inline float2 RotateUV(float2 uv, float2 rotation)
			{
				float2 outUV;
				outUV = uv - 0.5 * _ScaleOnCenter;
				outUV = float2( outUV.x * rotation.y - outUV.y * rotation.x ,
                        outUV.x * rotation.x + outUV.y * rotation.y );
				return outUV + 0.5 * _ScaleOnCenter;
			}
		    inline float2 TransFormUV(float2 argUV,float4 argST , float4 trans)
		    {
		        float2 result =  RotateUV(argUV , trans.zw)  * argST.xy + argST.zw;
		        result += _ScaleOnCenter * (1 - argST.xy)*0.5;
		        return result + frac(trans.xy * _Time.y * _TimeScale);
		    }
		    inline half2 ScreenUV(half4 pos)
		    {
		        half4 srcPos = ComputeScreenPos(pos);
		        return srcPos.xy /srcPos.w;
		    }
			
			v2f vert (appdata v)
			{
				v2f o;
				UNITY_INITIALIZE_OUTPUT(v2f, o)
				int index = round(v.uv.x * _Segment);
				// 拖尾billboard
				float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - _linePoints[index].xyz);
				float3 _firstPoint = _linePoints[index].xyz;
				float3 _secondPoint = _linePoints[index + 1].xyz;
				float3 lineDir = normalize(_secondPoint - _firstPoint);

				float3 widthDir = normalize(cross(lineDir, viewDir));
				float3 localPos = _secondPoint - widthDir * sign(v.uv.y - 0.5)* _Size * _lineWidths[index];

				o.vertex = UnityWorldToClipPos(float4(localPos, 1));

				half2 uvScreen = ScreenUV(o.vertex);
			#if _SCREENUV_ON
				o.uv.xy = any(_MainTexUvMode) ? uvScreen : v.uv;
				o.uv.zw = any(_MaskTexUvMode) ? uvScreen : v.uv;
				o.uvSub.xy = any(_DissolveTexUvMode) ? uvScreen : v.uv;
				o.uvSub.zw = any(_WarpTexUvMode) ? uvScreen : v.uv;
			#else
				o.uv = v.uv.xyxy;
				o.uvSub = v.uv.xyxy;
			#endif
				o.uv.xy = TransFormUV(o.uv.xy, _MainTex_ST, _MainTexTransform);
			#if _MASK_ON
	            o.uv.zw = TransFormUV(o.uv.zw, _MaskTex_ST, _MaskTexTransform);
	        #endif
	        #if _DISSOLVE_ON
	            o.uvSub.xy = TransFormUV(o.uvSub.xy , _DissolveTex_ST , _DissolveTexTransform);
	            o.customData.xy = v.uv.zw;
	        #endif
	        #if	_WARP_ON
	            o.uvSub.zw = TransFormUV(o.uvSub.zw, _WarpTex_ST, _WarpTexTransform);
	        #endif
			#if defined(LGAME_USEFOW) && _FOW_ON
	            float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
	            o.fowuv = half2((worldPos.x - _FOWParam.x) / _FOWParam.z, (worldPos.z -_FOWParam.y) / _FOWParam.w);
	        #endif
				o.vertexCol = v.color;
				return o;
			}

			fixed4 frag (v2f i) : SV_Target
			{
			#if	_WRAPMODE_ON
	            float4 uvSub = lerp(saturate(i.uvSub) , frac(i.uvSub) , _SubWrapMode);
	            float2 uvDissolveTex = uvSub.xy;
	            float2 uvWarpTex = uvSub.zw;
	        #   if	_WARP_ON
	                fixed2 warpTex = UnpackNormal(tex2D(_WarpTex, uvWarpTex, float2(0, 0), float2(0, 0))).xy;
	                i.uv.xy -= warpTex * _WarpIntensity;
	        #   endif
	            float4 uvMain = lerp(saturate(i.uv) , frac(i.uv) , _MainWrapMode);
	            float2 uvMainTex = uvMain.xy;
	            float2 uvMask = uvMain.zw;
	        #else
	            float2 uvMainTex = i.uv.xy;
	            float2 uvMask = i.uv.zw;
	            float2 uvDissolveTex = i.uvSub.xy;
	            float2 uvWarpTex = i.uvSub.zw;
	            #if	_WARP_ON
	                fixed2 warpTex = UnpackNormal(tex2D(_WarpTex, uvWarpTex, float2(0, 0), float2(0, 0))).xy;
	                uvMainTex -= warpTex * _WarpIntensity;
	            #endif
	        #endif
				fixed4 col = tex2D(_MainTex, uvMainTex, float2(0, 0), float2(0, 0)) * _Color;
			#if _MASK_ON
	            fixed mask = tex2D(_MaskTex, uvMask, float2(0, 0), float2(0, 0)).r;
	            col.a *= mask;
	        #endif
			#if	_DISSOLVE_ON
	            fixed dissolveTex = tex2D(_DissolveTex, uvDissolveTex, float2(0, 0), float2(0, 0)).r;
	            half disValue = lerp(_DissolveValue, i.customData.x, _UseCustomData) * 2 - 0.5;
	            fixed dissolve =  smoothstep(disValue - _DissolveRangeSize, disValue + _DissolveRangeSize, dissolveTex);
	            fixed4 rangeCol = (1- dissolve) * _DissolveRangeCol * dissolve;
	            col.rgb = lerp(_DissolveRangeCol.rgb, col.rgb, dissolve) * dissolve;
	            col.a *= dissolve;
	        #endif
	        #if _GRADIENT_ON
	            fixed4 gradientCol = tex2D(_GradientTex, i.uv.xy, float2(0, 0), float2(0, 0));
	            col *= gradientCol;
	        #endif
				col *= i.vertexCol;
				half4 offsetColor = lerp(_OffsetColor, _OffsetColor * _Multiplier, min(_Multiplier, 1));
				col.rgb *= lerp(fixed3(1,1,1), offsetColor.rgb, _OffsetColorLerp);
				// Pre-multiply alpha
				col.rgb *= col.a;
			#if defined(LGAME_USEFOW) && _FOW_ON
	            fixed fowTex = fixed(tex2D(_FOWTexture, i.fowuv).r);
	            fixed fowLast = fixed(tex2D(_FOWLastTexture, i.fowuv).r);

	            fixed add = max(0, fowTex.r - fowLast.r);
	            fixed less = -min(0, fowTex.r - fowLast.r);
	            fixed mid = fowTex.r - add;

	            fixed b = mid + add * _FOWBlend + less * saturate(_FOWOpenSpeed);
	            fixed4 fowCol = lerp(_FogRangeCol, _FogCol, b);

	            col *= saturate(lerp(1.0.rrrr, fowCol, b * (1 - _FowBrightness)));
	        #endif
				return col * _AlphaCtrl;
			}
			ENDCG

		}
	}
}
