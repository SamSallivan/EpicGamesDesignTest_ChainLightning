using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Vfx : MonoBehaviour
{
    private float curLifeTime;
    public float maxLifeTime = 1;
    protected Vector3 offset;
    protected GameObject attachedObject;

    private void Start()
    {
    }

    // Update is called once per frame
    public virtual void Update()
    {
        //deactivates the effect when time is up.
        curLifeTime = Mathf.Clamp(curLifeTime + Time.deltaTime, 0f, maxLifeTime);
        if (curLifeTime >= maxLifeTime)
        {
            Destroy(gameObject);
        }
        if (attachedObject)
        {
            transform.position = attachedObject.transform.position + offset;
        }
    }
}
