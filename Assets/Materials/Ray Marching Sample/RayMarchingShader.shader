Shader "Hidden/RayMarchingShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        // No culling or depth
        Cull Off ZWrite Off ZTest Always

        Pass
        {
            HLSLPROGRAM

	        // ----------------------------------------------------------------------------------------------------------------------------------- Pragma
            #pragma vertex vert
            #pragma fragment frag

	        // ---------------------------------------------------------------------------------------------------------------------------------- Include
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            //#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"

            #define MAX_STEP 100
            #define MAX_DIST 500
            #define MIN_DIST 0.001

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

	        // ---------------------------------------------------------------------------------------------------------------------------------- Kernels
            v2f vert (a2f v)
            {
                v2f o;
                o.vertexCS = mul(UNITY_MATRIX_MVP, v.vertexOS);
                o.uv = v.uv;
                o.viewVector = mul(unity_CameraToWorld, float4(mul(unity_CameraInvProjection, float4(v.uv * 2 - 1, 0, -1)).xyz, 0)).xyz;
                return o;
            }

            float getDist (float3 pos)
            {
                return 0;
            }

            float rayMarch (float3 origin, float3 dir)
            {
                float3 currentPos = origin;
                float depth = 0;
                for (int i = 0; i < MAX_STEP; i++)
                {
                    float dist = getDist(currentPos);

                    // Surface reached
                    if (dist < MIN_DIST)
                    {

                    }
                    // No surface reached
                    if (depth > MAX_DIST)
                    {

                    }
                    
                    depth += dist;
                    currentPos += dir * dist;
                }
                return depth;
            }

            float4 frag (v2f i) : SV_Target
            {
                float4 col = tex2D(_MainTex, i.uv);

                return col;
            }
            ENDHLSL
        }
    }
}
