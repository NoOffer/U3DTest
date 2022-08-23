Shader "Nofer/GerstnerWaveShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}

        [Header(WaveFactors)]
        // Direction.xy, Steepness, Wavelength
		_WaveA ("Wave A", Vector) = (1,1,0.5,20)
		_WaveB ("Wave B", Vector) = (1,1,0.5,20)
		_WaveC ("Wave C", Vector) = (1,1,0.5,20)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        Pass
        {
            Name "Pass"

	        // ------------------------------------------------------------------------------------------------------------------------------------- Tags
            Tags 
            { 
                
            }
            
            // ----------------------------------------------------------------------------------------------------------------------------- Render State
            Cull Back

            CGPROGRAM

	        // ----------------------------------------------------------------------------------------------------------------------------------- Pragma
            #pragma vertex vert
            #pragma fragment frag

	        // ---------------------------------------------------------------------------------------------------------------------------------- Include
            #include "UnityCG.cginc"

	        // ----------------------------------------------------------------------------------------------------------------------------------- Struct
            struct a2v
            {
                float4 vertexOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertexCS : SV_POSITION;
                float3 normalWS : NORMAL;
                float2 uv : TEXCOORD0;
            };

	        // ---------------------------------------------------------------------------------------------------------------------- Redifine Properties
            sampler2D _MainTex;
            float4 _MainTex_ST;

            float4 _WaveA;
            float4 _WaveB;
            float4 _WaveC;

	        // ---------------------------------------------------------------------------------------------------------------------------------- Kernels
            float3 Gerstner (float3 vertexWS, float4 waveFactors, inout float3 tangent, inout float3 binormal)
            {
                float frequency = 2 * UNITY_PI / waveFactors.w;
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
                float4 vertexWS = originalPosWS;
			    float3 tangent = float3(1, 0, 0);
			    float3 binormal = float3(0, 0, 1);
                vertexWS += float4(Gerstner(originalPosWS, _WaveA, tangent, binormal), 0);
                vertexWS += float4(Gerstner(originalPosWS, _WaveB, tangent, binormal), 0);
                vertexWS += float4(Gerstner(originalPosWS, _WaveC, tangent, binormal), 0);
                o.vertexCS = mul(UNITY_MATRIX_VP, vertexWS);

                o.normalWS = normalize(cross(binormal, tangent));

                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                return float4(i.normalWS, 1);
            }
            ENDCG
        }
    }
}
