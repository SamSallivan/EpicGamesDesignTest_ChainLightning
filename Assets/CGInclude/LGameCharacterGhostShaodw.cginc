#ifndef LGAME_CHARACTER_GHOSTSHADOW_INCLUDE
	#define LGAME_CHARACTER_GHOSTSHADOW_INCLUDE
	#pragma exclude_renderers gles
	#include "UnityCG.cginc"
	#include "Assets/CGInclude/LGameCharacterDgs.cginc" 

	fixed4		_GhostColor;
	fixed4		_GhostEndColor;
	half4		_GhostVector;
	half4		_GhostVector2;
	half		_GhostScale;
	half		_AlphaCtrl;
	half		_MultiVector;
	half		_GhostRimLightMultipliers;
	half		_DepthOffset;

	struct a2v
	{
		float4 vertex : POSITION;
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
		float4 pos	: SV_POSITION;
	    fixed4 color	: COLOR;
	};

	float Pow2(float x )
	{
		return x*x;
	}
	v2f vert (a2v v)
	{
		v2f o;
		UNITY_INITIALIZE_OUTPUT(v2f, o);
		float4 ghostPos = v.vertex;
		float3 normal;
		#if _USE_DIRECT_GPU_SKINNING
			float4 tangent;
			float3 binormal;
			DecompressTangentNormal(v.tangent, tangent, normal, binormal);
			ghostPos = CalculateGPUSkin(v.skinIndices, v.skinWeights, v.vertex, tangent, normal, binormal);
		#else
			normal = v.normal;
		#endif

		half4 offsetVector = (GHOST_OFFSET * _MultiVector)?_GhostVector2:_GhostVector;
		half posOffset = frac(_Time.y * offsetVector.w + GHOST_OFFSET * 0.5);

		ghostPos.xyz *= lerp(1  , _GhostScale , posOffset);
		ghostPos.xyz += offsetVector.xyz * posOffset;

		o.pos = UnityObjectToClipPos(ghostPos);

		fixed3 worldNormal = UnityObjectToWorldNormal(normal);
		fixed3 worldViewDir = normalize(WorldSpaceViewDir(ghostPos));
		half fresnel = 1 - abs(dot(worldViewDir, worldNormal));
		//o.color.a = fresnel * fresnel;
		half rimliht =(_GhostRimLightMultipliers > 0 )? pow(fresnel ,_GhostRimLightMultipliers) :1 ;
		o.color = lerp( _GhostColor ,_GhostEndColor ,_MultiVector?GHOST_OFFSET:posOffset) * rimliht;
		o.color.rgb *= o.color.a * _AlphaCtrl *  (1-Pow2(posOffset*2-1));
		
		#if defined(UNITY_REVERSED_Z)
		o.pos.z += _DepthOffset;
		#else
		o.pos.z -= _DepthOffset;
		#endif
		return o;
	}
	fixed4 frag (v2f i) : SV_Target
	{
		return  i.color;
	}
#endif  