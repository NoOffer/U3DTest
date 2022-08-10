Shader "Nofer/PBRBlackHoleShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _NoiseTex ("Noise Texture", 2D) = "" {}
        _RingColor ("Ring Color", Color) = (1, 1, 1, 1)

        // Black Hole Info
        _CenterPos ("Sphere Center", Vector) = (0, 20, 0)
        _EHRadius ("Event Horizon Radius", float) = 10
        _DiskRadius ("Disk Radius", float) = 30
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

            #define MAX_STEP 800
            #define MIN_DIST 0.001

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
            sampler2D _NoiseTex;
            float4 _RingColor;

            float3 _CenterPos;
            float _EHRadius;
            float _DiskRadius;
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

            float getDickDist (float3 pos)
            {
                float verticalDist = pos.y - _CenterPos.y;
                float horizontalDist = max(length(pos.xz - _CenterPos.xz) - _DiskRadius, 0);
                return sqrt(verticalDist * verticalDist + horizontalDist * horizontalDist);
            }

            float4 rayMarch (float3 origin, float3 dir)
            {
                float3 currentPos = origin;
                float depth = 0;
                for (int i = 0; i < MAX_STEP; i++)
                {
                    float dist = getDickDist(currentPos);

                    if (dist < MIN_DIST)
                    {
                        float3 rawUV = (currentPos - _CenterPos) / _DiskRadius;
                        float2 processedUV = float2(rawUV.x, rawUV.z);
                        processedUV = float2(atan2(processedUV.x, processedUV.y) / 6.283, length(processedUV));
                        return float4(processedUV, 0, depth);
                    }
                    if (depth > _MaxDist)
                    {
                        break;
                    }
                    
                    depth += dist;
                    dir = normalize(dir + (_CenterPos - currentPos) * dist / pow(length(_CenterPos - currentPos), 3) * _IOR);
                    currentPos += dir * dist;
                }
                return float4(0, 0, 0, depth);
            }

            float4 frag (v2f i) : SV_Target
            {
                //float sceneDepth = LinearEyeDepth(SampleSceneDepth(i.screenPos.xyz / i.screenPos.w), _ZBufferParams);

                float3 oc = _CenterPos - _WorldSpaceCameraPos.xyz;
                float3 poc = dot(oc, normalize(i.viewVector)) * normalize(i.viewVector);
                float d = length(oc - poc);                

                float4 diskInfo = rayMarch(_WorldSpaceCameraPos.xyz, normalize(i.viewVector));
                if (d < _EHRadius)
                {
                    float sphereDepth = length(poc) - sqrt(_EHRadius * _EHRadius - d * d);
                    if (sphereDepth < diskInfo.w)
                    {
                        return 0;
                    }
                }
                if (diskInfo.w < _MaxDist)
                {
                    float centralRing = saturate(1.5 - diskInfo.y * 1.5);
                    float4 ringCol = lerp(tex2D(_NoiseTex, diskInfo.xy * float2(1, 2)) * centralRing, float4(1, 1, 1, 1), pow(centralRing, 5));
                    ringCol = 2 * ringCol;
                    //ringCol *= lerp(_RingColor, float4(1, 1, 1, 1), centralRing);
                    //return pow(saturate(1.5 - diskInfo.y * 1.5), 5);
                    return ringCol;
                }
                float4 col = tex2D(_MainTex, i.uv);
                return col;
            }
            ENDHLSL
        }
    }
}