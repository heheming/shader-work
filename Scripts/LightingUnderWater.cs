using UnityEngine;
using System.Collections;

public class LightingUnderWater : PostProcessBase {
    public Shader shader;
    private Material _curMat;
    public Material material {
        get {
            _curMat = CheckShaderAndCreateMaterial(shader, _curMat);
            return _curMat;
        }
    }
    private Camera _myCamera;
    public Camera myCamera
    {
        get {
            if (_myCamera == null) {
                _myCamera = GetComponent<Camera>();
            }
            return _myCamera;
        }
    }

    //Control Variables
    public Transform lightSource;
    [Tooltip("光线颜色")]
    public Color rayColor = Color.white;
    [Tooltip("光线强度")]
    [Range(0, 3.0f)]
    public float rayStrScaler = 0.5f;
    [Tooltip("叠加透明度")]
    [Range(0, 1.0f)]
    public float alpha = 0.9f;
    [Tooltip("光线粗细度")]
    [Range(0, 3.0f)]
    public float thickness = 0.8f;
    [Tooltip("光源衰减")]
    [Range(0f, 1f)]
    public float fallOffRange = 0.5f;

    [Tooltip("光线1位置（uv位置）")]
    public Vector2 raySrcPos1 = new Vector2(0.7f, -0.4f);
    [Tooltip("光线1波动速度")]
    [Range(0f, 4.0f)]
    public float raySpeed1 = 1.5f;

    [Tooltip("光线2位置（uv位置）")]
    public Vector2 raySrcPos2 = new Vector2(0.8f, -0.6f);
    [Tooltip("光线2波动速度")]
    [Range(0f, 4.0f)]
    public float raySpeed2 = 1.1f;

    public float z = 0;

    void OnRenderImage(RenderTexture src, RenderTexture dest) {
        if (material)
        {
            if (lightSource)
            {
                Vector2 offset = new Vector2(0.02f, 0.04f);
                Vector3 lightScreenPos = myCamera.WorldToScreenPoint(lightSource.transform.position);
                lightScreenPos.x /= myCamera.pixelWidth;
                lightScreenPos.y /= myCamera.pixelHeight;
                //worldLightPos.x = Mathf.Clamp(worldLightPos.x / myCamera.pixelWidth, 1.1f, 2.0f);
                //lightScreenPos.y = Mathf.Clamp(lightScreenPos.y / myCamera.pixelHeight, 1.2f, 1.8f);
                material.SetVector("_raySource1", new Vector4(lightScreenPos.x, lightScreenPos.y, 0, 0));
                material.SetVector("_raySource2", new Vector4(lightScreenPos.x + offset.x, lightScreenPos.y - offset.y, 0, 0));
                raySrcPos1 = new Vector2(lightScreenPos.x, lightScreenPos.y);
                raySrcPos2 = new Vector2(lightScreenPos.x + offset.x, lightScreenPos.y - offset.y);
                z = lightScreenPos.z;
                float clipZ = 30.0f;

                float alphaFactor = 1f;
                if (lightScreenPos.z <= 0)
                {
                    Graphics.Blit(src, dest);
                    return;
                }
                if (lightScreenPos.z <= clipZ)
                {
                    alphaFactor *= lightScreenPos.z / clipZ;
                }

                material.SetFloat("_Alpha", alpha * alphaFactor);
                if (lightScreenPos.z <= 0)
                {
                    Graphics.Blit(src, dest);
                    return;
                }
            }
            else {
                material.SetVector("_raySource1", new Vector4(raySrcPos1.x, raySrcPos1.y, 0, 0));
                material.SetVector("_raySource2", new Vector4(raySrcPos2.x, raySrcPos2.y, 0, 0));
                material.SetFloat("_Alpha", alpha);
            }
            RenderTexture buff0 = RenderTexture.GetTemporary(src.width, src.height, 0);

            material.SetColor("_Color", rayColor);
            material.SetFloat("_rayStrScaler", rayStrScaler);
            material.SetFloat("_raySpeed1", raySpeed1);
            material.SetFloat("_raySpeed2", raySpeed2);
            material.SetFloat("_RayThickness", thickness);
            material.SetFloat("_FallOffRange", 1f - fallOffRange);

            Graphics.Blit(src, buff0, material, 0);
            material.SetTexture("_RayTex", buff0);
            Graphics.Blit(src, dest, material, 1);
            RenderTexture.ReleaseTemporary(buff0);
        }
        else {
            Graphics.Blit(src, dest);
        }
    }
}
