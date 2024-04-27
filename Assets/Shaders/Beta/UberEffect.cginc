#ifndef UBER_EFFECT
   #define UBER_EFFECT
   #define KEYVALUE(a,b,c) lerp(a, b, step(0, c))
   #include "UnityCG.cginc"
   //uv流动函数
   inline float2 uvAdd(float2 uv,float2 speed)
   {
       uv+=frac(_Time.x*speed);
       return uv;
   }
     inline float2 uvAddFreeDirection(float2 uv,float speed,float2 direction)
   {
        uv+=dot(uv,normalize(direction))*speed;
       return uv;
   }
   //uv旋转
    inline float2 rotateUV(float2 uv,float2 uvRotate)
   {
       float2 outUV;
       outUV = uv - 0.5;
       outUV = float2(outUV.x * uvRotate.y - outUV.y * uvRotate.x ,
                       outUV.x * uvRotate.x + outUV.y * uvRotate.y );
       return outUV + 0.5;
   }
   //图片染色函数
     inline fixed3 addColorToTexture(fixed3 color,fixed4 usetexture,half addstrength)
   {
       usetexture.rgb=usetexture.rgb*lerp(fixed3(1,1,1),color,addstrength);
       return usetexture;
   }
   //颜色关系函数
   //变亮颜色
     inline fixed3 addColor(fixed3 frontcolor,fixed3 backcolor,half addstrength)
   {
       return frontcolor+backcolor*addstrength;
   }
   //变暗颜色
     inline fixed3 multiColor(fixed3 frontcolor,fixed3 backcolor,half addstrength)
   {
       return frontcolor*lerp(fixed3(1,1,1),backcolor,addstrength);
   }
   //叠加颜色
    inline fixed3 overColor(fixed3 frontcolor,fixed3 backcolor,half addstrength)
   {
       return lerp(frontcolor,backcolor,addstrength);
   }
   //采样混合贴图
   inline fixed4 sampleMixedTexture(uint wrapMode, half2 uv, sampler2D mixedTexture)
		{
			// wrapMode = 10*uMode + vMode, 0 = clamp, 1 = repeat, 2 = mirror
			// e.g. 00 -> clampUV, 21 -> mirrorU and repeatV
			uint wrapV = fmod(wrapMode, 10);
			uint wrapU = (wrapMode - wrapV) / 10;
			/*
				clamp -> saturate(uv) 
				repeat -> frac(uv) 
				mirror -> frac(abs(uv)) 
			*/
			half2 wrapUV = half2(
				saturate(uv.x) * (1 - saturate(wrapU)) + saturate(wrapU) * frac(uv.x * (1 - saturate(wrapU - 1))),
				saturate(uv.y) * (1 - saturate(wrapV)) + saturate(wrapV) * frac( uv.y * (1 - saturate(wrapV - 1)))
			);
			// Why tex2Dgrad? https://forum.unity.com/threads/strange-render-artifact-dotted-white-lines-along-quad-borders.795870/#post-5296011
			fixed4 sampled = tex2Dgrad(mixedTexture, wrapUV, ddx(uv), ddy(uv));
			return sampled;
		}
   //颜色混合方式管理
   inline fixed3 colorManager(fixed3 frontcolor,fixed3 backcolor,half addstrength,int colortype)
   {
      //此方法不好读，暂时不用：
      //fixed3 finalcolor=KEYVALUE(KEYVALUE(coloradd,colormulti,colortype-1),colorover,colortype-2); 
      fixed3 finalcolor=frontcolor;
      if(colortype>1)
      {
          finalcolor=backcolor;
      }
      else
      {
          finalcolor=frontcolor*colortype+frontcolor*backcolor;
      }
      finalcolor=lerp(frontcolor,finalcolor,addstrength);
       return finalcolor;
   }
      inline fixed3 subColor(fixed3 frontcolor,fixed3 backcolor)
   {
       return frontcolor-backcolor;
   }
   inline fixed3 lightenColor(fixed3 frontcolor,fixed3 backcolor)
   {
       return max(frontcolor,backcolor);
   }
   inline fixed3 darkenColor(fixed3 frontcolor,fixed3 backcolor)
   {
       return min(frontcolor,backcolor);
   }
   inline fixed3 overlayColor(fixed3 frontcolor,fixed3 backcolor)
   {
       return frontcolor*backcolor*2*step(backcolor,fixed3(0.5,0.5,0.5))+(1-2*(1-frontcolor)*(1-backcolor))*step(fixed3(0.5,0.5,0.5),backcolor);
   }
    //屏幕空间运算
    float2 useScreenPosAsUV(float4 modelvertpos)
   {
       //这里取到模型空间的原点，并把它转换到屏幕空间中/Find the zero point in modlespace,then map it to screenspace.
      float origindist=UnityObjectToViewPos(float3(0,0,0)).z;
      float3 viewvertpos= UnityObjectToViewPos(modelvertpos);
      //这里是避免视口到平面的距离拉伸贴图，造成拉伸的原因是透视矩阵中含有深度，所以要去掉深度影响/Avoid effect of Perspective
      viewvertpos.xy/=viewvertpos.z;
      //这一行开启：纹理受自身位置影响；这一行关闭：纹理不受物体自身位置影响/Comment out:texture is affected by it's position;Comment in:texture is not affected by it's position
      viewvertpos.xy-=UnityObjectToViewPos(float3(0,0,0)).xy/origindist;
      viewvertpos*=origindist;
      return viewvertpos.xy;
   }
   //世界空间运算
   float2 useWorldPosAsUV(float4 worldspacepos,float3 direction,sampler2D _Texture,float4 _Texture_ST)
   {
       //在这里做了归一化，使用函数传参数的时候不用做归一化，原样丢进来就好
       direction=normalize(direction);
       //为了简化最后一行算式的表达，搞了一下简写
       float dx=direction.x;
       float dy=direction.y;
       float dz=direction.z;
       float wx=worldspacepos.x;
       float wy=worldspacepos.y;
       float wz=worldspacepos.z;
       float2 worlduv=float2(0,0);
       //这一步是计算了世界空间上的一个点在一个定义为：ax+by+cz=0的平面上的投影，其中a,b,c分别为平面法向量的xyz分量。
       worlduv.x=wx-dx*(dx*wx+dy*wy+dz*wz)/(dx*dx+dy*dy+dz*dz);
       worlduv.y=wy-dy*(dx*wx+dy*wy+dz*wz)/(dx*dx+dy*dy+dz*dz);
       return worlduv;
   }
   //三个方向的世界空间运算
     float2 useWorldPosAsUV(float4 worldspacepos,int projtype)
   {
       float2 worlduv=step(0,projtype)*step(0,-projtype)*worldspacepos.xz
                              +step(0,projtype-1)*step(0,1-projtype)*worldspacepos.xy
                              +step(0,projtype-2)*step(0,2-projtype)*worldspacepos.yz;
       return worlduv;
   }
   //固定水平方向的世界空间运算
   float2 useWorldPosAsUV( float4 modelspacepos)
   {
       float4 worldspacepos=mul(unity_ObjectToWorld,modelspacepos);
       float2 worlduv=worldspacepos.xy;
       return worlduv;
   }
   float2 uvManager(float2 inuv, sampler2D _Texture,float4 _Texture_ST, float4 modelspacepos,int uvtype)
   {
       float2 worldspaceuv=useWorldPosAsUV(modelspacepos);
       float2 screenspaceuv=useScreenPosAsUV(modelspacepos);
    if (any(uvtype-1)) 
    { 
        
    }
    else if (any(uvtype-2)) 
    { 
        
    }else{
    }

        //注释掉的部分能用，相当于建立了一个查找键值对的方法,但是比较繁琐，优点是如果需要新增键值对能直接在后面加，新表达得再套一层
       //float2 outuv=step(0,uvtype)*step(0,-uvtype)*inuv
       //                    +step(0,uvtype-1)*step(0,1-uvtype)*screenspaceuv
       //                    +step(0,uvtype-2)*step(0,2-uvtype)*worldspaceuv;
       //0:inuv1:screenspaceuv2:worldspaceuv
      // float2 outuv=lerp(lerp(inuv,screenspaceuv,step(1,uvtype)),worldspaceuv,step(2,uvtype));
       float2 outuv=KEYVALUE(KEYVALUE(inuv,screenspaceuv,uvtype-1),worldspaceuv,uvtype-2) ; 
       outuv=TRANSFORM_TEX(outuv,_Texture);
       return outuv;
   }
   inline fixed3 flowLight(fixed3 basecolor,fixed3 flowlightcolor,fixed flowlightmask,half flowlightstrength)
   {
       return lerp(basecolor,flowlightcolor,flowlightmask*flowlightstrength);
   }
    inline half rimLight(half3 worldnormal,half3 worldviewdir,half rimlightrange,half rimlightmultipler,half reverserimlight)
    {
         half fresnel = 1 - abs(dot(worldviewdir, worldnormal));
         half rimlightstrength=  rimlightmultipler*pow(fresnel, rimlightrange);
         return lerp(rimlightstrength,1-rimlightstrength,reverserimlight);
    }
    inline half dissolveFunc(half dissolvevalue,half smoothstepA,half dissolvebase)
    {
        dissolvevalue=dissolvevalue*2-0.5;
        return smoothstep(dissolvevalue-smoothstepA,dissolvevalue+smoothstepA,dissolvebase);
    }
   
#endif
