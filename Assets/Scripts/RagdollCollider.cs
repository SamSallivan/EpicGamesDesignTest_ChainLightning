using System.Collections;
using System.Collections.Generic;
using UnityEngine;

//Used when enemy enters ragdoll state, with its main collider turned off
//acts as its secondary collider to detect damage and slap.
public class RagdollCollider : MonoBehaviour, Damagable, Slappable
{
	public Enemy enemy { get; private set; }

	private void Awake()
	{
		enemy = GetComponentInParent<Enemy>();
	}

	public void Slap(Vector3 dir)
	{
		if(enemy.doll){
			enemy.Slap(dir);
		}
	}

	public void Damage(Damage damage)
	{
		if(enemy.doll)
			enemy.Damage(damage);
	}


}
