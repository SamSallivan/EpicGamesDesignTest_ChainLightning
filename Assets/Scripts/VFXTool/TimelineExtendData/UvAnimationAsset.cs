using UnityEngine;
using System.Collections;
using UnityEngine.Playables;

namespace TimelineExtend
{
    [System.Serializable]
    public class UvAnimationAsset : PlayableAsset
    {
        // 原始功能为：直接使用曲线变换
        // 修正为：先经过一段直线变换，再进行曲线变换
        public bool isMask = false;

        public float tillingX = 0;
        public float tillingY = 0;
        public float offsetX = 0;
        public float offsetY = 0;

        public float speedLineX = 0;
        public float speedLineY = 0;

        public float curveBeginTime = 0;
        public bool[] speedCurveEnables;
        public AnimationCurve speedCurveX = default;
        public AnimationCurve speedCurveY = default;

        public ExposedReference<Renderer> rendererDataBind;

        public override Playable CreatePlayable(PlayableGraph graph, GameObject owner)
        {
            var playable = ScriptPlayable<UvAnimationBehaviour>.Create(graph);
            UvAnimationBehaviour behaviour = playable.GetBehaviour();
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
