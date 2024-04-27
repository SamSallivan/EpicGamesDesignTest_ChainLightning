// 通用纹理变换shader
Shader "LGame/Transforming/Texture"
{
	Properties
	{
		_MainTex ("Sprite Texture", 2D) = "white" {}
        _Rotation ("Rotation", vector) = (0, 0, 0, 0)
        _Translation ("Translation", vector) = (0, 0, 0, 0)
        _Flipped ("Flipped", Int) = 0
	}

	SubShader
	{
		Tags
		{ 
			"Queue"="Transparent" 
			"IgnoreProjector"="True" 
			"RenderType"="Transparent" 
			"PreviewType"="Plane"
			"CanUseSpriteAtlas"="True"
		}

		Cull Off
		Lighting Off
		ZWrite Off
		Blend SrcAlpha OneMinusSrcAlpha

		Pass
		{
			Name "Default"
		CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 2.0

			#include "UnityCG.cginc"

            uniform float4 _Rotation;
            uniform float4 _Translation;
			
			struct appdata_t
			{
				float4 vertex   : POSITION;
				float4 color    : COLOR;
				float2 texcoord : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct v2f
			{
				float4 vertex   : SV_POSITION;
				fixed4 color    : COLOR;
				float2 texcoord  : TEXCOORD0;
				UNITY_VERTEX_OUTPUT_STEREO
			};

            float4x4 Translation(float4 translation)
            {
                return float4x4(1, 0, 0, translation.x
                , 0, 1, 0, translation.y
                , 0, 0, 1, translation.z
                , 0, 0, 0, 1);
            }

            float4x4 Rotation(float4 rotation)
            {
                float radX = radians(rotation.x);
                float radY = radians(rotation.y);
                float radZ = radians(rotation.z);

                float sinX = sin(radX);
                float cosX = cos(radX);
                float sinY = sin(radY);
                float cosY = cos(radY);
                float sinZ = sin(radZ);
                float cosZ = cos(radZ);

                float4x4 rot = float4x4(cosY * cosZ, -cosY * sinZ, sinY, 0
                , cosX * sinZ + sinX * sinY * cosZ, cosX * cosZ - sinX * sinY * sinZ, -sinX * cosY, 0
                , sinX * sinZ - cosX * sinY * cosZ, sinX * cosZ + cosX * sinY * sinZ, cosX * cosY, 0
                , 0, 0, 0, 1);

                return rot;
            }

			sampler2D _MainTex;
            int _Flipped;
			
			v2f vert(appdata_t IN)
			{
				v2f OUT;
                float4 pos = IN.vertex;


                pos = mul(Rotation(_Rotation), pos);

                pos = mul(Translation(_Translation), pos);


                //float4 rotationPos = IN.vertex;
				OUT.vertex = UnityObjectToClipPos(pos);
				OUT.texcoord = IN.texcoord;
                if (_Flipped == 1)
                {
                    OUT.texcoord = float2(1 - IN.texcoord.x, IN.texcoord.y);
                }

				return OUT;
			}

			fixed4 frag(v2f IN) : SV_Target
			{
				half4 color = tex2D(_MainTex, IN.texcoord);
			
				return color;
			}
		ENDCG
		}
	}
}
