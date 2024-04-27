Shader "LGame/Effect/ShadowProxy"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
		_AlphaCtrl("AlphaCtrl",range(0,1)) = 1
	   _MainColor("Main Color" , Color) = (1,1,1,1)//染色	

    }
    SubShader
    {
		//Tags { "Queue"="AlphaTest" "LightMode" = "ForwardBase" "RenderType"="AlphaTest" }
		LOD 70
		Tags{ "Queue" = "AlphaTest" "RenderType" = "AlphaTest" }


		UsePass "Hidden/Character/Shadow Srp/CharacterShadowSrp"
		UsePass "Hidden/Character/Shadow Srp/CharacterSoftShadowSrp"
		//用于默认管线显示
		Pass
		{
            Name "Shadow"
            Stencil
            {
                Ref 0
				ReadMask 1
				WriteMask 1
                Comp equal
                Pass incrWrap
            }
			Blend DstColor Zero
			ZWrite off
			Offset -1 , 0

			CGPROGRAM

			#include "UnityCG.cginc"
			#pragma vertex vert
			#pragma fragment frag

			half4 		_LightPos;
			fixed4 		_ShadowColor;
			half 		_AlphaCtrl;

			struct a2v
			{
				float4 vertex : POSITION;
			};
			struct v2f
			{
				float4 vertex		: SV_POSITION;
			    fixed4 color		: COLOR;
			};

			inline v2f vert(a2v v)
			 {
			    v2f o;
				UNITY_INITIALIZE_OUTPUT(v2f , o);
				float4 pos = v.vertex;

				//得到阴影的世界空间坐标
			    half3 worldPos = mul(unity_ObjectToWorld , pos).xyz;
			
			    //灯光方向
			    fixed3 lightDir = normalize(_LightPos.xyz);

			    //阴影的世界空间坐标
				half3 shadowPos;
			    shadowPos.y = min(worldPos.y , _LightPos.w);
				shadowPos.xz = worldPos.xz - lightDir.xz * max(0 , worldPos.y - _LightPos.w) / lightDir.y; 

				//转换到裁切空间												 
				o.vertex = UnityWorldToClipPos(shadowPos);

				o.color.a = _ShadowColor.a *_AlphaCtrl;
				o.color.rgb = lerp(1.0.rrr , _ShadowColor.rgb , o.color.a);

				return o;
			}
			fixed4 frag (v2f i) : SV_Target
			{
				return  i.color;
			}


			ENDCG
		}
    }
}
