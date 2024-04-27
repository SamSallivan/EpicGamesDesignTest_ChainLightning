using UnityEngine;
using System.Collections;
using UnityEngine.Playables;

namespace TimelineExtend
{
    [System.Serializable]
    public class ScaleBillboardAsset : PlayableAsset
    {
        public bool isLoop = false; // 此Loop会带着delay一起循环
        public float delayTime = 0;
        public float durationTime = 0;
        public bool[] scaleCurveEnables = { false, false, false };
        public Vector3 originScale;
        public Vector3 originRotation;
        public AnimationCurve scaleCurveX = default;
        public AnimationCurve scaleCurveY = default;
        public AnimationCurve scaleCurveZ = default;

        public ExposedReference<Renderer> rendererDataBind;

        public override Playable CreatePlayable(PlayableGraph graph, GameObject owner)
        {
            var playable = ScriptPlayable<ScaleBillboardBehaviour>.Create(graph);
            ScaleBillboardBehaviour behaviour = playable.GetBehaviour();
            behaviour.asset = this;
            behaviour.renderer = rendererDataBind.Resolve(graph.GetResolver());
            return playable;
        }

        public bool BindDataNode(PlayableDirector director, GameObject node, string nameTag)
        {
            nameTag = string.Format("{0}_{1}", nameTag, node.GetInstanceID()); // 加上InstanceID，防止因为是模型中的节点而未加index后缀，不唯一。
            rendererDataBind.exposedName = string.Format("{0}.RendererBind", nameTag);//UnityEditor.GUID.Generate().ToString();
            Renderer renderer = node.GetComponent<Renderer>();
            if (renderer == null) return false;
            director.SetReferenceValue(rendererDataBind.exposedName, renderer);

            return true;
        }
        public bool RebindDataNode(PlayableDirector director, GameObject node)
        {
            Renderer renderer = node.GetComponent<Renderer>();
            if (renderer == null) return false;
            director.SetReferenceValue(rendererDataBind.exposedName, renderer);

            return true;
        }

        public Object ResolveDataNode(PlayableDirector director)
        {
            var exposedName = rendererDataBind.exposedName;
            bool isValid = false;
            var render = director.GetReferenceValue(exposedName, out isValid);
            return render;
        }
    }
}
