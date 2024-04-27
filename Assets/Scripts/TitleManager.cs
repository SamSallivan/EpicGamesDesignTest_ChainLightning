using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using UnityEngine.SceneManagement;


//Manages UI in Title Screen.
public class TitleManager : MonoBehaviour
{
    //Stores where the inverse kinematic target is, relative to screen space.
    public Vector3 screenPoint;
    public GameObject IKTarget;


    void Awake(){
        Cursor.lockState = CursorLockMode.Confined;
    }

    void Update(){
        OnMouseMove();
    }

    public void StartGame(){
        SceneManager.LoadScene("Level", LoadSceneMode.Single);
    }

    public void StartDemo()
    {
        SceneManager.LoadScene("Level_ChainLightning", LoadSceneMode.Single);
    }

    public void QuitGame(){
        Application.Quit();
    }

    //Gets IKTarget's position in screen, 
    //Gets Mouse position in world,
    //Sets IKTarget's position to mouse position in world,
    //So it only moves on the plane parallel to screen.
    void OnMouseMove()
    {
        screenPoint = Camera.main.WorldToScreenPoint(IKTarget.transform.position);

        Vector3 curScreenPoint = new Vector3(Input.mousePosition.x, Input.mousePosition.y, screenPoint.z);

        Vector3 curPosition = Camera.main.ScreenToWorldPoint(curScreenPoint);
        IKTarget.transform.position = curPosition;

    }

}
