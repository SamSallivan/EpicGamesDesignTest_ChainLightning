using System.Collections;
using System.Collections.Generic;
using UnityEngine;

//weapon that is dropped or thrown
public class DroppedWeapon : Weapon
{
    public Damage damage = new Damage();

	//can be slapped
	//looks for close enemy and flies towards it
    public override void Slap(Vector3 dir){

        base.Slap(dir);

		if (!base.rb.isKinematic)
		{
			if (Physics.Raycast(base.rb.worldCenterOfMass, Vector3.down, 0.5f, 1))
			{
				base.rb.AddForce(dir * 5f + Vector3.up * 1.5f, ForceMode.Impulse);
				base.rb.AddTorque(base.t.forward * 10f, ForceMode.Impulse);
			}
			else
			{
                
				Enemy[] enemies = FindObjectsOfType<Enemy>(true);
                foreach (Enemy enemy in enemies)
				{
					if (enemy.dead)
					{
						continue;
					}

					Vector3 direction = (enemy.transform.position - transform.position).normalized;

					float distance = Vector3.Distance(transform.position, enemy.transform.position);
					float leastAngle = 30;

					if (!(distance > 18) && !Physics.Raycast(transform.position, direction, distance, 1))
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
		}
    }

	//deals damage on collision
	private void OnCollisionEnter(Collision c)
	{
		if (c.gameObject.layer == 10 || c.gameObject.layer == 14 )
		{
            damage.dir = (-c.contacts[0].normal + Vector3.up    ) / 2f;
            damage.amount = c.relativeVelocity.magnitude * 3f;

			c.gameObject.GetComponent<Damagable>().Damage(damage);

            PlayerController pc = FindObjectOfType<PlayerController>();
            pc.slamVFX.transform.position = c.transform.position;
            pc.slamVFX.transform.rotation = Quaternion.LookRotation(c.transform.forward);
            pc.slamVFX.GetComponent<ParticleSystem>().Play();
            
            rb.velocity = Vector3.zero;
            rb.AddForce(c.contacts[0].normal * c.relativeVelocity.magnitude);
		}
	}

}
