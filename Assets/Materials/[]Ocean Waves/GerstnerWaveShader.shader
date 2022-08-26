Shader "Nofer/GerstnerWaveShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _NormalMap ("Normal Map", 2D) = "" {}

        [Header(WaveFactors)]
        // Direction.xy, Steepness, Wavelength
		_WaveA ("Wave A", Vector) = (1,1,0.5,20)
		_WaveB ("Wave B", Vector) = (1,1,0.5,20)
		_WaveC ("Wave C", Vector) = (1,1,0.5,20)
        
        [Header(SurfaceSettings)]
        _NormalBlend ("Normal Blend", Range(0, 1)) = 0.3
        _NormalShiftSpeed ("Normal Shift Speed", float) = 0.1
        _Smoothness ("Smoothness", Range(0, 1)) = 1
        _SurfaceColor ("Surface Color", Color) = (1, 1, 1, 1)
        _DepthFactor ("Depth Factor", float) = 0.9
        _Transparency ("Transparency", Range(0, 1)) = 0.9

    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" }

        Pass
        {
            Name "Pass"

	        // ------------------------------------------------------------------------------------------------------------------------------------- Tags
            Tags 
            { 
                
            }
            
            // ----------------------------------------------------------------------------------------------------------------------------- Render State
            Cull Back

            HLSLPROGRAM

	        // ----------------------------------------------------------------------------------------------------------------------------------- Pragma
            #pragma vertex vert
            #pragma fragment frag

	        // ---------------------------------------------------------------------------------------------------------------------------------- Include
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

	        // ----------------------------------------------------------------------------------------------------------------------------------- Struct
            struct a2v
            {
                float4 vertexOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertexWS : TEXCOORD0;
                float4 vertexCS : SV_POSITION;
                float3 normalWS : NORMAL;
                float2 uv : TEXCOORD1;
                float4 screenPos : TEXCOORD2;
            };

	        // ---------------------------------------------------------------------------------------------------------------------- Redifine Properties
            sampler2D _MainTex;
            float4 _MainTex_ST;

            sampler2D _NormalMap;
            float4 _NormalMap_ST;

            SAMPLER(_CameraOpaqueTexture);

            float4 _WaveA;
            float4 _WaveB;
            float4 _WaveC;

            float _NormalBlend;
            float _NormalShiftSpeed;
            float _Smoothness;
            float4 _SurfaceColor;
            float _DepthFactor;
            float _Transparency;

	        // ---------------------------------------------------------------------------------------------------------------------------------- Kernels
            float3 Gerstner (float3 vertexWS, float4 waveFactors, inout float3 tangent, inout float3 binormal)
            {
                float frequency = 6.2831852 / waveFactors.w;
                float phaseSpeed = sqrt(9.8 / frequency);
                float2 dir = normalize(waveFactors.xy);
                float f = frequency * (dot(dir, vertexWS.xz) + _Time.y * phaseSpeed);
                float amp = waveFactors.z / frequency;

                tangent += float3(
                    (_WaveA.z * sin(f)) * dir.x * dir.x * -1,
				    (_WaveA.z * cos(f)) * dir.x,
				    (_WaveA.z * sin(f)) * dir.x * dir.y * -1
			        );
			    binormal += float3(
				    tangent.z,
				    (_WaveA.z * cos(f)) * dir.y,
				    (_WaveA.z * sin(f)) * dir.y * dir.y * -1
			        );

                return float3(
                    amp * cos(f) * dir.x,
                    amp * sin(f),
                    amp * cos(f) * dir.y
                    );
            }

            v2f vert (a2v v)
            {
                v2f o;

                float4 originalPosWS = mul(UNITY_MATRIX_M, v.vertexOS);
                o.vertexWS = originalPosWS;
			    float3 tangent = float3(1, 0, 0);
			    float3 binormal = float3(0, 0, 1);
                o.vertexWS += float4(Gerstner(originalPosWS.xyz, _WaveA, tangent, binormal), 0);
                o.vertexWS += float4(Gerstner(originalPosWS.xyz, _WaveB, tangent, binormal), 0);
                o.vertexWS += float4(Gerstner(originalPosWS.xyz, _WaveC, tangent, binormal), 0);

                o.vertexCS = mul(UNITY_MATRIX_VP, o.vertexWS);
                
                o.normalWS = normalize(cross(binormal, tangent));
                float3x3 matrixTBN = float3x3(
                    tangent.x, tangent.y, tangent.z,
                    binormal.x, binormal.y, binormal.z, 
                    o.normalWS.x, o.normalWS.y, o.normalWS.z
                    );
                float3 shiftedNormal =
                    mul(matrixTBN, o.normalWS) +
                    tex2Dlod(_NormalMap, float4(o.vertexWS.xz * _NormalMap_ST.xy + _Time.y * _NormalShiftSpeed, 0, 0)).xyz;
                o.normalWS = lerp(o.normalWS, normalize(mul(matrixTBN, shiftedNormal)), _NormalBlend);

                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                o.screenPos = ComputeScreenPos(o.vertexCS);

                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                float sceneDepth = LinearEyeDepth(SampleSceneDepth(i.screenPos.xy / i.screenPos.w), _ZBufferParams);
                // Get view direction
                float3 viewRay = _WorldSpaceCameraPos.xyz - i.vertexWS.xyz;
                float4 sceneColor = tex2D(_CameraOpaqueTexture, i.screenPos.xy / i.screenPos.w);

                Light l = GetMainLight();
                // Calculate diffuse
                float diffuse = saturate(dot(i.normalWS, l.direction));
                // Calculate specular
                float3 h = normalize(l.direction + normalize(viewRay));
                float specular = pow(saturate(dot(i.normalWS, h)), exp2(10 * _Smoothness + 1)) * diffuse * _Smoothness;
                float3 ambient = float3(unity_SHAr.w, unity_SHAg.w, unity_SHAb.w);

                float4 waterColor = float4(_SurfaceColor.rgb * diffuse + l.color.rgb * specular, 1);
                
                if (length(viewRay) > sceneDepth)
                {
                    return sceneColor;
                }
                //return pow(saturate((sceneDepth - length(viewRay)) * _DepthFactor), 3);
                return lerp(sceneColor, waterColor, pow(saturate((sceneDepth - length(viewRay)) * _DepthFactor), 3) * _Transparency);
            }
            ENDHLSL
        }
    }
}
