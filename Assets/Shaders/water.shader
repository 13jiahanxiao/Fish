﻿Shader "Unlit/water"
{
    Properties
    {
		_Color("Color",color)=(1,1,1,1)
        _MainTex ("Albedo(RGB)", 2D) = "white" {}
		_Glossiness("Smoothness",Range(0,1)) = 0.5
		_Metallic("Metallic",Range(0,1)) = 0.0
		[NoScaleOffset] _FlowMap("Flow(RG,A noise)",2D) = "black"{}
		//[NoScaleOffset] _NormalMap("Normal Map",2D) = "bump"{}
		[NoScaleOffset]_DerivHeightMap("Deriv Height",2D) = "black"{}
		_UJump("U Jump",Range(-0.25,0.25)) = 0.25
		_VJump("V Jump", Range(-0.25, 0.25)) = 0.25
		_Tiling("Tiling",Float) = 1
		_Speed("Speed",Float) = 1
		_FlowStrength("Flow Strength",Float) = 1
		_FlowOffset("Flow Offset",Float) = 0
			_HeightScale("Height Scale",Float) = 0.25
			_HeightScaleModulated("Height Scale(Modulated)",Float)=0.75
	}
		SubShader
		{
			Tags { "RenderType" = "Opaque" }
			LOD 200
				CGPROGRAM

	#pragma surface surf Standard fullforwardshadows
	#pragma target 3.0
			#include"Flow.cginc"
		sampler2D _MainTex,_FlowMap,_DerivHeightMap;
	    float _UJump, _VJump,_Tiling,_Speed,_FlowStrength,_FlowOffset;
		float _HeightScale,_HeightScaleModulated;
		struct Input 
		{
			float2 uv_MainTex;
		};

		half _Glossiness;
		half _Metallic;
		fixed4 _Color;

		float3 UnpackDerivativeHeight(float4 textureData) 
		{
			float3 dh = textureData.agb;
			dh.xy = dh.xy * 2 - 1;
			return dh;
		}

		void surf(Input IN, inout SurfaceOutputStandard o)
		{
			float2 jump = float2(_UJump, _VJump);
			//float2 flowUV = tex2D(_FlowMap, IN.uv_MainTex).rg*2-1;
			float3 flow = tex2D(_FlowMap, IN.uv_MainTex).rgb;
			flow.xy = flow.xy * 2 - 1;
			flow *= _FlowStrength;
			float noise = tex2D(_FlowMap, IN.uv_MainTex).a;
			float time = _Time.y*_Speed + noise;

			float3 uvw = FlowUVW(IN.uv_MainTex, flow.xy, time, false, jump, _Tiling, _FlowOffset);
			float3 uvwB = FlowUVW(IN.uv_MainTex, flow.xy, time, true, jump, _Tiling, _FlowOffset);

			float finalHeightScale = length(flow.z) * _HeightScaleModulated + _HeightScale;
			float3 dhA = UnpackDerivativeHeight(tex2D(_DerivHeightMap, uvw.xy))*(uvw.z*finalHeightScale);
			float3 dhB = UnpackDerivativeHeight(tex2D(_DerivHeightMap, uvwB.xy)) * (uvwB.z*finalHeightScale);
			o.Normal = normalize(float3(-(dhA.xy+dhB.xy),1));

			fixed4 texA= tex2D(_MainTex, uvw.xy) *uvw.z;
			fixed4 texB = tex2D(_MainTex, uvwB.xy) * uvwB.z;
			fixed4 c = (texA + texB)* _Color;
			o.Albedo = c.rgb;
			//o.Albedo = pow(dhA.z+dhB.z,2);
			o.Metallic = _Metallic;
			o.Smoothness = _Glossiness;
			o.Alpha = c.a;
		}
		ENDCG
    }
			FallBack"Diffuse"
}
