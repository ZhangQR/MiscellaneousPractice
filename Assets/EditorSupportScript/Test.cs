using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Test : MonoBehaviour
{
    [System.Serializable]
    public class ClassA
    {
        public int Num = 0;
        public string Str = "";
        public override string ToString()
        {
            return Num.ToString() + Str;
        }
    }
    

    [HideInInspector]public ClassA[] a;
    // Start is called before the first frame update
    void Start()
    {
        foreach (var aa in a)
        {
            Debug.Log(aa.ToString());    
        }
    }

    private void Function(ref ClassA a)
    {
        a = new ClassA();
        a.Num = 4;
    }
}
