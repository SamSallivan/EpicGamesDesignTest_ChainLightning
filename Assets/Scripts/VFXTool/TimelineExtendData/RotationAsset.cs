using UnityEngine;
using System.Collections;
using UnityEngine.Playables;

namespace TimelineExtend
{
    [System.Serializable]
    public class RotationAsset : PlayableAsset
    {
        public bool isLocal = false;
        public bool isLoop = false; // 此Loop会带着delay一起循环
        public float delayTime = 0;
        public float durationTime = 0;
        public Quaternion originRotation = default;
        public AnimationCurve angleCurveX = default;
        public AnimationCurve angleCurveY = default;
        public AnimationCurve angleCurveZ = default;
        public bool[] angleCurveEnables = { false, false, false };
        public ExposedReference<Transform> transformDataBind;

        public override Playable CreatePlayable(PlayableGraph graph, GameObject owner)
        {
            var playable = ScriptPlayable<RotationBehaviour>.Create(graph);
            RotationBehaviour rotationBehaviour = playable.GetBehaviour();
            rotationBehaviour.asset = this;
            rotationBehaviour.transform = transformDataBind.Resolve(graph.GetResolver());
            return playable;
        }

        public bool BindDataNode(PlayableDirector director, GameObject node, string nameTag)
        {
            nameTag = string.Format("{0}_{1}", nameTag, node.GetInstanceID()); // 加上InstanceID，防止因为是模型中的节点而未加index后缀，不唯一。
            transformDataBind.exposedName = string.Format("{0}.TransformBind", nameTag);//UnityEditor.GUID.Generate().ToString();
            director.SetReferenceValue(transformDataBind.exposedName, node.transform);

            return true;
        }
        public bool RebindDataNode(PlayableDirector director, GameObject node)
        {
            director.SetReferenceValue(transformDataBind.exposedName, node.transform);

            return true;
        }

        public Object ResolveDataNode(PlayableDirector director)
        {
            var exposedName = transformDataBind.exposedName;
            bool isValid = false;
            var tran = director.GetReferenceValue(exposedName, out isValid);
            return tran;
        }
    }
}
