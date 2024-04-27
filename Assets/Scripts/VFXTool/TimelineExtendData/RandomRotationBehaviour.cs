using UnityEngine;
using System.Collections;
using UnityEngine.Playables;

namespace TimelineExtend
{
    [System.Serializable]
    public class RandomRotationBehaviour : BasePlayableBehaviour
    {
        internal RandomRotationAsset asset;
        internal Transform transform;

        internal override void OnEnable()
        {
            base.OnEnable();

            if (asset == null || transform == null)
            {
                return;
            }

            var angle = transform.localEulerAngles;
            for (int i = 0; i < 3; ++i)
            {
                if (asset.enableChannels[i])
                {
                    angle[i] = Random.Range(asset.randomMin, asset.randomMax);
                }
            }
            transform.localEulerAngles = angle;
        }
    }
}
