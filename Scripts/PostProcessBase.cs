using UnityEngine;
using System.Collections;

[ExecuteInEditMode]
[RequireComponent(typeof(Camera))]
public class PostProcessBase : MonoBehaviour {
    protected void Start() {
        CheckResource();
    }

    //Call when start
    protected void CheckResource() {
        bool isSupported = CheckSupport();
        if (!isSupported) {
            NotSupported();
        }
    }

    protected bool CheckSupport() {
        if (!SystemInfo.supportsImageEffects)
        {
            Debug.Log("Error:ImageEffect is not supported!");
            return false;
        }
        else if (!SystemInfo.supportsRenderTextures) {
            Debug.Log("Error:RenderTexture is not supported!");
            return false;
        }

        return true;
    }

    protected void NotSupported() {
        enabled = false;
    }

    //Called when need to create a material used by the effect
    protected Material CheckShaderAndCreateMaterial(Shader shader, Material mat) {
        if (shader == null) {
            return null;
        }

        if(!shader.isSupported) {
            return null;
        }

        if (mat != null && mat.shader == shader) {
            return mat;
        }
        else {
            mat = new Material(shader);
            mat.hideFlags = HideFlags.DontSave;
            if (mat) {
                return mat;
            }
        }

        return null;
    } 
}
