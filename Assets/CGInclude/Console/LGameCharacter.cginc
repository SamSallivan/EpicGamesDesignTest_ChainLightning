
// Upgrade NOTE: excluded shader from OpenGL ES 2.0 because it uses non-square matrices
#pragma exclude_renderers gles
#ifndef LGAME_CHARACTER_INCLUDE
	#define LGAME_CHARACTER_INCLUDE
	#include "UnityCG.cginc" 
	#include "Assets/CGInclude/LGameCharacterDgs.cginc" 
	#include "Assets/CGInclude/Console/LGameConsoleCG.cginc"

	struct a2v
	{
		float4 vertex	: POSITION;
		float3 normal	: NORMAL;
		float4 texcoord : TEXCOORD0;
	#ifdef _USE_DIRECT_GPU_SKINNING
		float4 skinIndices : TEXCOORD2;
		float4 skinWeights : TEXCOORD3;
	#endif
	};
	struct v2f
	{
		fixed4 	color : COLOR;
		float4	pos			: SV_POSITION;
		half2	uv			: TEXCOORD0;
	#ifdef _METAL
		half2	uvMatcap	: TEXCOORD1;
	#endif
	#if  _FLOWLIGHTUV ||  _FLOWLIGHTSCREEN
		half2	uvFlow		: TEXCOORD2;
	#endif
	#ifdef _CUBESPEC
		float3  worldNormal   : TEXCOORD3;
		float3  viewDir       : TEXCOORD4;
	#endif
	};


	fixed4		_MainColor;
	fixed4		_SubColor;
	half		_Cutoff;
	fixed4		_OffsetColor;

	sampler2D	_MainTex;
	half4		_MainTex_ST;
	#if _SUBTEX
	sampler2D	_SubTex;
	half4		_SubTex_ST;

	half		_SubTexLerp;
	#endif

	#if _METAL || _RIMLIGHT || _FLOWLIGHTUV ||_FLOWLIGHTSCREEN
	sampler2D	_MaskTex;
	#endif

	#if  _METAL
	sampler2D	_MatCap;
	fixed4		_MatCapColor;
	half		_MatCapIntensity;
	#endif

	#if  _RIMLIGHT
	fixed4		_RimLightColor;
	half		_RimLighRange;
	half		_RimLighMultipliers;
	#endif

	#if  _FLOWLIGHTUV ||  _FLOWLIGHTSCREEN
	sampler2D	_FlowlightTex;
	half4		_FlowlightTex_ST;
	half		_FlowlightMultipliers;
	fixed4		_FlowlightCol;
	#endif

	#if _DISSOLVE
	sampler2D   _DissolveTex;
	fixed4		_DissolveRangeCol;
	half		_DissolveTilling;
	half		_DissolveThreshold;
	half		_DissolveRangeSize;
	#endif 

	#if _ALPHABLEND_ON || _DISSOLVE
	half		_AlphaCtrl;
	#endif

	fixed4		_OutlineCol;
	half		_OutlineScale;
	half4 		_LightPos;
	fixed4 		_ShadowColor;
	half 		_ShadowFalloff;

	half		_DepthOffset;
	v2f vert(a2v v)
	{
		v2f o;

		UNITY_INITIALIZE_OUTPUT(v2f, o);
		float4 pos = v.vertex;

	#if _USE_DIRECT_GPU_SKINNING


		pos = CalculateGPUSkin_L(v.skinIndices, v.skinWeights, v.vertex);
		v.texcoord.xy = DecompressUV(v.texcoord.xy, _uvBoundData);
		/********************************************************************************************************************
		//使用对偶四元数的逻辑，后面有需要再打开 by yeyang
		half2x4 q0 = GetDualQuat(v.skinIndices.x);
		half2x4 q1 = GetDualQuat(v.skinIndices.y);
		half2x4 q2 = GetDualQuat(v.skinIndices.z);
		half2x4 q3 = GetDualQuat(v.skinIndices.w);

		half2x4 blendDualQuat = q0 * v.skinWeights.x;
		if (dot(q0[0], q1[0]) > 0)
			blendDualQuat += q1 * v.skinWeights.y;
		else
			blendDualQuat -= q1 * v.skinWeights.y;

		if (dot(q0[0], q2[0]) > 0)
			blendDualQuat += q2 * v.skinWeights.z;
		else
			blendDualQuat -= q2 * v.skinWeights.z;

		if (dot(q0[0], q3[0]) > 0)
			blendDualQuat += q3 * v.skinWeights.w;
		else
			blendDualQuat -= q3 * v.skinWeights.w;

		blendDualQuat = NormalizeDualQuat(blendDualQuat);

		pos = float4(TransformFromDualQuat(blendDualQuat, v.vertex), 1);
		*********************************************************************************************************************/
	#endif

		o.pos = UnityObjectToClipPos(pos);
		o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
		o.color = _OffsetColor;


	#if _METAL || _RIMLIGHT || _CUBESPEC
		fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
	#endif
	#if  _METAL
		o.uvMatcap = normalize(mul(UNITY_MATRIX_V, float4(worldNormal, 0)).xyz) * 0.5 + 0.5;
	#endif

	#if  _FLOWLIGHTUV
		o.uvFlow = v.texcoord * _FlowlightTex_ST.xy + frac(_FlowlightTex_ST.zw * _Time.y);
	#elif _FLOWLIGHTSCREEN
		half4 srcPos = ComputeScreenPos(o.pos);
		o.uvFlow = (srcPos.xy / srcPos.w) * _FlowlightTex_ST.xy + frac(_FlowlightTex_ST.zw * _Time.y);
	#endif

	#if _RIMLIGHT || _CUBESPEC
		fixed3 worldViewDir = normalize(WorldSpaceViewDir(pos));
	#endif

	#if _RIMLIGHT
		half fresnel = 1 - abs(dot(worldViewDir, worldNormal));
		o.color.a = pow(fresnel, _RimLighRange);
	#endif

	#if defined(UNITY_REVERSED_Z)
		o.pos.z += _DepthOffset;
	#else
		o.pos.z -= _DepthOffset;
	#endif

	//@igs(nrm):  If we never add normal maps, we should just calculate the reflection vector directly in the vertex shader
	#if _CUBESPEC
		o.viewDir = worldViewDir;
		o.worldNormal = worldNormal;
	#endif

		return o;
	}

	fixed4 frag(v2f i) : SV_Target
	{
		half4 col = tex2D(_MainTex, i.uv.xy) * _MainColor;

		#if _SUBTEX
			half4 subTex = tex2D(_SubTex , TRANSFORM_TEX(i.uv.xy, _SubTex)) * _SubColor;
			col = lerp(col , subTex , _SubTexLerp);
		#endif

		#if _METAL || _RIMLIGHT || _FLOWLIGHTUV ||_FLOWLIGHTSCREEN
			fixed4 mask = tex2D(_MaskTex, i.uv.xy);
		#endif

		#if _METAL
			// using a "linear light." algorithm to make the metal look better (very sensual algorithm) @yvanliao
			half3 matcap = lerp(0.3.rrr, tex2D(_MatCap , i.uvMatcap) * _MatCapColor.rgb , _MatCapIntensity);
			col.rgb += (matcap * 2 - 0.6) * mask.r * _MatCapColor.a;
			//col.rgb = lerp( col.rgb , matcap , mask.r *_MatCapColor.a);	
		#endif

		#if _ALPHABLEND_ON || _DISSOLVE

			col.rgb *= col.a;
		#endif
		#if  _RIMLIGHT

			_RimLightColor.rgb = col.rgb * (1 - _RimLightColor).a + _RimLightColor.rgb;

			col = lerp(col  , _RimLightColor , i.color.a * mask.g * _RimLighMultipliers);

		#endif
		#if _FLOWLIGHTUV || _FLOWLIGHTSCREEN
			half4 flowlight = tex2D(_FlowlightTex , i.uvFlow) * _FlowlightCol * _FlowlightMultipliers * mask.b;
			col.rgb += flowlight.rgb * flowlight.a;
		#endif

		#if _DISSOLVE
			fixed dissolveTex = tex2D(_DissolveTex, i.uv.xy * _DissolveTilling).r;
			half disValue = _DissolveThreshold * 2 - 0.5;
			fixed dissolve = smoothstep(disValue - _DissolveRangeSize ,disValue + _DissolveRangeSize ,dissolveTex);
			col.rgb = lerp(_DissolveRangeCol.rgb ,col.rgb ,dissolve);
			col *= dissolve;
			clip(dissolve - 0.1);
		#endif


		col.rgb += i.color.rgb;

		#if _CUBESPEC
			col.rgb += GetSpecularCubeReflection(i.uv, i.viewDir, i.worldNormal)
				* _MainColor; // Multiply specular by _MainColor because that is used for FOW tinting and specularity should be dimmed in FOW.
		#endif

		#if _ALPHABLEND_ON || _DISSOLVE
			col *= _AlphaCtrl;
		#endif

		return col;

	}



#endif  