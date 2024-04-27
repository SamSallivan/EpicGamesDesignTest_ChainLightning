#ifndef LGAME_STARACTOR_BRDF_INCLUDED
#define LGAME_STARACTOR_BRDF_INCLUDED
half Diffuse_Wrap(half NoL, half w) {
	return saturate((NoL + w) / ((1.0 + w)*(1.0 + w)));
}
half D_GGX(half NdotH, half roughness)
{
	half a2 = roughness * roughness;
	half d = (NdotH * a2 - NdotH) * NdotH + 1.0f;
	return UNITY_INV_PI * a2 / (d * d + 1e-7f);
}
//Crafting a Next-Gen Material Pipeline for The Order : 1886
half D_Anisotropic(half ToH, half BoH, half NoH, half roughnessT, half roughnessB)
{
	half f = ToH * ToH / (roughnessT * roughnessT) + BoH * BoH / (roughnessB * roughnessB) + NoH * NoH;
	return 1 / (UNITY_PI * roughnessT * roughnessB * f * f);
}
half D_Charlie(half roughness, half NoH) {
	half invAlpha = 1.0 / roughness;
	half cos2h = NoH * NoH;
	half sin2h = max(1.0 - cos2h, 0.0078125);
	return (2.0 + invAlpha) * pow(sin2h, invAlpha * 0.5) / (2.0 * UNITY_PI);
}
half V_Kelemen(half LoH)
{
	return saturate(0.25 / (LoH*LoH));
}
half V_SmithGGXCorrelated_Anisotropic(half roughnessT, half roughnessB, half ToV, half BoV,
	half ToL, half BoL, half NoV, half NoL) {
	// Heitz 2014, "Understanding the Masking-Shadowing Function in Microfacet-Based BRDFs"
	// TODO: lambdaV can be pre-computed for all the lights, it should be moved out of this function
	half lambdaV = NoL * length(half3(roughnessT * ToV, roughnessB * BoV, NoL));
	half lambdaL = NoV * length(half3(roughnessT * ToL, roughnessB * BoL, NoV));
	half v = 0.5 / (lambdaV + lambdaL);
	return saturate(v);
}
half V_Neubelt(half NoV, half NoL) {
	return saturate(1.0 / (4.0 * (NoL + NoV - NoL * NoV)));
}
half3 F_Schlick(const half3 f0, half VoH) {
	half f = pow(1.0 - VoH, 5.0);
	return f + f0 * (1.0 - f);
}
half3 Silk_Specular_BxDF(half NoL, half NoV, half NoH, half ToV, half BoV, half ToL, half BoL, half ToH, half BoH, half LoH, half roughnessT, half roughnessB, half3 specColor) {
	half D = D_Anisotropic(ToH, BoH, NoH, roughnessT, roughnessB);
	half V = V_SmithGGXCorrelated_Anisotropic(roughnessT, roughnessB, ToV, BoV, ToL, BoL, NoV, NoL);
	half3 F = F_Schlick(specColor, LoH);
	return(D * V) * F;
}
half3 ClearCoat_Specular_BxDF(half NoH, half LoH, half clearCoat, half clearCoat_roughness, out half3 Fcc)
{
	half  D = D_GGX(NoH, clearCoat_roughness);
	half  V = V_Kelemen(LoH);
	half3  F = F_Schlick(0.04, LoH) * clearCoat;
	Fcc = F;
	return(D * V) * F;
}
half3 Velvet_Specular_BxDF(half NoL, half NoV, half NoH, half LoH, half roughness, half3 sheenColor) {
	half D = D_Charlie(roughness, NoH);
	half V = V_Neubelt(NoV, NoL);
	half3 F = F_Schlick(sheenColor, LoH);
	return(D * V) * F;
}
//Hair Anisotropic Specualr
//Kajiya_Kay Shading Mode
#ifdef _HAIR
fixed4	_SecondarySpecularColor;
fixed4	_PrimarySpecularColor;
half	_PrimarySpecularExponent;
half	_PrimarySpecularShift;
half	_SecondarySpecularExponent;
half	_SecondarySpecularShift;
half3 ShiftTangent(half3 T, half3 N, half Shift)
{
	return normalize(T + Shift * N);
}
half StrandSpecular(half3 T, half3 H, half exponent)
{
	half TdotH = dot(T, H);
	half sinTH = sqrt(1.0 - TdotH * TdotH);
	half dirAtten = smoothstep(-1.0, 0.0, TdotH);
	return dirAtten * pow(sinTH, exponent);
}
half3 Kajiya_Kay_Specular_BxDF(half3 H, half3 N, half3 T, half mask, half shift)
{
	half3 primaryShiftTangent = ShiftTangent(T, N, _PrimarySpecularShift + shift);
	half3 secondaryShiftTangent = ShiftTangent(T, N, _SecondarySpecularShift + shift);
	half3 primarySpecular = StrandSpecular(primaryShiftTangent, H, _PrimarySpecularExponent)*_PrimarySpecularColor;
	half3 secondarySpecular = StrandSpecular(secondaryShiftTangent, H, _SecondarySpecularExponent)*_SecondarySpecularColor;
	half3 specular = (secondarySpecular + primarySpecular)*mask;
	return specular;
}
#endif
#ifdef _EYE
half Diffuse_EYE(half3 IrisNormal, half3 CausticNormal, half NoL, half IrisMask, half3 L)
{
	half IrisNoL = saturate(dot(IrisNormal, L));
	half power = lerp(12.0, 1.0, IrisNoL);
	half caustic = 0.8 + 0.2 * (power + 1.0) * pow(saturate(dot(CausticNormal, L)), power);
	half iris = IrisNoL * caustic;
	half sclera = NoL;
	return lerp(sclera, iris, IrisMask);
}
#endif
#endif