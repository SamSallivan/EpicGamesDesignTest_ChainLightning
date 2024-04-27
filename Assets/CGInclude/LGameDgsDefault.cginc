#ifndef LGAME_DGSDEFAULT_INCLUDED
#define LGAME_DGSDEFAULT_INCLUDED

#include "Assets/CGInclude/LGameCharacterDgs.cginc"

struct appdata_dgs
{
	float4	vertex		: POSITION;
#ifdef _USE_DIRECT_GPU_SKINNING
	float4 skinIndices	: TEXCOORD2;
	float4 skinWeights	: TEXCOORD3;
#endif
};
struct v2f_dgs
{
	float4 pos : SV_POSITION;
};

v2f_dgs vert_dgs(appdata_dgs v)
{
	v2f_dgs o;
#if _USE_DIRECT_GPU_SKINNING
	v.vertex = CalculateGPUSkin_L(v.skinIndices, v.skinWeights, v.vertex);
#endif
	o.pos = UnityObjectToClipPos(v.vertex);
	return o;
}

fixed4 frag_dgs(v2f_dgs i) : SV_Target
{
	return fixed4(1,1,1,1);
}

#endif