Shader "Hidden/Character/GhostShadow"
{
	Properties
	{
		_GhostTex("Ghost Textrue" , 2D)	= "white" {} 
		_GhostColor("Ghost Color" , Color) = (0,0,0,0)
		_GhostVector("Ghost Vector(w for speed)" , Vector) = (0,0,0,0.1)
		_GhostVector2("Ghost Vector2(w for speed)" , Vector) = (0,0,0,0.1)
		[SimpleToggle]_MultiVector("Multi Vector" , int) = 0
		_GhostScale("Ghost Scale" , Range(0,2)) = 1
		
	}
	SubShader
	{
		Tags { "Queue"="AlphaTest" "RenderType"="AlphaTest"}

		Blend One One
        ZWrite off
        Offset -1 , 0
        //阴影pass
		Pass
		{
            Name "Base"
			CGPROGRAM
			#pragma multi_compile __ _USE_DIRECT_GPU_SKINNING
			#define  GHOST_OFFSET 0
			#pragma vertex vert
			#pragma fragment frag
			#include "Assets\CGInclude\LGameCharacterGhostShaodw.cginc"
			ENDCG
		}
		Pass
		{
            Name "Base2"
			CGPROGRAM
			#pragma multi_compile __ _USE_DIRECT_GPU_SKINNING
			#define  GHOST_OFFSET 1
			#pragma vertex vert
			#pragma fragment frag
			#include "Assets\CGInclude\LGameCharacterGhostShaodw.cginc"
			ENDCG
		}
		
	}

}
