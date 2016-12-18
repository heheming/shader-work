//----------------------------------------------------------
// 参考自 https://www.shadertoy.com/view/lljGDt#
// 
//----------------------------------------------------------

Shader "My Shader/FX/LightingUnderWaterPostFX"
{
	Properties
	{
		_Color("RayColor", Color) = (1,1,1,0.5)
		_MainTex ("Texture", 2D) = "white" {}
		_RayTex("Ray Texture", 2D) = "white" {}
		_rayStrScaler("Ray Strength Scaler", Range(0, 3.0)) = 1.0
		_Alpha("Alpha", Range(0, 2.0)) = 1.0 
		_raySource1("Ray Source 1", vector) = (0.7, -0.4, 0, 0)
		_raySpeed1("Ray Speed 1", Range(0, 4)) = 1.5
		_raySource2("Ray Source 2", vector) = (0.8, -0.6, 0, 0)
		_raySpeed2("Ray Speed 2", Range(0, 4)) = 1.1
		_test("TestVal", float) = 1.0
		_RayThickness("Ray Thickness", Range(0, 3.0)) = 1.0
		_FallOffRange("FallOff Range", Range(0, 1.0)) = 0.5
	}
	SubShader
	{
		CGINCLUDE 

		#include "UnityCG.cginc"

		fixed4 _Color;
		sampler2D _MainTex;
		sampler2D _RayTex;
		float4 _MainTex_TexelSize;
		float4 _raySource1;
		float4 _raySource2;
		fixed _Alpha;
		fixed _raySpeed1;
		fixed _raySpeed2;
		float _test;
		fixed _RayThickness;
		fixed _rayStrScaler;
		fixed _FallOffRange;

		struct appdata
		{
			float4 vertex : POSITION;
			float2 uv : TEXCOORD0;
		};

		struct v2f
		{
			float4 pos : SV_POSITION;
			half4 uv : TEXCOORD0;
		};
			
		//
		//	Ray
		//
		v2f vertRay (appdata v)
		{
			v2f o;
			o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
			o.uv.xy = v.uv;
			
			#if UNITY_UV_STARTS_AT_TOP
			if (_MainTex_TexelSize.y < 0) {
				o.uv.y = 1 - o.uv.y;
			}
			#endif
			

			return o;
		}


		float rayStrength(float2 raySource, float2 rayRefDirection, float2 coord, float seedA, float seedB, float speed)
		{	
				
			fixed2 sourceToCoord = coord - raySource;
			float cosAngle = dot(normalize(sourceToCoord), rayRefDirection);

			//计算距离衰减，并限制根据距离衰减后的强度范围在0.5-1.0之间
			fixed atten = clamp(0.5 - length(sourceToCoord), _FallOffRange, 1);

			//clamp() 获得受时间影响的光照强度:
			//将两个间距平均分布的灰度图叠加
			//灰度图1	(0.45 + 0.15 * sin((cosAngle * seedA + _Time.y * speed)/_RayThickness))
			//灰度图2	(0.3 + 0.2 * cos((-cosAngle * seedB + _Time.y * speed)/_RayThickness))
			return clamp((0.45 + 0.15 * sin((cosAngle * seedA + _Time.y * speed)/_RayThickness)) +
				(0.3 + 0.2 * cos((-cosAngle * seedB + _Time.y * speed)/_RayThickness)),
				0.0, 1.0) *
				atten;
		}
			
		fixed4 fragRay (v2f i) : SV_Target
		{
			half2 uv = i.uv;
			uv.y = 1 - uv.y;
			//获得基于x轴镜像位置
			half2 coord = half2(uv.x, 1 - uv.y);

			// Set the parameters of the sun rays
			//float2 rayPos1 = float2(0.7, -0.4);	
			float2 rayPos1 = float2(_raySource1.x, _raySource1.y);
			//float2 rayPos1 = float2(_raySource1.x, clamp(_raySource1.y, 1.1, 2));	
			//取一个向量作为Ray的ReferenceDirection;
			fixed2 rayRefDir1 = normalize(fixed2(1.0, -0.116));
			float raySeedA1 = 36.2214;
			float raySeedB1 = 21.11349;

			/*
			//同Ray1
			//float2 rayPos2 = float2(0.8, -0.6);
			float2 rayPos2 = float2(_raySource2.x, _raySource2.y);
			//float2 rayPos2 = float2(_raySource2.x, clamp(_raySource2.y, 1.1, 2));
			fixed2 rayRefDir2 = normalize(fixed2(1.0, 0.241));
			const float raySeedA2 = 22.39910;
			const float raySeedB2 = 18.0234;
			*/

			// Calculate the colour of the sun rays on the current fragment
			fixed rayStr = rayStrength(rayPos1, rayRefDir1, coord, raySeedA1, raySeedB1, _raySpeed1) * _rayStrScaler;
			fixed4 rays1 = fixed4(_Color.rgb * rayStr, rayStr);
			//rayStr = rayStrength(rayPos2, rayRefDir2, coord, raySeedA2, raySeedB2, _raySpeed2) * _rayStrScaler;
			//fixed4 rays2 = fixed4(_Color.rgb * rayStr, rayStr);
	 

			//fixed4 fragColor = rays1 * 0.5 + rays2 * 0.4;
			fixed4 fragColor = rays1;

			// Attenuate brightness towards the bottom, simulating light-loss due to depth.
			// Give the whole thing a blue-green tinge as well.	
			//假设亮度是从海平面到水底逐渐减弱
			float brightness = 1.0 - coord.y;
			fragColor.r *= 0.1 + (brightness * 0.8);
			fragColor.g *= 0.3 + (brightness * 0.6);
			fragColor.b *= 0.5 + (brightness * 0.5);
				
			return fragColor;
		}

		//
		//	Blend
		//
		v2f vertBlend (appdata v)
		{
			v2f o;
			o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
			o.uv.xy = v.uv;
			o.uv.zw = v.uv;
			#if UNITY_UV_STARTS_AT_TOP
			if (_MainTex_TexelSize.y < 0) {
				o.uv.w = 1 - o.uv.w;
			}
			#endif
			return o;
		}

		fixed4 fragBlend(v2f i) :SV_Target {
			return fixed4(tex2D(_MainTex, i.uv.xy).rgb + tex2D(_RayTex, i.uv.zw).rgb * _Alpha, 1.0);
		}

		ENDCG

		ZTest Always ZWrite Off Cull Off
		//Pass0 Generate Ray
		Pass 
		{
			CGPROGRAM
			#pragma vertex vertRay
			#pragma fragment fragRay
			
			ENDCG
		}

		//Pass1 Blend 
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
