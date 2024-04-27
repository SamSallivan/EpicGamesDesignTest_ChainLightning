#ifndef LGAME_FOG_INCLUDE
#define LGAME_FOG_INCLUDE

half		_FowBrightness;
fixed4		_FogCol;

#if _FOW_ON || _FOW_ON_CUSTOM
	// old
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


#define DECLARE_FOG_V2F(idx1) float3 worldPos:TEXCOORD##idx1;


// 体积雾基础版： 距离雾 + 高度雾
inline void FogApplyVolumetric(inout fixed4 finalRGBA, in float3 worldPos, fixed3 smokeRGB)
{
    #if _FOW_ON_CUSTOM
	    // half dist = length(_WorldSpaceCameraPos.xyz - worldPos);
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
	#if _FOW_ON || _FOW_ON_CUSTOM
		// TODO: 迁移到 vs 阶段，减少性能
		float2 smokeUV = fowUV * _FogSmokeTiling + float2(frac(_Time.z * _FogSmokeXScroll), frac(_Time.z * _FogSmokeYScroll));

		fixed4 smokeTex = tex2D(_SmokeTexture, smokeUV);
		fixed4 fowTex = tex2D( _FOWTexture, fowUV);

		//fixed4 fowLast = tex2D(_FOWLastTexture, i.fowuv);
		//fixed b = smoothstep(0.5 - _RangeSize,0.5 + _RangeSize, lerp( fowTex.r , fowTex.g, saturate(  _FOWBlend/0.4)));
		//fixed4 fowCol = lerp(_FogRangeCol , _FogCol ,  b) ;
		
		fixed add = max(0, fowTex.r - fowTex.g);
		fixed less = -min(0, fowTex.r - fowTex.g);
		fixed mid = fowTex.r - add;
		fixed b = mid + add * _FOWBlend + less * saturate( _FOWOpenSpeed);
	
		#if _FOW_ON_CUSTOM  // new fog
			fixed4 newFogCol = col;
			FogApplyVolumetric(newFogCol, worldPos.xyz, smokeTex.rgb);
			col = lerp(col, newFogCol, b); // extension： 迷雾亮度影响系数降低 或者 直接关闭
		#else				// old fog
			fixed4 fowCol = lerp(_FogRangeCol , _FogCol,  b) ;
			col *= saturate(lerp(1.0.rrrr ,fowCol, b * (1-_FowBrightness)));
		#endif
	#endif
}

inline void LGameFogApplySpecial(inout fixed4 col, in float3 worldPos, half2 fowUV)
{
	#if  _FOW_ON
		fixed4 fowTex = tex2D(_FOWTexture, fowUV);
		fixed b = smoothstep(0.5 - _RangeSize,0.5 + _RangeSize, lerp(fowTex.g , fowTex.r, _FOWBlend));

		// old fog
		fixed4 fowCol = lerp(_FogRangeCol , _FogCol ,  b);
		col *= saturate(lerp(1.0.rrrr ,fowCol ,b * (1 - _FowBrightness)));
	#endif
}

#endif