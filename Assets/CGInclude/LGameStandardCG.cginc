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

//---------------------------------------
half4       _Color;

sampler2D   _MainTex;
float4      _MainTex_ST;

sampler2D   _BumpMap;
half        _BumpScale;

sampler2D   _MetallicGlossMap;
half        _Metallic;
half        _Glossiness;
half        _GlossMapScale;

sampler2D	_ReflectionMap ;
half4		_AmbientCol; 
half		_AmbientColScale;

fixed4		_SubLight;
half		_SubLightIntensity ;
fixed4		_SubLightBack;
half		_SubLightBackIntensity;

half4		_ReflectionColor;
half		_ReflectionMapScale ;

half4		_EmissionColor;
sampler2D	_EmissionMap ;

sampler2D   _OcclusionMap;
half        _OcclusionStrength;

half		_ShadowStep;
half		_ShadowSmooth;

sampler2D	_RampMap;
half		_RampScale;

half		_ShadowFalloff;

//-------------------------------------------------------------------------------------
// Input functions

//片元着色器里面要用到的一些数据结构
struct FragmentCommonData
{
    half3 diffColor, specColor;
    // Note: smoothness & oneMinusReflectivity for optimization purposes, mostly for DX9 SM2.0 level.
    // Most of the math is being done on these (1-x) values, and that saves a few precious ALU slots.
    half oneMinusReflectivity, smoothness;
    half3 normalWorld, eyeVec;
    half alpha;
    float3 posWorld;
	half4 vertColor;
	half curvature;

};



//获得金属度、光滑度以及表面曲率
half3 MetallicGloss(float2 uv)
{
    half3 mg;

	#ifdef _METALLICGLOSSMAP
	    mg = tex2D(_MetallicGlossMap, uv).rag;
	    mg.g *= _GlossMapScale;
	#else
	    mg.r = _Metallic;
	    mg.g = _Glossiness;
		mg.b = 0;
	#endif
    return mg;
} 

//环境光闭塞
half3 Occlusion(float2 uv)
{
#if (SHADER_TARGET < 30)
    // SM20: instruction count limitation
    // SM20: simpler occlusion
    return tex2D(_OcclusionMap, uv).rgb;
#else
    half3 occ = tex2D(_OcclusionMap, uv).rgb;
	#ifndef _GAMMACORRECTION_OFF 
		GammaToLinearSpace (occ);
	#endif
    return LerpWhiteTo (occ, _OcclusionStrength);
#endif
}

//初始化FragmentCommonData的值
inline FragmentCommonData MetallicSetup (float4 i_uv)
{
    half3 metallicGloss = MetallicGloss(i_uv.xy);
    half metallic = metallicGloss.x;
    half smoothness = metallicGloss.y; // this is 1 minus the square root of real roughness m.
	half curvature = metallicGloss.z;
	fixed4 _ColorSpaceDielectricSpec = half4(0.220916301, 0.220916301, 0.220916301, 1.0 - 0.220916301);
   
	half3 albedo = tex2D ( _MainTex, i_uv.xy).rgb * _Color.rgb;
	#ifndef _GAMMACORRECTION_OFF 
		_ColorSpaceDielectricSpec = half4(0.04, 0.04, 0.04, 1.0 - 0.04) ;  
		albedo =GammaToLinearSpace(albedo);
	#endif
    half oneMinusReflectivity = (1 - metallic) * _ColorSpaceDielectricSpec.a;


	half3 specColor = lerp (_ColorSpaceDielectricSpec.rgb, albedo, metallic);


    half3 diffColor = albedo * oneMinusReflectivity;

    FragmentCommonData o = (FragmentCommonData)0;
    o.diffColor = diffColor;
    o.specColor = specColor;
    o.oneMinusReflectivity = oneMinusReflectivity;
    o.smoothness = smoothness;
	o.curvature = curvature;
    return o;
}	



//逐像素的法线计算（法线贴图）	   
half3 PerPixelWorldNormal(float4 i_uv, half4 tangentToWorld[3])
{
	#ifdef _NORMALMAP
	    half3 tangent = tangentToWorld[0].xyz;
	    half3 binormal = tangentToWorld[1].xyz;
	    half3 normal = tangentToWorld[2].xyz;
		
		//计算法线贴图以及凹凸强度
	    half3 normalTangent = UnpackScaleNormal(tex2D (_BumpMap, i_uv.xy), _BumpScale);
	    half3 normalWorld = normalize(tangent * normalTangent.x + binormal * normalTangent.y + normal * normalTangent.z); // @TODO: see if we can squeeze this normalize on SM2.0 as well
	#else
		half3 normalWorld = normalize(tangentToWorld[2].xyz);
	#endif
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
	#ifndef _GAMMACORRECTION_OFF 
		Gi.light.color = GammaToLinearSpace(Gi.light.color ) ;
	#endif
	Gi.indirect.diffuse = _AmbientCol * _AmbientColScale * occlusion;



	half perceptualRoughness = 1-s.smoothness;
	perceptualRoughness = perceptualRoughness*(1.7 - 0.7*perceptualRoughness);
	half mip = perceptualRoughness * UNITY_SPECCUBE_LOD_STEPS;
	//float3 reflUVW = reflect(-s.eyeVec, s.normalWorld);
	//half3 reflecTex = texCUBElod(_ReflectionMap,float4(-reflUVW,mip));
	half2 reflUV = GetOctahedronUV(s.eyeVec ,s.normalWorld );
	fixed3 reflecTex = tex2Dlod(_ReflectionMap , half4(reflUV , 0 , mip));
	#ifndef _GAMMACORRECTION_OFF 
		reflecTex = GammaToLinearSpace(reflecTex );
	#endif
	Gi.indirect.specular = _ReflectionColor * reflecTex * _ReflectionMapScale * occlusion;

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
	half nl = saturate(dot(s.normalWorld, gi.light.dir));
    half nh = saturate(dot(s.normalWorld, halfDir));
    half nv = saturate(dot(s.normalWorld, viewDir));
    half lh = saturate(dot(gi.light.dir, halfDir));

	half nrl = saturate(dot(s.normalWorld ,gi.light.dir * half3( -1 , 1 , 1))) ;

	// Specular term
	half perceptualRoughness = 1-s.smoothness;
	half roughness = perceptualRoughness * perceptualRoughness;
	// Diffuse term							    
	#ifdef _RAMPMAP
		fixed4 ramp = tex2D(_RampMap  , half2(nl * atten, s.curvature));
		ramp.rgb = GammaToLinearSpace(ramp)	;
		half3 diffuseTerm =lerp(nl * atten, ramp.rgb ,  _RampScale) ;
	#else
		half3 diffuseTerm = nl * atten;
	#endif


	// GGX Distribution multiplied by combined approximation of Visibility and Fresnel
	// See "Optimizing PBR for Mobile" from Siggraph 2015 moving mobile graphics course
	// https://community.arm.com/events/1155
	half a = roughness;
	half a2 = a*a;
	
	half d = nh * nh * (a2 - 1.h) + 1.00001h;
	#ifndef _GAMMACORRECTION_OFF
	    // Tighter approximation for Gamma only rendering mode!
	    // DVF = sqrt(DVF);
	    // DVF = (a * sqrt(.25)) / (max(sqrt(0.1), lh)*sqrt(roughness + .5) * d);
	    half specularTerm = a / (max(0.32h, lh) * (1.5h + roughness) * d);
	#else
	    half specularTerm = a2 / (max(0.1h, lh*lh) * (roughness + 0.5h) * (d * d) * 4);
	#endif
	// on mobiles (where half actually means something) denominator have risk of overflow
	// clamp below was added specifically to "fix" that, but dx compiler (we convert bytecode to metal/gles)
	// sees that specularTerm have only non-negative terms, so it skips max(0,..) in clamp (leaving only min(100,...))
	#if defined (SHADER_API_MOBILE)
	    specularTerm = specularTerm - 1e-4h;
	#endif



	#if defined (SHADER_API_MOBILE)
	    specularTerm = clamp(specularTerm, 0.0, 100.0); // Prevent FP16 overflow on mobiles
	#endif

    // surfaceReduction = Int D(NdotH) * NdotH * Id(NdotL>0) dH = 1/(realRoughness^2+1)

    // 1-0.28*x^3 as approximation for (1/(x^4+1))^(1/2.2) on the domain [0;1]
    // 1-x^3*(0.6-0.08*x)   approximation for 1/(x^4+1)
	#ifndef _GAMMACORRECTION_OFF
	    half surfaceReduction = 0.28;
	#else
	    half surfaceReduction = (0.6-0.08*perceptualRoughness);
	#endif
	surfaceReduction = 1.0 - roughness * perceptualRoughness * surfaceReduction;
	half grazingTerm = saturate(s.smoothness + (1-s.oneMinusReflectivity));

	//fixed3 rampCol = lerp(nl * atten , GammaToLinearSpace(tex2D(_RampMap  , half2(nl * atten , 0.5)).rgb) , _RampScale);
	half fresnel = Pow5(1 - nv);

    half3 color =   s.diffColor * (diffuseTerm * gi.light.color + gi.indirect.diffuse) 
					+ specularTerm * s.specColor * gi.light.color * diffuseTerm	
                    + surfaceReduction * gi.indirect.specular * lerp(s.specColor, grazingTerm, fresnel);	
					//+ (gi.light.color  *  nl * fresnel *  (1-surfaceReduction) + s.diffColor * _SubLightBack * nrl *  (1 - nv) * _SubLightBackIntensity)  * occlusion.r * occlusion.g;

	//color =   specularTerm * s.specColor * gi.light.color * diffuseTerm;
	return half4(color, 1);
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
	half3 diffuseTerm = nl * atten;


	// GGX Distribution multiplied by combined approximation of Visibility and Fresnel
	// See "Optimizing PBR for Mobile" from Siggraph 2015 moving mobile graphics course
	// https://community.arm.com/events/1155
	half a = roughness;
	half a2 = a*a;
	
	half d = nh * nh * (a2 - 1.h) + 1.00001h;
	#ifndef _GAMMACORRECTION_OFF
	    // Tighter approximation for Gamma only rendering mode!
	    // DVF = sqrt(DVF);
	    // DVF = (a * sqrt(.25)) / (max(sqrt(0.1), lh)*sqrt(roughness + .5) * d);
	    half specularTerm = a / (max(0.32h, lh) * (1.5h + roughness) * d);
	#else
	    half specularTerm = a2 / (max(0.1h, lh*lh) * (roughness + 0.5h) * (d * d) * 4);
	#endif
	// on mobiles (where half actually means something) denominator have risk of overflow
	// clamp below was added specifically to "fix" that, but dx compiler (we convert bytecode to metal/gles)
	// sees that specularTerm have only non-negative terms, so it skips max(0,..) in clamp (leaving only min(100,...))
	#if defined (SHADER_API_MOBILE)
	    specularTerm = specularTerm - 1e-4h;
	#endif


	#if defined (SHADER_API_MOBILE)
	    specularTerm = clamp(specularTerm, 0.0, 100.0); // Prevent FP16 overflow on mobiles
	#endif

    half3 color =   s.diffColor * diffuseTerm * gi.light.color 
					+ specularTerm * s.specColor * gi.light.color * diffuseTerm	;

	return half4(color, 1);
}

half4 LGAME_BRDF_NPR (FragmentCommonData s, half atten ,LgameGI gi)
{

	half perceptualRoughness = 1-s.smoothness;
	half3 halfDir = LGame_SafeNormalize (gi.light.dir + -s.eyeVec);


	half nv = abs(dot(s.normalWorld,-s.eyeVec)) ;	// This abs allow to limit artifact
	half nl = saturate(dot(s.normalWorld, gi.light.dir));
	half lh = saturate(dot(gi.light.dir, halfDir));

	// Diffuse term
	half diffuseTerm = DisneyDiffuse(nv, nl, lh, perceptualRoughness) * nl;
														 
    half3 color =	s.diffColor * lerp(gi.indirect.diffuse , gi.light.color ,smoothstep(_ShadowStep , _ShadowStep + _ShadowSmooth , diffuseTerm ) * atten ) + pow(1-nv , 4) * _ReflectionColor.rgb; 

	return half4(color, 1);
}


half3 Emission(float2 uv)
{
#ifndef _EMISSION
	return 0;
#else

	half3 emission = tex2D(_EmissionMap, uv).rgb; 
	#ifndef _GAMMACORRECTION_OFF
		emission = GammaToLinearSpace(emission);
	#endif
	return emission * _EmissionColor.rgb;
#endif
}
#endif // LGAME_STANDARD_INCLUDED