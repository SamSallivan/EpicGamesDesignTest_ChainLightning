Shader "LGame/Character/GhostShadowOnePass"
{																		
	Properties
	{
		_GhostTex("Ghost Textrue" , 2D)	= "white" {} 
		_GhostColor("Ghost Color" , Color) = (1,0,0,1)
		_GhostVector("Ghost Vector(w for speed)" , Vector) = (1,0,0,0.1)
		_GhostScale("Ghost Scale" , Range(0,2)) = 1
		[HideInInspector]_AlphaCtrl("AlphaCtrl", Range(0,1)) = 1
		[HideInInspector][Enum(UnityEngine.Rendering.BlendMode)]_BlendModeSrc("BlendModeSrc",int)=1
		[HideInInspector][Enum(UnityEngine.Rendering.BlendMode)]_BlendModeDst("BlendModeDst",int)=1
		[HideInInspector]_BlendMode("BlendMode",float)=0
	}

SubShader
	{
		Tags { "Queue"="AlphaTest" "RenderType"="AlphaTest"}

		Blend [_BlendModeSrc][_BlendModeDst]
        ZWrite off
        Offset -1 , 0
		//该Pass用于在SRP中显示
		Pass
		{
            Name "Base2Srp"
			Tags {  "LightMode" = "GhostShadowSrp2" }
			CGPROGRAM
			#pragma multi_compile __ _USE_DIRECT_GPU_SKINNING
			#define  GHOST_OFFSET 1
			#pragma vertex vert
			#pragma fragment frag
			#pragma exclude_renderers gles
			#include "UnityCG.cginc"
			#include "Assets/CGInclude/LGameCharacterDgs.cginc" 

			fixed4		_GhostColor;
			half4		_GhostVector;
			half		_GhostScale;
			half		_AlphaCtrl;

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
				half posOffset = frac(_Time.y * _GhostVector.w + GHOST_OFFSET * 0.5);
				ghostPos.xyz *= lerp(1,_GhostScale ,posOffset);
				//为了避免不同角色模型坐标系方向差异，转换到世界空间计算偏移方向
				float4 ghostPosWS=mul(unity_ObjectToWorld,ghostPos);
				ghostPosWS.xyz+=_GhostVector.xyz * posOffset;
				o.pos = UnityWorldToClipPos(ghostPosWS);
				o.color = _GhostColor;
				o.color *= _AlphaCtrl * (1-Pow2(posOffset*2-1));
				return o;
			}
			fixed4 frag (v2f i) : SV_Target
			{
				return  i.color;
			}
			ENDCG
		}
		//该Pass用于预览效果
		Pass
		{
            Name "BasePreview"
			CGPROGRAM
			#pragma multi_compile __ _USE_DIRECT_GPU_SKINNING
			#define  GHOST_OFFSET 1
			#pragma vertex vert
			#pragma fragment frag
			#pragma exclude_renderers gles
			#include "UnityCG.cginc"
			#include "Assets/CGInclude/LGameCharacterDgs.cginc" 
		
			fixed4		_GhostColor;
			half4		_GhostVector;
			half		_GhostScale;
			half		_AlphaCtrl;
		
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
				half posOffset = frac(_Time.y * _GhostVector.w + GHOST_OFFSET * 0.5);
				ghostPos.xyz *= lerp(1,_GhostScale ,posOffset);
				//为了避免不同角色模型坐标系方向差异，转换到世界空间计算偏移方向
				float4 ghostPosWS=mul(unity_ObjectToWorld,ghostPos);
				ghostPosWS.xyz+=_GhostVector.xyz * posOffset;
				o.pos = UnityWorldToClipPos(ghostPosWS);
				o.color = _GhostColor;
				o.color *= _AlphaCtrl * (1-Pow2(posOffset*2-1));
				return o;
			}
			fixed4 frag (v2f i) : SV_Target
			{
				return  i.color;
			}
			ENDCG
		}
	}
	CustomEditor"LGameSDK.AnimTool.LGameCharacterOnePassGUI"
}
