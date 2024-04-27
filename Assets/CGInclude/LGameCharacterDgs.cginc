// Upgrade NOTE: upgraded instancing buffer 'outline' to new syntax.
// Upgrade NOTE: excluded shader from OpenGL ES 2.0 because it uses non-square matrices
#pragma exclude_renderers gles

#ifndef LGAME_CHARACTER_DGS_INCLUDE  
#define LGAME_CHARACTER_DGS_INCLUDE

#if _USE_DIRECT_GPU_SKINNING
float4 _SkinedColor;
float4 _meshColor;
float4 _GPUSkinMatrices[216];

inline float3x4 GetMatrix(float index)
{
	int realIndex = int(255 * index + 0.5) * 3;
	return float3x4(_GPUSkinMatrices[realIndex], _GPUSkinMatrices[realIndex + 1], _GPUSkinMatrices[realIndex + 2]);
}

inline float2x4 GetDualQuat(float index)
{
	int realIndex = int(255 * index + 0.5) * 2;
	return float2x4(_GPUSkinMatrices[realIndex], _GPUSkinMatrices[realIndex + 1]);
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


inline float3x3 Quaternion2Matrix(float4 quat)
{
	float3x3 result = 0;

	float xx = quat.x * quat.x;
	float yy = quat.y * quat.y;
	float zz = quat.z * quat.z;
	float xy = quat.x * quat.y;
	float zw = quat.z * quat.w;
	float zx = quat.z * quat.x;
	float yw = quat.y * quat.w;
	float yz = quat.y * quat.z;
	float xw = quat.x * quat.w;

	result._11 = (2.0 * (yy + zz)) - 1.0;
	result._21 = -2.0 * (xy + zw);
	result._31 = -2.0 * (zx - yw);
	result._12 = -2.0 * (xy - zw);
	result._22 = (2.0 * (zz + xx)) - 1.0;
	result._32 = -2.0 * (yz + xw);
	result._13 = -2.0 * (zx + yw);
	result._23 = -2.0 * (yz - xw);
	result._33 = (2.0 * (yy + xx)) - 1.0;

	return result;
}

float4 _uvBoundData;
float4 _posBoundMin;
float4 _posBoundSize;

inline float2 DecompressUV(float2 compressedUV, float4 bound)
{
	return compressedUV * bound.zw + bound.xy;
	//float2 outUV;

	//compressedUV *= 255;
	//outUV.x = compressedUV.x + compressedUV.z * 256;
	//outUV.y = compressedUV.y + compressedUV.w * 256;
	//outUV = (outUV / 65535) * bound.zw + bound.xy;    

	//return outUV;
}

inline float4 DecompressPosition(float4 float16Pos, float4 boundMin, float4 boundSize)
{
	return float4((float16Pos * boundSize + boundMin).xyz, 1);
	//return float16Pos;
}

inline void DecompressTangentNormal(half4 source, out float4 tangent, out float3 normal, out float3 binormal)
{
	float4 quat = source * 2 - 1;
	float3x3 mat = Quaternion2Matrix(quat);
	tangent.w = quat.w < 0 ? -1 : 1;
	tangent.xyz = float3(mat._31, mat._21, mat._11) * tangent.w;
	binormal = float3(mat._32, mat._22, mat._12) * tangent.w;
	normal = float3(mat._33, mat._23, mat._13) * tangent.w;
}

inline float4 CalculateGPUSkin_L(float4 skinIndices, float4 skinWeights, half4 vertex)
{
	float4 vecPos = DecompressPosition(vertex, _posBoundMin, _posBoundSize);

#if !_USE_DUAL_QUAT
	float3x4 blendMatrix = GetMatrix(skinIndices.x) * skinWeights.x + GetMatrix(skinIndices.y) * skinWeights.y +
		GetMatrix(skinIndices.z) * skinWeights.z + GetMatrix(skinIndices.w) * skinWeights.w;

	float4x4 finalMatrix = float4x4(blendMatrix, float4(0, 0, 0, 1));

	float4 pos = mul(finalMatrix, vecPos);
#else
	half2x4 q0 = GetDualQuat(skinIndices.x);
	half2x4 q1 = GetDualQuat(skinIndices.y);
	half2x4 q2 = GetDualQuat(skinIndices.z);
	half2x4 q3 = GetDualQuat(skinIndices.w);

	half2x4 blendDualQuat = q0 * skinWeights.x;
	if (dot(q0[0], q1[0]) > 0)
		blendDualQuat += q1 * skinWeights.y;
	else
		blendDualQuat -= q1 * skinWeights.y;

	if (dot(q0[0], q2[0]) > 0)
		blendDualQuat += q2 * skinWeights.z;
	else
		blendDualQuat -= q2 * skinWeights.z;

	if (dot(q0[0], q3[0]) > 0)
		blendDualQuat += q3 * skinWeights.w;
	else
		blendDualQuat -= q3 * skinWeights.w;

	blendDualQuat = NormalizeDualQuat(blendDualQuat);

	float4 pos = float4(TransformFromDualQuat(blendDualQuat, vecPos.xyz), 1);
#endif

	return pos;
}

inline float4 CalculateGPUSkin(float4 skinIndices, float4 skinWeights, half4 vertex, inout half4 tangent, inout half3 normal, inout half3 binormal)
{
	float4 vecPos = DecompressPosition(vertex, _posBoundMin, _posBoundSize);

#if !_USE_DUAL_QUAT
	float3x4 blendMatrix = GetMatrix(skinIndices.x) * skinWeights.x + GetMatrix(skinIndices.y) * skinWeights.y +
		GetMatrix(skinIndices.z) * skinWeights.z + GetMatrix(skinIndices.w) * skinWeights.w;

	float4x4 finalMatrix = float4x4(blendMatrix, float4(0, 0, 0, 1));

	float4 pos = mul(finalMatrix, vecPos);
	tangent.xyz = (finalMatrix._m00_m10_m20 * -tangent.z + finalMatrix._m01_m11_m21 * -tangent.y + finalMatrix._m02_m12_m22 * -tangent.x);
	normal = (finalMatrix._m00_m10_m20 * -normal.z + finalMatrix._m01_m11_m21* -normal.y + finalMatrix._m02_m12_m22 * -normal.x);
	binormal = (finalMatrix._m00_m10_m20 * -binormal.z + finalMatrix._m01_m11_m21* -binormal.y + finalMatrix._m02_m12_m22 * -binormal.x);
#else
	half2x4 q0 = GetDualQuat(skinIndices.x);
	half2x4 q1 = GetDualQuat(skinIndices.y);
	half2x4 q2 = GetDualQuat(skinIndices.z);
	half2x4 q3 = GetDualQuat(skinIndices.w);

	half2x4 blendDualQuat = q0 * skinWeights.x;
	if (dot(q0[0], q1[0]) > 0)
		blendDualQuat += q1 * skinWeights.y;
	else
		blendDualQuat -= q1 * skinWeights.y;

	if (dot(q0[0], q2[0]) > 0)
		blendDualQuat += q2 * skinWeights.z;
	else
		blendDualQuat -= q2 * skinWeights.z;

	if (dot(q0[0], q3[0]) > 0)
		blendDualQuat += q3 * skinWeights.w;
	else
		blendDualQuat -= q3 * skinWeights.w;

	blendDualQuat = NormalizeDualQuat(blendDualQuat);

	float4 pos = float4(TransformFromDualQuat(blendDualQuat, vecPos.xyz), 1);
	tangent.xyz = TransformFromDualQuat(blendDualQuat, tangent.xyz);
	normal = TransformFromDualQuat(blendDualQuat, normal);
	binormal = TransformFromDualQuat(blendDualQuat, binormal);
#endif

	return pos;
}

#endif

#endif  