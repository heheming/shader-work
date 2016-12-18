Shader "My Shader/PostFX/GodRay_simple"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_RayTex("RayTexture", 2D) = "white" {}
		_LightScreenPos("Light Screen Position", vector) = (0,0,0,0)
		_Luminance("God Ray Luminance Factor", float) = 1.0
		_Decay("Weight Decay", float) = 0.9
		_Weight("Inital Sample Weight", float) = 1.0
		_Density("Density", float) = 0.01
		_Alpha("Blending Alpha", float) = 0.5
		_LuminanceThreshold ("Luminance Threshold", Range(1.0, 1)) = 1.0
	}
	SubShader
	{
		CGINCLUDE

		#include "UnityCG.cginc"

		sampler2D _MainTex;
		sampler2D _RayTex;
		float4 _MainTex_TexelSize;
		float4 _LightScreenPos;
		float _Density;
		fixed _Luminance;
		fixed _Decay;
		fixed _Weight;
		float _Alpha;
		float _LuminanceThreshold;

		//-----------------
		// Common
		//-----------------
		struct appdata
		{
			float4 vertex : POSITION;
			float2 uv : TEXCOORD0;
		};

		struct v2f {
			float4 pos : SV_POSITION;
			half4 uv : TEXCOORD0;
		};
		//-----------------
		// Grab Bright
		//-----------------
		v2f vertGrabBrightness (appdata v) {
			v2f o; 
			o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
			o.uv.xy = v.uv;
			return o;
		}

		fixed LuminanceColor(fixed4 color) {
			return 0.2125 * color.r + 0.7154 * color.g + 0.0721 * color.b;
		}

		fixed4 fragGrabBrightness (v2f i) : SV_Target {
			fixed4 texColor = tex2D(_MainTex, i.uv.xy);
			fixed val = clamp((LuminanceColor(texColor) - _LuminanceThreshold), 0, 1.0);
			return texColor * val * 4.0f;
		}
		//-----------------
		// Ray
		//-----------------
		struct v2fRay
		{
			float4 pos : SV_POSITION;
			half2 uv0 : TEXCOORD0;
			half2 uv1 : TEXCOORD1;
			half2 uv2 : TEXCOORD2;
			half2 uv3 : TEXCOORD3;
			half2 uv4 : TEXCOORD4;
			half2 uv5 : TEXCOORD5;
			half2 uv6 : TEXCOORD6;
			half2 uv7 : TEXCOORD7;
		};

		v2fRay vertRay (appdata v)
		{
			v2fRay o;
			o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
			half2 uv = v.uv;
			//7个额外采样点（依据到光源的距离推进）
			half2 deltaTexcoord = (uv - _LightScreenPos) * 1.0f/8 *  _Density;
			o.uv0 = uv;
			o.uv1 = o.uv0 - deltaTexcoord;
			o.uv2 = o.uv1 - deltaTexcoord;
			o.uv3 = o.uv2 - deltaTexcoord;
			o.uv4 = o.uv3 - deltaTexcoord;
			o.uv5 = o.uv4 - deltaTexcoord;
			o.uv6 = o.uv5 - deltaTexcoord;
			o.uv7 = o.uv6 - deltaTexcoord;
			return o;
		}

		fixed4 fragRay (v2fRay i) : SV_Target
		{
			fixed weight = _Weight;
			fixed4 color = tex2D(_MainTex, i.uv0);
			//对7个偏移点进行采样并叠加color
			color += tex2D(_MainTex, i.uv1) * weight;
			weight *= _Decay;
			color += tex2D(_MainTex, i.uv2) * weight;
			weight *= _Decay;
			color += tex2D(_MainTex, i.uv3) * weight;
			weight *= _Decay;
			color += tex2D(_MainTex, i.uv4) * weight;
			weight *= _Decay;
			color += tex2D(_MainTex, i.uv5) * weight;
			weight *= _Decay;
			color += tex2D(_MainTex, i.uv6) * weight;
			weight *= _Decay;
			color += tex2D(_MainTex, i.uv7) * weight;
			color.rgb /= 8.0;

			return fixed4(color.rgb * _Luminance, 1);
		}
		//-----------------
		// Blend
		//-----------------
		v2f vertBlend(appdata v) {
			v2f o;
			o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
			o.uv.xy = v.uv;
			o.uv.zw = v.uv;
			//平台差异化
			#if UNITY_UV_STARTS_AT_TOP
			if (_MainTex_TexelSize.y < 0) {
				o.uv.w = 1.0 - o.uv.w;
			}
			#endif
			return o;
		}

		fixed4 fragBlend(v2f i) : SV_Target {
			//Brightness as mask
			//将高亮反转后作为一个alpha来决定最终合成的时候将多少颜色值叠加到原图像上（比如本来很亮的地区就叠加更低的颜色值）
			fixed4 texColor = tex2D(_MainTex, i.uv.xy);
			fixed val = 1.0 - clamp((LuminanceColor(texColor) - _LuminanceThreshold), 0, 1.0);
			return (texColor + tex2D(_RayTex, i.uv.zw) * _Alpha * val);

			//return fixed4(tex2D(_MainTex, i.uv.xy) + tex2D(_RayTex, i.uv.zw) * _Alpha);
		}

		ENDCG

		Cull Off ZWrite Off ZTest Always

		//Pass0 抓取高亮区域
		Pass 
		{
			CGPROGRAM
			#pragma vertex vertGrabBrightness
			#pragma fragment fragGrabBrightness
			ENDCG
		}
		//Pass1 制造Ray
		Pass
		{
			CGPROGRAM
			#pragma vertex vertRay
			#pragma fragment fragRay
			ENDCG
		}
		//Pass2 混合图像
		Pass 
		{
			CGPROGRAM
			#pragma vertex vertBlend
			#pragma fragment fragBlend
			ENDCG
		}
	}
	FallBack Off
}
