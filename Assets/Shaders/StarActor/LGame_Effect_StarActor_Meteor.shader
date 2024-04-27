Shader "LGame/Effect/StarActor/Meteor"
{
	Properties
	{
		_Color("Color",Color) = (1,1,1,1)
		_Lifetime("Lifetime",Float)=50.0
		_RotateSpeed("Rotate Speed",Float)=1.0
		_RotateRandomSpeed("Rotate Random Speed",Vector) = (1.0,1.0,1.0,0.0)
		_ReMapRatio("ReMap Ratio",Float) = 1.0
		_ReMapConstant("ReMap Constant",Float) = 1.0
	}
	SubShader
	{
		Tags { "Queue" = "Geometry"  "RenderType" = "Opaque"}
		Pass
		{
			Tags{"LightMode" = "Always"}
			LOD 200
			Cull Back
			Zwrite On
			CGPROGRAM
			#pragma target 3.0
			#pragma vertex vert
			#pragma fragment frag			
			#pragma multi_compile _ _FASTEST_QUALITY
			#include "UnityCG.cginc"
			fixed4		_Color;
			float	_RotateSpeed;
			float	_Lifetime;
			float	_ReMapRatio;
			float	_ReMapConstant;
			float3	_RotateRandomSpeed;
			struct a2v
			{
				float4 vertex	: POSITION;
				float4 color	: COLOR;
			};
			struct v2f
			{
				float4 pos		:SV_POSITION;
			};
			//用于替代脚本NcRotation的整体绕Z轴旋转——已验证
			float3 RotateAxisY(float3 vertex)
			{
				float alpha = _Time.y * _RotateSpeed * UNITY_PI / 180.0;
				float sina, cosa;
				sincos(alpha, sina, cosa);
				float2x2 m = float2x2(cosa, -sina, sina, cosa);
				return float3(mul(m, vertex.xz), vertex.y).xzy;
			}
			//简化的随机数算法
			float3 rand(float cox, float coy, float coz)
			{
				return frac(sin(float3(cox, coy, coz)) * 43758.5453);
			}
			//用于替代粒子的个体绕中心旋转
			float3x3 RotateRandom(half seed)
			{
				float3x3 LocalAxis = float3x3(
					1, 0, 0,
					0, 1, 0,
					0, 0, 1
					);
				float seedpi = seed * UNITY_PI;
				float3 RotateRandomSpeed = rand(seed, seedpi, seedpi - seed) * _RotateRandomSpeed;
				float3 alpha = _Time.y * RotateRandomSpeed * 16.0 * UNITY_PI / 180.0;
				float3 sina, cosa;
				sincos(alpha, sina, cosa);
				//优化Alu
				float sinycosz = sina.y * cosa.z;
				float sinysinz = sina.y * sina.z;
				float3x3 m= float3x3(
					cosa.x * cosa.z + sina.x * sinysinz,		sina.z * cosa.y,	-sina.x * cosa.z + cosa.x * sinysinz,
					-cosa.x * sina.z + sina.x * sinycosz,		cosa.z * cosa.y,	sina.z * sina.x + cosa.x * sinycosz,
					sina.x * cosa.y,							-sina.y,			cosa.x * cosa.y
					);
				return mul(LocalAxis, m);
			}
			float3  MoveLocalAxisY(float3 vertex, float sine, float cycle)
			{
				float curve = sine * 0.0011f + 0.0233 * frac(cycle);
				vertex.y += curve * _Lifetime;
				return vertex;
			}
			float3 Max2UnityWithoutPivotCorrection(float3 offset)
			{
				offset.x = -offset.x;
				return offset;
			}
			float3 Max2UnityWithPivotCorrection(float3 offset)
			{
				float pre_y = offset.y;
				offset.x = -offset.x;
				offset.y = offset.z;
				offset.z = -pre_y;
				return offset;
			}
			v2f vert(a2v v, uint vid : SV_VertexID)
			{
				v2f o;
#ifdef _FASTEST_QUALITY
				float3 AfterRotateAxisYPosition = RotateAxisY(v.vertex.xyz);
				o.pos = UnityObjectToClipPos(AfterRotateAxisYPosition);
#else
				float LifetimeInv = 1.0f / _Lifetime;
				float RandomSeed = v.color.w;
				float Cycle =_Time.y * LifetimeInv + RandomSeed;//50秒一个周期
				//计算Size动画
				float ScaleCoefficient = abs(sin(Cycle * UNITY_PI));
				//距离mesh中心点距离
				float3 VertexOffset = v.color.xyz * _ReMapRatio - _ReMapConstant;
				VertexOffset = Max2UnityWithPivotCorrection(VertexOffset);
				//经过计算后，得到mesh中心点的坐标。
				float3 CenterPosition = v.vertex.xyz - VertexOffset.xyz;
				//对中心点的高度进行动画计算
				float3 AfterMoveLocalAxisYPosition = MoveLocalAxisY(CenterPosition, ScaleCoefficient, Cycle);
				//计算整体的绕Z轴旋转
				float3 AfterRotateAxisYPosition = RotateAxisY(AfterMoveLocalAxisYPosition);
				//计算陨石mesh的独立随机旋转
				float3x3 AfterRotateRandomAxis = RotateRandom(RandomSeed);		
				//还原mesh的形状
				float3 AfterAllPosition = AfterRotateAxisYPosition +(VertexOffset.x * AfterRotateRandomAxis[0] + VertexOffset.y *AfterRotateRandomAxis[1] + VertexOffset.z *AfterRotateRandomAxis[2])* ScaleCoefficient;
				o.pos = UnityObjectToClipPos(AfterAllPosition);
#endif
				return o;
			}
			fixed4 frag(v2f i) : SV_Target
			{
				return _Color;
			}
			ENDCG
		}		
	}
}
