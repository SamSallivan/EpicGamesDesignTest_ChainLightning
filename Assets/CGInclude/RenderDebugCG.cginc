#ifndef RENDER_DEBUG_INCLUDE  
#define RENDER_DEBUG_INCLUDE

float4    _MainTex_TexelSize; 

fixed4 _MipColor_0;
fixed4 _MipColor_1;
fixed4 _MipColor_2;
fixed4 _MipColor_3;
fixed4 _MipColor_4;
fixed4 _MipColor_5;
fixed4 _MipColor_6;
fixed4 _MipColor_7;
fixed4 _MipColor_8;
fixed4 _MipColor_9;
fixed4 _MipColor_10;

//偏导数方法 求mipmap的等级
inline float GetMipmapsLevel(half2 uv)
{
	float2 dx = ddx(uv);
	float2 dy = ddy(uv);
	float max_sqr = max(dot(dx,dx),dot(dy,dy));

	return 0.5 * log2(max_sqr);
}

inline fixed4 GetMipmapsLevelColor(fixed3 color , half2 uv)
{
    fixed4 c = 1.0;

    float mipmapLevel = GetMipmapsLevel(uv * _MainTex_TexelSize.zw );

    mipmapLevel = max(0,mipmapLevel);

    mipmapLevel = ceil(mipmapLevel);

    if(mipmapLevel == 0)
    {
        c.rgb = _MipColor_0;
    }
    else if(mipmapLevel == 1)
    {
        c.rgb = _MipColor_1;
    }
    else if(mipmapLevel == 2)
    {
        c.rgb = _MipColor_2;
    }
    else if(mipmapLevel == 3)
    {
        c.rgb = _MipColor_3;
    }
    else if(mipmapLevel == 4)
    {
        c.rgb = _MipColor_4;
    }
    else if(mipmapLevel == 5)
    {
        c.rgb = _MipColor_5;
    }
    else if(mipmapLevel == 6)
    {
        c.rgb = _MipColor_6;
    }
    else if(mipmapLevel == 7)
    {
        c.rgb = _MipColor_7;
    }
    else if(mipmapLevel == 8)
    {
        c.rgb = _MipColor_8;
    }
    else if(mipmapLevel == 9)
    {
        c.rgb = _MipColor_9;
    }
    else if(mipmapLevel == 10)
    {
        c.rgb = _MipColor_10;
    }


    return c;
}

#endif 