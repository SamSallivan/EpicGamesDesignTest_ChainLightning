// Upgrade NOTE: upgraded instancing buffer 'character' to new syntax.

Shader "LGame/Character/ShadowAnimMap"
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
    half4 _LightPos;
	fixed4 _ShadowColor;

	struct v2f_simplest
	{
		float4 vertex : SV_POSITION;
	};
	struct v2f
	{
		float4 vertex : SV_POSITION;
        fixed4 color : COLOR;
		UNITY_VERTEX_INPUT_INSTANCE_ID
	};
	UNITY_INSTANCING_BUFFER_START (character)
		UNITY_DEFINE_INSTANCED_PROP (half, _ShadowFalloff)
#define _ShadowFalloff_arr character
		UNITY_DEFINE_INSTANCED_PROP (half, _AlphaCtrl)
#define _AlphaCtrl_arr character
	UNITY_INSTANCING_BUFFER_END(character)

	v2f_simplest vert_simplest (appdata_simplest v)
	{
		v2f_simplest o;
		o.vertex = UnityObjectToClipPos(v.vertex);
		return o;
	}
	v2f vert_alpha (appdata_simplest v,uint vid : SV_VertexID)
	{
		v2f o;
				
		UNITY_SETUP_INSTANCE_ID(v);
		UNITY_TRANSFER_INSTANCE_ID( v , o);

		float4 pos = AnimMapVertex(vid);
				
		pos = tex2Dlod(_AnimMap, pos);

        //得到阴影的世界空间坐标
        half3 shadowPos = ShadowProjectPos(pos,_LightPos);

        //转换到裁切空间
        o.vertex = UnityWorldToClipPos(shadowPos);

        //得到中心点世界坐标
        //half3 center =half3( unity_ObjectToWorld[0].w , _LightPos.w , unity_ObjectToWorld[2].w);

        //计算阴影衰减
        //half falloff = 1-saturate(distance(shadowPos , center) * UNITY_ACCESS_INSTANCED_PROP(_ShadowFalloff_arr, _ShadowFalloff));

        //阴影颜色
        o.color = _ShadowColor; 
		o.color.a *=  UNITY_ACCESS_INSTANCED_PROP(_AlphaCtrl_arr, _AlphaCtrl);

		return o;
	}
	v2f vert (appdata_simplest v,uint vid : SV_VertexID)
	{
		v2f o;

		UNITY_SETUP_INSTANCE_ID(v);
		UNITY_TRANSFER_INSTANCE_ID( v , o);

		float4 pos = AnimMapVertex(vid);
				
		pos = tex2Dlod(_AnimMap, pos);

        //得到阴影的世界空间坐标
        half3 shadowPos = ShadowProjectPos(pos,_LightPos);

        //转换到裁切空间
        o.vertex = UnityWorldToClipPos(shadowPos);

        //得到中心点世界坐标
        //half3 center =half3( unity_ObjectToWorld[0].w , _LightPos.w , unity_ObjectToWorld[2].w);

        //计算阴影衰减
        //half falloff = 1-saturate(distance(shadowPos , center) * UNITY_ACCESS_INSTANCED_PROP(_ShadowFalloff_arr, _ShadowFalloff));

        //阴影颜色
        o.color = _ShadowColor; 
		//o.color.a *= falloff;

		return o;
	}	
	fixed4 frag_simplest (v2f_simplest i) : SV_Target
	{
		return _MainCol;
	}
			
	fixed4 frag (v2f i) : SV_Target
	{
		return i.color;
	}
	ENDCG

	SubShader
	{
		Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" }
		//渲染本身的pass
        Pass
		{
            Name "ForwardBase"
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
            Stencil
            {
                Ref 0
                Comp equal
                Pass incrWrap
                Fail keep
                ZFail keep
            }

            //透明混合模式
            Blend SrcAlpha OneMinusSrcAlpha

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
            Stencil
            {
                Ref 0
                Comp equal
                Pass incrWrap
                Fail keep
                ZFail keep
            }

            //透明混合模式
            Blend SrcAlpha OneMinusSrcAlpha

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
	}
}