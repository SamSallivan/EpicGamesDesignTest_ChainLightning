using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Playables;

public class Vfx_Chain : Vfx
{
    private GameObject startTarget;
    private GameObject endTarget;
    public List<LineRenderer> lineRenderers;


    public void Initiate(GameObject start, GameObject end, Vector3 offset = new Vector3(), float animationSpeed = 1)
    {
        this.startTarget = start;
        this.endTarget = end;
        if (start.GetComponent<Animator>().GetBoneTransform(HumanBodyBones.Chest))
            this.startTarget = start.GetComponent<Animator>().GetBoneTransform(HumanBodyBones.Chest).gameObject;
        if (end.GetComponent<Animator>().GetBoneTransform(HumanBodyBones.Chest))
            this.endTarget = end.GetComponent<Animator>().GetBoneTransform(HumanBodyBones.Chest).gameObject;

        this.offset = offset;
        foreach (LineRenderer line in lineRenderers)
        {
            line.SetPosition(0, startTarget.transform.position + offset);
            line.SetPosition(1, endTarget.transform.position + offset);
        }

        if (GetComponent<PlayableDirector>())
            GetComponent<PlayableDirector>().playableGraph.GetRootPlayable(0).SetSpeed(animationSpeed);
        //Debug.Log(animationSpeed);
    }

    public override void Update()
    {
        base.Update();
        foreach (LineRenderer line in lineRenderers)
        {
            line.SetPosition(0, startTarget.transform.position + offset);
            line.SetPosition(1, endTarget.transform.position + offset);
        }
    }
}
