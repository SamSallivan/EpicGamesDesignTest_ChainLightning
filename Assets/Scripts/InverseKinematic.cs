using System.Collections;
using System.Collections.Generic;
using UnityEngine;

//The inverse kinematic that player arms use
//Enables me to only animate the inverse kinematic target when animating,
//and the whole arm just animates following the target.
[ExecuteInEditMode]
public class InverseKinematic : MonoBehaviour
{
	//the 3 bones of an arm, shoulder, forearm and hand
	public Transform a;
	public Transform b;
	public Transform c;

	//length of an arm segment.
	public float width = 1f;

	public float distance;

	public float height;

	public Vector3 midPoint;

	public Vector3 elbowDir;

	public Vector3 elbowPos;

	//the target object the arm follows
	public Transform tTarget;

	public void LateUpdate()
	{
		SetTarget(tTarget);
	}

	public void Setup()
	{
		Transform[] componentsInChildren = GetComponentsInChildren<Transform>();
		if (componentsInChildren.Length >= 2)
		{
			a = componentsInChildren[0];
			b = componentsInChildren[1];
			c = componentsInChildren[2];
		}
		width = Vector3.Distance(a.position, c.position) / 2f;
	}

	public void SetTarget(Transform target)
	{
		//Gets the distance between shoulder and target.
		distance = Vector3.Distance(a.position, target.position);

		//Gets the position in middle of shoulder and target.
		midPoint = (a.position + target.position) / 2f;

		//calculate the direction the elbow should be going.
		elbowDir = Vector3.Cross(a.position - target.position, -target.right).normalized;

		//Calculate the height of the elbow, if the arm is not straight.
		if (distance < width * 2f)
		{
			height = Mathf.Sqrt(width * width - distance * distance / 4f);
		}
		else
		{
			height = 0f;
		}

		//calculates the elbow position.
		elbowPos = midPoint - elbowDir * height;

		//makes upper arm point towards elbow.
		a.LookAt(elbowPos, elbowDir);
		a.Rotate(180, 0f, 0f);

		//makes forearm point towards target.
		b.LookAt(target.position, elbowDir);
		b.Rotate(180, 0f, 0f);

		//makes hand rotate with target.
		c.rotation = target.rotation;
	}
}
