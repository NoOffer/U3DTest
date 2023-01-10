Shader "Nofer/CloudImgEffect"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "White" {}

        _BoundMin ("Start Corner of the Bound", Vector) = (-1, -1, -1)
        _BoundMax ("End Corner of the Bound", Vector) = (1, 1, 1)

        _CloudTex ("Cloud Texture", 3D) = "" {}
        _CloudScale ("Scale of Cloud Noise", Vector) = (0, 0, 0)
        _CloudOffset ("Offset of Cloud Noise", Vector) = (0, 0, 0)
        _CloudColor ("Cloud Color", Color) = (1, 1, 1, 1)

        _SampleStepCount ("Sample Step Count", int) = 20
        _DensityThreshold ("Density Threshold", Range(0, 1)) = 0.5

        //_PhaseParams ("Phase Parameters", Vector) = (0.5, -0.1, 0.5, 0.5)
        _CloudAbsorption ("Light Absorption Through Cloud", Range(0.1, 10)) = 1
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
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareOpaqueTexture.hlsl"

	        // ----------------------------------------------------------------------------------------------------------------------------------- Struct
            struct a2v
            {
                float4 vertexOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertexCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 viewVector : TEXCOORD1;
                float4 screenPos : TEXCOORD2;
            };

	        // ---------------------------------------------------------------------------------------------------------------------- Redifine Properties
            sampler2D _MainTex;

            float3 _BoundMin;
            float3 _BoundMax;

            sampler3D _CloudTex;
            float3 _CloudScale;
            float3 _CloudOffset;
            float4 _CloudColor;

            float _SampleStepCount;
            float _DensityThreshold;

            //float4 _PhaseParams;
            float _CloudAbsorption;

	        // ---------------------------------------------------------------------------------------------------------------------------------- Kernels
            v2f vert (a2v v)
            {
                v2f o;
                o.vertexCS = mul(UNITY_MATRIX_MVP, v.vertexOS);
                o.uv = v.uv;
                o.viewVector = mul(unity_CameraToWorld, float4(mul(unity_CameraInvProjection, float4(v.uv * 2 - 1, 0, -1)).xyz, 0)).xyz;
                o.screenPos = ComputeScreenPos(o.vertexCS);
                return o;
            }

            float2 RayBoxDist (float3 boxMin, float3 boxMax, float3 rayOrigin, float3 rayDir)
            {
                float3 t0 = (boxMin - rayOrigin) / rayDir;
                float3 t1 = (boxMax - rayOrigin) / rayDir;
                float3 tmin = min(t0, t1);
                float3 tmax = max(t0, t1);
                float distToBox = max(0, max(max(tmin.x, tmin.y), tmin.z));
                float distInsideBox = max(0, min(min(tmax.x, tmax.y), tmax.z) - distToBox);

                return float2(distToBox, distInsideBox);
            }

            float SampleDensity (float3 pos)
            {
                float3 uvw = pos * _CloudScale * 0.01 + _CloudOffset * 0.1;
                return tex3D(_CloudTex, uvw).a;
            }

            float3 SampleNormal (float3 pos)
            {
                float3 uvw = pos * _CloudScale * 0.01 + _CloudOffset * 0.1;
                return tex3D(_CloudTex, uvw).rgb;
            }

            //// Henyey-Greenstein
            //float hg (float a, float g)
            //{
            //    float g2 = g * g;
            //    return (1 - g2) / (4 * 3.1415 * pow(1 + g2 - 2 * g * a, 1.5));
            //}

            //float phase (float a)
            //{
            //    float blend = 0.5;
            //    float hgBlend = hg(a, _PhaseParams.x) * (1 - blend) + hg(a, -_PhaseParams.y) * blend;
            //    return _PhaseParams.z + hgBlend * _PhaseParams.w;
            //}

            float BeerPowder (float d)
            {
                return 2 * exp(-d) * (1 - exp(-2 * d));
            }

            float LightMarch (float3 origin, float3 lightDir)
            {
                float3 currentPos = origin;
                float distLimit = RayBoxDist(_BoundMin, _BoundMax, origin, lightDir).y;
                float totalDensity = 0;
                float stride = distLimit / _SampleStepCount;
                [unroll(100)]
                for (int stepCount = 0; stepCount < _SampleStepCount; stepCount++)
                {
                    currentPos += lightDir * stride;
                    totalDensity += SampleDensity(currentPos);
                }
                return exp(-totalDensity * _CloudAbsorption);
            }

            float4 frag (v2f i) : SV_Target
            {
                float4 bgCol = tex2D(_MainTex, i.uv);

                // Calculate view direction
                float3 viewDir = normalize(i.viewVector);
                // Calculate the distance to, and travelled in the box
                float2 boxDistInfo = RayBoxDist(_BoundMin, _BoundMax, _WorldSpaceCameraPos.xyz, viewDir);
                // Calculate scene depth
                float sceneDepth = LinearEyeDepth(SampleSceneDepth(i.screenPos.xy / i.screenPos.w), _ZBufferParams);
                sceneDepth *= length(i.viewVector);

                Light l = GetMainLight();

                //// Phase function makes clouds brighter around sun
                //float phaseVal = phase(dot(viewDir, l.direction));
                
                // Accumulate density into cloud
                float totalDensity = 0;
                float lightEnergy = 0;
                float distLimit = min(sceneDepth - boxDistInfo.x, boxDistInfo.y);
                if (distLimit > 0)
                {
                    float stride = distLimit / _SampleStepCount;
                    float3 rayPos = _WorldSpaceCameraPos.xyz + viewDir * boxDistInfo.x;
                    [unroll(100)]
                    for (int stepCount = 0; stepCount < _SampleStepCount; stepCount++)
                    {
                        rayPos += viewDir * stride;
                        float density = SampleDensity(rayPos);
                        float transmittance = LightMarch(rayPos, l.direction);
                        totalDensity += density;
                        lightEnergy += transmittance * stride;
                    }
                    return exp(-totalDensity * _CloudAbsorption);
                    return BeerPowder(totalDensity / _SampleStepCount);
                }
                return bgCol;

                //return BeerPowder(totalDensity / 10);
                //return SampleDensity(_WorldSpaceCameraPos.xyz + viewDir * boxDistInfo.x);
            }
            ENDHLSL
        }
    }
}
