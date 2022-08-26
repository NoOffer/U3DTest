Shader "Nofer/ScannerShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}

        _Center ("Effect Center", Vector) = (0, 0, 0)
        _Frequency ("Frequency", float) = 0.01
        _LineWidth ("Line Width", Range(0, 1)) = 1
        _LineIntensity ("Line Intensity", Range(0, 1)) = 1
        _RangeAtten ("Range Attenuation", Range(1, 10)) = 1
        _RangeIntensity ("Range Intensity", Range(0, 1)) = 1
        _EffectR ("Effect Radius", float) = 100
        _LineColor ("Effect Color", Color) = (1, 1, 1, 1)
    }
    SubShader
    {
        // No culling or depth
        Cull Off ZWrite Off ZTest Always

        Pass
        {
            HLSLPROGRAM

	        // ----------------------------------------------------------------------------------------------------------------------------------- Pragma
            #pragma shader_feature _AdditionalLights

            #pragma multi_compile _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile _SHADOWS_SOFT

            #pragma vertex vert
            #pragma fragment frag

	        // ---------------------------------------------------------------------------------------------------------------------------------- Include
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            //#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"

            struct a2f
            {
                float4 vertexOS : POSITION;
                float2 uv : TEXCOORD0;
            };

	        // ----------------------------------------------------------------------------------------------------------------------------------- Struct
            struct v2f
            {
                float4 vertexCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 viewVector : TEXCOORD1;
            };

	        // ---------------------------------------------------------------------------------------------------------------------- Redifine Properties
            sampler2D _MainTex;

            float3 _Center;
            float _Frequency;
            float _LineWidth;
            float _LineIntensity;
            float _RangeAtten;
            float _RangeIntensity;
            float _EffectR;
            float4 _LineColor;

	        // ---------------------------------------------------------------------------------------------------------------------------------- Kernels
            v2f vert (a2f v)
            {
                v2f o;
                o.vertexCS = mul(UNITY_MATRIX_MVP, v.vertexOS);
                o.uv = v.uv;
                o.viewVector = mul(unity_CameraToWorld, float4(mul(unity_CameraInvProjection, float4(v.uv * 2 - 1, 0, -1)).xyz, 0)).xyz;
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                float4 col = tex2D(_MainTex, i.uv);

                float depth = LinearEyeDepth(SampleSceneDepth(i.uv), _ZBufferParams);
                float3 worldCoord = _WorldSpaceCameraPos + i.viewVector * depth;
                float rFromCenter = length(worldCoord - _Center);
                //float scannerLine = step(1 - _LineWidth, sin(rFromCenter * _Frequency)) * saturate(1 - rFromCenter / _EffectR);
                float scannerLine = step(1 - _LineWidth, sin(rFromCenter * _Frequency));
                float scannerRange = rFromCenter / _EffectR;
                float scannerEffect = (scannerLine * _LineIntensity + pow(scannerRange, _RangeAtten) * _RangeIntensity);

                return scannerEffect * step(0, 1 - rFromCenter / _EffectR);
                return lerp(col, _LineColor, scannerLine);
            }
            ENDHLSL
        }
    }
}
