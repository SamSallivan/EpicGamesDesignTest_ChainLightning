using UnityEngine;
using System.Collections;
using UnityEngine.Playables;

namespace TimelineExtend
{
    public class RandomRotationAsset : PlayableAsset
    {
        public bool[] enableChannels = { false, false, false };
        public short randomMin = 0;
        public short randomMax = 0;
        public ExposedReference<Transform> transformDataBind;

        public override Playable CreatePlayable(PlayableGraph graph, GameObject owner)
        {
            var playable = ScriptPlayable<RandomRotationBehaviour>.Create(graph);
            RandomRotationBehaviour behaviour = playable.GetBehaviour();
            behaviour.asset = this;
            behaviour.transform = transformDataBind.Resolve(graph.GetResolver());
            return playable;
        }

        public bool BindDataNode(PlayableDirector director, GameObject node, string nameTag)
        {
            nameTag = string.Format("{0}_{1}", nameTag, node.GetInstanceID()); // 加上InstanceID，防止因为是模型中的节点而未加index后缀，不唯一。
            transformDataBind.exposedName = string.Format("{0}.TransformBind", nameTag);
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
