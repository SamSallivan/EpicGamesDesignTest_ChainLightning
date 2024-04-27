// Upgrade NOTE: upgraded instancing buffer 'animmap' to new syntax.

#ifndef GPU_ANIM_INCLUDE  
#define GPU_ANIM_INCLUDE

uniform sampler2D	_AnimMap;
uniform float4 		_AnimMap_TexelSize;

UNITY_INSTANCING_BUFFER_START (animmap)
    UNITY_DEFINE_INSTANCED_PROP (float, _AnimTime)
#define _AnimTime_arr animmap
    UNITY_DEFINE_INSTANCED_PROP (float, _PauseTime)
#define _PauseTime_arr animmap
	UNITY_DEFINE_INSTANCED_PROP (float, _AnimSpeed)
#define _AnimSpeed_arr animmap
	UNITY_DEFINE_INSTANCED_PROP (float, _padding)

	UNITY_DEFINE_INSTANCED_PROP (float4 , _PlayVector)
#define _PlayVector_arr animmap
UNITY_INSTANCING_BUFFER_END(animmap)

float4 AnimMapVertex(uint vid)
{
	//暂停动画标记
	float pauseFlag = step(0,UNITY_ACCESS_INSTANCED_PROP(_PauseTime_arr, _PauseTime));

	//计算时间偏移量
	float f =((_Time.y - UNITY_ACCESS_INSTANCED_PROP(_AnimTime_arr, _AnimTime))*(1-pauseFlag) + UNITY_ACCESS_INSTANCED_PROP(_PauseTime_arr, _PauseTime)*pauseFlag)/UNITY_ACCESS_INSTANCED_PROP(_PlayVector_arr, _PlayVector).z;

	//超出播放时间标记
	float overTime = step(1.0 , f);

	//取余
	f = fmod(f, 1.0);

	//计算考虑循环与否的播放时间
	f = UNITY_ACCESS_INSTANCED_PROP(_PlayVector_arr, _PlayVector).w *f + (overTime+(1-overTime)*f)*(1-UNITY_ACCESS_INSTANCED_PROP(_PlayVector_arr, _PlayVector).w);

	//uv坐标换算成像素坐标，需要+0.5
	float animMap_x = (vid + 0.5) * _AnimMap_TexelSize.x;
	float animMap_y = f*UNITY_ACCESS_INSTANCED_PROP(_PlayVector_arr, _PlayVector).y + 0.5 * _AnimMap_TexelSize.y;
	animMap_y += UNITY_ACCESS_INSTANCED_PROP(_PlayVector_arr, _PlayVector).x;

	return float4(animMap_x, animMap_y, 0, 0);
}

float GpuSkinUvX()
{
    //暂停动画标记
	float pauseFlag = step(0,UNITY_ACCESS_INSTANCED_PROP(_PauseTime_arr, _PauseTime));

	//计算时间偏移量
	float f =((_Time.y - UNITY_ACCESS_INSTANCED_PROP(_AnimTime_arr, _AnimTime))*(1-pauseFlag) + UNITY_ACCESS_INSTANCED_PROP(_PauseTime_arr, _PauseTime)*pauseFlag)/UNITY_ACCESS_INSTANCED_PROP(_PlayVector_arr, _PlayVector).z;
	
	f *= UNITY_ACCESS_INSTANCED_PROP(_AnimSpeed_arr, _AnimSpeed);
	//超出播放时间标记
	float overTime = step(1.0 , f);
	//取余
	f = fmod(f, 1.0);

	//计算考虑循环与否的播放时间
	f = UNITY_ACCESS_INSTANCED_PROP(_PlayVector_arr, _PlayVector).w *f + (overTime+(1-overTime)*f)*(1-UNITY_ACCESS_INSTANCED_PROP(_PlayVector_arr, _PlayVector).w);

	//uv坐标换算成像素坐标，需要+0.5
	float animMap_x = f*UNITY_ACCESS_INSTANCED_PROP(_PlayVector_arr, _PlayVector).y + 0.5 * _AnimMap_TexelSize.x;
	animMap_x += UNITY_ACCESS_INSTANCED_PROP(_PlayVector_arr, _PlayVector).x;

	return animMap_x;
}

inline float IndexToUV(half index)
{
	float row = (index+0.5) * _AnimMap_TexelSize.y;

	return row;
}

inline half4x4 GetMatrix(float x, half index)
{
	half matStartIndex = index * 3;
	half4 row0 = tex2Dlod(_AnimMap, float4(x,IndexToUV(matStartIndex),0,0));
	half4 row1 = tex2Dlod(_AnimMap, float4(x,IndexToUV(matStartIndex+1),0,0));
	half4 row2 = tex2Dlod(_AnimMap, float4(x,IndexToUV(matStartIndex+2),0,0));
	half4x4 mat = half4x4(row0, row1, row2, half4(0, 0, 0, 1));
	return mat;
}

inline half2x4 GetDualQuat(float x, half index)
{
	half matStartIndex = index * 2;
	half4 row0 = tex2Dlod(_AnimMap, float4(x, IndexToUV(matStartIndex), 0, 0));
	half4 row1 = tex2Dlod(_AnimMap, float4(x, IndexToUV(matStartIndex + 1), 0, 0));
	half2x4 quat = half2x4(row0, row1);
	return quat;
}

inline half2x4 NormalizeDualQuat(half2x4 dualQuat)
{
	float len = length(dualQuat[0]);
	dualQuat[0] /= len;
	dualQuat[1] /= len;
	return dualQuat;
}

inline float3 TransformFromDualQuat(half2x4 dualQuat, float3 p)
{
	float3 trans = 2.0*(dualQuat[0].w*dualQuat[1].xyz - dualQuat[1].w*dualQuat[0].xyz + cross(dualQuat[0].xyz, dualQuat[1].xyz));
	float3 position = p + 2.0*cross(dualQuat[0].xyz, cross(dualQuat[0].xyz, p) + dualQuat[0].w*p);
	return position + trans;
}

#endif  