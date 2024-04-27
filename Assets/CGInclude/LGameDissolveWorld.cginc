#ifndef LGAME_DISSOLVE_WORLD_INCLUDE
#define LGAME_DISSOLVE_WORLD_INCLUDE

half _IsDissolveSecond;

#if defined(LGAME_DISSOLVE_WORLD) && _ENABLE_DISSOLVE_WORLD
	uniform vector _DissolveWorldPos;		// 溶解世界 - 中心坐标
	uniform float _DissolveWorldRadius;		// 溶解世界 - 半径（控制溶解切换的面积）
	uniform float _DissolveWorldAmount;		// 溶解世界 - 过渡距离（控制过渡边缘效果，默认值0.1）
#endif

// 场景过渡：溶解切换
inline void LGameApplyDissolveWorld(inout float4 finalCol, in float3 worldPos)
{
	// 两个场景动态溶解切换过渡效果
	#if defined(LGAME_DISSOLVE_WORLD) && _ENABLE_DISSOLVE_WORLD
		float3 dis = distance(_DissolveWorldPos, worldPos.xyz); // TODO: 这个后续可以修改为基于相机的距离
		float3 R = 1 - saturate(dis/_DissolveWorldRadius);  // 获取区域面积信息
		if(_IsDissolveSecond == 1) // TODO: 效率优化
		{
			finalCol.a = step(R, _DissolveWorldAmount);
		}
		else
		{
			finalCol.a = step(_DissolveWorldAmount, R);
		}
		// if(finalCol.a == 0)
		// {
		// 	finalCol.rgb = half3(0,0,0);
		// }
		clip(finalCol.a - 0.001);
	#endif
}

#endif