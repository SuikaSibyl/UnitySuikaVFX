using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CameraAnime : MonoBehaviour
{

    // Start is called before the first frame update
    void Start()
    {
        
    }
    
    Vector3 origin;

    // Update is called once per frame
    void Update()
    {

    }

    public void StartShake()
    {
        origin = transform.position;
        StartCoroutine(Shake(0.2f, 0.4f));
    }

    public IEnumerator Shake(float duration, float magnitude)
    {
        Vector3 orignalPosition = transform.position;
        float elapsed = 0f;

        while (elapsed < duration)
        {
            float x = Random.Range(-1f, 1f) * magnitude;
            float y = Random.Range(-1f, 1f) * magnitude;
            float z = Random.Range(-1f, 1f) * magnitude;
            transform.position = new Vector3(origin.x + x, origin.y + y, origin.z + z);
            elapsed += Time.deltaTime;
            yield return 0;
        }

        transform.position = orignalPosition;
    }
}
