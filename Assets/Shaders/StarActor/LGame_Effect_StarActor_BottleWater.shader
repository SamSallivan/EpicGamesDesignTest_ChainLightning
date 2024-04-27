Shader "LGame/Effect/StarActor/BottleWater"
{
	Properties {
		[Header(Bubble Motion)]
		_Qipao("QiPao R",2D)="white"{}
		_Noise("Noise",2D)="white"{}
		[Header(Water Caustics)]
		_Caustics("Caustics R",2D)="white"{}
		_CausticsSpeed("Caustics Speed",float)=0
		_CausticsColor("Caustics Color",Color)=(1.0,1.0,1.0,1.0)
		[Header(Water Color)]
		_ShallowColor("Top Color",Color)=(1.0,1.0,1.0,1.0)
		_DeepColor("Bottom Color",Color)=(1.0,1.0,1.0,1.0)
		_BackColor("Back Color",Color) = (1.0,1.0,1.0,1.0)
		[Header(Bottle Settings)]
		_Percent("Percent",float)=0
		_Ratio("Aspect Ratio",Range(-1,1))=1
		[Header(Water Wave)]
		_WaveScale("Wave Scale",Range(-1,1))=0
		_WaveWidth("Wave Width",float)=0
		_WaveSpeed("Wave Speed",float)=0
		[Header(Rim Light)]
		_RimColor("Rim Color",Color)=(1,1,1,1)
		_RimPower("Rim Power",float)=10
	}
SubShader {
	Tags { 
	"Queue"="Transparent" 
	"IgnoreProjector"="True" 
	"RenderType"="Transparent" 
	}
	Blend SrcAlpha OneMinusSrcAlpha
	LOD 300
	Cull Front
	zWrite On
	Stencil {
		Ref 16
		Comp always
		Pass replace
	}
	Pass {
	CGPROGRAM
	//#pragma multi_compile __ _USE_DIRECT_GPU_SKINNING
	#pragma vertex vert
	#pragma fragment frag
	#pragma target 3.0
	#include "UnityCG.cginc"
	#include "Assets/CGInclude/LGameCharacterDgs.cginc" 
	struct a2v {
		half4 uv : TEXCOORD0 ;
		half4 vertex : POSITION ;
#ifdef _USE_DIRECT_GPU_SKINNING
		float4 skinIndices : TEXCOORD2;
		float4 skinWeights : TEXCOORD3;
#endif
	};

	struct v2f{
		half4 pos : SV_POSITION ;
		float2 uv : TEXCOORD0  ;		
		float4 wPos:TEXCOORD1;
		float4 screenPos:TEXCOORD2;
		float2 params:TEXCOORD3;
	};
	fixed4 _ShallowColor;
	fixed4 _DeepColor;
	fixed4 _BackColor;

	float4 _Caustics_ST;
	fixed4 _CausticsColor;
	half _Percent;
	float _WaveScale;
	float _WaveSpeed;
	half _Ratio;
	float _WaveWidth;
	float _CausticsSpeed;

	v2f vert(a2v v)
	{
		v2f o;
#if _USE_DIRECT_GPU_SKINNING
		v.vertex = CalculateGPUSkin_L(v.skinIndices, v.skinWeights, v.vertex);
		v.uv.xy = DecompressUV(v.uv.xy, _uvBoundData);
#endif
		o.uv.xy = v.uv;
		o.wPos.xyz=mul(unity_ObjectToWorld,v.vertex).xyz;
		o.pos=UnityObjectToClipPos(v.vertex);
		o.screenPos=ComputeScreenPos(o.pos);
		half3 origin=mul(unity_ObjectToWorld,half4(0,0,0,1));
		half3 up=mul(unity_ObjectToWorld,half4(-1,0,0,1));
		half3 dir=normalize(up-origin);
		o.wPos.w=length(UnityWorldSpaceViewDir(origin.xyz));
		o.params.x=abs(dot(half3(0,1,0),dir));
		o.params.y=origin.y;
		return o;
	}
	fixed4 frag(v2f i) : COLOR
	{
		half2 screenUV=i.screenPos.xy/i.screenPos.w*i.wPos.w*_ScreenParams.xy/_ScreenParams.x;
		half percent=lerp(_Percent*_Ratio,_Percent,i.params.x);

		half height=percent+i.params.y;

		float wave=_WaveScale*sin(screenUV.x*_WaveWidth*75+_Time.y*_WaveSpeed);
		wave+=_WaveScale*cos(screenUV.x*_WaveWidth*40+_Time.y*_WaveSpeed*2);
		wave*=0.1;

		/*
		float noise=tex2D(_Noise,screenUV).r;
		float qipao=tex2D(_Qipao,screenUV+half2(0,-_Time.y+noise*0.1));
		float caustics=tex2D(_Caustics,screenUV.xy+_Time.y*_CausticsSpeed*3).r;
		caustics*=tex2D(_Caustics,screenUV.xy+_Time.y*_CausticsSpeed+noise*0.1).r;
		_CausticsColor*=caustics;
		*/

		/*
		//颜色的混合顺序，先深度着色，然后气泡，然后焦散，最后小气泡。
		fixed4 col=lerp(_ShallowColor,_DeepColor,height-i.wPos.y);
		col = lerp(col, _BackColor, 0.5);
		col.rgb=lerp(col,col.rgb+_DeepColor.rgb,min(1,qipao));
		col=lerp(col,1,_CausticsColor);
		if(i.wPos.y+wave>height)
			col.a=0;
		*/
		_BackColor.a *= lerp(1.0, 0.0, height-i.wPos.y);
		
		if(i.wPos.y+wave>height)
			_BackColor.a=0;

		//return col;	
		return _BackColor;
	}
	ENDCG
	}
	Blend SrcAlpha OneMinusSrcAlpha
	LOD 200
	Cull Back
	zWrite On
	Pass {
	CGPROGRAM
	//#pragma multi_compile __ _USE_DIRECT_GPU_SKINNING
	#pragma vertex vert
	#pragma fragment frag
	#pragma target 3.0
	#include "UnityCG.cginc"
	#include "Assets/CGInclude/LGameCharacterDgs.cginc" 
	struct a2v {
		float4 uv : TEXCOORD0 ;
		half4 vertex : POSITION ;
		half3 normal:NORMAL;
#ifdef _USE_DIRECT_GPU_SKINNING
		float4 skinIndices : TEXCOORD2;
		float4 skinWeights : TEXCOORD3;
#endif
	};

	struct v2f{
		float4 pos : SV_POSITION ;
		float4 uv : TEXCOORD0  ;		
		float4 wPos:TEXCOORD1;
		float4 screenPos:TEXCOORD2;
		float4 viewDir:TEXCOORD3;
		float4 wNormal:TEXCOORD4;
	};
	fixed4 _ShallowColor;
	fixed4 _DeepColor;
	fixed4 _BackColor;
	sampler2D _Caustics;
	float4 _Caustics_ST;
	fixed4 _CausticsColor;
	half _Percent;
	float _WaveScale;
	float _WaveSpeed;
	half _Ratio;
	float _WaveWidth;
	float _CausticsSpeed;
	half _RimPower;
	fixed4 _RimColor;

	sampler2D _Noise;
	sampler2D _Qipao;
	v2f vert(a2v v)
	{
		v2f o;
#if _USE_DIRECT_GPU_SKINNING
		v.vertex = CalculateGPUSkin_L(v.skinIndices, v.skinWeights, v.vertex);
		v.uv.xy = DecompressUV(v.uv.xy, _uvBoundData);
#endif
		half3 origin=mul(unity_ObjectToWorld,half4(0,0,0,1));
		half3 up=mul(unity_ObjectToWorld,half4(-1,0,0,1));
		half3 dir=normalize(up-origin);

		o.uv.xy = v.uv;
		o.wPos.xyz=mul(unity_ObjectToWorld,v.vertex).xyz;
		o.pos=UnityObjectToClipPos(v.vertex);
		o.screenPos=ComputeScreenPos(o.pos);
		o.viewDir.xyz=UnityWorldSpaceViewDir(o.wPos.xyz);
		o.wNormal.xyz=UnityObjectToWorldNormal(v.normal);

		o.viewDir.w=length(UnityWorldSpaceViewDir(origin.xyz));
		o.wPos.w=abs(dot(half3(0,1,0),dir));
		o.wNormal.w=origin.y;
		return o;
	}
	fixed4 frag(v2f i) : COLOR
	{
		half ndotv=saturate(dot(i.wNormal.xyz,normalize(i.viewDir.xyz)));
		half3 rim=pow(1-ndotv,_RimPower)*_RimColor.rgb;

		half2 screenUV=i.screenPos.xy/i.screenPos.w*i.viewDir.w*_ScreenParams.xy/_ScreenParams.x;
		half percent=lerp(_Percent*_Ratio,_Percent,i.wPos.w);

		half height=percent+i.wNormal.w;

		float wave=_WaveScale*sin(screenUV.x*_WaveWidth*100+_Time.y*_WaveSpeed);
		wave+=_WaveScale*cos(screenUV.x*_WaveWidth*50+_Time.y*_WaveSpeed*2);
		wave*=0.1;

		
		float noise=tex2D(_Noise,screenUV).r;
		float qipao=tex2D(_Qipao,screenUV+ float2(0,-_Time.y * 0.15 + noise * 0.5));
		float caustics=tex2D(_Caustics,screenUV.xy+_Time.y*_CausticsSpeed*3).r;
		caustics*=tex2D(_Caustics,screenUV.xy+_Time.y*_CausticsSpeed+noise*0.1).r;
		_CausticsColor*=caustics;
		

		
		//颜色的混合顺序，先深度着色，然后气泡，然后焦散，最后小气泡。
		fixed4 col=lerp(_ShallowColor,_DeepColor,height-i.wPos.y);
		//col = lerp(col, _BackColor, 0.5);
		col.rgb=lerp(col.rgb,col.rgb+_DeepColor.rgb,min(1,qipao));
		col += _CausticsColor;
		col.rgb+=rim;
		if(i.wPos.y+wave>height)
			col.a=0;
		return col;	
	}
	ENDCG
	}
	}
	SubShader{
	Tags {
	"Queue" = "Transparent"
	"IgnoreProjector" = "True"
	"RenderType" = "Transparent"
	}
	Blend SrcAlpha OneMinusSrcAlpha
	LOD 100
	Cull Front
	zWrite On
	Stencil {
		Ref 16
		Comp always
		Pass replace
	}
	Pass {
	CGPROGRAM
	//#pragma multi_compile __ _USE_DIRECT_GPU_SKINNING
	#pragma vertex vert
	#pragma fragment frag
	#pragma target 3.0
	#include "UnityCG.cginc"
	#include "Assets/CGInclude/LGameCharacterDgs.cginc" 
	struct a2v {
		float4 uv : TEXCOORD0;
		float4 vertex : POSITION;
#ifdef _USE_DIRECT_GPU_SKINNING
		float4 skinIndices : TEXCOORD2;
		float4 skinWeights : TEXCOORD3;
#endif
	};

	struct v2f {
		half4 pos : SV_POSITION;
		float2 uv : TEXCOORD0;
		float4 wPos:TEXCOORD1;
		float4 screenPos:TEXCOORD2;
		float2 params:TEXCOORD3;
	};
	fixed4 _ShallowColor;
	fixed4 _DeepColor;
	fixed4 _BackColor;
	half _Percent;
	float _WaveScale;
	float _WaveSpeed;
	half _Ratio;
	float _WaveWidth;
	v2f vert(a2v v)
	{
		v2f o;
#if _USE_DIRECT_GPU_SKINNING
		v.vertex = CalculateGPUSkin_L(v.skinIndices, v.skinWeights, v.vertex);
		v.uv.xy = DecompressUV(v.uv.xy, _uvBoundData);
#endif
		o.uv.xy = v.uv;
		o.wPos.xyz = mul(unity_ObjectToWorld,v.vertex).xyz;
		o.pos = UnityObjectToClipPos(v.vertex);
		o.screenPos = ComputeScreenPos(o.pos);
		half3 origin = mul(unity_ObjectToWorld,half4(0,0,0,1));
		half3 up = mul(unity_ObjectToWorld,half4(-1,0,0,1));
		half3 dir = normalize(up - origin);
		o.wPos.w = length(UnityWorldSpaceViewDir(origin.xyz));
		o.params.x = abs(dot(half3(0,1,0),dir));
		o.params.y = origin.y;
		return o;
	}
	fixed4 frag(v2f i) : COLOR
	{
		half2 screenUV = i.screenPos.xy / i.screenPos.w*i.wPos.w*_ScreenParams.xy / _ScreenParams.x;
		half percent = lerp(_Percent*_Ratio,_Percent,i.params.x);
		half height = percent + i.params.y;
		float wave = _WaveScale * sin(screenUV.x*_WaveWidth * 75 + _Time.y*_WaveSpeed);
		wave += _WaveScale * cos(screenUV.x*_WaveWidth * 40 + _Time.y*_WaveSpeed * 2);
		wave *= 0.1;
		_BackColor.a *= lerp(1.0, 0.0, height - i.wPos.y);
		if (i.wPos.y + wave > height)
			_BackColor.a = 0;	
		return _BackColor;
	}
	ENDCG
	}
	Blend SrcAlpha OneMinusSrcAlpha
	LOD 100
	Cull Back
	zWrite On
	Pass {
	CGPROGRAM
	//#pragma multi_compile __ _USE_DIRECT_GPU_SKINNING
	#pragma vertex vert
	#pragma fragment frag
	#pragma target 3.0
	#include "UnityCG.cginc"
	#include "Assets/CGInclude/LGameCharacterDgs.cginc" 
	struct a2v {
		half4 vertex : POSITION;
		half3 normal:NORMAL;
#ifdef _USE_DIRECT_GPU_SKINNING
		float4 skinIndices : TEXCOORD2;
		float4 skinWeights : TEXCOORD3;
#endif
	};

	struct v2f {
		half4 pos : SV_POSITION;
		float4 wPos:TEXCOORD1;
		float4 screenPos:TEXCOORD2;
		float4 viewDir:TEXCOORD3;
		float4 wNormal:TEXCOORD4;
	};
	fixed4 _ShallowColor;
	fixed4 _DeepColor;
	fixed4 _BackColor;
	half _Percent;
	float _WaveScale;
	float _WaveSpeed;
	half _Ratio;
	float _WaveWidth;
	half _RimPower;
	fixed4 _RimColor;
	v2f vert(a2v v)
	{
		v2f o;
#if _USE_DIRECT_GPU_SKINNING
		v.vertex = CalculateGPUSkin_L(v.skinIndices, v.skinWeights, v.vertex);
#endif
		half3 origin = mul(unity_ObjectToWorld,half4(0,0,0,1));
		half3 up = mul(unity_ObjectToWorld,half4(-1,0,0,1));
		half3 dir = normalize(up - origin);
		o.wPos.xyz = mul(unity_ObjectToWorld,v.vertex).xyz;
		o.pos = UnityObjectToClipPos(v.vertex);
		o.screenPos = ComputeScreenPos(o.pos);
		o.viewDir.xyz = UnityWorldSpaceViewDir(o.wPos.xyz);
		o.wNormal.xyz = UnityObjectToWorldNormal(v.normal);
		o.viewDir.w = length(UnityWorldSpaceViewDir(origin.xyz));
		o.wPos.w = abs(dot(half3(0,1,0),dir));
		o.wNormal.w = origin.y;
		return o;
	}
	fixed4 frag(v2f i) : COLOR
	{
		half ndotv = saturate(dot(i.wNormal.xyz,normalize(i.viewDir.xyz)));
		half3 rim = pow(1 - ndotv,_RimPower)*_RimColor.rgb;
		half2 screenUV = i.screenPos.xy / i.screenPos.w*i.viewDir.w*_ScreenParams.xy / _ScreenParams.x;
		half percent = lerp(_Percent*_Ratio,_Percent,i.wPos.w);
		half height = percent + i.wNormal.w;
		float wave = _WaveScale * sin(screenUV.x*_WaveWidth * 100 + _Time.y*_WaveSpeed);
		wave += _WaveScale * cos(screenUV.x*_WaveWidth * 50 + _Time.y*_WaveSpeed * 2);
		wave *= 0.1;
		fixed4 col = lerp(_ShallowColor,_DeepColor,height - i.wPos.y);
		col.rgb += rim;
		if (i.wPos.y + wave > height)
			col.a = 0;
		return col;
	}
	ENDCG
	}
	}
}
