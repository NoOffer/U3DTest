Shader "Hidden/GodRayShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}

        _MaxDist ("Max Distance", float) = 150
        _MaxStepLen ("Max Step Length", Range(0, 1)) = 1
        _MinLum ("Minimum Level of Lumination", Range(0, 1)) = 0
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

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile _ _SHADOWS_SOFT

            #pragma vertex vert
            #pragma fragment frag

	        // ---------------------------------------------------------------------------------------------------------------------------------- Include
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"

            #define MAX_STEP 32
            //#define MAX_DIST 50
            //#define MIN_DIST 0.001

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

            float _MaxDist;
            float _MaxStepLen;
            float _MinLum;

	        // ---------------------------------------------------------------------------------------------------------------------------------- Kernels
            v2f vert (a2f v)
            {
                v2f o;
                o.vertexCS = mul(UNITY_MATRIX_MVP, v.vertexOS);
                o.uv = v.uv;
                o.viewVector = mul(unity_CameraToWorld, float4(mul(unity_CameraInvProjection, float4(v.uv * 2 - 1, 0, -1)).xyz, 0)).xyz;
                return o;
            }

            //float getDist (float3 pos)
            //{
            //    return 0;
            //}

            float getShadow (float3 posWS)
            {
                return MainLightRealtimeShadow(TransformWorldToShadowCoord(posWS));
            }

            float rayMarch (float3 dir, float sceneDepth)
            {
                float3 currentPos = _WorldSpaceCameraPos;
                float stepSize = min(sceneDepth / MAX_STEP, _MaxStepLen);
                float shadowSample = 1;
                for (int i = 0; i < MAX_STEP; i++)
                {
                    currentPos += dir * stepSize;
                    
                    shadowSample += getShadow(currentPos);
                }
                return shadowSample / MAX_STEP;
            }

            //float EasyInOut (float x)
            //{
            //    x = saturate(x);
            //    return pow(x, _Rate);
            //    //return sin(3.1415926 * (x - 0.5)) * 0.5 + 0.5;
            //}

            float4 frag (v2f i) : SV_Target
            {
                float4 col = tex2D(_MainTex, i.uv);

                float depth = LinearEyeDepth(SampleSceneDepth(i.uv), _ZBufferParams);
                float3 worldCoord = _WorldSpaceCameraPos + normalize(i.viewVector) * depth;
                //float shadowAtCam = getShadow(_WorldSpaceCameraPos);
                float shadowSample = rayMarch(normalize(i.viewVector), length(worldCoord - _WorldSpaceCameraPos));

                //return step(0.99, shadowSample);
                return float4(col.rgb * (shadowSample * (1 - _MinLum) + _MinLum), 1);
            }
            ENDHLSL
        }
    }
}
