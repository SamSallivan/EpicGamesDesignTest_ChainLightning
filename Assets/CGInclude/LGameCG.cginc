// Upgrade NOTE: upgraded instancing buffer 'outline' to new syntax.

#ifndef LGAME_CG_INCLUDE  
#define LGAME_CG_INCLUDE

inline half3 ShadowProjectPos(float4 vertDir,half4 lightPos)
 {
    half3 shadowPos;

    //得到顶点的世界空间坐标
    half3 wPos = mul(unity_ObjectToWorld , vertDir).xyz;
                
    //灯光方向
    fixed3 lightDir = normalize(lightPos.xyz);

    //阴影的世界空间坐标
    shadowPos.y = min(wPos.y , lightPos.w);
	shadowPos.xz = wPos.xz - lightDir.xz * max(0 , wPos.y - lightPos.w) / lightDir.y; 

    //低于地面的部分不计算阴影
    //shadowPos = lerp( shadowPos , wPos , step(wPos.y - _ShadowDir.w , 0));
	return shadowPos;
}

struct appdata_simplest
{
	float4 vertex : POSITION;
	UNITY_VERTEX_INPUT_INSTANCE_ID
};
struct appdata_simple
{
	float4 vertex : POSITION;
	half2 texcoord : TEXCOORD0;
	UNITY_VERTEX_INPUT_INSTANCE_ID
};
struct appdata_uv2
{
	float4 vertex : POSITION;
	half2 texcoord : TEXCOORD0;
    half4 uv2: TEXCOORD1;
	UNITY_VERTEX_INPUT_INSTANCE_ID
};
struct appdata_uv3
{
	float4 vertex : POSITION;
    half4 uv2: TEXCOORD1;
	half4 uv3: TEXCOORD2;
	UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct appdata_uv3_gpu
{
	float4 vertex : POSITION;
	half2 texcoord : TEXCOORD0;
	half4 uv2: TEXCOORD1;
	half4 uv3: TEXCOORD2;
	UNITY_VERTEX_INPUT_INSTANCE_ID
};

inline half2 SimpleMatcapUV (half3 modelNormal)	
{
	 return normalize(mul((float3x3)UNITY_MATRIX_MV, modelNormal)).xy * 0.5 + 0.5 ;
}

UNITY_INSTANCING_BUFFER_START (outline)
	UNITY_DEFINE_INSTANCED_PROP (fixed , _HightLightValue)
#define _HightLightValue_arr outline
UNITY_INSTANCING_BUFFER_END(outline)

inline half GetOulineValue()
{
	return (frac(half(unity_ObjectToWorld[2].w)) * 0.7 + 0.2) * (1-UNITY_ACCESS_INSTANCED_PROP(_HightLightValue_arr, _HightLightValue));
}


//顶点边缘光
fixed4		_RimLightColor;
half		_RimLighRange ;
half		_RimLighMultipliers ;

inline fixed3 GetRimLight(fixed3 worldNormal , fixed3 worldViewDir)
{
	return (1-pow(abs( dot(worldViewDir, worldNormal) ), _RimLighRange)) * _RimLightColor.rgb * _RimLighMultipliers;
}


//金属反射
sampler2D	_MatCap;
fixed4		_MatCapColor ;
half		_MatCapIntensity;
half		_DiffuseIntensity;

inline half2 GetMatCapUv(fixed3 worldNormal)
{
	return normalize(mul(UNITY_MATRIX_V, float4(worldNormal,0)).xyz) *0.5;
}

inline half3 GetMapCap(half2 uv)
{
	half3 matcap = _MatCapColor.rgb * _MatCapIntensity * tex2D(_MatCap , uv + 0.5);
	matcap = (_DiffuseIntensity + matcap ) * _MatCapIntensity * _MatCapColor;

	return matcap;
}

#endif  