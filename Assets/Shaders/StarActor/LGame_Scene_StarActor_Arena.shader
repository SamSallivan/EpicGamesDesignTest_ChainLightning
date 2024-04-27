Shader "LGame/Scene/StarActor/Arena"
{
    Properties
    {
		_Color("Color", Color) = (1,1,1,1)
		_MainTex("Albedo", 2D) = "white" {}
		_WireframeTex("Wireframe",2D) = "black"{}
		_Metallic("Metallic", Range(0.0, 1.0)) = 0.0
		_Glossiness("Smoothness", Range(0.0, 1.0)) = 0.5
		_AmbientCol("Ambient Color" , Color) = (0.3,0.3,0.3,0.3)
		[Enum(Algorithm,0,Ramp,1)] _SparkleMode("Sparkle Mode", Float) = 0
		_SparkleMatCap("Sparkle MatCap", 2D) = "black" {}
		_SparkleSpeed("Sparkle Speed", Range(0,1)) = 1
		_SparkleStrength("Sparkle Strength", Range(0,4)) = 1
		_EmissionMap("Emission", 2D) = "black" {}
		[Enum(MatCap,0,CubeMap,1)] _ReflectionType("Reflection Type", Float) = 0
		[HDR]_ReflectionColor("Reflection Color", Color) = (0.5 , 0.5 , 0.5 , 0)
		_ReflectionCubeMap("Reflection CubeMap", Cube) = "" {}
		_ReflectionMatCap("Reflection MatCap", 2D) = "" {}
		_ReflectionRange("Reflection Range" , Range(0,1)) = 0
		_ShadowStrength("Self Shadow Strength" , Range(0,1)) = 1
		_Red("Red", Range(-1.0, 1.0)) = 0.0
		_Green("Green", Range(-1.0, 1.0)) = 0.0
		_Blue("Blue", Range(-1.0, 1.0)) = 0.0
		_RampMap("Ramp Map", 2D) = "white" {}
		_PointLightSize("Point Light Size",Vector) = (10,10,10,10)
		_PointLightRange("Point Light Range",Vector) = (8,8,8,8)	
		_PointLightMovability("Point Light Movability",Vector) = (0,1,1,1)
		_PointLightX("Point Light X",Vector) = (0,1,1,1)
		_PointLightY("Point Light Y",Vector) = (0,1,1,1)
		_PointLightZ("Point Light Z",Vector) = (0,1,1,1)
		_PointLightRhythmOrSpeed("Point Light Rhythm/Speed",Vector) = (0,1,1,1)
		_PointLightBrightness("Point Light Brightness",Vector) = (0.5,0.5,0.5,0.5)
		_Parallax("Parallax",Range(-1.0, 1.0))=0.0
		[HDR]_PointLightColor0("Point Light Color 0",Color) = (1,1,1,1)
		[HDR]_PointLightColor1("Point Light Color 1",Color) = (1,1,1,1)
		[HDR]_PointLightColor2("Point Light Color 2",Color) = (1,1,1,1)
		[HDR]_PointLightColor3("Point Light Color 3",Color) = (1,1,1,1)
    }
    SubShader
    {
		Tags{ "Queue" = "Geometry" "RenderType"="Opaque" }
		LOD 300
        Pass
        {
			Stencil {
				Ref 0
				Comp always
				Pass replace
			}
            Name "FORWARD"
            Tags { "LightMode" = "ForwardBase" }          
            CGPROGRAM
			#pragma target 3.0
			#pragma multi_compile_fwdbase nolightmap nodirlightmap nodynlightmap novertexlight noshadowmask  
			#pragma skip_variants LIGHTMAP_SHADOW_MIXING LIGHTPROBE_SH SPOT DIRECTIONAL_COOKIE POINT_COOKIE
			#pragma multi_compile _ _FASTEST_QUALITY
			#pragma shader_feature _REFLECTION_CUBEMAP
			#pragma shader_feature _RAMPMAP
			#pragma vertex Vert
			#pragma fragment Frag
			#include "UnityCG.cginc"
			#include "AutoLight.cginc"	
			#include "Lighting.cginc"
			sampler2D	_MainTex;
			sampler2D	_RampMap;
			sampler2D	_WireframeTex;
			sampler2D	_EmissionMap;
			sampler2D	_SparkleMatCap;
			sampler2D	_ReflectionMatCap;
			samplerCUBE _ReflectionCubeMap;
			half    _Metallic;
			half    _Glossiness;
			half	_Parallax;
			half	_Red;
			half	_Green;
			half	_Blue;
			half	_SparkleSpeed;
			half    _SparkleStrength;
			half	_ReflectionRange;
			half	_ShadowStrength;
			float4	_PointLightRange;
			float4	_PointLightSize;
			float4  _PointLightX;
			float4	_PointLightY;
			float4	_PointLightZ;
			float4	_PointLightRhythmOrSpeed;
			float4  _PointLightMovability;
			float4  _PointLightBrightness;
			float4	_SparkleMatCap_ST;
			float4	_RampMap_TexelSize;
			fixed4 _PointLightColor0;
			fixed4 _PointLightColor1;
			fixed4 _PointLightColor2;
			fixed4 _PointLightColor3;
			fixed4	_ReflectionColor;
			fixed4	_AmbientCol;
			fixed4	_Color;
			struct a2v
			{
				float4 vertex			: POSITION;
				float2 uv0				: TEXCOORD0;
				float2 uv1				: TEXCOORD1;
				half3 normal			: NORMAL;
				half4 tangent			: TANGENT;
			};
			struct v2f
			{
				float4 pos				: SV_POSITION;
				float4 uv				: TEXCOORD0;
				half3 viewDir           : TEXCOORD1;
				float3 wPos				: TEXCOORD2;
				float3 worldNormal		: TEXCOORD3;
				half3 lightDir			: TEXCOORD4;
				half3 tangentViewDir	: TEXCOORD5;
				half4 PointLight[3]		: TEXCOORD6;
				half4 Rhythm			: TEXCOORD9;
				UNITY_SHADOW_COORDS(10)
			};
			struct MusicFestivalData
			{
				half3 DiffColor;
				half3 SpecColor;
				float3 Normal;
				half Smoothness;
				half Roughness;
				half PerceptualRoughness;
				half OneMinusReflectivity;
				half Wireframe;
				half3 PointLight;
				half3 Emission;
			};
			half3  FilmIridescence_Ramp(half cos0, half thickness, half IOR)
			{
				half2 texcoord = clamp(half2(IOR, cos0 * thickness), _RampMap_TexelSize.xy * 0.5, 1.0 - _RampMap_TexelSize.xy * 0.5);
				half3 n_color = tex2D(_RampMap, texcoord);
				return n_color;
			}
			half3  FilmIridescence_MonsterHunterWorld(half cos0, half thickness, half IOR)
			{
				half tr = cos0 * thickness - IOR;
				half3 n_color = (cos((tr * 35.0) * half3(0.71, 0.87, 1.0)) * -0.5) + 0.5;
				n_color = lerp(n_color, half3(0.5, 0.5, 0.5), tr);
				n_color *= n_color * 2.0f;
				return n_color;
			}
			half3  FilmIridescence(half cos0, half thickness, half IOR)
			{
				half3 n_color;
#ifdef _RAMPMAP
				n_color = FilmIridescence_Ramp(cos0, thickness, IOR);
#else
				n_color = FilmIridescence_MonsterHunterWorld(cos0, thickness, IOR);
#endif
				return 	n_color * _SparkleStrength;
			}
			void MusicFestivalDataSetup(v2f i, out MusicFestivalData Data)
			{
				Data.Normal = normalize(i.worldNormal);
				float4 ToLightX = i.PointLight[0] - i.wPos.x;
				float4 ToLightY = i.PointLight[1] - i.wPos.y;
				float4 ToLightZ = i.PointLight[2] - i.wPos.z;

				float4 lengthSq = ToLightX * ToLightX;
				lengthSq += ToLightY * ToLightY;
				lengthSq += ToLightZ * ToLightZ;
				lengthSq = max(lengthSq, 0.000001);
	
				float4 NoL = -ToLightX * Data.Normal.x;
				NoL += -ToLightY * Data.Normal.y;
				NoL += -ToLightZ * Data.Normal.z;

				float4 CorrectNoL = rsqrt(lengthSq);
				NoL = max(0.0, NoL * CorrectNoL);
				half4 Atten = 1.0f - clamp(lengthSq / (_PointLightRange * _PointLightRange), 0.0f, 1.0f);
				Atten *= Atten;
				float4 Diffuse = NoL * Atten * i.Rhythm;
				Data.PointLight = _PointLightColor0 * Diffuse.x;
				Data.PointLight += _PointLightColor1 * Diffuse.y;
				Data.PointLight += _PointLightColor2 * Diffuse.z;
				Data.PointLight += _PointLightColor3 * Diffuse.w;

				Data.Wireframe = tex2D(_WireframeTex, i.uv.xy).r;
#ifndef	_FASTEST_QUALITY
				Data.Wireframe = tex2D(_WireframeTex, i.uv.xy + ParallaxOffset(0.025, _Parallax * Data.Wireframe, normalize(i.tangentViewDir))).r;
#endif			
				half4 albedo = tex2D(_MainTex, i.uv.xy) * _Color;
#ifdef UNITY_COLORSPACE_GAMMA
				albedo.rgb = GammaToLinearSpace(albedo.rgb);
#endif
				Data.Smoothness = _Glossiness;
				Data.PerceptualRoughness = 1.0 - Data.Smoothness;
				Data.Roughness = max(0.001, Data.PerceptualRoughness * Data.PerceptualRoughness);
				half4 _ColorSpaceDielectricSpec = half4(0.1, 0.1, 0.1, 1.0 - 0.1);
				Data.OneMinusReflectivity = (1.0 - _Metallic) * _ColorSpaceDielectricSpec.a;

				Data.DiffColor = albedo.rgb * Data.OneMinusReflectivity;
				Data.SpecColor = lerp(_ColorSpaceDielectricSpec.rgb, albedo.rgb, _Metallic);
				Data.Emission = tex2D(_EmissionMap, i.uv.xy);
			}
			half4 LGAME_BRDF_PBS_MUSIC_FESTIVAL(MusicFestivalData Data, half3 viewDir, half3 lightDir, half3 wPos, half atten)
			{
				viewDir = normalize(viewDir.xyz);
				lightDir = normalize(lightDir.xyz);
				half3 H = normalize(lightDir + viewDir);
				half NoV = saturate(dot(Data.Normal, viewDir));
				half NoL = saturate(dot(Data.Normal, lightDir));
				half NoH = saturate(dot(Data.Normal, H));
				half LoH = saturate(dot(lightDir, H));

				half3 DiffuseTerm = _LightColor0.rgb * atten * NoL;

				float a2 = Data.Roughness * Data.Roughness;
				float d = (NoH * NoH * (a2 - 1.f) + 1.0f) + 0.00001f;
				half3 SpecularTerm = a2 / (max(0.1f, LoH * LoH) * (Data.Roughness + 0.5f) * (d * d) * 4.0) * Data.SpecColor;
				SpecularTerm = SpecularTerm - 1e-4f;
				SpecularTerm = clamp(SpecularTerm, 0.0, 100.0);

				half SurfaceReduction = (0.6 - 0.08 * Data.PerceptualRoughness);
				SurfaceReduction = 1.0 - Data.Roughness * Data.PerceptualRoughness * SurfaceReduction;
				half GrazingTerm = saturate(Data.Smoothness + (1.0 - Data.OneMinusReflectivity));

				//half Mip = Data.PerceptualRoughness * (1.7 - 0.7*Data.PerceptualRoughness) * 6.0;
				float3 vNormal = mul(UNITY_MATRIX_V, float4(Data.Normal, 0)).xyz;
				float3 vPos = normalize(UnityWorldToViewPos(wPos));
				float3 R = reflect(vPos, vNormal);
			/*
					half m = 2.0 * sqrt(R.x * R.x + R.y * R.y + (R.z + 1) * (R.z + 1));
					half2 matcapuv = R.xy / m + 0.5;
			*/
				half3 EnvironmentSpecular;
			/*
			#ifndef	_FASTEST_QUALITY
					half3 Offset = half3(_Red, _Green, _Blue) + 1.0;
					half3 R0 = reflect(vPos, vNormal* Offset.x);
					half3 R1 = reflect(vPos, vNormal* Offset.y);
					half3 R2 = reflect(vPos, vNormal* Offset.z);
			#ifndef _REFLECTION_CUBEMAP
					half m0 = 2.0 * sqrt(R0.x * R0.x + R0.y * R0.y + (R0.z + 1) * (R0.z + 1));
					half m1 = 2.0 * sqrt(R1.x * R1.x + R1.y * R1.y + (R1.z + 1) * (R1.z + 1));
					half m2 = 2.0 * sqrt(R2.x * R2.x + R2.y * R2.y + (R2.z + 1) * (R2.z + 1));
					EnvironmentSpecular.x = tex2D(_ReflectionMatCap, R0.xy / m0 + 0.5).x;
					EnvironmentSpecular.y = tex2D(_ReflectionMatCap, R1.xy / m1 + 0.5).y;
					EnvironmentSpecular.z = tex2D(_ReflectionMatCap, R2.xy / m2 + 0.5).z;
			#else
					EnvironmentSpecular.x = texCUBE(_ReflectionCubeMap, R0).x;
					EnvironmentSpecular.y = texCUBE(_ReflectionCubeMap, R1).y;
					EnvironmentSpecular.z = texCUBE(_ReflectionCubeMap, R2).z;
			#endif
					EnvironmentSpecular *= _ReflectionColor;
			#else
			*/
#ifndef _REFLECTION_CUBEMAP
				half m = 2.0 * sqrt(R.x * R.x + R.y * R.y + (R.z + 1) * (R.z + 1));
				half2 matcapuv = R.xy / m + 0.5;
				EnvironmentSpecular = tex2D(_ReflectionMatCap, matcapuv) * _ReflectionColor;
#else
				EnvironmentSpecular = texCUBE(_ReflectionCubeMap, R) * _ReflectionColor;
#endif
			//#endif

#ifdef UNITY_COLORSPACE_GAMMA
				EnvironmentSpecular = GammaToLinearSpace(EnvironmentSpecular);
#endif
			/*
					half3 Sparkle;
			#ifndef	_FASTEST_QUALITY
					Sparkle = tex2Dlod(_SparkleMatCap, half4(matcapuv * _SparkleMatCap_ST.xy + _SparkleMatCap_ST.zw, 0, 0));
					Sparkle = FilmIridescence(frac(_Time.y * _SparkleSpeed + m), NoV, NoH) * Sparkle;
			#ifdef UNITY_COLORSPACE_GAMMA
					Sparkle = GammaToLinearSpace(Sparkle);
			#endif
			#else
					Sparkle = 0.0;
			#endif
			*/
				half3 Color = (Data.DiffColor + SpecularTerm) * DiffuseTerm;
#ifdef UNITY_PASS_FORWARDBASE
				half3 Fresnel = FresnelLerpFast(Data.SpecColor, GrazingTerm, NoV);
				half Mask = 1.0 - Fresnel;
				Fresnel = lerp(Fresnel, 1.0, _ReflectionRange);
				Color += (Data.PointLight + Data.Emission) * Data.Wireframe * Mask;
				Color += _AmbientCol * Data.DiffColor;
				Color += SurfaceReduction * EnvironmentSpecular * Fresnel;
				//Color += SurfaceReduction * (EnvironmentSpecular + Sparkle) * Fresnel;
#endif
				return half4(Color, 1.0);
			}

			v2f Vert(a2v v)
			{
				v2f o;
				UNITY_INITIALIZE_OUTPUT(v2f, o);
				o.wPos = mul(unity_ObjectToWorld, v.vertex);
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv.xy = v.uv0;
				o.uv.zw = v.uv1;
				o.viewDir = UnityWorldSpaceViewDir(o.wPos);
				o.lightDir = UnityWorldSpaceLightDir(o.wPos);
				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				float4 Offset = _Time.y * _PointLightRhythmOrSpeed;
				float4 CosOffset = cos(Offset);
				o.Rhythm = abs(CosOffset) * (1.0 - _PointLightBrightness) + _PointLightBrightness;
				float3 Ratio = float3(1.0, UNITY_PI, UNITY_TWO_PI);
				float3 P0 = sin(Ratio + Offset.x);
				float3 P1 = sin(Ratio + Offset.y);
				float3 P2 = sin(Ratio + Offset.z);
				float3 P3 = sin(Ratio + Offset.w);
				float4 Movable = _PointLightMovability * _PointLightSize;
				o.PointLight[0] = _PointLightX + float4(P0.x, P1.x, P2.x, P3.x) * Movable;
				o.PointLight[1] = _PointLightY + float4(P0.y, P1.y, P2.y, P3.y) * Movable;
				o.PointLight[2] = _PointLightZ + float4(P0.z, P1.z, P2.z, P3.z) * Movable;
				half3x3 objectToTangent = half3x3(
					v.tangent.xyz,
					cross(v.normal, v.tangent.xyz) * v.tangent.w,
					v.normal
				);
				o.tangentViewDir = mul(objectToTangent, ObjSpaceViewDir(v.vertex)).xyz;
				UNITY_TRANSFER_SHADOW(o, v.uv1);
				return o;
			}
			fixed4 Frag(v2f i) : SV_Target
			{
				MusicFestivalData Data;
				MusicFestivalDataSetup(i,Data);
				#ifndef	_FASTEST_QUALITY
					UNITY_LIGHT_ATTENUATION(atten, i, i.wPos)
					atten = lerp(1.0, atten, _ShadowStrength);
				#else
				half atten = 1.0;
				#endif
				fixed4 Color = LGAME_BRDF_PBS_MUSIC_FESTIVAL(Data, i.viewDir, i.lightDir, i.wPos, atten);
				#ifdef UNITY_COLORSPACE_GAMMA
					Color.rgb = LinearToGammaSpace(Color.rgb);
				#endif
				return Color;
			}
            ENDCG           
        }
		Pass
		{
			Name "ShadowCaster"
			Tags { "LightMode" = "ShadowCaster" }
			ZTest LEqual
			CGPROGRAM
			#pragma multi_compile_shadowcaster
			#pragma skip_variants SHADOWS_CUBE
			#pragma vertex Vert_Shadow
			#pragma fragment Frag_Shadow
			#include "Assets/CGInclude/LGameStarActorShadowCaster.cginc"				
			ENDCG
		}
    }	
	CustomEditor "LGameSDK.AnimTool.LGameSceneStarActorArenaShaderGUI"
}
