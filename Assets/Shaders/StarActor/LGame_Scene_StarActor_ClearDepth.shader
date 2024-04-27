Shader "LGame/Scene/StarActor/ClearDepth"
{
    Properties
    {

    }
	SubShader
	{
		Tags { "Queue" = "AlphaTest-50" "RenderType" = "Transparent" }
		Pass
		{
			Stencil {
				Ref 16
				Comp always
				Pass replace
			}
			ColorMask 0
			Cull Off
			ZTest Always
			ZWrite On
		}
	}
}
