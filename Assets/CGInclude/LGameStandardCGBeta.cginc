#ifndef LGAME_STANDARD_INCLUDED
#define LGAME_STANDARD_INCLUDED
#include "UnityCG.cginc"
#include "AutoLight.cginc"	
#include "Lighting.cginc"	
   
//从tangentToWorld中得到WorldPos
#define IN_WORLDPOS(i) half3(i.tangentToWorld[0].w,i.tangentToWorld[1].w,i.tangentToWorld[2].w)		
#define IN_LIGHTDIR_FWDADD(i) half3(i.tangentToWorldAndLightDir[0].w, i.tangentToWorldAndLightDir[1].w, i.tangentToWorldAndLightDir[2].w)					   
#define LGAME_FRAGMENT_SETUP(x) FragmentCommonData x = \
    FragmentSetup(i.uv, i.vertColor , i.eyeVec, i.tangentToWorld, IN_WORLDPOS(i));
#define FRAGMENT_SETUP_FWDADD(x) FragmentCommonData x = \
	FragmentSetup(i.uv, i.vertColor , i.eyeVec,  i.tangentToWorldAndLightDir, i.posWorld);

//#define LGAME_ACTOREFFECT_COORDS(coodID)  half2 effect_uv : TEXCOORD##coodID;
//#define LGAME_TRANSFER_ACTOREFFECT(o,uv)	 o.effect_uv = uv.xy * _EffectTex_ST.xy  + frac(_Time.xxxx * _EffectTex_ST.zw)
//#define LGAME_ACTOREFFECT(a ,mask)  LgameEffect(IN_WORLDPOS(i), a.effect_uv ,mask)
//---------------------------------------
	half4       _Color;
	
	sampler2D   _MainTex;
	float4      _MainTex_ST;
	
	half		_Cutoff;
	
	sampler2D   _BumpMap;
	half        _BumpScale;
	
#ifdef _METALLICGLOSSMAP
	sampler2D   _MetallicGlossMap;
	half        _GlossMapScale;
#else
	half        _Metallic;
	half        _Glossiness;
#endif
	
	
	
#ifndef _EMISSION_MATCAP
	UNITY_DECLARE_TEXCUBE(	_ReflectionMap) ;
#else
	sampler2D	_ReflectionMatCap;
#endif
	half4		_ReflectionColor;
	half		_ReflectionMapScale;
	
	half4		_AmbientCol; 
	half		_AmbientColScale;
#if _EMISSION
	sampler2D	_EmissionMap ;
	half4		_EmissionColor;
#endif
	sampler2D   _OcclusionMap;
	half        _OcclusionStrength;
	
	
	fixed4		_SSSCol;
	half		_SSSIntensity;
	
	
	//sampler2D	_EffectTex;
	//half4		_EffectTex_ST;
	//half		_EffectStrength;
	//half4		_EffectCol;
	
	 
	//half		_DissolveRange;
	//half		_Dissolve;
	//half4		_DissolveRangeColor;
	half		_BrightnessInOcclusion;
//-------------------------------------------------------------------------------------
// Effect functions
/*
half3 LgameEffect(half3 worldPos , half2 effect_uv , half mask)
{
	#if _FLOWLIGHT||_HIGHCLIP 
		half2 noise =  tex2D(_EffectTex , effect_uv.xy ).rg; 
		half3 effectCol = 0;
		#if _FLOWLIGHT
			effectCol += _EffectCol.rgb * noise.g * _EffectStrength * mask; 
		#endif
		#if _HIGHCLIP
			half clipVal = smoothstep(_Dissolve - _DissolveRange, _Dissolve + _DissolveRange, worldPos.y + noise.r );
			clip(clipVal - 0.5);
			effectCol += _DissolveRangeColor.rgb * saturate(1-clipVal * 1.5)  ;
		#endif
		return effectCol ;
	#else
		return 0;
	#endif
}
void ShadowClip(half3 worldPos , half2 effect_uv )
{
	#if _HIGHCLIP 
		half noise =  tex2D(_EffectTex , effect_uv.xy ).r; 

		half clipVal = smoothstep(_Dissolve - _DissolveRange, _Dissolve + _DissolveRange, worldPos.y + noise );
		clip(clipVal - 0.5);
	#endif
}
*/
//-------------------------------------------------------------------------------------
// Input functions

//片元着色器里面要用到的一些数据结构
struct FragmentCommonData
{
    half3 diffColor;
	half3 specColor;
	half alpha;
    // Note: smoothness & oneMinusReflectivity for optimization purposes, mostly for DX9 SM2.0 level.
    // Most of the math is being done on these (1-x) values, and that saves a few precious ALU slots.
    half oneMinusReflectivity;
	half smoothness;
    half3 normalWorld;
	half3 eyeVec;

    float3 posWorld;
	half4 vertColor;
	half curvature;
	half mask;

};



//获得金属度、光滑度以及表面曲率
half4 MetallicGloss(float2 uv)
{
    half4 mgsm;

	#ifdef _METALLICGLOSSMAP
	    mgsm = tex2D(_MetallicGlossMap, uv).rgba;
	    mgsm.g *= _GlossMapScale;
		mgsm.b *= _SSSIntensity;
		//mgsm.a *= _EffectStrength;
	#else
	    mgsm.r = _Metallic;
	    mgsm.g = _Glossiness;
		mgsm.b = _SSSIntensity;
		//mgsm.a = _EffectStrength;
	#endif
    return mgsm;
} 
/*
//环境光闭塞
half3 Occlusion(float2 uv)
{
#if (SHADER_TARGET < 30)
    // SM20: instruction count limitation
    // SM20: simpler occlusion
    return tex2D(_OcclusionMap, uv).rgb;
#else
    half3 occ = tex2D(_OcclusionMap, uv).rgb;
    return LerpWhiteTo (occ, _OcclusionStrength);
#endif
}*/
half3 Occlusion(float2 uv)
{
	half3 occlusion = tex2D(_OcclusionMap, uv).rgb;
	occlusion.r = LerpWhiteTo(occlusion.r, _OcclusionStrength);
	occlusion.g = LerpWhiteTo(occlusion.g, _BrightnessInOcclusion);
	return occlusion;
}

//初始化FragmentCommonData的值
inline FragmentCommonData MetallicSetup (float4 i_uv)
{

    half4 metallicGloss = MetallicGloss(i_uv.xy);
    half metallic = metallicGloss.x;
    half smoothness = metallicGloss.y; // this is 1 minus the square root of real roughness m.
	half curvature = metallicGloss.z;
	half mask = metallicGloss.w;
	fixed4 _ColorSpaceDielectricSpec = half4(0.04, 0.04, 0.04, 1.0 - 0.04) ;
   
	half4 albedo = tex2D( _MainTex, i_uv.xy) * _Color;

	//gamma矫正
	albedo.rgb =GammaToLinearSpace(albedo.rgb);

	half3 specColor = lerp (_ColorSpaceDielectricSpec.rgb , albedo.rgb, metallic);
    half oneMinusReflectivity = (1 - metallic) * _ColorSpaceDielectricSpec.a;

    half3 diffColor = albedo.rgb * oneMinusReflectivity;

    FragmentCommonData o = (FragmentCommonData)0;
    o.diffColor = diffColor;
	o.alpha = albedo.a;
    o.specColor = specColor;
    o.oneMinusReflectivity = oneMinusReflectivity;
    o.smoothness = smoothness;
	o.curvature = curvature;
	o.mask = mask;
    return o;
}	



//逐像素的法线计算（法线贴图）	   
half3 PerPixelWorldNormal(float4 i_uv, half4 tangentToWorld[3])
{
	//#ifdef _NORMALMAP
	    half3 tangent = tangentToWorld[0].xyz;
	    half3 binormal = tangentToWorld[1].xyz;
	    half3 normal = tangentToWorld[2].xyz;
		
		//计算法线贴图以及凹凸强度
	    half3 normalTangent = UnpackScaleNormal(tex2D (_BumpMap, i_uv.xy), _BumpScale);
	    half3 normalWorld = normalize(tangent * normalTangent.x + binormal * normalTangent.y + normal * normalTangent.z); // @TODO: see if we can squeeze this normalize on SM2.0 as well
	//#else
	//	half3 normalWorld = normalize(tangentToWorld[2].xyz);
	//#endif
    return normalWorld;
}

//片元着色器变量设置
inline FragmentCommonData FragmentSetup (inout float4 i_uv,half4 i_vertColor , half3 i_eyeVec ,half4 tangentToWorld[3], float3 i_posWorld)
{
    //i_tex = Parallax(i_tex, i_viewDirForParallax);


    FragmentCommonData o = MetallicSetup (i_uv);
    o.normalWorld = PerPixelWorldNormal(i_uv, tangentToWorld);
    o.eyeVec = normalize(i_eyeVec);
    o.posWorld = i_posWorld;
	o.vertColor = i_vertColor;

    return o;
}

struct LgameLight
{
    half3 color;//主光源颜色
    half3 dir; //主光源方向

};

struct LgameIndirect
{
    half3 diffuse; //环境光
    half3 specular;	//镜面反射（cubeMap）
};
//全局光照
struct LgameGI
{
    LgameLight light;
    LgameIndirect indirect;
};
LgameLight MainLight ()
{
    LgameLight l;

    l.color = _LightColor0.rgb;
    l.dir = _WorldSpaceLightPos0.xyz;
    return l;
}
LgameLight AdditiveLight (half3 lightDir, half atten)
{
	LgameLight l;

	l.color = _LightColor0.rgb * atten;
	l.dir = lightDir;
	#ifndef USING_DIRECTIONAL_LIGHT
        l.dir = normalize(l.dir);
    #endif
	return l;
}

inline void ResetUnityGI(out LgameGI outGI)
{
	outGI.light.color = half3(0, 0, 0);
	outGI.light.dir = half3(0, 1, 0); // Irrelevant direction, just not null
	outGI.indirect.diffuse = 0;
	outGI.indirect.specular = 0;
}

half2 GetOctahedronUV(half3 viewDir, half3 worldNor)
{
	half3 reflDir=reflect(viewDir,worldNor);

	half3 d=reflDir/dot(half3(1,1,1),abs(reflDir));
	
   	if(d.y<0.0)
		d.xz=(1-abs(d.zx))*sign(d.xz);
	half2 uv = d.xz * 0.5 + 0.5 ;
	return uv;
}



inline LgameGI LGame_FragmentGI (FragmentCommonData s, half atten, half occlusion , LgameLight light, bool reflections)
{


	LgameGI Gi;
	ResetUnityGI(Gi);																												  

	Gi.light = light;
	Gi.indirect.diffuse = _AmbientCol * _AmbientColScale * occlusion;


	//八面体环境反射
	//half2 reflUV = GetOctahedronUV(s.eyeVec ,s.normalWorld );
	//fixed3 reflecTex = tex2Dlod(_ReflectionMap , half4(reflUV , 0 , mip)) ;
	half perceptualRoughness = 1-s.smoothness;
	perceptualRoughness = perceptualRoughness*(1.7 - 0.7*perceptualRoughness);
	half mip = perceptualRoughness * 6;

	half4 reflecTex = 0;


	#ifndef _EMISSION_MATCAP

		float3 reflUVW = -normalize( reflect(s.eyeVec, s.normalWorld) );
		reflecTex = UNITY_SAMPLE_TEXCUBE_LOD(_ReflectionMap,-reflUVW,mip) * _ReflectionColor*2;
	#else
		//MatCap环境反射方案
		//half2 matcapuv;
		//
		//matcapuv.x = dot(UNITY_MATRIX_V[0].xyz , s.normalWorld.xyz) ;
		//matcapuv.y = dot(UNITY_MATRIX_V[1].xyz , s.normalWorld.xyz) ; 
		//matcapuv = matcapuv * 0.5 + 0.5;

		//matcap反射矫正
		//很大程度缓解了平面反射效果不正确的问题
		//参考：https://www.clicktorelease.com/blog/creating-spherical-environment-mapping-shader/
		half3 viewNormal = mul(UNITY_MATRIX_V , half4(s.normalWorld.xyz,0)).xyz;
		half3 viewPos = UnityWorldToViewPos(s.posWorld);
		float3 r = normalize(reflect(viewPos, viewNormal));
		float m = 2.0 * sqrt(r.x * r.x + r.y * r.y + (r.z + 1) * (r.z + 1));
		half2 matcapuv = r.xy/m + 0.5;

		reflecTex = tex2Dlod(_ReflectionMatCap ,half4( matcapuv ,0, mip)) * _ReflectionColor;		

	#endif


	//gamma矫正
	reflecTex.rgb = GammaToLinearSpace(reflecTex.rgb);


	Gi.indirect.specular = reflecTex .rgb * _ReflectionMapScale * occlusion ;

	return Gi;
}						 

LgameGI LGame_FragmentGI (FragmentCommonData s,  half atten, half occlusion , LgameLight light)
{
	return LGame_FragmentGI(s, atten, occlusion , light,  true);
}
LgameGI LGame_FragmentGI (FragmentCommonData s,  half atten , LgameLight light)
{
	return LGame_FragmentGI(s, atten, 1 , light,  true);
}
inline half3 LGame_SafeNormalize(half3 inVec)
{
	half dp3 = max(0.001f, dot(inVec, inVec));
	return inVec * rsqrt(dp3);
} 


inline half4 LGAME_BRDF_PBS (FragmentCommonData s, half atten , LgameGI gi , half3 occlusion)
{
	half3 viewDir = -s.eyeVec;

	half3 halfDir = Unity_SafeNormalize (gi.light.dir + viewDir);
	half nl = dot(s.normalWorld, gi.light.dir);
	half clampNL = saturate(nl);
    half nh = saturate(dot(s.normalWorld, halfDir));
    half nv = saturate(dot(s.normalWorld, viewDir));
    half lh = saturate(dot(gi.light.dir, halfDir));



	// Specular term
	half perceptualRoughness = 1-s.smoothness;
	half roughness = perceptualRoughness * perceptualRoughness;

	//SSS效果						    
	#ifdef _SSS
		half3 sssCol =   _SSSCol * saturate(nl*0.5+0.5) * s.curvature * (1 - clampNL * atten);
		half3 diffuseTerm = gi.light.color * (clampNL * atten + sssCol);//lerp(sssCol , gi.light.color ,clampNL * atten);
	#else
		half3 diffuseTerm = gi.light.color * clampNL * atten;
	#endif

	


	half a = roughness;
	half a2 = a*a;
	
	half d = nh * nh * (a2 - 1.h) + 1.00001h;
	half specularTerm = a2 / (max(0.1h, lh*lh) * (roughness + 0.5h) * (d * d) * 4);

	#if defined (SHADER_API_MOBILE)
		specularTerm = clamp(specularTerm - 1e-4h , 0.0, 100.0);
	#endif

	half surfaceReduction = (0.6-0.08*perceptualRoughness);
	surfaceReduction = 1.0 - roughness * perceptualRoughness * surfaceReduction;

	//surfaceReduction = 1.0 / (roughness*roughness + 3.0);   
	half grazingTerm = saturate(s.smoothness + (1-s.oneMinusReflectivity));

	half3 color =   (s.diffColor + specularTerm * s.specColor ) * diffuseTerm	 
                    + gi.indirect.diffuse * s.diffColor 	
                    +  surfaceReduction * gi.indirect.specular * FresnelLerpFast (s.specColor, grazingTerm ,  nv);
	//color =   diffuseTerm;//surfaceReduction * gi.indirect.specular * FresnelLerpFast (s.specColor, grazingTerm ,  nv);//F * D * G ;
	return half4(color, s.alpha);
}

half4 LGAME_BRDF_PBS (FragmentCommonData s, half atten ,LgameGI gi )
{
	 return LGAME_BRDF_PBS (s, atten ,gi ,  1) ;
}

half4 LGAME_BRDF_PBS_ADD (FragmentCommonData s, half atten ,LgameGI gi )
{
	half3 viewDir = -s.eyeVec;

	half3 halfDir = Unity_SafeNormalize (gi.light.dir + viewDir);
	half nl = saturate(dot(s.normalWorld, gi.light.dir));
    half nh = saturate(dot(s.normalWorld, halfDir));
    half lh = saturate(dot(gi.light.dir, halfDir));

	// Specular term
	half perceptualRoughness = 1-s.smoothness;
	half roughness = perceptualRoughness * perceptualRoughness;
	// Diffuse term							    
	half3 diffuseTerm = nl * atten ;

	half a = roughness;
	half a2 = a*a;
	
	half d = nh * nh * (a2 - 1.h) + 1.00001h;

	    half specularTerm = a / (max(0.32h, lh) * (1.5h + roughness) * d);
	#if defined (SHADER_API_MOBILE)
	    specularTerm = clamp(specularTerm - 1e-4h ,  0.0, 100.0);
	#endif

    half3 color =   s.diffColor * diffuseTerm * gi.light.color 
					+ specularTerm * s.specColor * gi.light.color * diffuseTerm	;

	return half4(color, 1);
}


half3 Emission(float2 uv)
{
#ifndef _EMISSION
	return 0;
#else

	half3 emission = tex2D(_EmissionMap, uv).rgb * _EmissionColor.rgb; 
	#ifdef _GAMMACORRECTION
		emission = GammaToLinearSpace(emission);
	#endif
	return emission;
#endif
}
#endif // LGAME_STANDARD_INCLUDED