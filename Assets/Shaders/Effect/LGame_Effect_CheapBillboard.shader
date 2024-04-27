Shader "LGame/Effect/CheapBillboard" {
	Properties{
		[HideInInspector] _AlphaCtrl("AlphaCtrl",range(0,1)) = 1

		[HideInInspector][Enum(UnityEngine.Rendering.BlendMode)] 		_SrcFactor("SrcFactor()", Float) = 5
		[HideInInspector][Enum(UnityEngine.Rendering.BlendMode)] 		_DstFactor("DstFactor()", Float) = 10
		[HideInInspector][Enum(UnityEngine.Rendering.BlendMode)] 		_SrcAlphaFactor("SrcAlphaFactor()", Float) = 0
		[HideInInspector][Enum(UnityEngine.Rendering.BlendMode)] 		_DstAlphaFactor("DstAlphaFactor()", Float) = 10
		[Enum(UnityEngine.Rendering.CullMode)] 							_CullMode("消隐模式(CullMode)", int) = 0
		[Enum(LessEqual,4,Always,8)]									_ZTestMode("深度测试(ZTest)", int) = 4
		[Enum(RGB,14,ALL,15, NONE,0)]									_ColorMask("颜色遮罩(ColorMask)", int) = 15
		[HDR]_Color("Color",Color)=(1,1,1,1)
		_MainTex("Base texture", 2D) = "white" {}
		[Header(Billboard)]
		[Toggle]_Billboard("Enable Billboard",float) = 0.0
		_Size("Size",Float) = 0.2
		_VerticalBillboarding("Vertical Restraints", Range(0,1)) = 1
		[SimpleToggle]_BillboardTile("TileX&Y", float) = 0.0
		_BillboardTileX("Tile X",int) = 2
		_BillboardTileY("Tile Y",int) = 2
		[Header(Atals Walk)]
		[Toggle]_AtlasWalk("Enable Atlas Walk",float) = 0.0
		_TileX("Tile X",int) = 4
		_TileY("Tile Y",int) = 4
		_Speed("Speed",Float) = 0.2
	}
		SubShader{
			Tags { "Queue" = "Transparent" "IgnoreProjector" = "True" "RenderType" = "Transparent" "DisableBatching" = "True" "LightMode" = "ForwardBase"}
			ColorMask[_ColorMask]
			Blend[_SrcFactor][_DstFactor],[_SrcAlphaFactor][_DstAlphaFactor]
			Cull[_CullMode]
			ZWrite off
			ZTest[_ZTestMode]
			Offset[_OffsetFactor] ,[_OffsetUnits]
			LOD 100
			Pass {
				CGPROGRAM
				#pragma vertex vert  
				#pragma fragment frag  
				#pragma target 3.0
				//#pragma multi_compile_instancing
				#pragma shader_feature _ATLASWALK_ON
				#pragma shader_feature _BILLBOARD_ON
				#include "UnityCG.cginc"  
	#if _ATLASWALK_ON
				UNITY_INSTANCING_BUFFER_START(Atlas)
					UNITY_DEFINE_INSTANCED_PROP(half, _TileX)
					UNITY_DEFINE_INSTANCED_PROP(half, _TileY)
					UNITY_DEFINE_INSTANCED_PROP(half, _Speed)
				UNITY_INSTANCING_BUFFER_END(Atlas)
	#endif

	#if _BILLBOARD_ON
			
			UNITY_INSTANCING_BUFFER_START(Billboard)
				UNITY_DEFINE_INSTANCED_PROP(half, _Size)
				UNITY_DEFINE_INSTANCED_PROP(half, _VerticalBillboarding)
				UNITY_DEFINE_INSTANCED_PROP(float, _BillboardTile)
				UNITY_DEFINE_INSTANCED_PROP(int, _BillboardTileX)
				UNITY_DEFINE_INSTANCED_PROP(int, _BillboardTileY)
			UNITY_INSTANCING_BUFFER_END(Billboard)

#endif
			sampler2D _MainTex;
			UNITY_INSTANCING_BUFFER_START(Props)
				UNITY_DEFINE_INSTANCED_PROP(float4, _MainTex_ST)
				UNITY_DEFINE_INSTANCED_PROP(half, _AlphaCtrl)
				UNITY_DEFINE_INSTANCED_PROP(fixed4, _Color)
			UNITY_INSTANCING_BUFFER_END(Props)

		struct v2f {
			float4  pos		: SV_POSITION;
			float2  uv		: TEXCOORD0;
#if _ATLASWALK_ON
			float3  data	: TEXCOOR1;
#endif
			UNITY_VERTEX_INPUT_INSTANCE_ID

		};
		void CalcOrthonormalBasis(float3 dir,out float3 right,out float3 up)
		{
			up = abs(dir.y) > 0.999f ? float3(0,0,1) : float3(0,1,0);
			right = normalize(cross(up,dir));
			up = cross(dir,right);
		}

		struct appdata {
			float4  vertex		: POSITION;
			float2  texcoord : TEXCOORD0;
			UNITY_VERTEX_INPUT_INSTANCE_ID

		};
		v2f vert(appdata v)
		{
			v2f o;
			UNITY_SETUP_INSTANCE_ID(v);
			UNITY_TRANSFER_INSTANCE_ID(v, o);
#if _BILLBOARD_ON
			// 为了适配外包错误制作方式，将散图合成了图集。求中心点需要*Tile再frac
			// 对应图集的模型uv不要卡在象限边缘，否则会frac出错变0
			float2 scaleTexcoord = float2(v.texcoord.x * UNITY_ACCESS_INSTANCED_PROP(Billboard, _BillboardTileX), 
											v.texcoord.y * UNITY_ACCESS_INSTANCED_PROP(Billboard, _BillboardTileY));
			scaleTexcoord = frac(scaleTexcoord);
			scaleTexcoord = lerp(v.texcoord, scaleTexcoord, UNITY_ACCESS_INSTANCED_PROP(Billboard, _BillboardTile));

			// 求uv空间的中心点。原坐标+(0.5-原坐标)变化后都会变为(0.5, 0.5)
			// x-0.5变成0.5-x是为了适配3dsMax和Unity的左右手坐标系
			// 两个坐标系z轴同向的话x轴反向，即-(x-0.5)
			float3  centerOffs = float3(scaleTexcoord.x - 0.5, 0.5 - scaleTexcoord.y, 0)*UNITY_ACCESS_INSTANCED_PROP(Billboard, _Size);
			float3  centerLocal = v.vertex.xyz + centerOffs.xyz;
			
			float3  localDir = ObjSpaceViewDir(float4(centerLocal,1));
			localDir.y = localDir.y * UNITY_ACCESS_INSTANCED_PROP(Billboard, _VerticalBillboarding);
			float3  rightLocal;
			float3  upLocal;
			CalcOrthonormalBasis(normalize(localDir) ,rightLocal,upLocal);
			float3  BBLocalPos = centerLocal - (rightLocal * centerOffs.x + upLocal * centerOffs.y);
			o.pos = UnityObjectToClipPos(float4(BBLocalPos, 1.0));
#else
			o.pos = UnityObjectToClipPos(v.vertex);
			
#endif

#if _ATLASWALK_ON
			float count = UNITY_ACCESS_INSTANCED_PROP(Atlas, _TileX) * UNITY_ACCESS_INSTANCED_PROP(Atlas, _TileY);
			float offset = _Time.y * UNITY_ACCESS_INSTANCED_PROP(Atlas, _Speed);
			o.data.x = offset * count;
			o.data.yz = 1.0f/ float2(UNITY_ACCESS_INSTANCED_PROP(Atlas, _TileX), UNITY_ACCESS_INSTANCED_PROP(Atlas, _TileY));
#endif
			o.uv = v.texcoord.xy * UNITY_ACCESS_INSTANCED_PROP(Props,_MainTex_ST.xy) + UNITY_ACCESS_INSTANCED_PROP(Props,_MainTex_ST.zw);
			return o;
		}
		fixed4 frag(v2f i) : COLOR
		{
			UNITY_SETUP_INSTANCE_ID(i);
			float2 uv = i.uv;
#if _ATLASWALK_ON
			uv.x = floor(i.data.x);
			uv.y = -floor(uv.x/ UNITY_ACCESS_INSTANCED_PROP(Atlas, _TileX));
			uv += i.uv.xy;
			uv = frac(uv *i.data.yz);
#endif
			fixed4 col = tex2D(_MainTex, uv, float2(0, 0), float2(0, 0)) * UNITY_ACCESS_INSTANCED_PROP(Props, _Color);
			return float4(col.rgb, col.a * UNITY_ACCESS_INSTANCED_PROP(Props, _AlphaCtrl));
		}
		ENDCG
		}
	}
		// 特效性能自动化扫描工具需要用到此Subshader
	/*SubShader
	{
		Tags { "Queue" = "Transparent" "IgnoreProjector" = "True" "RenderType" = "Transparent" "LightMode" = "ForwardBase"}
		LOD 5
		Blend One One
		Cull[_CullMode]
		ZWrite off
		ZTest[_ZTestMode]
		Offset[_OffsetFactor] ,[_OffsetUnits]

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
			};
			sampler2D _MainTex;
			float4 _MainTex_ST;
			v2f vert(appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				return o;
			}

			half4 frag(v2f i) : SV_Target
			{
				fixed4 texColor = tex2D(_MainTex, i.uv.xy);
				return half4(0.15,0.06,0.03, texColor.a < 0.001);
			}
		ENDCG
		}
	}*/
}