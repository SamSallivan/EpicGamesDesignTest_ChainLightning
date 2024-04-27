using UnityEngine;
using System.Collections;
using UnityEngine.Playables;
namespace TimelineExtend
{
    [System.Serializable]
    public class ScaleBillboardBehaviour : BasePlayableBehaviour
    {
        internal ScaleBillboardAsset asset;
        internal Renderer renderer;

        private MaterialPropertyBlock propertyBlock = null;

        private static int sShaderID_BillboardMatrix0 = 0;
        private static int sShaderID_BillboardMatrix1 = 0;
        private static int sShaderID_BillboardMatrix2 = 0;
        private static int sShaderID_BillboardScale = 0;

        private Quaternion rotation;

        private float loopOnce = 0;
        
        internal override void OnAwake(Playable playable)
        {
            base.OnAwake(playable);

            propertyBlock = MaterialPropertyHelper.Instance.GetPropertyBlock(renderer);
            //propertyBlock = new MaterialPropertyBlock();
            //renderer.GetPropertyBlock(propertyBlock);

            if (sShaderID_BillboardMatrix0 == 0)
            {
                sShaderID_BillboardMatrix0 = MaterialPropertyHelper.Instance.GetPropertyID("_BillboardMatrix0");
                sShaderID_BillboardMatrix1 = MaterialPropertyHelper.Instance.GetPropertyID("_BillboardMatrix1");
                sShaderID_BillboardMatrix2 = MaterialPropertyHelper.Instance.GetPropertyID("_BillboardMatrix2");
                sShaderID_BillboardScale = MaterialPropertyHelper.Instance.GetPropertyID("_BillboardScale");
            }
        }

        internal override void OnEnable()
        {
            base.OnEnable();

            rotation = Quaternion.Euler(asset.originRotation);

            loopOnce = asset.delayTime + asset.durationTime;
        }

        internal override void OnUpdate(float currentTime, float deltaTime, Playable playable, FrameData info, object playerData)
        {
            base.OnUpdate(currentTime, deltaTime, playable, info, playerData);

            if (renderer == null || propertyBlock == null || asset == null)
            {
                return;
            }

            float curveTime = 0;
            if (asset.isLoop)
            {
                curveTime = currentTime % loopOnce;
                curveTime -= asset.delayTime;
            }
            else
            {
                curveTime = currentTime - asset.delayTime;
            }
            if (curveTime < 0) return;

            Vector3 scale = Vector3.zero;
            if (asset.scaleCurveEnables[0])
            {
                scale.x = (asset.scaleCurveX.Evaluate(curveTime) + 1) * asset.originScale.x;
            }
            if (asset.scaleCurveEnables[1])
            {
                scale.y = (asset.scaleCurveY.Evaluate(curveTime) + 1) * asset.originScale.y;
            }
            if (asset.scaleCurveEnables[2])
            {
                scale.z = (asset.scaleCurveZ.Evaluate(curveTime) + 1) * asset.originScale.z;
            }


            float scaleZ = propertyBlock.GetVector(sShaderID_BillboardScale).w;
            Matrix4x4 m = Matrix4x4.TRS(Vector3.zero, rotation, scale);

            propertyBlock.SetVector(sShaderID_BillboardMatrix0, m.GetColumn(0));
            propertyBlock.SetVector(sShaderID_BillboardMatrix1, m.GetColumn(1));
            //propertyBlock.SetVector(sShaderID_BillboardMatrix2, m.GetColumn(2));
            // Use same logic as Editor code @kittyjdhe
            propertyBlock.SetVector(sShaderID_BillboardMatrix2, - m.GetColumn(2) * scaleZ);

            renderer.SetPropertyBlock(propertyBlock);
        }

    }

}
