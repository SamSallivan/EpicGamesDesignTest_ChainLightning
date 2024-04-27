Shader "LGame/UI/AdaptableEffect"
{
    Properties
    {
		_Sprite("Sprite", 2D) = "white" {}
		_MainTex("Texture", 2D) = "white" {}
		_Border("Border(L/T/R/B)",Vector) = (0,0,0,0)
		_Alpha("Alpha", Range(0.0, 1.0)) = 1.0
	}
	SubShader
	{
		// No culling or depth
		Cull Off ZWrite Off ZTest Always
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

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            sampler2D _MainTex;
			sampler2D _Sprite;
			float4 _MainTex_TexelSize;
			float4 _Sprite_TexelSize;
			float4 _Border;//L/T/R/B
			half _Alpha;

            fixed4 frag (v2f i) : SV_Target
            {
				//屏幕RT
				fixed4 Source = tex2D(_MainTex, i.uv);

				float SpriteWidth = _Sprite_TexelSize.z;
				float SpriteHeight = _Sprite_TexelSize.w;

				float MainWidth = _MainTex_TexelSize.z;
				float MainHeight = _MainTex_TexelSize.w;

				float4 Border = _Border / float4(SpriteWidth, SpriteHeight, SpriteWidth, SpriteHeight);
				float4 BorderT = _Border / float4(MainWidth, MainHeight, MainWidth, MainHeight);

				float TopBorder = 1.0 - Border.y;
				float BottomBorder = Border.w;
				float LeftBorder = Border.x;
				float RightBorder = 1.0 - Border.z;
		
				float TopBorderT = 1.0 - BorderT.y;
				float BottomBorderT = BorderT.w;
				float LeftBorderT = BorderT.x;
				float RightBorderT = 1.0 - BorderT.z;

				float MultiX = _MainTex_TexelSize.z / _Sprite_TexelSize.z;
				float MultiY = _MainTex_TexelSize.w / _Sprite_TexelSize.w;

				float ReMapRatioX = (RightBorder - LeftBorder) / (RightBorderT - LeftBorderT);
				float ReMapRatioY = (TopBorder - BottomBorder) / (TopBorderT - BottomBorderT);

				//float ReMapConstantX = LeftBorder - LeftBorderT;
				//float ReMapConstantY = BottomBorder - BottomBorderT;

				float GapX = _Sprite_TexelSize.x * 0.5;
				float GapY = _Sprite_TexelSize.y * 0.5;

				float WidthOffset = frac(MultiX);
				float HeightOffset = frac(MultiY);

				float TopBorderGap = TopBorder - GapY;
				float BottomBorderGap = BottomBorder + GapY;
				float LeftBorderGap = LeftBorder + GapX;
				float RightBorderGap = RightBorder - GapX;

				float2 AspectUV = i.uv * float2(MultiX, MultiY);


				float ReMapConstantX = LeftBorder - LeftBorderT * ReMapRatioX;
				float ReMapConstantY = LeftBorder - BottomBorderT * ReMapRatioY;
				////////////////////////////////////////////////////////
				//Four Conrners
                fixed4 LBSprite = tex2D(_Sprite, AspectUV);
				fixed4 LTSprite = tex2D(_Sprite, AspectUV - float2(0.0,HeightOffset));
				fixed4 RTSprite = tex2D(_Sprite, AspectUV - float2(WidthOffset, HeightOffset));
				fixed4 RBSprite = tex2D(_Sprite, AspectUV - float2(WidthOffset, 0.0));
				//Four Edges
				float2 XMCoord = i.uv;
				XMCoord.x = AspectUV.x;

				XMCoord.y = XMCoord.y * ReMapRatioY + ReMapConstantY;
				XMCoord.y = clamp(XMCoord.y, BottomBorderGap, TopBorderGap);
				fixed4 LMSprite = tex2D(_Sprite, XMCoord);
				fixed4 RMSprite = tex2D(_Sprite, XMCoord - float2(WidthOffset, 0.0));

				float2 MXCoord = i.uv;
				MXCoord.x = MXCoord.x * ReMapRatioX + ReMapConstantX;
				MXCoord.x = clamp(MXCoord.x, LeftBorderGap, RightBorderGap);
				MXCoord.y = AspectUV.y;
				fixed4 MTSprite = tex2D(_Sprite, MXCoord - float2(0.0, HeightOffset));
				fixed4 MBSprite = tex2D(_Sprite, MXCoord);
				
				float2 MMCoord = i.uv;
				MMCoord.x = MMCoord.x  * ReMapRatioX + ReMapConstantX;
				MMCoord.y = MMCoord.y  * ReMapRatioY + ReMapConstantY;

				MMCoord.x = clamp(MMCoord.x, LeftBorderGap, RightBorderGap);
				MMCoord.y = clamp(MMCoord.y, BottomBorderGap, TopBorderGap);

				fixed4 MMSprite = tex2D(_Sprite, MMCoord);

				float2 AspectOneMinusUV = float2(MultiX, MultiY)- AspectUV;
				float Row0 = step(AspectUV.y, Border.w);
				float Row2 = step(AspectOneMinusUV.y,Border.y);
				float Row1 = 1.0 - Row0 - Row2;

				float Col0 = step(AspectUV.x, Border.x);
				float Col2 = step(AspectOneMinusUV.x, Border.z);
				float Col1 = 1.0 - Col0 - Col2;

				fixed4 Color =
					LBSprite * Row0 * Col0 +
					LMSprite * Row1 * Col0 +
					LTSprite * Row2 * Col0 +

					MBSprite * Row0 * Col1 +
					MMSprite * Row1 * Col1 +
					MTSprite * Row2 * Col1 +

					RBSprite * Row0 * Col2 +
					RMSprite * Row1 * Col2 +
					RTSprite * Row2 * Col2 ;
				Color.rgb = lerp(0.0.xxx, Color.rgb, Color.a);
				return fixed4(lerp(Source.rgb, Color.rgb + Source.rgb, _Alpha), 1.0); //fixed4(_Alpha, _Alpha, _Alpha, 1);
            }
            ENDCG
        }
    }
	CustomEditor "LGameSDK.AnimTool.LGameUIAdaptableEffectShaderGUI"
}
