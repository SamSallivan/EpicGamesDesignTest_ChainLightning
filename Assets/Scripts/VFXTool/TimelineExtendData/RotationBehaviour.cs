using UnityEngine;
using System.Collections;
using UnityEngine.Playables;
namespace TimelineExtend
{
    [System.Serializable]
    public class RotationBehaviour : BasePlayableBehaviour
    {
        internal RotationAsset asset;
        internal Transform transform;

        private float beforeAngleX, beforeAngleY, beforeAngleZ;
        private float loopOnce = 0;
        
        internal override void OnEnable()
        {
            base.OnEnable();

            if (asset != null && transform != null)
            {
                transform.localRotation = asset.originRotation;

                beforeAngleX = beforeAngleY = beforeAngleZ = 0;
                loopOnce = asset.delayTime + asset.durationTime;
            }
        }

        internal override void OnUpdate(float currentTime, float deltaTime, Playable playable, FrameData info, object playerData)
        {
            base.OnUpdate(currentTime, deltaTime, playable, info, playerData);

            if (asset == null || transform == null)
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

            float addX = 0, addY = 0, addZ = 0;
            if (asset.angleCurveEnables[0])
            {
                var cur = asset.angleCurveX.Evaluate(curveTime);
                addX = cur - beforeAngleX;
                beforeAngleX = cur;
            }
            if (asset.angleCurveEnables[1])
            {
                var cur = asset.angleCurveY.Evaluate(curveTime);
                addY = cur - beforeAngleY;
                beforeAngleY = cur;
            }
            if (asset.angleCurveEnables[2])
            {
                var cur = asset.angleCurveZ.Evaluate(curveTime);
                addZ = cur - beforeAngleZ;
                beforeAngleZ = cur;
            }

            var quaternion = Quaternion.Euler(addX, addY, addZ);
            if (asset.isLocal)
            {
                transform.localRotation *= quaternion;
            }
            else
            {
                transform.rotation *= quaternion;
            }
        }

    }

}
