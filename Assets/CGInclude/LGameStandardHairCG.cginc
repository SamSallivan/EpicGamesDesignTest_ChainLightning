#ifndef LGAME_STANDARD_HAIR_INCLUDED
#define LGAME_STANDARD_HAIR_INCLUDED
#include "UnityCG.cginc"
sampler2D _TangentMap;
sampler2D _SpecularShiftMap;
sampler2D _SpecularMaskMap;
fixed4	_SecondarySpecularColor;
fixed4	_PrimarySpecularColor;
half	_GeneralShift;
half	_PrimarySpecularExponent;
half	_PrimarySpecularShift;
half	_PrimarySpecularStrength;
half	_PrimarySpecularGitterPow;
half	_SecondarySpecularExponent;
half	_SecondarySpecularShift;
half	_SecondarySpecularStrength;
half	_SecondarySpecularGitterPow;
half	_PrimarySpecularGitter;
half	_SecondarySpecularGitter;
half	_Jitter;
struct HairData
{
	half3 tangent;
	half3 view;
	half shift;
	half mask;
	half jitter;
	half mirror;
};
half3 ShiftTangent(half3 T, half3 N, half Shift)
{
	return normalize(T + Shift * N);
}
half StrandSpecular(half3 T, half3 H, half exponent, half strength)
{
	half TdotH = dot(T, H);
	half sinTH = sqrt(1 - TdotH * TdotH);
	half dirAtten = smoothstep(-1.0, 0.0, TdotH);
	return dirAtten * strength*pow(sinTH, exponent);
}
fixed3 HairSpecular(half3 L, half3 N,HairData hair)
{
	half3 viewFront = mul(UNITY_MATRIX_IT_MV, half4(0, 0, 1, 0)).xyz;
	viewFront = UnityObjectToWorldDir(viewFront);
	hair.view = hair.view - viewFront;
	hair.view = normalize(hair.view);
	//	V.x *= temp;
	half3 H = normalize(L + hair.view);

	half3 primaryShiftTangent = ShiftTangent(hair.tangent, N, _PrimarySpecularShift + hair.jitter);
	half3 secondaryShiftTangent = ShiftTangent(hair.tangent, N, _SecondarySpecularShift + hair.jitter);
	half3 primarySpecular = StrandSpecular(primaryShiftTangent, H, _PrimarySpecularExponent, _PrimarySpecularStrength)*_PrimarySpecularColor;
	half3 secondarySpecular = StrandSpecular(secondaryShiftTangent, H, _SecondarySpecularExponent, _SecondarySpecularStrength)*_SecondarySpecularColor;

	fixed3 specular = secondarySpecular + primarySpecular;
	specular = specular * hair.mask;
	return specular;
}

HairData HairDataSetup(half4 temp, half4 tangentToWorld[3],float2 uv)
{
	HairData hair;
	half3 tangent = tex2D(_TangentMap, uv) * 2 - 1;
	hair.tangent = normalize(tangentToWorld[0].xyz*tangent.r + tangentToWorld[1].xyz*tangent.g + tangentToWorld[2].xyz*tangent.b);
	hair.shift = tex2D(_SpecularShiftMap, uv).r;
	hair.mask = tex2D(_SpecularMaskMap, uv).r;
	hair.jitter = clamp(_Jitter, 0, 10)*0.5;
	hair.jitter = lerp(hair.jitter - 0.5, hair.jitter + 0.5, hair.shift) - _GeneralShift;
	hair.mirror = temp.w;
	hair.view = temp.xyz;
	return hair;
}
#endif