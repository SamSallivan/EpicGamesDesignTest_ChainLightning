using System.Collections;
using System.Collections.Generic;
using Unity.VisualScripting;
using UnityEngine;
using UnityEngine.Playables;

public class Vfx_Billboard : Vfx
{
    public void Initiate(Vector3 pos, Vector3 offset = new Vector3())
    {
        this.offset = offset;
        this.attachedObject = null;
        transform.position = pos + offset;
    }

    public void Initiate(GameObject attachedObject, Vector3 offset = new Vector3(), float animationSpeed = 1)
    {
        this.offset = offset;
        this.attachedObject = attachedObject;
        if (attachedObject.GetComponent<Animator>().GetBoneTransform(HumanBodyBones.Chest))
            this.attachedObject = attachedObject.GetComponent<Animator>().GetBoneTransform(HumanBodyBones.Chest).gameObject;
        transform.position = attachedObject.transform.position + offset;

        if(GetComponent<PlayableDirector>())
            GetComponent<PlayableDirector>().playableGraph.GetRootPlayable(0).SetSpeed(animationSpeed);
    }

    // Update is called once per frame
    public override void Update()
    {
        base.Update();
        var lookPos = Camera.main.transform.position - transform.position;
        //lookPos.y = 0;
        var rotation = Quaternion.LookRotation(lookPos);
        transform.rotation = Quaternion.LookRotation(lookPos);

    }
}
