Shader "LGame/Effect/DirectionalMatcap"
{
     Properties
	{
		[Enum(UnityEngine.Rendering.BlendMode)]_DstFactor("混合：OneMinusSrcAlpha/叠加：One", Float) = 10
		_BackColor			("BackColor",Color)=(1,1,1,1)
		_ColorPosition		("ColorPosition",Range(0,1))=0.5
		_ColorSoft			("ColorSoft",Range(0,1))=0.5
		_MatCap				("MatCap",2D)="white" {}
		_MatCapStrength		("MatCapStrength",Range(-1.5,1.5))=0.5
		_MatCapRange		("MatCapRange",Range(0,1.5))=0.5
		_Contrast			("Contrast",Range(0,1))=0.5
		_Mask				("_Mask",2D)="white"{}
		_Alpha				("_Alpha",Range(0,1))=0.5
	}
	SubShader
	{
		Tags {"LightMode"="ForwardBase" "Queue"="Transparent" "DisableBatching"="True" "RenderType"="Transparent" "IgnoreProjector"="True"}
		Blend SrcAlpha [_DstFactor]
		ZWrite Off
		ZTest LEqual
		Cull Back
		LOD 100
		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"
			struct appdata
			{
				half4 vertex		: POSITION;
				half2 uv			: TEXCOORD0;
				half3 normal		: NORMAL;
			};
			struct v2f
			{
				half4 vertex		: SV_POSITION;
				half2 matcapuv		: TEXCOORD0;
				half3 wNormal		:TEXCOORD1;
				half4 mPos			:TEXCOORD2;
			};
			fixed4					_BackColor;
			sampler2D				_MatCap;
			float4					_MatCap_ST;
			sampler2D				_Mask;
			float4					_Mask_ST;
			half					_ColorPosition;
			half					_ColorSoft;
			half					_MatCapStrength;
			half					_MatCapRange;
			half					_Contrast;
			half					_Alpha;
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.wNormal=UnityObjectToWorldNormal(v.normal);
				//引入局部空间
				//做法：取模型空间的旋转轴和世界空间的Y轴，叉乘获取固定的向前方向，进而获得顶点所需颜色强度
				half3 localanchorx=half3(1,0,0);
				half3 localanchory=normalize(mul(unity_WorldToObject,half3(0,1,0)));
				half3 newanchor=normalize(cross(localanchory,localanchorx));
				half3 wspos=normalize(v.vertex);
				o.mPos.xyz=dot(wspos,newanchor);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				//计算matcapuv并采样
				half3 nDirVS=mul(UNITY_MATRIX_V,i.wNormal);
				i.matcapuv=nDirVS.xy*0.5+0.5;
				fixed4 var_matcap=tex2D(_MatCap,i.matcapuv);
				fixed4 var_mask=tex2D(_Mask,i.matcapuv*_Mask_ST.xy+_Mask_ST.zw);
				//利用位置获取颜色强度
				half colorstrength=clamp(0,1,i.mPos.x);
				fixed4 col=fixed4(1,1,1,1);
				col.rgb=_BackColor;
				colorstrength=smoothstep(_ColorPosition-_ColorSoft,_ColorPosition+_ColorSoft,colorstrength);
				col.a=_Alpha*var_mask.r*lerp(1,0,saturate(colorstrength));
				//对matcap贴图进行平滑插值操作
				fixed3 matcap=var_mask.r*smoothstep(_MatCapStrength-_MatCapRange,_MatCapStrength+_MatCapRange,var_matcap.r);
				fixed3 colormax=max(col.xyz,matcap);
				fixed3 colormul=col.xyz*matcap;
				col.xyz=lerp(colormul,colormax,lerp(1,matcap.r,_Contrast));
				return col;
			}
			ENDCG
		}
	}
}
