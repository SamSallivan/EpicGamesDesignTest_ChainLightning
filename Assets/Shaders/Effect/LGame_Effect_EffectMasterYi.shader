Shader "LGame/Effect/EffectMasterYi"
{
	Properties
	{
		_Color				("Color" , Color) = (1,1,1,1)
		_MainTex			("Texture", 2D) = "white" {}
		_EffectCol			("Effect Color" , Color) = (0.4,0.1,0,0)
		_InfoVetor			("Info(xy for Tilling , yw for flow speed)" , vector) = (1,1,10,0)
		_VertOffset			("Vert Offset" , float) = 0.2

	}
	SubShader
	{
		Tags {"Queue"="AlphaTest"  "RenderType"="Transparent"}
		LOD 100
		//默认管线预览阴影Pass
		Pass
		{
			Name "PreviewMasterYiGostShadow"
			Blend One One
			ZTest Always
			ZWrite On
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile __ _USE_DIRECT_GPU_SKINNING
			#include "UnityCG.cginc"
			#include "Assets/CGInclude/LGameCharacterDgs.cginc" 
			struct appdata
			{
				float4 vertex				: POSITION;
				float4 texcoord				: TEXCOORD0;
#ifdef _USE_DIRECT_GPU_SKINNING
				half4 tangent				: TANGENT;
				float4 skinIndices			: TEXCOORD2;
				float4 skinWeights			: TEXCOORD3;
#else
				float3 normal				: NORMAL;
#endif
			};

			struct v2f
			{
				float4 vertex				: SV_POSITION;
			};
			fixed4							_EffectCol;
			half							_VertOffset;
			v2f vert (appdata v)
			{
				v2f o;
				UNITY_INITIALIZE_OUTPUT(v2f, o);
				float4 pos = v.vertex;
				float3 normal;
#if _USE_DIRECT_GPU_SKINNING
				float4 tangent;
				float3 binormal;
				DecompressTangentNormal(v.tangent, tangent, normal, binormal);
				pos = CalculateGPUSkin(v.skinIndices, v.skinWeights, v.vertex, tangent, normal, binormal);
				v.texcoord.xy = DecompressUV(v.texcoord.xy, _uvBoundData);
#else
				normal = v.normal;
#endif
				o.vertex = UnityObjectToClipPos(pos + float4(0,0,_VertOffset,0));
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				return _EffectCol;
			}
			ENDCG
		}
		//默认管线预览角色Pass
		Pass
		{
			Name "PreviewMasterYiScreenPass"
			Blend One Zero
			ZTest Always
			ZWrite On
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile __ _USE_DIRECT_GPU_SKINNING
			#include "UnityCG.cginc"
			#include "Assets/CGInclude/LGameCharacterDgs.cginc"
			struct appdata
			{
				float4 vertex				: POSITION;
				float4 texcoord				: TEXCOORD0;
#ifdef _USE_DIRECT_GPU_SKINNING
				half4 tangent				: TANGENT;
				float4 skinIndices			: TEXCOORD2;
				float4 skinWeights			: TEXCOORD3;
#else
				float3 normal				: NORMAL;
#endif
			};

			struct v2f
			{
				float4 vertex				: SV_POSITION;
				float4 srcPos				: TEXCOORD0;
			};

			sampler2D						_MainTex;
			half4							_Color;
			half4							_InfoVetor;
			v2f vert (appdata v)
			{
				v2f o;
				UNITY_INITIALIZE_OUTPUT(v2f, o);
				float4 pos = v.vertex;
				float3 normal;
#if _USE_DIRECT_GPU_SKINNING
				float4 tangent;
				float3 binormal;
				DecompressTangentNormal(v.tangent, tangent, normal, binormal);
				pos = CalculateGPUSkin(v.skinIndices, v.skinWeights, v.vertex, tangent, normal, binormal);
				v.texcoord.xy = DecompressUV(v.texcoord.xy, _uvBoundData);
#else
				normal = v.normal;
#endif
				o.vertex = UnityObjectToClipPos(pos);
				o.srcPos = ComputeScreenPos(o.vertex);

				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				fixed4 col = tex2D(_MainTex, i.srcPos.xy * _InfoVetor.xy / i.srcPos.w + _Time.x * _InfoVetor.zw) * _Color;
				col.rgb *= col.a; 
				return col;
			}
			ENDCG
		}
		//SRP被遮挡残影
		Pass
		{
			Name "MasterYiSRPGostShadow"
			Tags{ "LightMode"="CharacterShadowSrp" }
			Blend One One
			ZTest Always
			ZWrite On
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile __ _USE_DIRECT_GPU_SKINNING
			#include "UnityCG.cginc"
			#include "Assets/CGInclude/LGameCharacterDgs.cginc" 
			struct appdata
			{
				float4 vertex				: POSITION;
				float4 texcoord				: TEXCOORD0;
#ifdef _USE_DIRECT_GPU_SKINNING
				half4 tangent				: TANGENT;
				float4 skinIndices			: TEXCOORD2;
				float4 skinWeights			: TEXCOORD3;
#else
				float3 normal				: NORMAL;
#endif
			};

			struct v2f
			{
				float4 vertex				: SV_POSITION;
			};
			fixed4							_EffectCol;
			half							_VertOffset;
			v2f vert (appdata v)
			{
				v2f o;
				UNITY_INITIALIZE_OUTPUT(v2f, o);
				float4 pos = v.vertex;
				float3 normal;
#if _USE_DIRECT_GPU_SKINNING
				float4 tangent;
				float3 binormal;
				DecompressTangentNormal(v.tangent, tangent, normal, binormal);
				pos = CalculateGPUSkin(v.skinIndices, v.skinWeights, v.vertex, tangent, normal, binormal);
				v.texcoord.xy = DecompressUV(v.texcoord.xy, _uvBoundData);
#else
				normal = v.normal;
#endif
				o.vertex = UnityObjectToClipPos(pos + float4(0,0,_VertOffset,0));
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				return _EffectCol;
			}
			ENDCG
		}
		//SRP屏幕空间角色
		Pass
		{
			Name "MasterYiSRPScreenPass"
			Tags { "LightMode"="CharacterDefaultSrp" }
			Blend One Zero
			ZTest Always
			ZWrite On
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile __ _USE_DIRECT_GPU_SKINNING
			#include "UnityCG.cginc"
			#include "Assets/CGInclude/LGameCharacterDgs.cginc"
			struct appdata
			{
				float4 vertex				: POSITION;
				float4 texcoord				: TEXCOORD0;
#ifdef _USE_DIRECT_GPU_SKINNING
				half4 tangent				: TANGENT;
				float4 skinIndices			: TEXCOORD2;
				float4 skinWeights			: TEXCOORD3;
#else
				float3 normal				: NORMAL;
#endif
			};

			struct v2f
			{
				float4 vertex				: SV_POSITION;
				float4 srcPos				: TEXCOORD0;
			};

			sampler2D						_MainTex;
			half4							_Color;
			half4							_InfoVetor;
			v2f vert (appdata v)
			{
				v2f o;
				UNITY_INITIALIZE_OUTPUT(v2f, o);
				float4 pos = v.vertex;
				float3 normal;
#if _USE_DIRECT_GPU_SKINNING
				float4 tangent;
				float3 binormal;
				DecompressTangentNormal(v.tangent, tangent, normal, binormal);
				pos = CalculateGPUSkin(v.skinIndices, v.skinWeights, v.vertex, tangent, normal, binormal);
				v.texcoord.xy = DecompressUV(v.texcoord.xy, _uvBoundData);
#else
				normal = v.normal;
#endif
				o.vertex = UnityObjectToClipPos(pos);
				o.srcPos = ComputeScreenPos(o.vertex);

				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				fixed4 col = tex2D(_MainTex, i.srcPos.xy * _InfoVetor.xy / i.srcPos.w + _Time.x * _InfoVetor.zw) * _Color;
				col.rgb *= col.a; 
				return col;
			}
			ENDCG
		}
	}
}
