Shader "Unlit/TessellationShader"
{
    Properties
    {
        _TessellationLevel("Level of Tessellation", Range(1, 32)) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        Pass
        {
            CGPROGRAM

            // ----------------------------------------------------------------------------------------------------------------------------------- Pragma
            #pragma vertex beforeTessVert

            #pragma require tessellation
            #pragma hull hullProgram
            #pragma domain domainProgram

            #pragma fragment frag

            #pragma target 5.0

            // ---------------------------------------------------------------------------------------------------------------------------------- Include
            #include "UnityCG.cginc"
            #include "Tessellation.cginc" 

            // ----------------------------------------------------------------------------------------------------------------------------------- Struct
            struct a2v
            {
                float4 vertexOS : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 vertexCS : SV_POSITION;
                float3 normal : NORMAL;
            };
            
            #ifdef UNITY_CAN_COMPILE_TESSELLATION
                // Define tessellation factor & inner tessellation factor
                struct TessFactors
                {
                    float edge[3] : SV_TESSFACTOR;
                    float inside  : SV_INSIDETESSFACTOR;
                };

                struct ControlPoint{
                    float4 vertexTess : INTERNALTESSPOS;
                    float3 normal : NORMAL;
                };

                // ------------------------------------------------------------------------------------------------------------------ Redifine Properties
                float _TessellationLevel;

                // ------------------------------------------------------------------------------------------------------------------------------ Kernels
                ControlPoint beforeTessVert (a2v v)
                {
                    ControlPoint o;

                    o.vertexTess  = v.vertexOS;
                    o.normal  = v.normal;

                    return o;
                }
                
                v2f afterTessVert (a2v v)
                {
                    v2f o;

                    o.vertexCS = UnityObjectToClipPos(v.vertexOS);
                    o.normal = v.normal;

                    return o;
                }

                TessFactors hsconst (InputPatch<ControlPoint, 3> patch)  // Helper method
                {
                    TessFactors o;

                    o.edge[0] = _TessellationLevel;
                    o.edge[1] = _TessellationLevel;
                    o.edge[2] = _TessellationLevel;
                    o.inside  = _TessellationLevel;

                    return o;
                }

                [UNITY_domain("tri")] // Fragment type
                [UNITY_outputcontrolpoints(3)]
                [UNITY_outputtopology("triangle_cw")]
                [UNITY_partitioning("fractional_odd")] // Tessellation method (Choose frome "qual_spacing", "fractional_odd", and "fractional_even"
                [UNITY_patchconstantfunc("hsconst")]
                ControlPoint hullProgram (InputPatch<ControlPoint, 3> patch, uint id : SV_OutputControlPointID)
                {
                    return patch[id];
                }

                [UNITY_domain("tri")] // Fragment type
                v2f domainProgram (TessFactors tessFactors, OutputPatch<ControlPoint, 3> patch,float3 bary : SV_DOMAINLOCATION)
                {
                    a2v v;

                    v.vertexOS = patch[0].vertexTess * bary.x + patch[1].vertexTess * bary.y + patch[2].vertexTess * bary.z;
			        v.normal = patch[0].normal * bary.x + patch[1].normal * bary.y + patch[2].normal * bary.z;

                    v2f o = afterTessVert(v);

                    return o;
                }
            #endif

            fixed4 frag (v2f i) : SV_Target
            {
                return float4(1, 1, 1, 1);
            }
            ENDCG
        }
    }
}
