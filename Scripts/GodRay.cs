//----------------------------------------
// GodRay 参考自 http://blog.csdn.net/wolf96/article/details/44256445
//----------------------------------------

using UnityEngine;
using System.Collections;

public class GodRay : PostProcessBase {
    public Shader shader;
    //public Shader replaceShader;
    private Material _curMat;
    public Material material {
        get {
            _curMat = CheckShaderAndCreateMaterial(shader, _curMat);
            return _curMat;
        }
    }

    //Control Variables
    public Transform lightSource;
    [Range(0, 1.0f)]
    public float weight = 1.0f;
    [Range(0, 1.0f)]
    public float decay = 0.8f;
    [Range(0f, 1.0f)]
    public float density = 0.5f;
    [Range(0, 4.0f)]
    public float luminance = 1.05f;
    [Range(0, 1.0f)]
    public float luminanceThreshold = 0.6f;
    [Range(0, 1.0f)]
    public float alpha = 0.9f;
    [Range(1, 4)]
    public int iteration = 2;

    private Camera _myCamera;
    public Camera myCamera {
        get {
            if (_myCamera == null) {
                _myCamera = GetComponent<Camera>();
            }
            return _myCamera;
        }
    }

    //private RenderTexture rt;

    void OnRenderImage(RenderTexture src, RenderTexture dest) {
        if (material != null && lightSource != null)
        {
            Vector3 lightScreenPos = myCamera.WorldToScreenPoint(lightSource.transform.position);
            //NOTE:使用IBL光照的情况下关闭这个检测效果更好
            /*
            //判断光源是否在屏幕内
            if (lightScreenPos.x < 0 || lightScreenPos.x > myCamera.pixelWidth || lightScreenPos.y < 0 || lightScreenPos.y > myCamera.pixelHeight) {
                Graphics.Blit(src, dest);
                return;
            }
            */
            //判断光源是否在摄像机背面
            //lightScreenPos.z为光源到摄像机的矢量距离
            if (lightScreenPos.z < 0)
            {
                Graphics.Blit(src, dest);
                return;
            }

            material.SetVector("_LightScreenPos", new Vector4(lightScreenPos.x / myCamera.pixelWidth, lightScreenPos.y / myCamera.pixelHeight, 0, 0));
            material.SetFloat("_Weight", weight);
            material.SetFloat("_Decay", decay);
            material.SetFloat("_Luminance", luminance);
            material.SetFloat("_Density", density);
            material.SetFloat("_LuminanceThreshold", luminanceThreshold);

            //降采样x4
            int scaler = 4;
            RenderTexture buff0 = RenderTexture.GetTemporary(src.width / scaler, src.height / scaler, 0);
            buff0.hideFlags = HideFlags.DontSave;
            RenderTexture buff1 = RenderTexture.GetTemporary(src.width / scaler, src.height / scaler, 0);
            buff1.hideFlags = HideFlags.DontSave;
            //获取高亮
            /*
            Graphics.Blit(src, buff0, material, 0);
            RenderTexture.ReleaseTemporary(buff0); //debug
            buff0 = RenderTexture.GetTemporary(src.width / scaler, src.height / scaler, 0); //debug
            */
            //制造Ray
            Graphics.Blit(src, buff1, material, 1);

            for (int i = 0; i < iteration; i++) {
                Graphics.Blit(buff1, buff0, material, 1);
                Graphics.Blit(buff0, buff1, material, 1);
            }


            //混合图像
            material.SetTexture("_RayTex", buff1);
            material.SetFloat("_Alpha", alpha);
            Graphics.Blit(src, dest, material, 2);

            RenderTexture.ReleaseTemporary(buff0);
            RenderTexture.ReleaseTemporary(buff1);
        }
        else {
            Graphics.Blit(src, dest);
        }
    }

    /*
    void OnPreCull() {
        if (myCamera) {
            myCamera.clearFlags = CameraClearFlags.SolidColor;
            myCamera.backgroundColor = Color.black;
            myCamera.targetTexture = rt;
            myCamera.Render();
        }
    }

    void OnPostRender()
    {
        if (myCamera)
        {
            myCamera.clearFlags = CameraClearFlags.Skybox;
            myCamera.backgroundColor = Color.cyan;
        }
    }

    void Start() {
        rt = new RenderTexture(myCamera.pixelWidth, myCamera.pixelHeight, 16);
    }
    */
}
