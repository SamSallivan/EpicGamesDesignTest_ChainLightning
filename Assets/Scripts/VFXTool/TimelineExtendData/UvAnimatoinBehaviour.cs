using UnityEngine;
using System.Collections;
using UnityEngine.Playables;
namespace TimelineExtend
{
    [System.Serializable]
    public class UvAnimationBehaviour : BasePlayableBehaviour
    {
        internal UvAnimationAsset asset;
        internal Renderer renderer;

        private MaterialPropertyBlock propertyBlock = null;
        private static int sShaderID_MainTexST = 0;
        private static int sShaderID_MaskTexST = 0;

        private float totalOffsetX = 0;
        private float totalOffsetY = 0;

        private float last_time = 0;

        public static bool bOpenDelayFix = true;
        private float firstFrameDelayFix = 0;

        internal override void OnAwake(Playable playable)
        {
            base.OnAwake(playable);

            propertyBlock = MaterialPropertyHelper.Instance.GetPropertyBlock(renderer);
            //propertyBlock = new MaterialPropertyBlock();
            //renderer.GetPropertyBlock(propertyBlock);

            if (sShaderID_MainTexST == 0)
            {
                sShaderID_MainTexST = MaterialPropertyHelper.Instance.GetPropertyID("_MainTex_ST");
                sShaderID_MaskTexST = MaterialPropertyHelper.Instance.GetPropertyID("_MaskTex_ST");
                //sShaderID_MainTexST = Shader.PropertyToID("_MainTex_ST");
                //sShaderID_MaskTexST = Shader.PropertyToID("_MaskTex_ST");
            }
            last_time = 0;
        }

        internal override void OnEnable()
        {
            base.OnEnable();

            totalOffsetX = asset.offsetX;
            totalOffsetY = asset.offsetY;
            last_time = 0;
            firstFrameDelayFix = 0;
        }

        internal override void OnUpdate(float currentTime, float deltaTime, Playable playable, FrameData info, object playerData)
        {
            base.OnUpdate(currentTime, deltaTime, playable, info, playerData);

            if (renderer == null || propertyBlock == null || asset == null || asset.speedCurveEnables == null || asset.speedCurveEnables.Length != 2)
            {
                return;
            }
            if (currentTime - last_time < float.Epsilon)
            {
                totalOffsetX = asset.offsetX;
                totalOffsetY = asset.offsetY;
                last_time = 0;
                firstFrameDelayFix = 0;
            }
            if (currentTime - last_time > 0.033f && currentTime - last_time < 30)
            {
                float t = last_time;

                float speedX = asset.speedLineX;
                float speedY = asset.speedLineY;
                while (t < currentTime)
                {
                    t += 0.033f;
                    if (t > currentTime)
                    {
                        break;
                    }
                    if (t >= asset.curveBeginTime)
                    {
                        float curveTime = 0;
                        if (bOpenDelayFix)
                        {
                            if (asset.curveBeginTime > float.Epsilon && firstFrameDelayFix <= float.Epsilon)
                            {
                                firstFrameDelayFix = t;
                                curveTime = 0;
                            }
                            else
                            {
                                curveTime = t - firstFrameDelayFix;
                            }
                        }
                        else
                        {
                            curveTime = t - asset.curveBeginTime;
                        }                        

                        if (asset.speedCurveEnables[0] && asset.speedCurveX != null)
                        {
                            speedX = asset.speedCurveX.Evaluate(curveTime);
                        }
                        if (asset.speedCurveEnables[1] && asset.speedCurveY != null)
                        {
                            speedY = asset.speedCurveY.Evaluate(curveTime);
                        }
                    }
                    totalOffsetX += (0.033f * speedX);
                    totalOffsetY += (0.033f * speedY);
                    last_time = t;
                }
            }
            else
            {
                float speedX = asset.speedLineX;
                float speedY = asset.speedLineY;

                if (currentTime >= asset.curveBeginTime)
                {
                    float curveTime = 0;

                    if (bOpenDelayFix)
                    {
                        // 此处理论上应该使用Timeline的计算方式，因为FXMaker计算是错误的。原因
                        //   FX: 当时间到达delay播放时间后，首帧时间按照0来算。（此处其抛弃了 current - delay的一个细微差距时间）
                        //   TL: 当时间到达delay播放时间之后，使用current - delay来计算超出的那点时间。
                        // 但因为特效是用FX制作的，此处只能修复为和FX相同，故也抛弃这个不足一帧的时间。
                        // tapd: https://tapd.woa.com/LSGame/bugtrace/bugs/view?bug_id=1010147831112618251
                        if (asset.curveBeginTime > float.Epsilon && firstFrameDelayFix <= float.Epsilon)
                        {
                            firstFrameDelayFix = currentTime;
                            curveTime = 0;
                        }
                        else
                        {
                            curveTime = currentTime - firstFrameDelayFix;
                        }
                    }
                    else
                    {
                        curveTime = currentTime - asset.curveBeginTime;
                    }

                    if (asset.speedCurveEnables[0] && asset.speedCurveX != null)
                    {
                        speedX = asset.speedCurveX.Evaluate(curveTime);
                    }
                    if (asset.speedCurveEnables[1] && asset.speedCurveY != null)
                    {
                        speedY = asset.speedCurveY.Evaluate(curveTime);
                    }
                }

                if (currentTime > 0)
                {
                    totalOffsetX += (deltaTime * speedX);
                    totalOffsetY += (deltaTime * speedY);
                }
                last_time = currentTime;

                //Debug.LogFormat("TL, {0}, frame:{1}, current:{2}, speed:{3}, deltaTime:{4} offsetXUsed:{5}", renderer.gameObject.name, Time.frameCount, currentTime, speedX, deltaTime, totalOffsetX);
            }
            if (!asset.isMask)
            {
                // 避免由于滚动次数太多导致卡顿问题，虽然不知道为什么。可能是累计的小数值？
                if (totalOffsetX > 9) totalOffsetX -= 8;
                else if (totalOffsetX < -9) totalOffsetX += 8;
                if (totalOffsetY > 9) totalOffsetY -= 8;
                else if (totalOffsetY < -9) totalOffsetY += 8;
            }

            var st = new Vector4(asset.tillingX, asset.tillingY, totalOffsetX, totalOffsetY);
            if (asset.isMask)
            {
                propertyBlock.SetVector(sShaderID_MaskTexST, st);
            }
            else
            {
                propertyBlock.SetVector(sShaderID_MainTexST, st);
            }

            renderer.SetPropertyBlock(propertyBlock);
        }

    }

}
