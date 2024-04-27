using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

//Class that manages and switches all the potential weapons player could accuquire.
//currently there are only the Bat and Slap.
public class WeaponManager : MonoBehaviour
{
	//a list of weapon controllers.
	public WeaponController[] weaponControllerList;

	//slap controller is different from all other weapons,
	//for it activates when no weapon is present.
	public SlapController slapController { get; private set; }

	public PlayerController playerController;

	public int currentWeaponIndex;

	//list of prefabs to be created when a weapon is dropped or thrown.
    public GameObject[] weaponDrops;

	private void Awake()
	{
		weaponControllerList = GetComponentsInChildren<WeaponController>(true);
		slapController = GetComponentInChildren<SlapController>(true);
		playerController = GetComponentInParent<PlayerController>();
		currentWeaponIndex = -1;
		Deactivate();
	}
    public void LaunchCurrentWeapon(Vector3 dir = new Vector3(), float torque = -90f, Vector3 spawnOffset = new Vector3())
    {
        if (currentWeaponIndex > -1)
        {
            Weapon droppedWeapon = GameObject.Instantiate(weaponControllerList[currentWeaponIndex].droppedWeapon, playerController.tHead.position + spawnOffset, Quaternion.LookRotation(playerController.tHead.right)).GetComponent<Weapon>();
            droppedWeapon.Launch(dir, torque);
            //((PooledWeapon)QuickPool.instance.Get(weapons[currentWeapon].name, p.tHead.position, Quaternion.LookRotation(p.tHead.right))).Drop(dir * 8f, -90f);
        }
        currentWeaponIndex = -1;
    }

    //deactivates the current weapon, 
    //creates a weapon prefab, and throw in given direction.
    public void DropCurrentWeapon(Vector3 dir = new Vector3(), float torque = -90f, Vector3 spawnOffset = new Vector3())
	{
		LaunchCurrentWeapon(dir, torque, spawnOffset);
        currentWeaponIndex = -1;
        Refresh();
    }

	//receives input for slap or weapons.
	private void Update()
    {
        slapController.SlapInputUpdate();
        if (currentWeaponIndex == -1)
        {
            MenuManager.instance.lmbTip.gameObject.SetActive(false);
            MenuManager.instance.rmbTip.gameObject.SetActive(false);
            MenuManager.instance.gTip.gameObject.SetActive(false);
        }
		else if (currentWeaponIndex > -1)
		{
			weaponControllerList[currentWeaponIndex].WeaponInputeUpdate();
			weaponControllerList[currentWeaponIndex].animator.SetBool("Sliding", playerController.slide.slideState != 0);
		}

        if (Input.GetKey(KeyCode.G))
        {
			DropCurrentWeapon(new Vector3(), 90f, playerController.tHead.forward);
        }

    }

	//returns the charged time of current weapon.
	public float GetChargeTime()
	{
		if (currentWeaponIndex <= -1)
		{
			return 0;
		}
		return weaponControllerList[currentWeaponIndex].chargeTimer;
	}

	public bool IsBlocking()
	{
		if (currentWeaponIndex <= -1)
		{
			return false;
		}
		return weaponControllerList[currentWeaponIndex].isBlocking;
	}

	//equips the given index of weapon.
	public void EquipWeapon(Weapon weapon)
    {
        if (currentWeaponIndex != -1)
        {
            DropCurrentWeapon();
        }

        currentWeaponIndex = weapon.weaponIndex;
        Destroy(weapon.gameObject);
        Refresh();
        MenuManager.instance.lmbTip.gameObject.SetActive(true);
        MenuManager.instance.rmbTip.gameObject.SetActive(true);
        MenuManager.instance.gTip.gameObject.SetActive(true);
    }

	//activates the current weapon's controller.
	public void Refresh()
	{
		for (int i = 0; i < weaponControllerList.Length; i++)
		{
			if (i == currentWeaponIndex)
			{
				weaponControllerList[i].gameObject.SetActive(true);
			}
			else
			{
				weaponControllerList[i].gameObject.SetActive(false);
			}
		}
	}

	//deactivates all weapon controllers.
	public void Deactivate()
	{
		for (int i = 0; i < weaponControllerList.Length; i++)
		{
			weaponControllerList[i].gameObject.SetActive(false);
		}
	}
}

