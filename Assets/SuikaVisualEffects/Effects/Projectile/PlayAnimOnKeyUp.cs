using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PlayAnimOnKeyUp : MonoBehaviour
{
    public GameObject mainProjectile;
    public ParticleSystem mainParticleSystem;

    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        if (Input.GetKeyDown(KeyCode.Space))
        {
            Debug.Log("Hello");
            mainProjectile.SetActive(true);
        }

        if (mainParticleSystem.IsAlive() == false)
        {
            mainProjectile.SetActive(false);
        }
        
    }
}
