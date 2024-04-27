Shader  "PhotonShader/Effect/Default_CastShadow" 
{
    Properties
	{
		[HideInInspector]_AlphaCtrl("AlphaCtrl",range(0,1)) = 1
		[HideInInspector][Enum(UnityEngine.Rendering.BlendMode)] 		_SrcFactor ("SrcFactor()", Float) = 5
		[HideInInspector][Enum(UnityEngine.Rendering.BlendMode)] 		_DstFactor ("DstFactor()", Float) = 10
		[HideInInspector][Enum(UnityEngine.Rendering.BlendMode)] 		_SrcAlphaFactor ("SrcAlphaFactor()", Float) = 0
		[HideInInspector][Enum(UnityEngine.Rendering.BlendMode)] 		_DstAlphaFactor ("DstAlphaFactor()", Float) = 10
		[Enum(UnityEngine.Rendering.CullMode)] 							_CullMode ("消隐模式(CullMode)", int) = 0
		[Enum(LessEqual,4,Always,8)]									_ZTestMode ("深度测试(ZTest)", int) = 4
        _Multiplier	("亮度",range(1,20)) = 1

		[SimpleToggle] _ScaleOnCenter("以贴图中心进行uv缩放", Float) = 1
        _MainTex ("MainTex", 2D) = "white" {}
		_Color ("Color", Color) = (1,1,1,1)
		[WrapMode] _MainTexWrapMode ("MainTex wrapMode", Vector) = (1,1,0,0)
        [TexTransform] _MainTexTransform ("MaitTex Transform" , Vector) = (0,0,0,1) //scrollU , scrollV , scrollRot

		[HideInInspector] _StencilComp("Stencil Comparison", Float) = 8
		[HideInInspector] _Stencil("Stencil ID", Float) = 0
		[HideInInspector] _StencilOp("Stencil Operation", Float) = 0
		[HideInInspector] _StencilWriteMask("Stencil Write Mask", Float) = 255
		[HideInInspector] _StencilReadMask("Stencil Read Mask", Float) = 255
		[HideInInspector] _TimeScale("Time Scale", Float) = 1

		
		[Enum(UnityEngine.Rendering.CompareFunction)] _ShadowStencilComp ("Shadow Stencil Compare Func", Int) = 6
		[Enum(UnityEngine.Rendering.StencilOp)] _ShadowStencilOp ("Shadow Stencil Operation", Int) = 2
    }

	CGINCLUDE
		#include "UnityCG.cginc"
		#include "Assets/CGInclude/EffectCG.cginc"

		struct appdata
		{
			float4 vertex : POSITION;
			float2 uv : TEXCOORD0;
			fixed4 vertexColor : COLOR;
			UNITY_VERTEX_INPUT_INSTANCE_ID
		};

		struct fragData
		{
			float2 uv : TEXCOORD0;
			float4 vertex : SV_POSITION;
			float3 worldPos : TEXCOORD1;
			fixed4 vertexColor : TEXCOORD2;
			UNITY_VERTEX_INPUT_INSTANCE_ID
		};

		UNITY_INSTANCING_BUFFER_START (effectAlpha)
			UNITY_DEFINE_INSTANCED_PROP(fixed4, _Color)
#define _Color_arr effectAlpha
			UNITY_DEFINE_INSTANCED_PROP(half ,_AlphaCtrl)
#define _AlphaCtrl_arr effectAlpha
			UNITY_DEFINE_INSTANCED_PROP(half ,_Multiplier)
#define _Multiplier_arr effectAlpha
		UNITY_INSTANCING_BUFFER_END(effectAlpha)

		sampler2D _MainTex;
		UNITY_INSTANCING_BUFFER_START (effectMain)
			UNITY_DEFINE_INSTANCED_PROP(half4 ,_MainTex_ST)
#define _MainTex_ST_arr effectMain
			UNITY_DEFINE_INSTANCED_PROP(half4 ,_MainTexTransform)
#define _MainTexTransform_arr effectMain
			UNITY_DEFINE_INSTANCED_PROP(fixed4 ,_MainTexWrapMode)
#define _MainTexWrapMode_arr effectMain
		UNITY_INSTANCING_BUFFER_END(effectMain)

		fixed _ScaleOnCenter;
		fixed _TimeScale;

		half4 _LightPos;
		fixed4 _ShadowColor;
		fixed4 _SoftShadowColor;

		/////////////
		fragData vert (appdata v)
		{
			fragData o = (fragData)0;
			UNITY_SETUP_INSTANCE_ID(v);
			UNITY_TRANSFER_INSTANCE_ID( v , o);

			o.vertex =  UnityObjectToClipPos(v.vertex);

			o.vertexColor = v.vertexColor; // to support trail

			o.uv = TransFormUV(v.uv, UNITY_ACCESS_INSTANCED_PROP(_MainTex_ST_arr, _MainTex_ST), _ScaleOnCenter);
			o.uv = RotateUV(o.uv, UNITY_ACCESS_INSTANCED_PROP(_MainTexTransform_arr, _MainTexTransform).zw);
			o.uv += frac(_TimeScale * _Time.z * UNITY_ACCESS_INSTANCED_PROP(_MainTexTransform_arr, _MainTexTransform).xy);
			return o;
		}

		fragData shadowVert (appdata v)
		{
			fragData o;
			UNITY_INITIALIZE_OUTPUT(fragData , o);
			UNITY_SETUP_INSTANCE_ID(v);
			UNITY_TRANSFER_INSTANCE_ID( v , o);
			float4 pos = v.vertex;

			//得到阴影的世界空间坐标
			half3 worldPos = mul(unity_ObjectToWorld , pos).xyz;
			o.worldPos = worldPos;
			
			//灯光方向
			fixed3 lightDir = normalize(_LightPos.xyz);

			//阴影的世界空间坐标
			half3 shadowPos;
			shadowPos.y = min(worldPos.y , _LightPos.w);
			shadowPos.xz = worldPos.xz - lightDir.xz * max(0 , worldPos.y - _LightPos.w) / lightDir.y; 

			//转换到裁切空间												 
			o.vertex = UnityWorldToClipPos(shadowPos);

			o.vertexColor = v.vertexColor; // to support trail
		
			o.uv = TransFormUV(v.uv, UNITY_ACCESS_INSTANCED_PROP(_MainTex_ST_arr, _MainTex_ST), _ScaleOnCenter);
			o.uv = RotateUV(o.uv, UNITY_ACCESS_INSTANCED_PROP(_MainTexTransform_arr, _MainTexTransform).zw);
			o.uv += frac(_TimeScale * _Time.z * UNITY_ACCESS_INSTANCED_PROP(_MainTexTransform_arr, _MainTexTransform).xy);
			
			return o;
		}

		fixed4 shadowFrag (fragData i) : SV_Target
		{
			fixed4 color = _ShadowColor * step(_LightPos.w, i.worldPos.y);
			UNITY_SETUP_INSTANCE_ID(i);

			float2 texUV = lerp(i.uv, frac(i.uv), UNITY_ACCESS_INSTANCED_PROP(_MainTexWrapMode_arr, _MainTexWrapMode));

			fixed4 texColor = tex2D(_MainTex, texUV);

			color.a *= UNITY_ACCESS_INSTANCED_PROP(_AlphaCtrl_arr, _AlphaCtrl);
			color.a *= texColor.a;
			color.a *= i.vertexColor.a;

			color.rgb = lerp(fixed3(1,1,1), color.rgb, color.a);

			return color;
		}

	ENDCG

	SubShader
	{
		Tags { "IgnoreProjector"="True" }// "LightMode" = "ForwardBase"
		LOD 100
		Blend [_SrcFactor] [_DstFactor],[_SrcAlphaFactor] [_DstAlphaFactor]
		Cull [_CullMode]
		ZWrite off
		ZTest [_ZTestMode]

		Stencil
		{
			Ref[_Stencil]
			Comp[_StencilComp]
			Pass[_StencilOp]
			ReadMask[_StencilReadMask]
			WriteMask[_StencilWriteMask]
		}

		Pass
		{
			// Display shadow in editor
			Name "EffectShadow"
			Tags { "Queue"="AlphaTest" "RenderType"="AlphaTest" }
			Stencil
			{
				Ref 1
				Comp NotEqual
				Pass Replace
			}
			Blend DstColor Zero
			ZWrite off
			Offset -1, 0

			CGPROGRAM

			#pragma vertex shadowVert
			#pragma fragment shadowFrag
			ENDCG
		}

		Pass
		{
			// main pass
			Tags { "Queue"="Transparent" "LightMode" = "ForwardBase" "RenderType"="Transparent"}
			CGPROGRAM

			#pragma vertex vert
			#pragma fragment frag

			#pragma target 2.0

			fixed4 frag (fragData i) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID(i);

				float2 texUV = lerp(i.uv, frac(i.uv), UNITY_ACCESS_INSTANCED_PROP(_MainTexWrapMode_arr, _MainTexWrapMode));

				fixed4 texColor = tex2D(_MainTex, texUV);
				texColor.rgb *= UNITY_ACCESS_INSTANCED_PROP(_Color_arr, _Color).rgb;	
				texColor *= UNITY_ACCESS_INSTANCED_PROP(_Multiplier_arr, _Multiplier);
				texColor.a *= UNITY_ACCESS_INSTANCED_PROP(_AlphaCtrl_arr, _AlphaCtrl);
				texColor.a = saturate(texColor.a) * i.vertexColor.a;

				return texColor;
			}
			ENDCG
		}
		Pass
		   {
			   // hard shadow pass
			   Name "EffectShadowSrp"
			   Tags { "LightMode" = "CharacterShadowSrp"  "Queue"="AlphaTest" "RenderType"="AlphaTest" }  
			   Stencil
			   {
				   Ref 1
				   Comp [_ShadowStencilComp] //NotEqual
				   Pass [_ShadowStencilOp] //Replace
			   }
			   Blend DstColor Zero
			   ZWrite off
			   Offset -1, 0

			   CGPROGRAM

			   #pragma vertex shadowVert
			   #pragma fragment shadowFrag

			   ENDCG
		   }

		Pass
		{
			// soft shadow pass
			Name "EffectSoftShadowSrp"
			Tags {"LightMode" = "ShadowPrepass" "Queue"="AlphaTest" "RenderType"="AlphaTest" }
			CGPROGRAM

			#pragma vertex shadowVert
			#pragma fragment softShadowFrag

			fixed4 softShadowFrag (fragData i) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID(i);
				fixed4 color = _SoftShadowColor.a * step(_LightPos.w, i.worldPos.y);

			    float2 texUV = lerp(i.uv, frac(i.uv), UNITY_ACCESS_INSTANCED_PROP(_MainTexWrapMode_arr, _MainTexWrapMode));

				fixed4 texColor = tex2D(_MainTex, texUV);

				color *= texColor.a;
				color *= UNITY_ACCESS_INSTANCED_PROP(_AlphaCtrl_arr, _AlphaCtrl);
				color *= i.vertexColor.a;

				return fixed4(0, color.yzw);
			}

			ENDCG
		}
	}

	SubShader
	{
		Tags { "Queue"="Transparent" "LightMode" = "ForwardBase" "IgnoreProjector"="True" "RenderType"="Transparent"}
		LOD 5
		Blend One One
		Cull [_CullMode]
		ZWrite off
		ZTest [_ZTestMode]

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			half4 frag (fragData i) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID(i);
                
				fixed4 texColor = tex2D(_MainTex, i.uv);

				return half4(0.15,0.06,0.03, texColor.a < 0.001);
			}
			ENDCG
		}
	}
}
