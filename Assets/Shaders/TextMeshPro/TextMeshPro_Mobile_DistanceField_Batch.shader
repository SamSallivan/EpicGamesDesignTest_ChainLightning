// Simplified SDF shader:
// - No Shading Option (bevel / bump / env map)
// - No Glow Option
// - Softness is applied on both side of the outline

Shader "TextMeshPro/Mobile/Distance Field Batch" {

Properties {
	//_Color				("FXMaker Curve Color", Color) = (1,1,1,1)
	_FaceColor			("Face Color", Color) = (1,1,1,1)
	_FaceDilate			("Face Dilate", Range(-1,1)) = 0

	_OutlineColor		("Outline Color", Color) = (0,0,0,1)
	_OutlineWidth		("Outline Thickness", Range(0,1)) = 0
	_OutlineSoftness	("Outline Softness", Range(0,1)) = 0

	_UnderlayColor		("Border Color", Color) = (0,0,0,.5)
	_UnderlayOffsetX 	("Border OffsetX", Range(-1,1)) = 0
	_UnderlayOffsetY 	("Border OffsetY", Range(-1,1)) = 0
	_UnderlayDilate		("Border Dilate", Range(-1,1)) = 0
	_UnderlaySoftness 	("Border Softness", Range(0,1)) = 0

	_WeightNormal		("Weight Normal", float) = 0
	_WeightBold			("Weight Bold", float) = .5

	_ShaderFlags		("Flags", float) = 0
	_ScaleRatioA		("Scale RatioA", float) = 1
	_ScaleRatioB		("Scale RatioB", float) = 1
	_ScaleRatioC		("Scale RatioC", float) = 1

	_MainTex			("Font Atlas", 2D) = "white" {}
	_TextureWidth		("Texture Width", float) = 512
	_TextureHeight		("Texture Height", float) = 512
	_GradientScale		("Gradient Scale", float) = 5
	_ScaleX				("Scale X", float) = 1
	_ScaleY				("Scale Y", float) = 1
	_PerspectiveFilter	("Perspective Correction", Range(0, 1)) = 0.875
	_Sharpness			("Sharpness", Range(-1,1)) = 0

	_VertexOffsetX		("Vertex OffsetX", float) = 0
	_VertexOffsetY		("Vertex OffsetY", float) = 0

	_ClipRect			("Clip Rect", vector) = (-32767, -32767, 32767, 32767)
	_MaskSoftnessX		("Mask SoftnessX", float) = 0
	_MaskSoftnessY		("Mask SoftnessY", float) = 0
	
	_StencilComp		("Stencil Comparison", Float) = 8
	_Stencil			("Stencil ID", Float) = 0
	_StencilOp			("Stencil Operation", Float) = 0
	_StencilWriteMask	("Stencil Write Mask", Float) = 255
	_StencilReadMask	("Stencil Read Mask", Float) = 255

    _BorderBlend        ("Border Blend Range", vector) = (0,0,0,0)
	_BorderBlendAlpha("Border Blend Alpha Range", vector) = (0,0,0,0)
	
	_CullMode			("Cull Mode", Float) = 0
	_ColorMask			("Color Mask", Float) = 15

	_IconTex			("Icon Atlas", 2D) = "white" {}

}

SubShader {
	Tags 
	{
		"Queue"="Transparent"
		"IgnoreProjector"="True"
		"RenderType"="Transparent"
	}


	Stencil
	{
		Ref [_Stencil]
		Comp [_StencilComp]
		Pass [_StencilOp] 
		ReadMask [_StencilReadMask]
		WriteMask [_StencilWriteMask]
	}

	Cull [_CullMode]
	ZWrite Off
	Lighting Off
	Fog { Mode Off }
	ZTest [unity_GUIZTestMode]
	Blend One OneMinusSrcAlpha
	ColorMask [_ColorMask]

	Pass {
		Tags { "LightMode" = "ForwardBase" }
		CGPROGRAM
		#pragma vertex VertShader
		#pragma fragment PixShader
		//#pragma shader_feature __ OUTLINE_ON
		//#pragma shader_feature __ UNDERLAY_ON UNDERLAY_INNER

		#pragma multi_compile __ SOFT_CLIP
		#pragma multi_compile __ UNITY_UI_ALPHACLIP
		#pragma multi_compile __ USE_CURVE

		#include "UnityCG.cginc"
		#include "UnityUI.cginc"
		#include "Assets/CGInclude/TMPro_Properties.cginc"
		#include "Assets/CGInclude/LGameSysUI.cginc"

CBUFFER_START(PerDrawFlyTextVertices)
		float4		_tmp_subMeshTRS[128];	// max count per draw
		fixed4		_tmp_subMeshOpacity[32];
CBUFFER_END
CBUFFER_START(PerDrawFlyTextMaterial)
		fixed4		_tmp_subMaterial_FaceColor_Dilate[8];
		fixed4		_tmp_subMaterial_OutlineColor[8];
		fixed4		_tmp_subMaterial_UnderlayColor[8];
		float4		_tmp_subMaterial_UnderlayData[8];	// OffsetX,OffsetY,Dilate,Softness
		//float		_tmp_subMaterial_FaceDilate[8];
		//float		_tmp_subMaterial_OutlineSoftness[8];
		//float		_tmp_subMaterial_OutlineWidth[8];
		//float		_tmp_subMaterial_UnderlayOffsetX[8];
		//float		_tmp_subMaterial_UnderlayOffsetY[8];
		//float		_tmp_subMaterial_UnderlayDilate[8];
		//float		_tmp_subMaterial_UnderlaySoftness[8];
CBUFFER_END

		sampler2D _tmp_IconTex;
		sampler2D _tmp_ExtTextTex1;
		float	  _tmp_ExtText_TextureWidth;
		float	  _tmp_ExtText_TextureHeight;
		float 	  _tmp_ExtText_GradientScale;
		float	  _tmp_ExtText_ScaleX;
		float	  _tmp_ExtText_ScaleY;
		float	  _tmp_ExtText_PerspectiveFilter;
		float	  _tmp_ExtText_Sharpness;

		sampler2D _tmp_ProgressTex;

		struct vertex_t {
			UNITY_VERTEX_INPUT_INSTANCE_ID
			float4	vertex			: POSITION;
			fixed4	color			: COLOR;
			float2	texcoord0		: TEXCOORD0;
			float2	texcoord1		: TEXCOORD1;
			fixed4	texcoord2		: TEXCOORD2;			// index(x), iconMask(y), materialIndex(z), keywordFlag(w)
		};

		struct pixel_t {
			UNITY_VERTEX_INPUT_INSTANCE_ID
			UNITY_VERTEX_OUTPUT_STEREO
			float4	vertex			: SV_POSITION;
			fixed4	faceColor		: COLOR;
			fixed4	outlineColor	: COLOR1;
			float4	texcoord0		: TEXCOORD0;			// Texture UV, Mask UV
			half4	param			: TEXCOORD1;			// Scale(x), BiasIn(y), BiasOut(z), Bias(w)
			half4	mask			: TEXCOORD2;			// Position in clip space(xy), Softness(zw)
			//#if (UNDERLAY_ON | UNDERLAY_INNER)
			float4	texcoord1		: TEXCOORD3;			// Texture UV, alpha, reserved, texture selector
			half2	underlayParam	: TEXCOORD4;			// Scale(x), Bias(y)
			//#endif
			half4	extMask			: TEXCOORD5;			// iconMask(x), outline_On(y), underlay_On/inner(z), materialIndex(w)
		};

		float4 _BorderBlend;
		float4 _BorderBlendAlpha;
		//fixed4 _Color;


#ifdef USE_CURVE
		float _UI_CurveLength;
#endif

		inline float4x4 TRS(float4 trs)
		{
			float4x4 result = 0;

			float sY = sin(trs.z * 0.5f);
			float cY = cos(trs.z * 0.5f);

			result._11 = (1.0 - (2.0 * (sY * sY))) * trs.w;
			result._21 = 0;
			result._31 = (-2.0 * (sY * cY)) * trs.w;
			result._41 = 0;
			result._12 = 0;
			result._22 = trs.w;
			result._32 = 0;
			result._42 = 0;
			result._13 = (-2.0 * (sY * cY));
			result._23 = 0;
			result._33 = ((2.0 * (sY * sY)) - 1.0);
			result._43 = 0;
			result._14 = trs.x;
			result._24 = trs.y;
			result._34 = 0;
			result._44 = 0;

			return result;
		}

		pixel_t VertShader(vertex_t input)
		{
			pixel_t output;

			////////////////////////////
			output.vertex = float4(0, 0, 0, 0);
			////////////////////////////
			UNITY_INITIALIZE_OUTPUT(pixel_t, output);
			UNITY_SETUP_INSTANCE_ID(input);
			UNITY_TRANSFER_INSTANCE_ID(input, output);
			UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

			output.extMask.x = input.texcoord2.y * 255;
			int flag = round(input.texcoord2.w * 255);
			output.extMask.y = flag % 2;
			output.extMask.z = 0;
			// underlay_On
			output.extMask.z = lerp(output.extMask.z, 2, step(0.5f, (flag / 2) % 2));
			// underlay_inner
			output.extMask.z = lerp(output.extMask.z, 1, step(0.5f, (flag / 4) % 2));
			output.texcoord1.w = (flag / 8) % 2;

			float extraFontTex = step(0.5f, output.texcoord1.w);
			float textureWidth = lerp(_TextureWidth, _tmp_ExtText_TextureWidth, extraFontTex);
			float textureHeight = lerp(_TextureHeight, _tmp_ExtText_TextureHeight, extraFontTex);
			float gradientScale = lerp(_GradientScale, _tmp_ExtText_GradientScale, extraFontTex);
			float scaleX = lerp(_ScaleX, _tmp_ExtText_ScaleX, extraFontTex);
			float scaleY = lerp(_ScaleY, _tmp_ExtText_ScaleY, extraFontTex);
			//float perspectiveFilter = lerp(_PerspectiveFilter, _tmp_ExtText_PerspectiveFilter, extraFontTex);
			float sharpness = lerp(_Sharpness, _tmp_ExtText_Sharpness, extraFontTex);

			int trsIndex = round(input.texcoord2.x * 255);
			int index128 = (trsIndex / 4);
			int subIndex128 = (trsIndex % 4);
			float4x4 trsMat = TRS(_tmp_subMeshTRS[trsIndex]);
			float4 calculateVertex = mul(trsMat, input.vertex);
			int matIdx = round(input.texcoord2.z * 255);
			output.extMask.w = matIdx;

			//const float4 immCB[4] =
			//{
			//	float4(1.0, 0.0, 0.0, 0.0),
			//	float4(0.0, 1.0, 0.0, 0.0),
			//	float4(0.0, 0.0, 1.0, 0.0),
			//	float4(0.0, 0.0, 0.0, 1.0)
			//};

			//float4 calculateVertex = input.vertex;
			float4 vert = calculateVertex;
			vert.x += _VertexOffsetX;
			vert.y += _VertexOffsetY;
			float iconMask = step(0.5f, output.extMask.x);
#ifdef USE_CURVE
			float4 pos = mul(UNITY_MATRIX_MV, calculateVertex);
			float rate = length(pos.x) / _UI_CurveLength;
			pos.yz /= pos.w + rate * length(rate);
			output.vertex = lerp(mul(UNITY_MATRIX_P, pos), UnityObjectToClipPos(calculateVertex), iconMask);
#else
			output.vertex = UnityObjectToClipPos(calculateVertex);
#endif

			float2 pixelSize = output.vertex.w;
			pixelSize /= float2(scaleX, scaleY) * abs(mul((float2x2)UNITY_MATRIX_P, _ScreenParams.xy));

			float scale = rsqrt(dot(pixelSize, pixelSize));
			scale *= abs(input.texcoord1.y) * gradientScale * (sharpness + 1);
			//if(UNITY_MATRIX_P[3][3] == 0) scale = lerp(abs(scale) * (1 - perspectiveFilter), scale, abs(dot(UnityObjectToWorldNormal(input.normal.xyz), normalize(WorldSpaceViewDir(vert)))));

			float weight = lerp(_WeightNormal, _WeightBold, step(input.texcoord1.y, 0)) / 4.0;
			weight = (weight + _tmp_subMaterial_FaceColor_Dilate[matIdx].w) * _ScaleRatioA * 0.5;

			output.underlayParam.x = scale;

			// 浣跨敤鐨勬潗璐ㄩ噷_OutlineSoftness閮戒负0锛屾墍浠ヨ繖閲屼负浜嗚妭鐪佷笉鍐嶅湪鏉愯川閲屽瓨_OutlineSoftness
			//scale /= 1 + (_tmp_subMaterial_OutlineSoftness[matIdx] * _ScaleRatioA * scale);
			float bias = (0.5 - weight) * scale - 0.5;
			//float outline = _tmp_subMaterial_OutlineWidth[matIdx] * _ScaleRatioA * 0.5 * scale;
			float outline = input.texcoord1.x * _ScaleRatioA * 0.5 * scale;

			float underlayFlag = step(0.5f, output.extMask.z);
			//fixed inputOpacity = dot(_tmp_subMeshOpacity[index128], immCB[subIndex128]);
			fixed inputOpacity = 0;//
			if (subIndex128 == 0)
				inputOpacity = _tmp_subMeshOpacity[index128].r;
			else if (subIndex128 == 1)
				inputOpacity = _tmp_subMeshOpacity[index128].g;
			else if (subIndex128 == 2)
				inputOpacity = _tmp_subMeshOpacity[index128].b;
			else if (subIndex128 == 3)
				inputOpacity = _tmp_subMeshOpacity[index128].a;
			fixed opacity = lerp(inputOpacity, 1.0f, underlayFlag);

			output.faceColor = fixed4(input.color.rgb, opacity) * fixed4(_tmp_subMaterial_FaceColor_Dilate[matIdx].rgb, 1);// *_Color;
			output.faceColor.rgb *= output.faceColor.a;

			output.outlineColor = _tmp_subMaterial_OutlineColor[matIdx];// *_Color;
			output.outlineColor.a *= opacity;
			output.outlineColor.rgb *= output.outlineColor.a;
			output.outlineColor = lerp(output.faceColor, output.outlineColor, sqrt(min(1.0, (outline * 2))));

			output.faceColor = lerp(output.faceColor, input.color, iconMask);

			//output.texcoord1.xy = input.texcoord0;

			output.underlayParam.x = lerp(scale, scale / (1 + ((_tmp_subMaterial_UnderlayData[matIdx].w * _ScaleRatioC) * output.underlayParam.x)), underlayFlag);
			output.underlayParam.y = lerp(0, (.5 - weight) * output.underlayParam.x - .5 - ((_tmp_subMaterial_UnderlayData[matIdx].z * _ScaleRatioC) * .5 * output.underlayParam.x), underlayFlag);
			output.texcoord1.xy = lerp(input.texcoord0,
										input.texcoord0 + float2(-(_tmp_subMaterial_UnderlayData[matIdx].x * _ScaleRatioC) * gradientScale / textureWidth,
																-(_tmp_subMaterial_UnderlayData[matIdx].y * _ScaleRatioC) * gradientScale / textureHeight),
										underlayFlag);
			output.texcoord1.z = lerp(0, inputOpacity, underlayFlag);
			output.texcoord1.w = lerp(output.texcoord1.w, 0, underlayFlag);

			// Generate UV for the Masking Texture
			float4 clampedRect = clamp(_ClipRect, -2e10, 2e10);
			output.texcoord0.zw = (vert.xy - clampedRect.xy) / (clampedRect.zw - clampedRect.xy);
			output.texcoord0.z = lerp(output.texcoord0.z, inputOpacity, iconMask);
			// Populate structure for pixel shader
			output.texcoord0.xy = input.texcoord0.xy;
			output.param = half4(scale, bias - outline, bias + outline, bias);
			output.mask = half4(vert.xy * 2 - clampedRect.xy - clampedRect.zw, 0.25 / (0.25 * half2(_MaskSoftnessX, _MaskSoftnessY) + pixelSize.xy));

			return output;
		}

		inline half4 GetTexture(fixed value, float2 uv)
		{
			//return lerp(tex2D(_MainTex, uv), tex2D(_tmp_ExtTextTex1, uv), step(0.5f, value));
			if (value > 0.5)
				return tex2D(_tmp_ExtTextTex1, uv);

			return tex2D(_MainTex, uv);
		}

		fixed4 GetTextColor(pixel_t input)
		{
			half d = GetTexture(input.texcoord1.w, input.texcoord0.xy).a * input.param.x;
			half d2 = GetTexture(input.texcoord1.w, input.texcoord1.xy).a * input.underlayParam.x;
			half4 c = lerp(input.faceColor * saturate(d - input.param.w),
				lerp(input.outlineColor, input.faceColor, saturate(d - input.param.z)) * saturate(d - input.param.y),
				step(0.5f, input.extMask.y));
			// underlay_On
			float step15 = step(1.5f, input.extMask.z);
			// underlay_inner
			float step05 = step(0.5f, input.extMask.z);
			float step15_05 = lerp(step05, 0, step15);
			int matIdx = (int)input.extMask.w;
			float4 cTemp = float4(_tmp_subMaterial_UnderlayColor[matIdx].rgb * _tmp_subMaterial_UnderlayColor[matIdx].a, _tmp_subMaterial_UnderlayColor[matIdx].a) * (1 - c.a);
			float step15Result = lerp(1.0f, saturate(d2 - input.underlayParam.y), step15);
			//float step05Result = lerp(1.0f, ((1 - saturate(d2 - input.underlayParam.y)) * (saturate(d - input.param.z))), step15_05);
			//float step05Result = lerp(1.0f, 0.0f, step15_05);
			float step05Result = 1.0f;
			if (step05 && !step15)
				step05Result = ((1 - saturate(d2 - input.underlayParam.y)) * (saturate(d - input.param.z)));
			c = lerp(c, c + cTemp * step15Result * step05Result, step05);

			// Alternative implementation to UnityGet2DClipping with support for softness.
#ifdef SOFT_CLIP
			float4 clampedRect = clamp(_ClipRect, -2e10, 2e10);
			half2 pos = (input.mask.xy + (clampedRect.xy + clampedRect.zw)) / 2;
			c *= LGameGetSoft2DClippingEx(pos, _ClipRect, _BorderBlend, _BorderBlendAlpha);

			//	half2 m = saturate((_ClipRect.zw - _ClipRect.xy - abs(input.mask.xy)) * input.mask.zw);
			//	c *= m.x * m.y;
#endif
			c = lerp(c, c * input.texcoord1.z, step(0.5, input.extMask.z));

#if UNITY_UI_ALPHACLIP
			clip(c.a - 0.001);
#endif

			return c;
		}
		fixed4 GetIconColor(pixel_t input)
		{
			half4 c = lerp(tex2D(_tmp_IconTex, input.texcoord0.xy) * input.faceColor, tex2D(_tmp_ProgressTex, input.texcoord0.xy) * input.faceColor, step(1.5f, input.extMask.x));
			c.a *= input.texcoord0.z;
			c.rgb *= c.a;
			return c;
		}
		// PIXEL SHADER
		fixed4 PixShader(pixel_t input) : SV_Target
		{
			UNITY_SETUP_INSTANCE_ID(input);

			return lerp(GetTextColor(input), GetIconColor(input), step(0.5f, input.extMask.x));
		}
		ENDCG
	}
}

CustomEditor "TMPro.EditorUtilities.TMP_SDFShaderGUI"
}
