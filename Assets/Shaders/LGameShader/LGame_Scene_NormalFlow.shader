Shader "LGame/Scene/NormalFlow"
{
	Properties
	{

		[HDR]_Color("Color", Color) = (1,1,1,1)
		_MainTex("WaterTex", 2D) = "white" {}
		_TextureSpeed("Texture Speed",  vector) = (0,0,0,0)

		[Header(TAG                  Normal Calculate)]
		_SpecularColor("SpecularColor", Color) = (1,1,1,1)
		_Normalmap("Normalmap", 2D) = "white" {}
		//_NormalmapPow("Normalmap Pow",Range(0.01 ,1)) = 1

		_WaverTexSpeed("WaverTex speed",  Range(0,1)) = 1

		//[Header(TAG                  Vertex Animate)]
		//_WaverIntensity("Waver Intensity",  Range(0,10)) = 0.15
		//_WaverSpeed("WaverMove speed",  Range(0,10)) = 1

		[Header(TAG                  PBR Property)]

		_ReflectionColor("Reflection Color", Color) = (0.5 , 0.5 , 0.5 , 0)
		_ReflectionMatCap("Reflection MatCap", 2D) = "" {}
		_ReflectionMapScale("CubeMap Scale", Range(0.0, 8.0)) = 1.0

		_Metallic("Metallic", Range(0.0, 1.0)) = 0.0
		_Glossiness("Smoothness", Range(0.0, 1.0)) = 0.5

		[Header(Fog)]
		_FogColor("Fog Color",Color) = (0.0,0.0,0.0,1.0)
		_FogStart("Fog Start",float) = 0.0
		_FogEnd("Fog End",float) = 300.0
	}

		CGINCLUDE
		#include "UnityCG.cginc"


		struct v2a {
			float4 vertex : POSITION;
			float3 normal : NORMAL;
			float4 tangent : TANGENT;
			float2 texcoord0 : TEXCOORD0;
			float2 uv		: TEXCOORD1;
			float2 uv2		: TEXCOORD2;

		};

		struct v2f
		{
			fixed4 color : COLOR;
			float4 vertex	: SV_POSITION;
			float4 uv		: TEXCOORD0;
			float4 uv2		: TEXCOORD1;

			float4 test :  TEXCOORD3;
			float3 normalDir : TEXCOORD4;
			float3 tangentDir : TEXCOORD5;
			float3 bitangentDir : TEXCOORD6;
			float4 posWorld : TEXCOORD7;

		};

		fixed4		_Color;
		fixed4		_SpecularColor;
		sampler2D	_MainTex;
		float4		_MainTex_ST;
		sampler2D	_Normalmap;
		float4		_Normalmap_ST;

		
		half		_Brightness;
		half		_FowBrightness;
		float		_DropletDensity;
		float		_Speed;
		//half		_NormalmapPow;
		//=========pbr===============
		half		_Metallic;
		half		_Glossiness;
		fixed4		_ReflectionColor;
		half		_ReflectionMapScale;
		sampler2D	_ReflectionMatCap;


		half4 _ActorPos;
		half _WaverIntensity;
		//half _WaverHighCurve;
		half _WaverSpeed;
		half _WaverTexSpeed;
		half4 _TextureSpeed;
		//half _SceneDepthOffset;


		//=========fog===============
		half		_FogStart;
		half		_FogEnd;
		fixed4		_FogColor;

		inline float4 AnimateVertex2(float3 worldPos)
		{
			float offset = (sin((_Time.y + worldPos.xz - worldPos.y * 2) * _WaverSpeed) * _WaverIntensity) * worldPos.y * 0.5;
			worldPos += half3(offset, offset * 0.2, offset);
			return float4(worldPos, 1);

		}

		float GetG(float3 color) {
			return color.r * 0.2126 + color.g * 0.7152 + color.b * 0.0722;
		}


		fixed3 SimulateFog(float3 worldPos, fixed3 col)
		{
			//half dist = length(_WorldSpaceCameraPos.xyz - worldPos);  
			//修改运动相机的fog改变 2018.9.3-jaffhan
			half dist = length(half3(0.0, 0.0, 0.0) - worldPos);
			half fogFactor = (_FogEnd - dist) / (_FogEnd - _FogStart);
			fogFactor = saturate(fogFactor);
			fixed3 afterFog = lerp(_FogColor.rgb, col.rgb, fogFactor);
			return afterFog;
		}

		ENDCG


		SubShader
		{

			LOD 100

			Tags
			{
			"DisableBatching" = "True"
			"LightMode" = "ForwardBase"
			"Queue" = "AlphaTest-10"
			//"IgnoreProjector" = "true"
			//"RenderType" = "TransparentCuout"
			}

			Pass
			{
				Name "FORWARD"
				Tags {  "LightMode" = "ForwardBase" }
				//BlendOp Add
			//Blend[_SrcBlend][_DstBlend]

			//ZWrite off
			Blend SrcAlpha OneMinusSrcAlpha

			//Cull Off
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma shader_feature _ALPHACLIP_ON 
			//#pragma shader_feature _WAVE_ON 
			#include "UnityCG.cginc"
			#include "Lighting.cginc"

			v2f vert(v2a v)
			{
				v2f o;
				UNITY_INITIALIZE_OUTPUT(v2f, o);
				float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

				o.normalDir = UnityObjectToWorldNormal(v.normal);
				o.tangentDir = normalize(mul(unity_ObjectToWorld, float4(v.tangent.xyz, 0.0)).xyz);
				o.bitangentDir = normalize(cross(o.normalDir, o.tangentDir) * v.tangent.w);
				o.posWorld = mul(unity_ObjectToWorld, v.vertex);

				o.vertex = UnityWorldToClipPos(worldPos.xyz);
				o.test = worldPos.xyzz;

				o.uv.xy = v.uv;

				half waveValue = 0.1;
				half waveValueDouble = _WaverTexSpeed;

				half lineWaveDouble = _Time.y * waveValueDouble;

				o.uv.zw = o.uv.xy + half2(lineWaveDouble,  lineWaveDouble )* float2(_TextureSpeed.x, _TextureSpeed.y);



				o.color = saturate(worldPos.y * 2);

				//UNITY_INITIALIZE_OUTPUT(v2f, o);
				return o;
			}
			fixed4 frag(v2f i) : SV_Target
			{

				//============================基色结果=================================
				half3 tex0 = tex2D(_MainTex, TRANSFORM_TEX(i.uv.xy, _MainTex) + i.uv.zw);
				half3 finalFlowColor = tex0 ;
				//======================================================================


				//=======================法线计算过程==================================
				half3x3 tangentTransform = float3x3(i.tangentDir, i.bitangentDir, i.normalDir);
				half3 norm = tex2D(_Normalmap, TRANSFORM_TEX(i.uv.xy, _Normalmap) + i.uv.zw);
				float3 objNormal = norm;
				float3 normalWorld = normalize(mul(objNormal, tangentTransform)); // Perturbed normals
				float3 worldNormal = normalWorld ;

				//======================================================================

				//=======================光照准备======================================
				//float3 lightDirection = normalize(_WorldSpaceLightPos0.xyz);

				half3 worldPos = i.posWorld.rgb;
				half3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));
				half3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
				half3 halfDir = normalize( worldLightDir+ worldViewDir);

				half3 texCol = finalFlowColor  * _Color;
				half metallic = _Metallic;
				half smoothness = _Glossiness;

				half nh = clamp(dot(worldNormal, halfDir),0,1);
				half lh = saturate(dot(worldLightDir, halfDir));
				half nv = abs(dot(worldNormal, worldViewDir));
				half nl = saturate(dot(worldNormal, worldLightDir));


				// Specular term
				half perceptualRoughness = 1 - smoothness;
				half roughness = perceptualRoughness * perceptualRoughness;
				half a = roughness* roughness;
				half a2 = a * a;
				half d = nh * nh * (a2 - 1.h) + 1.00001h;

				half specularTerm = clamp(a / (max(0.32h, lh) * (1.5h + roughness) * d),0,3);
				half3 specColor = lerp(texCol.rrr * _SpecularColor, texCol.rgb * _SpecularColor, _Metallic)* _LightColor0.rgb;

				
				// Reflection
				perceptualRoughness = perceptualRoughness * (1.7 - 0.7 * perceptualRoughness);
				half mip = perceptualRoughness * 6;


				half3 viewNormal = mul(UNITY_MATRIX_V, half4(worldNormal, 0)).xyz;
				half3 viewPos = UnityWorldToViewPos(worldPos);
				float3 r = normalize(reflect(viewPos, viewNormal));
				float m = 2.0 * sqrt(r.x * r.x + r.y * r.y + (r.z + 1) * (r.z + 1));
				half2 matcapUV = r.xy / m + 0.5;
				fixed4 ReflectionMatcapCol = tex2Dlod(_ReflectionMatCap, half4(matcapUV, 0, mip));
				ReflectionMatcapCol *= _ReflectionMapScale * _ReflectionColor;
				half oneMinusReflectivity = (1 - _Metallic) * 0.78;
				half3 diffColor = texCol.rgb * oneMinusReflectivity* nl;


				half surfaceReduction = (0.6 - 0.08 * perceptualRoughness);
				half grazingTerm = saturate(smoothness + (1 - oneMinusReflectivity));

				half fresnel = Pow4(1 - nv);
				//half alpha = lerp(texCol.a, ReflectionMatcapCol.a, fresnel);

				half3 col = diffColor + specularTerm * specColor + 
					ReflectionMatcapCol * lerp(specColor, grazingTerm.rrr, fresnel);

				col.rgb = SimulateFog(i.posWorld, col.rgb);

				return float4(col , _Color.a);
				}
				ENDCG
		}

		}

}
