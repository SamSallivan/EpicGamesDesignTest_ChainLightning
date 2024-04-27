using System.Collections;
using System.Collections.Generic;
using UnityEngine;

//Class used by all physics based props.
public class ObjectFracture : MonoBehaviour, Slappable, Damagable
{

	public LayerMask damageMask;

	public Damage damage = new Damage();

	//minimal velocity needed to trigger damage on collision.
	public float minDamageVelocitySqr = 25f;

	//the prefab to create when object health gets 0
	public GameObject onBreakPrefab;

	private Transform t;

	public bool lethal;

	public bool broken;

	public float health = 100f;

	public Rigidbody rb;

	public Collider clldr;

    public float materialTimer;

	//whether the object has a kinematic rigidbody on awake.
    public bool sleep;

	//a list of enemies to be activated when exiting the sleep.
	public Enemy[] activateEnemies;

    public bool roomCleared;


	public void Slap(Vector3 dir)
	{
		//activates the enemies when slapped
		if(activateEnemies.Length!=0){
			foreach(Enemy enemy in activateEnemies){
				enemy.gameObject.SetActive(true);
			}
		}

		rb.isKinematic = false;
	
		//Look for enemies within range and angle.
		//Adjusts direction and flies towards it.
		foreach (Enemy enemy in activateEnemies)
		{
			if (enemy.dead)
			{
				continue;
			}

			Vector3 direction = (enemy.transform.position - transform.position).normalized;

			float distance = Vector3.Distance(transform.position, enemy.transform.position);
			float leastAngle = 30;

			if (!(distance > 15) && !Physics.Raycast(transform.position, direction, distance, 1))
			{
				if (Vector3.Angle(direction, dir) < leastAngle)
				{
					leastAngle = Vector3.Angle(direction, dir);
					dir = direction;
				}
			}
		}

		rb.AddForce(dir.normalized * 45f, ForceMode.Impulse);
	}

	public void Damage(Damage damage)
	{
		//activates the enemies when attacked
		if(activateEnemies.Length!=0){
			foreach(Enemy enemy in activateEnemies){
				enemy.gameObject.SetActive(true);
			}
		}

		rb.isKinematic = false;
		
		materialTimer = 1;
		health -= damage.amount;

		//flies in given direction
		if (damage.amount > 0f)
		{
			Vector3 dir = damage.dir;
			dir *= Mathf.Clamp(damage.amount, 0f, 50f);
			rb.AddForce(dir, ForceMode.Impulse);
			rb.AddTorque(dir, ForceMode.Impulse);
		}
		
		//breaks when health gets below 0
		if (health < 0f)
		{
			Break(damage.dir);
		}
	}

	private void Break(Vector3 dir)
	{	
        broken = true;

		//if given a broken version of the object,
		//turns self off
		//create the broken version of self
		if(onBreakPrefab != null){

			GetComponent<MeshRenderer>().enabled = false;
			GetComponent<MeshCollider>().enabled = false;

			if (gameObject.activeInHierarchy)
			{
				GameObject temp = GameObject.Instantiate(onBreakPrefab, rb.worldCenterOfMass, t.rotation);
				
				foreach (Transform t in temp.transform)
				{
					var rb = t.GetComponent<Rigidbody>();

					//scatters the debris
					if (rb != null)
						rb.AddExplosionForce(Random.Range(0, 5), transform.position, Random.Range(5, 20));

					//shrinks the debris over time
					StartCoroutine(Shrink(t, 2));
				}
			}
		}
	}

	//shrinks the debris over time before destroying it
    IEnumerator Shrink (Transform t, float delay)
    {
        yield return new WaitForSeconds(delay);

        while(t.localScale.x >= 0.05f)
        {

            t.localScale = t.localScale * 9/10;

            yield return new WaitForSeconds (0.05f);
        }

        Destroy(t.gameObject);

        yield return new WaitForSeconds(delay);
    }

	private void Awake()
	{
		t = base.transform;
		rb = GetComponent<Rigidbody>();
		clldr = GetComponent<Collider>();
		if(sleep){
			rb.isKinematic = true;
		}
	}

	//turns the material color red
    public void MaterialUpdate(){
        if (materialTimer > 0){
            materialTimer = Mathf.MoveTowards(materialTimer, 0, Time.deltaTime*2);
        }
        Color color = Color.Lerp(Color.white, Color.red, materialTimer);
        GetComponentInChildren<Renderer>().material.SetColor("_Color", color);
    }

	private void Update()
	{
		MaterialUpdate();
		
		//checks if the speed is fast enough to deal damage
		lethal = rb.velocity.sqrMagnitude > minDamageVelocitySqr;
		
		//slow the time a while when enemies on list are ded
		if(!roomCleared){
			int deathCount = 0;
			foreach(Enemy enemy in activateEnemies){
				if(enemy && enemy.dead){
					deathCount++;
				}
			}
			if(deathCount == activateEnemies.Length && !roomCleared){
				roomCleared = true;
				TimeManager.instance.SlowMotion(0.2f, 0.6f, 0.1f);
			}
		}
	}

	//damages collider collided, if within given layer and fast enough
	private void OnCollisionEnter(Collision c)
	{
		int layer = c.gameObject.layer;
		if (minDamageVelocitySqr != 0f && lethal && (int)damageMask == ((int)damageMask | (1 << layer)))
		{

            damage.dir = (-c.contacts[0].normal + Vector3.up) / 2f;
            damage.amount = c.relativeVelocity.magnitude * 3f;

            if (c.gameObject.activeInHierarchy)
            {
                c.transform.GetComponentInChildren<Damagable>().Damage(damage);
				
				PlayerController pc = FindObjectOfType<PlayerController>();
				pc.slamVFX.transform.position = c.transform.position;
				pc.slamVFX.transform.rotation = Quaternion.LookRotation(c.transform.forward);
				pc.slamVFX.GetComponent<ParticleSystem>().Play();
            }
            rb.velocity = Vector3.zero;
            rb.AddForce(c.contacts[0].normal * c.relativeVelocity.magnitude);

			//also deals damage to self.
			health -= c.relativeVelocity.sqrMagnitude;
			if (health <= 0f)
			{
				Break(c.contacts[0].normal);
			}

		}
	}

}
