using System.Collections;
using System.Collections.Generic; 
using UnityEngine.SceneManagement;
using UnityEngine;
using UnityEngine.Rendering.PostProcessing;

//Enabled when player dies
//Controlls the game restart function
public class PlayerDecapitate : MonoBehaviour
{
	private PlayerController player;

	private Transform t;

	private Rigidbody rb;


	private void Awake()
	{
		t = base.transform;
		rb = GetComponent<Rigidbody>();
		player = GetComponentInParent<PlayerController>();
	}

	//restarts game on input
    void Update()
    {
        if(Input.GetKey(KeyCode.R)){
            Scene scene = SceneManager.GetActiveScene(); 
            SceneManager.LoadScene(scene.name);
        }
    }

	//separates the camera from player transform
    public void Decapitate(Transform pos, Vector3 dir){
        if ((bool)transform.parent)
		{
			transform.SetParent(null);
		}
		transform.SetPositionAndRotation(pos.position, pos.rotation);
		rb.AddForce(dir * 5f, ForceMode.Impulse);
		rb.AddTorque(Vector3.one * 10f, ForceMode.Impulse);
    }
}
