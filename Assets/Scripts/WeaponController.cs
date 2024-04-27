using MyBox;
using System;
using UnityEngine;

//Base Class for all weapons.
//Currently there is only sword.
//Saved for future development.
public abstract class WeaponController : MonoBehaviour
{
    [Foldout("Weapon Settings", true)]
    public PlayerController playerController;

	public WeaponManager weaponManager;

	//Charge timer.

	public float chargeTimer;

	//Allows to attack up to 3 targets.
	public Collider[] colliders = new Collider[3];

	//Index for attack types.
	public int attackIndex;

	//State of the player in terms of attack.
	public int attackState;

	public bool isBlocking;

	public Animator animator;

    public Weapon droppedWeapon;

    protected virtual void Awake()
	{
		attackIndex = -1;
		attackState = 0;
		animator = GetComponent<Animator>();
		playerController = GetComponentInParent<PlayerController>();
		weaponManager = GetComponentInParent<WeaponManager>();
	}

	//each weapon will have a block funtion.
	public virtual void OnWeaponBlock()
	{
		
	}

	//each weapon will have a input receiver funtion.
 	public virtual void WeaponInputeUpdate()
    {
        if (Time.timeScale == 0)
        {
            return;
        }


    }

    public virtual void Drop()
	{
        weaponManager.DropCurrentWeapon(new Vector3(), 90f, playerController.tHead.forward);
    }
}
