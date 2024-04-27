#ifndef LGAME_STARACTOR_EFFECT_INCLUDED
#define LGAME_STARACTOR_EFFECT_INCLUDED
#include "UnityStandardBRDF.cginc"
//In Order To Simplify Shader Structure,Additional ALU Is Needed
//Configuration
//Struct Marco
#define LGAME_STARACTOR_EFFECT_STRUCT(i) \
	float4 ScreenPosition	: TEXCOORD##i;

//Vertex Marco
#define LGAME_STARACTOR_EFFECT_VERTEX(o) \
	o.ScreenPosition = ComputeScreenPos(o.pos);

//Fragment Marco
#define LGAME_STARACTOR_EFFECT_FRAGMENT_BEGIN(i) \
	LGAME_STARACTOR_DISSOVLE(i) \
	float3 wPosTemp = float3(i.tangentToWorld[0].w, i.tangentToWorld[1].w, i.tangentToWorld[2].w);\
	LGAME_STARACTOR_WORLD_CLIP(wPosTemp,i.ScreenPosition)

#define LGAME_STARACTOR_EFFECT_FRAGMENT_SETUP(i,base) \
	LGAME_STARACTOR_DITHER_CLIP(i,base)

#define LGAME_STARACTOR_EFFECT_FRAGMENT_END(i,color) \
	LGAME_STARACTOR_FLOW(i,color);
	
//World Clip & Dissolve
#if defined(_WORLD_CLIP)||defined(_DISSOLVE)
float _Dissolve;
sampler2D _DissolveMap;
float4 _DissolveMap_ST;
#endif
//World Clip
#ifdef _WORLD_CLIP
float3 _WorldOrigin;
float3 _WorldTerminal;
float _WorldDirection;
float _WorldClip;
void LGame_Effect_WorldClip(float3 wPos,float4 screenPos)
{
	float2 screenUV = frac(screenPos.xy / screenPos.ww * _DissolveMap_ST.xy + _DissolveMap_ST.zw);
	float Dissolve = tex2Dlod(_DissolveMap, float4(screenUV,0,0)).r * _Dissolve;

	float Dir = sign(0.5f - _WorldDirection);
	float3 OT =_WorldTerminal - _WorldOrigin;
	float3 OW = wPos - _WorldOrigin;
	float3 DirOT = Unity_SafeNormalize(OT);
	float3 DirOW = Unity_SafeNormalize(OW);
	float OWoOT = dot(DirOW, DirOT);
	OW = length(OW) * OWoOT * DirOT ;
	OW = lerp(OW, (OT - OW)* Dir, _WorldDirection);

	float3 OC = (_WorldClip + Dissolve) * OT;
	OC = lerp(OC, (OT  - OC) * Dir, _WorldDirection);
	float c = length(OC) - length(OW);
	clip(c);
}
#define LGAME_STARACTOR_WORLD_CLIP(wPos, ScreenPosition) \
	LGame_Effect_WorldClip(wPos,ScreenPosition);
#else
#define LGAME_STARACTOR_WORLD_CLIP(wPos, ScreenPosition) 
#endif
//Dissolve
#ifdef _DISSOLVE
float _DissolveUVChannel;
float _DissolveClip;
void LGame_Effect_Dissolve(float4 TexCoord)
{
	float2 DissolveUV = lerp(TexCoord.xy, TexCoord.zw, _DissolveUVChannel);
	DissolveUV = TRANSFORM_TEX(DissolveUV, _DissolveMap);
	float Dissolve = tex2D(_DissolveMap, DissolveUV).r * _Dissolve;
	float c = Dissolve - _DissolveClip;
	clip(c);
}
#define LGAME_STARACTOR_DISSOVLE(i) \
	LGame_Effect_Dissolve(i.uv);
#else
#define LGAME_STARACTOR_DISSOVLE(i) 
#endif
//Dither
#ifdef _DITHER
half LGame_Dither_Clip(half4 clipPos, half opacity)
{
	half2 Pos = clipPos.xy;
	half2 DepthGrad = half2(ddx(clipPos.z), ddy(clipPos.z));
	half Dither5 = frac((Pos.x + Pos.y * 2.0 - 1.5) / 5.0);
	half Noise = frac(dot(half2(171.0, 231.0) / 71.0, Pos.xy));
	half Dither = (Dither5 * 5 + Noise) * (1.0 / 6.0);
	half ClipValue = opacity - 0.3333 + Dither;
	clip(ClipValue - 0.5);
	return  saturate(ClipValue);
}
#ifdef _CHIFFON
#define LGAME_STARACTOR_DITHER_CLIP(i,base) \
	base.opacity=LGame_Dither_Clip(i.pos,base.opacity);
#else
#define LGAME_STARACTOR_DITHER_CLIP(i,base) 
#endif
#else
#define LGAME_STARACTOR_DITHER_CLIP(i,base) 
#endif

/*--------------------------------------------------------*/
/*-------------------* FLOW TERM *------------------------*/
/*--------------------------------------------------------*/
#ifdef _FLOW
sampler2D _FlowMap;
sampler2D _MaskTex;
float4 _FlowMap_ST;
fixed4 _FlowColor;
float _FlowUVChannel;
float _FlowSpeedX;
float _FlowSpeedY;
float _CenterRotation;
float2 CenterRotationUV(float2 TexCoord)
{
	float RatationAngle = _CenterRotation * UNITY_TWO_PI;
	float CosAngle;
	float SinAngle;
	sincos(RatationAngle,SinAngle, CosAngle);
	float2x2 Rotation = float2x2(CosAngle, -SinAngle, SinAngle, CosAngle);
	TexCoord = TexCoord - float2(0.5, 0.5);
	TexCoord = mul(Rotation, TexCoord);
	TexCoord += float2(0.5, 0.5);
	return TexCoord;
}
// UV0
half3 LGame_Effect_Flow(float4 TexCoord)
{
	float2 FlowUV = TRANSFORM_TEX(TexCoord.zw, _FlowMap);
	FlowUV += frac(_Time.y * float2(_FlowSpeedX, _FlowSpeedY));
	half3 Flow = tex2D(_FlowMap, frac(FlowUV), float2(0, 0), float2(0, 0)) * _FlowColor;
	float2 RatationUV = CenterRotationUV(TexCoord.xy);
	half Mask = tex2D(_MaskTex, RatationUV);
	return Flow * Mask;
}
// UV0 & UV1 & Screen
float4 ReturnFlowUV(float4 TextureUV,float4 ScreenPosition)
{
	float4 FlowUV = TextureUV.xyxy;
	switch (_FlowUVChannel)
	{
	case 0:
	default:
		FlowUV.zw = TextureUV.xy;
		break;
	case 1:
		FlowUV.zw = TextureUV.zw;
		break;
	case 2:
		FlowUV.zw = ScreenPosition.xy / ScreenPosition.ww;
		break;
	}
	return FlowUV;
}
#define LGAME_STARACTOR_FLOW(i,Color) \
	float4 FlowUV = ReturnFlowUV(i.uv,i.ScreenPosition);\
	Color.rgb += LGame_Effect_Flow(FlowUV);
#else
#define LGAME_STARACTOR_FLOW(i,Color) 
#endif
//Other
half	_MGSyncMotion;
#endif