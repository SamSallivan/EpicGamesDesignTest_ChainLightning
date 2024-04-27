using System.Collections;
using System.Collections.Generic;
using UnityEngine;

//Base class for all weapons present in game level
public class Weapon : MonoBehaviour, Slappable
{
	//What weapon will player equip when this is picked up.
	public int weaponIndex;

	public WeaponController weaponController;

	public Transform t;

	public Rigidbody rb;

	//timer that changes material color of the weapon.
    public float materialTimer;

	protected virtual void Awake()
	{
		t = base.transform;
		rb = GetComponentInChildren<Rigidbody>();
	}

	//when slapped, turn red for 1 sec
	public virtual void Slap(Vector3 dir)
	{
        materialTimer = 1;
	}

	public virtual void Update(){
        MaterialUpdate();
	}

	//lerps material color based on timer
	//also counts down the timer
    public void MaterialUpdate(){
        if (materialTimer > 0){
            materialTimer = Mathf.MoveTowards(materialTimer, 0, Time.deltaTime*2);
        }
        Color color = Color.Lerp(Color.white, Color.red, materialTimer);
        GetComponentInChildren<Renderer>().material.SetColor("_Color", color);
    }

	//drops the weapon with given force and torque.
	public virtual void Launch(Vector3 force, float torque = 0f)
	{
		rb.AddForce(force, ForceMode.Impulse);
		rb.AddTorque(-t.right * torque, ForceMode.Impulse);
	}

	//Makes the player equip this weapon.
	//enables corrisponding weapon controller
	//destroys this weapon object.
	/*public virtual void Interact(WeaponManager manager)
    {
        manager.EquipWeapon(this);
        
        Destroy(gameObject);
	}*/
}
