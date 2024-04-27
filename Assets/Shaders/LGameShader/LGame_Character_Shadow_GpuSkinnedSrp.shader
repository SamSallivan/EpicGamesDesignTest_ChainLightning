// Upgrade NOTE: upgraded instancing buffer 'character' to new syntax.

Shader "LGame/Character/Shadow_GpuSkinned Srp"
{
	Properties
	{
		_MainCol ("Color", Color) = (0,0,0,0)//自身颜色
	
        //_ShadowColor("Shadow Color" , Color) = (0,0,0,0)//阴影颜色
        //_ShadowDir("Light Diretion" , vector) = (-1,1,0,0)//灯光方向
        _ShadowFalloff("Shadow Falloff" , Range(0.01,1)) = 1//阴影衰减
	}
	CGINCLUDE
				
			#include "UnityCG.cginc"
			#include "Assets/CGInclude/LGameCG.cginc"
			#include "Assets/CGInclude/GpuAnim.cginc"
            fixed4 _MainCol;

			struct v2f_simplest
			{
				float4 vertex : SV_POSITION;
			};

			v2f_simplest vert_simplest (appdata_simplest v)
			{
				v2f_simplest o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				return o;
			}
			
			fixed4 frag_simplest (v2f_simplest i) : SV_Target
			{
				return _MainCol;
			}

			struct v2f
			{
				float4 vertex : SV_POSITION;
                fixed4 color : COLOR;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

            half4 _LightPos;
			fixed4 _ShadowColor;
			fixed4 _SoftShadowColor;
			UNITY_INSTANCING_BUFFER_START (character)
				UNITY_DEFINE_INSTANCED_PROP (half, _ShadowFalloff)
#define _ShadowFalloff_arr character
				UNITY_DEFINE_INSTANCED_PROP (half, _AlphaCtrl)
#define _AlphaCtrl_arr character
			UNITY_INSTANCING_BUFFER_END(character)

            

			v2f vert (appdata_uv3_gpu v)
			{
				v2f o;

				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID( v , o);

				float posX = GpuSkinUvX();

				half2x4 q0 = GetDualQuat(posX, v.uv2.x);
				half2x4 q1 = GetDualQuat(posX, v.uv2.z);
				half2x4 q2 = GetDualQuat(posX, v.uv3.x);
				half2x4 q3 = GetDualQuat(posX, v.uv3.z);

				half2x4 blendDualQuat = q0 * v.uv2.y;
				if (dot(q0[0], q1[0]) > 0)
					blendDualQuat += q1 * v.uv2.w;
				else
					blendDualQuat -= q1 * v.uv2.w;

				if (dot(q0[0], q2[0]) > 0)
					blendDualQuat += q2 * v.uv3.y;
				else
					blendDualQuat -= q2 * v.uv3.y;

				if (dot(q0[0], q3[0]) > 0)
					blendDualQuat += q3 * v.uv3.w;
				else
					blendDualQuat -= q3 * v.uv3.w;

				blendDualQuat = NormalizeDualQuat(blendDualQuat);

				float4 pos = float4(TransformFromDualQuat(blendDualQuat, v.vertex), 1);

				//得到阴影的世界空间坐标
                half3 shadowPos = ShadowProjectPos(pos,_LightPos);

                //转换到裁切空间
                o.vertex = UnityWorldToClipPos(shadowPos);

                //阴影颜色
				o.color.a = _ShadowColor.a;
                o.color.rgb = lerp(1.0.xxx , _ShadowColor.rgb , o.color.a);
				return o;
			}
			v2f vert_alpha (appdata_uv3_gpu v)
			{
				v2f o;
				
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID( v , o);

				float posX = GpuSkinUvX();

				half2x4 q0 = GetDualQuat(posX, v.uv2.x);
				half2x4 q1 = GetDualQuat(posX, v.uv2.z);
				half2x4 q2 = GetDualQuat(posX, v.uv3.x);
				half2x4 q3 = GetDualQuat(posX, v.uv3.z);

				half2x4 blendDualQuat = q0 * v.uv2.y;
				if (dot(q0[0], q1[0]) > 0)
					blendDualQuat += q1 * v.uv2.w;
				else
					blendDualQuat -= q1 * v.uv2.w;

				if (dot(q0[0], q2[0]) > 0)
					blendDualQuat += q2 * v.uv3.y;
				else
					blendDualQuat -= q2 * v.uv3.y;

				if (dot(q0[0], q3[0]) > 0)
					blendDualQuat += q3 * v.uv3.w;
				else
					blendDualQuat -= q3 * v.uv3.w;

				blendDualQuat = NormalizeDualQuat(blendDualQuat);

				float4 pos = float4(TransformFromDualQuat(blendDualQuat, v.vertex), 1);

                //得到阴影的世界空间坐标
                half3 shadowPos = ShadowProjectPos(pos,_LightPos);

                //转换到裁切空间
                o.vertex = UnityWorldToClipPos(shadowPos);

                //阴影颜色
				o.color.a = _ShadowColor.a * UNITY_ACCESS_INSTANCED_PROP(_AlphaCtrl_arr, _AlphaCtrl);
                o.color.rgb = lerp(1.0.xxx , _ShadowColor.rgb , o.color.a);
				return o;
			}
			v2f vert_soft(appdata_uv3_gpu v)
			{
				v2f o;

				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);

				float posX = GpuSkinUvX();

				half2x4 q0 = GetDualQuat(posX, v.uv2.x);
				half2x4 q1 = GetDualQuat(posX, v.uv2.z);
				half2x4 q2 = GetDualQuat(posX, v.uv3.x);
				half2x4 q3 = GetDualQuat(posX, v.uv3.z);

				half2x4 blendDualQuat = q0 * v.uv2.y;
				if (dot(q0[0], q1[0]) > 0)
					blendDualQuat += q1 * v.uv2.w;
				else
					blendDualQuat -= q1 * v.uv2.w;

				if (dot(q0[0], q2[0]) > 0)
					blendDualQuat += q2 * v.uv3.y;
				else
					blendDualQuat -= q2 * v.uv3.y;

				if (dot(q0[0], q3[0]) > 0)
					blendDualQuat += q3 * v.uv3.w;
				else
					blendDualQuat -= q3 * v.uv3.w;

				blendDualQuat = NormalizeDualQuat(blendDualQuat);

				float4 pos = float4(TransformFromDualQuat(blendDualQuat, v.vertex), 1);

				//得到阴影的世界空间坐标
				half3 shadowPos = ShadowProjectPos(pos, _LightPos);

				//转换到裁切空间
				o.vertex = UnityWorldToClipPos(shadowPos);

				o.color.a = _SoftShadowColor.a;
				return o;
			}
			fixed4 frag (v2f i) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID(i);
				return i.color;
			}
			fixed4 frag_soft(v2f i) : SV_Target
			{
				fixed4 col = i.color.a;
				return float4(0.0f, col.yzw);
			}
	ENDCG
	SubShader
	{
		Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" }
		//渲染本身的pass
        Pass
		{
            Name "ForwardBase"
			Tags { "LightMode" = "CharacterDefault"}
			//透明混合模式
            Blend SrcAlpha OneMinusSrcAlpha
            //关闭深度写入
            ZWrite off

			CGPROGRAM
			#pragma vertex vert_simplest
			#pragma fragment frag_simplest

			ENDCG
		}

        //阴影pass
		Pass
		{
            Name "Shadow"
			Tags { "LightMode" = "CharacterShadowSrp"}
            Stencil
            {
                Ref 0
                Comp equal
                Pass incrWrap
                Fail keep
                ZFail keep
            }

            //透明混合模式
            Blend DstColor Zero

			//阴影不写入a通道
			//ColorMask rgb

            //关闭深度写入
            ZWrite off

            //深度稍微偏移防止阴影与自己穿插
            Offset -1 , 0

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			//#pragma multi_compile_instancing
			//#pragma instancing_options forcemaxcount:32
			
			
			ENDCG
		}

		//半透明材质的阴影pass
		Pass
		{
            Name "TransparentShadow"
			Tags { "LightMode" = "CharacterShadowSrp"}
            Stencil
            {
                Ref 0
                Comp equal
                Pass incrWrap
                Fail keep
                ZFail keep
            }

            //透明混合模式
            Blend DstColor Zero

            //关闭深度写入
            ZWrite off

            //深度稍微偏移防止阴影与自己穿插
            Offset -1 , 0

			//阴影不写入a通道
			//ColorMask rgb

			CGPROGRAM
			#pragma vertex vert_alpha
			#pragma fragment frag
			//#pragma multi_compile_instancing
			//#pragma instancing_options forcemaxcount:32

			
			ENDCG
		}
		//软阴影pass
		Pass
		{
            Name "CharacterShadowSrp"
			Tags { "LightMode" = "ShadowPrepass"}

			CGPROGRAM
			#pragma vertex vert_soft
			#pragma fragment frag_soft
			ENDCG
		}
	}
}