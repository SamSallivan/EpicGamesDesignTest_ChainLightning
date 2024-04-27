
// Upgrade NOTE: excluded shader from OpenGL ES 2.0 because it uses non-square matrices
#pragma exclude_renderers gles
#ifndef LGAME_CHARACTER_INCLUDE
	#define LGAME_CHARACTER_INCLUDE
	#include "UnityCG.cginc"
	#include "Assets/CGInclude/LGameCharacterDgs.cginc"
	#include "Assets/CGInclude/LGameDissolveWorld.cginc"


	struct a2v
	{
		float4 vertex	: POSITION;
		float4 texcoord : TEXCOORD0;
	#ifdef _USE_DIRECT_GPU_SKINNING
		half4 tangent	: TANGENT;
		float4 skinIndices : TEXCOORD2;
		float4 skinWeights : TEXCOORD3;
	#else
		float3 normal	: NORMAL;
	#endif
	};
	struct v2f
	{
		fixed4 	color : COLOR;
		float4	pos			: SV_POSITION;
		half4	uv			: TEXCOORD0;
	#ifdef _METAL
		half2	uvMatcap	: TEXCOORD1;
	#endif
	#if  _FLOWLIGHTUV ||  _FLOWLIGHTSCREEN
		half2	uvFlow		: TEXCOORD2;
	#endif
	#if  _SUBTEX
		half2	uvSub		: TEXCOORD3;
	#endif
	#if defined(LGAME_USEFOW) && _FOW_ON_CUSTOM
		half2 fowuv	: TEXCOORD4;
	#endif
		
	#if (defined(LGAME_USEFOW) && _FOW_ON_CUSTOM) || (defined(LGAME_DISSOLVE_WORLD) && _ENABLE_DISSOLVE_WORLD)
		float3 worldPos : TEXCOORD5;
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
	sampler2D	_NoiseTex;
	half		_NoiseTiling;
	half4		_EdgeColor;
	half		_EdgeWidth;
	half		_SubTexLerp;
	half		_SubTexMode;
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
	int			_RimLightBlendMode;
	#endif

	#if  _FLOWLIGHTUV ||  _FLOWLIGHTSCREEN
	sampler2D	_FlowlightTex;
	half4		_FlowlightTex_ST;
	half		_FlowlightMultipliers;
	fixed4		_FlowlightCol;
	int			_FlowLightBlendMode;
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

	half		_FowBrightness;
	fixed4		_FogCol;

	#if defined(LGAME_USEFOW) && _FOW_ON_CUSTOM
		sampler2D	_FOWTexture;
		//sampler2D	_FOWLastTexture;
		fixed4		_FogRangeCol;
		half		_FOWBlend;
		half		_FOWOpenSpeed;
		half4		_FOWParam;
		half		_RangeSize;
		half		_fow;
		float3		_BattleCameraPos;
			
		// new
		half4 _FogColor;
		half4 	_FogColorFade;
		half  	_FogDensity;
		half	_FogStartDistance;
		half 	_FogEndDistance;
		half 	_FogHeight;
		half 	_FogHeightSize;

		sampler2D   _SmokeTexture;
		half	_FogSmokeTiling;
		float	_FogSmokeXScroll;
		float	_FogSmokeYScroll;

		half _DarkSmokePow;
		half _LightSmokePow;
		half _LightSmokeExp;
		half4 _LightSmokeColor;
		half _FogBlendValue;
	#endif

	// 体积雾基础版： 距离雾 + 高度雾
	inline void FogApplyVolumetric(inout fixed4 finalRGBA, in float3 worldPos, fixed3 smokeRGB)
	{
		#if defined(LGAME_USEFOW) && _FOW_ON_CUSTOM
			half dist = length(_BattleCameraPos.xyz - worldPos); // 改为角色移动时传入
			half fogHeightIntensity = ( 1.0 - min ( ( length ( worldPos.y - _FogHeight ) / _FogHeightSize ), 1.0 ) );

			// _FogDensity 受 _FowBrightness 影响
			// _FogDensity 最小值限定在 0.3
			_FogDensity = _FogDensity * saturate(1.0 - _FowBrightness*2);  // c# 层潜规则：_FowBrightness 最大值限制不超过 0.5
			_FogDensity = max(_FogDensity, 0.3);
		
			finalRGBA.rgb = lerp (finalRGBA.rgb, _FogColor, fogHeightIntensity * _FogDensity );
			fixed4 oldFinalRGB = finalRGBA;

			// 计算烟雾部分 ↓
			half distFade = 1.0 - clamp ((_FogEndDistance - dist) / _FogStartDistance, 0.0, 1.0);
			distFade *= pow(smokeRGB.r, _DarkSmokePow);  // todo: _DarkSmokePow 需优化
			finalRGBA = lerp (finalRGBA, _FogColorFade, distFade);
			fixed3 lightSmokeValue = pow(smokeRGB.r, _LightSmokePow) * _LightSmokeExp * _LightSmokeColor;  // todo: _LightSmokePow 需优化
			finalRGBA.rgb += lightSmokeValue;
			
			// 混合部分 ↓
			finalRGBA = lerp(oldFinalRGB, finalRGBA, _FogBlendValue);
		#endif
	}

	inline void LGameFogApply(inout fixed4 col, in float3 worldPos, half2 fowUV)
	{
		#if defined(LGAME_USEFOW) && _FOW_ON_CUSTOM
			// TODO: 迁移到 vs 阶段，减少性能
			float2 smokeUV = fowUV * _FogSmokeTiling + float2(frac(_Time.z * _FogSmokeXScroll), frac(_Time.z * _FogSmokeYScroll));
			
			fixed4 smokeTex = tex2D(_SmokeTexture, smokeUV);
			fixed4 fowTex = tex2D( _FOWTexture, fowUV);
				
			fixed add = max(0, fowTex.r - fowTex.g);
			fixed less = -min(0, fowTex.r - fowTex.g);
			fixed mid = fowTex.r - add;
			fixed b = mid + add * _FOWBlend + less * saturate( _FOWOpenSpeed);
		
			fixed4 newFogCol = col;
			FogApplyVolumetric(newFogCol, worldPos.xyz, smokeTex.rgb); // 体积雾
			// col = lerp(col, newFogCol, b * (1-_FowBrightness));
			col = lerp(col, newFogCol, b);  // extension： 迷雾亮度影响系数降低 或者 直接关闭
		#endif
	}

	v2f vert(a2v v)
	{
		v2f o;

		UNITY_INITIALIZE_OUTPUT(v2f, o);
		float4 pos = v.vertex;

		float3 normal;
	#if _USE_DIRECT_GPU_SKINNING

		float4 tangent;
		float3 binormal;

		DecompressTangentNormal(v.tangent, tangent, normal, binormal);
		pos = CalculateGPUSkin(v.skinIndices, v.skinWeights, v.vertex, tangent, normal, binormal);
		//pos = CalculateGPUSkin_L(v.skinIndices, v.skinWeights, v.vertex);
		//normal = v.normal;
		v.texcoord.xy = DecompressUV(v.texcoord.xy, _uvBoundData);
		/********************************************************************************************************************
		//ʹ�ö�ż��Ԫ�����߼�����������Ҫ�ٴ� by yeyang
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
	#else
		normal = v.normal;
	#endif

		o.pos = UnityObjectToClipPos(pos);
		o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
		o.uv.zw = v.texcoord.xy;
		o.color = _OffsetColor;


	#if _METAL || _RIMLIGHT 
		fixed3 worldNormal = UnityObjectToWorldNormal(normal);
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
	#if _SUBTEX
		half4 subTexSrcPos = ComputeScreenPos(o.pos);
		o.uvSub = lerp(TRANSFORM_TEX(o.uv.xy, _SubTex),
						(subTexSrcPos.xy / subTexSrcPos.w) *_SubTex_ST.xy + frac(_SubTex_ST.zw * _Time.y),
						_SubTexMode) ;
	#endif
	#if _RIMLIGHT
		fixed3 worldViewDir = normalize(WorldSpaceViewDir(pos));
		half fresnel = 1 - abs(dot(worldViewDir, worldNormal));
		o.color.a = pow(fresnel, _RimLighRange);
	#endif		

	#if defined(UNITY_REVERSED_Z)
		o.pos.z += _DepthOffset;
	#else
		o.pos.z -= _DepthOffset;
	#endif

	#if (defined(LGAME_USEFOW) && _FOW_ON_CUSTOM) || (defined(LGAME_DISSOLVE_WORLD) && _ENABLE_DISSOLVE_WORLD)
		o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
	#endif

	#if (defined(LGAME_USEFOW) && _FOW_ON_CUSTOM)
		o.fowuv = half2 ((o.worldPos.x -_FOWParam.x)/_FOWParam.z, (o.worldPos.z -_FOWParam.y)/_FOWParam.w);
	#endif
		
		return o;
	}

	fixed4 frag(v2f i) : SV_Target
	{
		half4 col = tex2D(_MainTex, i.uv.xy) * _MainColor;
		half mainAlpha = col.a;

		#if _SUBTEX
			half4 subTex = tex2D(_SubTex ,i.uvSub) * _SubColor;
			half noise =  tex2D(_NoiseTex , i.uv.zw * _NoiseTiling).r;	
			noise = lerp(1,noise,_SubTexLerp);
			half subT_disValue =  _SubTexLerp + 0.5;
			half blendValue  = smoothstep(subT_disValue + _EdgeWidth ,subT_disValue - _EdgeWidth ,noise);
			half3 edgeCol = blendValue * (1-blendValue) * _EdgeColor.rgb;
			col = lerp(col , subTex , blendValue);
			col.rgb += edgeCol;
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
			// _RimLightBlendMode��
			// 0 => multiply(default)
			// 1 => add
			// Use more readable encoding  @bartwang 2022-03-10
			if(any(_RimLightBlendMode))
			{
				col.rgb += i.color.a * mask.g * _RimLighMultipliers *_RimLightColor;
			}
			else
			{
				col = lerp(col,_RimLightColor , i.color.a * mask.g * _RimLighMultipliers);
			}
		#endif

		#if _FLOWLIGHTUV || _FLOWLIGHTSCREEN
			half4 flowlightTex = tex2D(_FlowlightTex , i.uvFlow) *mask.b;
			half4 flowlightColor = _FlowlightCol * _FlowlightMultipliers;

			// _FlowLightBlendMode��
			// 0 => multiply
			// 1 => add
			// 2 => mask to multiply
			// Use more readable encoding  @yvanliao 2022-03-01
			if(_FlowLightBlendMode>1)
			{
				col.rgb *=	lerp(1,flowlightColor.rgb, flowlightTex.rgb * flowlightTex.a);
			}
			else
			{
				flowlightColor *=  flowlightTex;
				flowlightColor.rgb *=flowlightColor.a;
				
				
				if(any(_FlowLightBlendMode))
				{
					col.rgb += flowlightColor.rgb;
				}
				else
				{
					col.rgb *= flowlightColor.rgb;
				}
			}
		#endif

		#if _DISSOLVE
			fixed dissolveTex = tex2D(_DissolveTex, i.uv.xy * _DissolveTilling).r;
			half disValue = _DissolveThreshold * 2 - 0.5;
			fixed dissolve = smoothstep(disValue - _DissolveRangeSize ,disValue + _DissolveRangeSize ,dissolveTex);
			col.rgb = lerp(_DissolveRangeCol.rgb ,col.rgb ,dissolve);
			col *= dissolve;
			clip(dissolve - 0.1);
		#endif
		
		#if _ALPHABLEND_ON || _DISSOLVE
		i.color.rgb *= mainAlpha;
		#endif

		#if defined(LGAME_USEFOW) && _FOW_ON_CUSTOM
			LGameFogApply(col, i.worldPos.xyz, i.fowuv);
		#endif
		
		col.rgb += i.color.rgb;

		#if _ALPHABLEND_ON || _DISSOLVE
			col *= _AlphaCtrl;
		#endif

		// Apply Dissolve World
		#if defined(LGAME_DISSOLVE_WORLD) && _ENABLE_DISSOLVE_WORLD
			LGameApplyDissolveWorld(col, i.worldPos.xyz);
		#endif
		
		return col;

	}



#endif  