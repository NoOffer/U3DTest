Shader "Nofer/BlackHoleShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}

        // Black Hole Info
        _CenterPos ("Sphere Center", Vector) = (0, 20, 0)
        _SphereRadius ("Sphere Radiuss", float) = 15
        _EHRadius ("Event Horizon Radius", float) = 10
        _IOR ("IOR", float) = 0

        // Ray Marching Settings
        _MaxDist ("Max Distance", float) = 100
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
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"

            // ----------------------------------------------------------------------------------------------------------------------------------- Struct
            struct appdata
            {
                float4 vertexOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertexCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float4 screenPos : TEXCOORD1;
                float3 viewVector : TEXCOORD2;
            };

	        // ---------------------------------------------------------------------------------------------------------------------- Redifine Properties
            sampler2D _MainTex;

            float3 _CenterPos;
            float _SphereRadius;
            float _EHRadius;
            float _IOR;

            float _MaxDist;

	        // ---------------------------------------------------------------------------------------------------------------------------------- Kernels
            v2f vert (appdata v)
            {
                v2f o;
                o.vertexCS = mul(UNITY_MATRIX_MVP, v.vertexOS);
                o.uv = v.uv;
                o.screenPos = ComputeScreenPos(o.vertexCS);
                o.viewVector = mul(unity_CameraToWorld, float4(mul(unity_CameraInvProjection, float4(v.uv * 2 - 1, 0, -1)).xyz, 0)).xyz;
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                float3 oc = _CenterPos - _WorldSpaceCameraPos.xyz;
                float3 poc = dot(oc, normalize(i.viewVector)) * normalize(i.viewVector);
                float d = length(oc - poc);
                float2 centralVector = normalize(mul(unity_CameraProjection, mul(unity_WorldToCamera, float4(normalize(oc), 1))).xy - (i.uv * 2 - 1));

                if (d < _EHRadius)
                {
                    float sphereDepth = length(poc) - sqrt(_EHRadius * _EHRadius - d * d);
                    float sceneDepth = LinearEyeDepth(SampleSceneDepth(i.screenPos.xy / i.screenPos.w), _ZBufferParams);
                    if (sphereDepth < sceneDepth)
                    {
                        return 0;
                    }
                }
                else
                {
                    i.uv += centralVector / (pow(d / _SphereRadius, 2) + 0.01) * _IOR;
                }
                float4 col = tex2D(_MainTex, i.uv);
                return col;
                //return 1 / (pow(d / _SphereRadius, 2) + 0.01) * _IOR;
                //return float4(i.uv + centralVector / (pow(d / _SphereRadius, 2) + 0.01) * _IOR, 0, 1);
            }
            ENDHLSL
        }
    }
}
