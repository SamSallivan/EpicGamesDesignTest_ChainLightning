Shader "LGame/Scene/VirtualFluid"
{
	Properties
	{

		[HDR]_Color("Color", Color) = (1,1,1,1)
		_MainTex("WaterTex", 2D) = "white" {}
		_TextureSpeed("Texture Speed",  Range(0,1)) = 1


		[Header(TAG                  Mask Calculate)]
		_UVTiling("Mask UVTiling",vector) = (0,0,0,0)
		//[HideInInspector]
		_FixedDroplet("Fixed Droplet",Range(0 ,1)) = 0.7
		_MoreRainAmount("Random Amount",Range(0, 1)) = 1
		//_DropletSize("Droplet Size",Range(0 ,1)) = 0.4
		_DropletDensity("Random Density",Range(0 ,10)) = 1.85
		_Speed("Random Speed",Range(0 ,2)) = 1

		[Header(TAG                  Normal Calculate)]
		_SpecularColor("SpecularColor", Color) = (1,1,1,1)
		_Normalmap("Normalmap", 2D) = "white" {}
		_NormalmapPow("Normalmap Pow",Range(1 ,5)) = 1
		_normMask("Normalmap Mask",Range(0 ,1)) = 1
		_flowMask("flow Mask",Range(0.5 ,1.5)) = 0.5
		_flowMaskRange("flow Mask Range",Range(0.5 ,3)) = 0.5

		_WaverTexSpeed("WaverTex speed Y",  Range(0,0.5)) = 1

		[Header(TAG                  Vertex Animate)]
		_WaverIntensity("Waver Intensity",  Range(0,10)) = 0.15
		//_WaverHighCurve("Waver High Curve",  Range(0,10)) = 2
		_WaverSpeed("WaverMove speed",  Range(0,10)) = 1
		//_DeltaScale("DeltaScale",  Range(0,2)) = 1
		//_WaterMask_TexelSize("WaterMask_TexelSize",vector) = (1,1,1,1)
		//_HeightScale("HeightScale",Range(-2,20000)) = 1
		//_MaskTex("MaskTex", 2D) = "white" {}


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
		float4		_UVTiling;
		sampler2D	_Normalmap;
		float4		_Normalmap_ST;
		sampler2D	_MaskTex;
		float4		_MaskTex_ST;

		
		half		_Brightness;
		half		_FowBrightness;
		//float		_DeltaScale;
		//float		_HeightScale;
		float		_FixedDroplet;
		//float		_DropletSize;
		float		_DropletDensity;
		float		_Speed;
		float		_MoreRainAmount;
		half		_NormalmapPow;
		half		_normMask;
		half		_flowMask;
		half		_flowMaskRange;
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
		half _TextureSpeed;
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
		////灰度转法线
		//float3 GetNormalByGray( float2 uv)
		//{
		//	float2 deltaU = float2(_WaterMask_TexelSize.x * _DeltaScale, 0);
		//	float h1_u = tex2D(_WaterMask, uv - deltaU).g;
		//	float h2_u = tex2D(_WaterMask, uv + deltaU).g;
		//	float3 tangent_u = float3(deltaU.x, 0, _HeightScale* (h2_u - h1_u));

		//	float2 deltaV = float2(0, _WaterMask_TexelSize.y * _DeltaScale);
		//	float h1_v = tex2D(_WaterMask, uv - deltaV).g;
		//	float h2_v = tex2D(_WaterMask, uv + deltaV).g;
		//	float3 tangent_v = float3(0, deltaV.x, _HeightScale * (h2_v - h1_v));

		//	//float3 normal = normalize(cross(tangent_v, tangent_u));
		//	float3 normal = clamp(cross(tangent_u,tangent_v),float3(-1,-1,-1), float3(1,1,1));

		//	return normal;
		//}

		//随机透明度
		float3 N13(float p) {
			float3 p3 = frac(float3(p, p, p) * float3(.1031, .11369, .13787));
			p3 += dot(p3, p3.yzx + 19.19);
			return frac(float3((p3.x + p3.y) * p3.z, (p3.x + p3.z) * p3.y, (p3.y + p3.z) * p3.x));
		}
		float4 N14(float t) {
			return frac(sin(t * float4(123., 1024., 1456., 264.)) * float4(6547., 345., 8799., 1564.));
		}
		float N(float t) {
			return frac(sin(t * 12345.564) * 7658.76);
		}

		float Saw(float b, float t) {
			return smoothstep(0., b, t) * smoothstep(1., b, t);
		}

		float3 DropLayer2(float2 uv, float t) {
			float2 UV = uv;
			//第一层
			uv.y += t * 0.75;
			float2 a = float2(6+ _UVTiling.x, 0.5+ _UVTiling.y);//均分6分
			float2 grid = a * 2.;
			float2 id = floor(uv * grid);

			float colShift = N(id.x);
			uv.y += colShift;

			id = floor(uv * grid);
			float3 n = N13(id.x * 35.2 + id.y * 2376.1);
			float2 st = frac(uv * grid) - float2(0.5, 0);

			float x = n.x - 0.5;

			float y = UV.y * 20;
			float wiggle = sin(y + sin(y));
			x += wiggle * (0.5 - abs(x)) * (n.z - 0.5);
			x *= _FixedDroplet;
			float ti = frac(t + n.z);
			y = (Saw(0.85, ti) - 0.5) * 0.9 + 0.5;


			float2 p = float2(x, y);

			float d = length((float2(st.x, st.y * 2 - 1))); //算园范围
			d = smoothstep(-0.1, 0.5, d);
			//float d = 1.0;

			//float mainDrop = smoothstep(_DropletSize, 0, d) * y;//⚪计算 优化掉

			float r = 1 - st.y;//控制上下波动

			float cd = abs(st.x - x);

			float trail = smoothstep(0.8 * r, 0.05 * r * r, cd) * (0.5 - cd * cd);

			trail = smoothstep(0.0, 0.8, trail);

			float trailFront = st.y * y;
			trail = trail * trailFront * (1 - cd) * 8 * (1 - st.y * st.y);
			//trail = max(mainDrop, trail);
			float halfU = st.x - x;


			trail = lerp((1 - d), trail.x,  y) ;


			float normalPow = 4* _NormalmapPow;//法线强度
			float normalG = clamp((r - 0.5) * trail * normalPow, 0, 1) ;
			float normalR = -(halfU) * trail * normalPow ;// *c.r + 0.5;// -(c.g - 0.5) * c.r + 0.5;


			return float3(trail, normalR , normalG);

		}



		float StaticDrops(float2 uv, float t) {
			uv *= 10.;
			uv.y += t * 5;
			float2 id = floor(uv);
			uv = frac(uv) - .5;
			float3 n = N13(id.x * 107.45 + id.y * 3543.654);
			float2 p = (n.xy - .5) * .7;
			float d = length(uv - p);

			float fade = Saw(.025, frac(t + n.z));
			float c = smoothstep(.3, 0., d) * frac(n.z * 10.) * fade;
			return c;
		}
		half3 BlendNormal(half3 n1, half3 n2)
		{
			return normalize(half3(n1.xy + n2.xy, n1.z * n2.z));
		}
		float3 Drops(float2 uv, float t, float l0, float l1, float l2) {

			//可以优化掉一个降一点效果
			float3 m1 = DropLayer2(uv, t) * l1;
			float3 m2 = DropLayer2(uv * _DropletDensity, t) * l2;
			//float3 m2 = float3(0, 0, 0);
			float3 m3 = DropLayer2(uv * _DropletDensity*0.8, t) * l0;
			//m3 = float3(0, 0, 0);
			float res = (m1.x + m2.x + m3.x) * (1 - uv.y*4* uv.y);
			float3 normalFini = BlendNormal(float3(m1.yz, 1), float3(m2.yz, 1));
			normalFini = BlendNormal(float3(m3.yz, 1) , float3(normalFini.xyz));
			normalFini = float3(m1.yz+ m2.yz+ m3.yz, 1);
			//normalFini = m1.;
			//return float2(c, max(m1.y * l0, m2.y * l1));
			return float3(res, normalFini.x , normalFini.y);

		}

		float2 DropsDynamic(float2 uv, float t, float l1, float l2)
		{
			float2 m1 = DropLayer2(uv, t) * l1;
			float2 m2 = DropLayer2(uv * 1.75, t) * l2;

			float c = m1.x + m2.x;
			c = smoothstep(.4, 1., c);

			return float2(c, max(0, m2.y * l1));
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
			"IgnoreProjector" = "true"
			"RenderType" = "TransparentCuout"
			}

			Pass
			{
				Name "FORWARD"
				Tags {  "LightMode" = "ForwardBase" }
				BlendOp Add
			//Blend[_SrcBlend][_DstBlend]

			ZWrite off
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
				float4 mdlPos = AnimateVertex2(worldPos);

				o.normalDir = UnityObjectToWorldNormal(v.normal);
				o.tangentDir = normalize(mul(unity_ObjectToWorld, float4(v.tangent.xyz, 0.0)).xyz);
				o.bitangentDir = normalize(cross(o.normalDir, o.tangentDir) * v.tangent.w);
				o.posWorld = mul(unity_ObjectToWorld, v.vertex);

				o.vertex = UnityWorldToClipPos(mdlPos.xyz);
				o.test = mdlPos.xyzz;

				o.uv.xy = v.uv;


				half waveValue = 0.1;
				half waveValueDouble = _WaverTexSpeed;

				half lineWaveDouble = _Time.y * waveValueDouble;

				o.uv.zw = o.uv.xy + half2(0,  lineWaveDouble * 1.5 - 0.1);


				o.uv2.zw = half2(v.uv2.x * 0.8 , v.uv2.y * 0.9 + lineWaveDouble - 0.5);


				o.color = saturate(worldPos.y * 2);

				//UNITY_INITIALIZE_OUTPUT(v2f, o);
				return o;
			}
			fixed4 frag(v2f i) : SV_Target
			{
				//===================normal and flowmap mask calculate====================
				float4 fragColor = 0;
				float2 caluv1 = i.uv.xy;
				float3 M = 2;
				float T = (_Time.y + M.x * 2) * _Speed;
				float t = T * (.2 + 0.1 * _MoreRainAmount);
				float rainAmount = M.y;
				caluv1 *= 0.5;
				float staticDrops = smoothstep(-.5, 1., rainAmount) * 2.;
				float layer1 = smoothstep(.25, .75, rainAmount);
				float layer2 = smoothstep(.0, .5, rainAmount);
				float3 calRM = Drops(caluv1, t, staticDrops, layer1, layer2);
				//===================扰动及法线预处理计算===============================

				float2 UV1 = TRANSFORM_TEX(i.uv.xy, _MainTex);
				float2 UV2 = TRANSFORM_TEX(i.uv.xy, _MaskTex);

				//=============================flowMap==================================
				//float3 flowTex = tex2D(_WaterMask, i.uv2.xy).rgb;
				float3 flowTex = float3(0,0.5,0);
				half uvMask = (i.uv.y) * (i.uv.y);
				half maskRange = smoothstep( _flowMask-0.5 , _flowMask+ _flowMaskRange, 1 - uvMask);
				flowTex = float3(calRM.r*0.5 * maskRange, calRM.r  *(maskRange), 0);//* 1.5

				float3 flowDir = flowTex * 2.0f - 1.0f;
				flowDir *= _TextureSpeed;

				float phase0 = frac(_Time[1] * 0.5f + 0.5f);
				float phase1 = frac(_Time[1] * 0.5f + 1.0f);

				half3 tex0 = tex2D(_MainTex, UV1 + flowDir.xy * float2(1,-phase0));
				half3 tex1 = tex2D(_MainTex, UV1 + flowDir.xy * float2(1, -phase1));
				half3 maskTex = tex2D(_MaskTex, UV2);

				float flowLerp = abs((0.5f - phase0) * 2);
				half3 finalFlowColor = lerp(tex0, tex1, flowLerp);//最后的基色结果
				//======================================================================


				//=======================法线计算过程==================================
				/* 灰度转法线
					float3 objNormal = GetNormalByGray(i.uv.xy);
					objNormal.rgb = float3(objNormal.r, objNormal.g, 1.0);
				 */
				//float3 lightDirection = normalize(_WorldSpaceLightPos0.xyz + float3(0, +0.0000000001, 0));
				half3x3 tangentTransform = float3x3(i.tangentDir, i.bitangentDir, i.normalDir);
				half3 norm = tex2D(_Normalmap, TRANSFORM_TEX(i.uv.zw, _Normalmap));
				half3 norm2 = tex2D(_Normalmap, TRANSFORM_TEX(i.uv2.zw, _Normalmap));

				half normMask = lerp(1, uvMask, _normMask);
				half3 norm3 = norm * norm2 * 0.5 * normMask + 0.25;// (norm* norm2 - 0.5)* (i.uv.y)* (i.uv.y) + 0.5;

				float3 objNormal = float3(calRM.g, calRM.b, 0.5) * maskRange * _flowMask;
				objNormal += norm3;
				float3 normalWorld = normalize(mul(objNormal, tangentTransform)); // Perturbed normals
				float3 worldNormal = normalWorld;

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

				//待优化计算
				half alpha = 1.0 - smoothstep(0.52, 0.55, flowTex.g);
				half SSSF = lerp(alpha, alpha * (1 - flowTex.g), 1 - _Color.a);

				col.rgb = SimulateFog(i.posWorld, col.rgb);


				return float4(col , SSSF);
				//return float4(objNormal,1);
				//return float4(norm * norm2 * 0.5 * (i.uv.y) * (i.uv.y)+0.25 + objNormal, 1);
				}
				ENDCG
		}

		}

}
