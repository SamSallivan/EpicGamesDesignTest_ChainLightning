using System.Collections;
using System.Collections.Generic;
using UnityEngine;

//indication arrow that appears on top of targeted weapons that can be picked up
public class WeaponIndicator : MonoBehaviour
{
	public Transform tMesh;
    void Awake()
    {
		tMesh = transform.GetChild(0);
    }
    void Update()
    {   
        if((bool)tMesh){
            tMesh.localPosition = new Vector3(0f, Mathf.Sin(Time.timeSinceLevelLoad * 2 ) * 0.1f, 0f);
            tMesh.Rotate(Vector3.up * (270f * Time.deltaTime));
        }
    }
}
