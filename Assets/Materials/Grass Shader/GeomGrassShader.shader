Shader "Unlit/GeomGrassShader"
{
    Properties
    {
        // Grass color
        _TopColor ("Grass Top Color", Color) = (0.2, 1, 0.2, 1)
        _BottomColor ("Grass Bottom Color", Color) = (0, 0.5, 0, 1)

        // Grass shape
        _BladeWidth("Blade Width", Range(0, 1)) = 0.05
        _BladeWidthVary("Blade Width Varying", Range(0, 1)) = 0.02
        _BladeHeight("Blade Height", Range(0, 5)) = 0.5
        _BladeHeightVary("Blade Height Varying", Range(0, 1)) = 0.3
        // Grass forward
        _BladeForward("Blade Forward Amount", Float) = 0.4
        _BladeCurvature("Blade Curvature Level", Range(1, 4)) = 2
        
        // Wind effects
        _WindMap("Wind Map", 2D) = "white" {}
        _WindStrength("Wind Strength", Float) = 1
        _WindFrequency("Wind Frequency", Vector) = (0.05, 0.05, 0, 0)
        
        // Tessellation
        _TessellationLevel("Level of Tessellation", Range(1, 16)) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        // Base plane
        Pass
        {
            Tags
            {
                "LightMode" = "SRPDefaultUnlit"
            }

            Cull back

            CGPROGRAM
            // ----------------------------------------------------------------------------------------------------------------------------------- Pragma
            #pragma vertex vert
            #pragma fragment baseFrag

            // ---------------------------------------------------------------------------------------------------------------------------------- Include
            #include "UnityCG.cginc"

            // ---------------------------------------------------------------------------------------------------------------------------------- Kernels
            v2f vert (a2v i)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(i.vertex);
                o.normal = i.normal;
                o.tangent = i.tangent;
                return o;
            }

            float4 baseFrag (v2f v) : SV_Target
            {
                return _BottomColor;
            }
            ENDCG
        }

        // Grass
        Pass
        {
            Tags
            {
                "LightMode" = "UniversalForward"
            }

            Cull off

            CGPROGRAM
            // ----------------------------------------------------------------------------------------------------------------------------------- Pragma
            #pragma vertex beforeTessVert

            #pragma require tessellation
            #pragma hull hullProgram
            #pragma domain domainProgram

            #pragma require geometry
            #pragma geometry geo

            #pragma fragment grassFrag

            #pragma target 5.0
            #pragma multi_compile_fwdbase
            ENDCG

            CGINCLUDE
            // ---------------------------------------------------------------------------------------------------------------------------------- Include
            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            // ----------------------------------------------------------------------------------------------------------------------------------- Struct
            // ------------------------------------------------------------------------------------------------------------------------ vertex Phase ----
            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
            };

            // ------------------------------------------------------------------------------------------------------------------ Tessellation Phase ----
            // Define tessellation factor & inner tessellation factor
            struct TessFactors
            { 
                float edge[3] : SV_TESSFACTOR;
                float inside  : SV_INSIDETESSFACTOR;
            };
                
            struct ControlPoint
            {
                float4 vertex : INTERNALTESSPOS;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
            };

            // ---------------------------------------------------------------------------------------------------------------------- Geometry Phase ----
            struct geomData
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            // ---------------------------------------------------------------------------------------------------------------------- Fragment Phase ----
            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
            };

            // ---------------------------------------------------------------------------------------------------------------------- Redifine Properties
            // Grass color
            float4 _TopColor;
            float4 _BottomColor;
            
            // Grass shape
            float _BladeHeight;
            float _BladeHeightVary;	
            float _BladeWidth;
            float _BladeWidthVary;
            // Grass forward
            float _BladeForward;
            float _BladeCurvature;

            // Wind effects
            sampler2D _WindMap;
            float4 _WindMap_ST;
            float _WindStrength;
            float2 _WindFrequency;

            // Tessellation
            float _TessellationLevel;

            // ---------------------------------------------------------------------------------------------------------------------------------- Kernels
            // ------------------------------------------------------------------------------------------------------------------------ Vertex Phase ----
            ControlPoint beforeTessVert (a2v v)
            {
                ControlPoint o;

                o.vertex  = v.vertex;
                o.normal  = v.normal;
                o.tangent = v.tangent;

                return o;
            }
            
            // ------------------------------------------------------------------------------------------------------------------- Tesselation Phase ----
            v2f afterTessVert (a2v v)
            {
                v2f o;

                //o.vertex = UnityObjectToClipPos(v.vertex);
                o.vertex = v.vertex;
                o.normal = v.normal;
                o.tangent = v.tangent;

                return o;
            }

            TessFactors hsconst (InputPatch<ControlPoint,3> patch)
            {
                TessFactors o;
                o.edge[0] = _TessellationLevel;
                o.edge[1] = _TessellationLevel;
                o.edge[2] = _TessellationLevel;
                o.inside  = _TessellationLevel;
                return o;
            }
                
            // Fragment type
            [UNITY_domain("tri")]
            [UNITY_outputcontrolpoints(3)]
            [UNITY_outputtopology("triangle_cw")]
            // Tessellation method
            //[UNITY_partitioning("equal_spacing")]
            [UNITY_partitioning("fractional_odd")]
            //[UNITY_partitioning("fractional_even")]
            // Other settings that I don't understand
            [UNITY_patchconstantfunc("hsconst")]
            ControlPoint hullProgram (InputPatch<ControlPoint,3> patch,uint id : SV_OutputControlPointID){
                return patch[id];
            }

            // Fragment type
            [UNITY_domain("tri")]
            v2f domainProgram (TessFactors tessFactors, const OutputPatch<ControlPoint,3> patch, float3 bary : SV_DOMAINLOCATION)
            {
                a2v v;
                v.vertex = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
			    v.normal = patch[0].normal * bary.x + patch[1].normal * bary.y + patch[2].normal * bary.z;
			    v.tangent = patch[0].tangent * bary.x + patch[1].tangent * bary.y + patch[2].tangent * bary.z;

                return afterTessVert(v);
            }

            // ---------------------------------------------------------------------------------------------------------------------- Geometry Phase ----
            float rand (float3 coord)  // Helper method
            {
                return frac(sin(dot(coord.xyz, float3(12.9898, 78.233, 53.539))) * 43758.5453);
            }

            float3x3 AngleAxis3x3 (float angle, float3 axis)  // Helper method
            {
                float s;
                float c;
                sincos(angle, s, c);

                float t = 1 - c;
                float x = axis.x;
                float y = axis.y;
                float z = axis.z;

                return float3x3(
                    t * x * x + c, t * x * y - s * z, t * x * z + s * y,
                    t * x * y + s * z, t * y * y + c, t * y * z - s * x,
                    t * x * z - s * y, t * y * z + s * x, t * z * z + c
                    );
            }

            #define BLADE_SEGMENTS 3
            [maxvertexcount(BLADE_SEGMENTS * 2 + 1)]
            void geo (triangle v2f IN[3], inout TriangleStream<geomData> triStream)
            {
                float4 pos = IN[0].vertex;
                
                // Randomize shape
                float height = (rand(pos.zyx) * 2 - 1) * _BladeHeightVary + _BladeHeight;
                float width = (rand(pos.xzy) * 2 - 1) * _BladeWidthVary + _BladeWidth;

                // Calculate TBN
                float3 normal = IN[0].normal;
                float4 tangent = IN[0].tangent;
                float3 binormal = cross(normal, tangent) * tangent.w;

                // Construct TBN matrix
                float3x3 tangentToObject = float3x3(
                    tangent.x, binormal.x, normal.x,
                    tangent.y, binormal.y, normal.y,
                    tangent.z, binormal.z, normal.z
                );

                // Calculate wind effects
                float2 windUV = pos.xz * _WindMap_ST.xy + _WindMap_ST.zw + _WindFrequency * _Time.y;
                float2 windEffect = (tex2Dlod(_WindMap, float4(windUV, 0, 0)).xy * 2 - 1) * _WindStrength;
                float3x3 windRotation = AngleAxis3x3(UNITY_PI * windEffect, normalize(float3(windEffect, 0)));

                // Calculate transformation matrix
                float3x3 transformationMatrix = mul(mul(tangentToObject, AngleAxis3x3(rand(pos.xyz) * UNITY_TWO_PI, float3(0, 0, 1))), windRotation);

                // Calculate grass blade forward offset
                float forward = rand(pos.xyz) * _BladeForward;
                
                // Arrange grass mesh points
                geomData o;
                for (int i = 0; i < BLADE_SEGMENTS; i++)
                {
                    float t = i / (float)BLADE_SEGMENTS;
                    float segmentHeight = height * t;
                    float segmentForward = pow(t, _BladeCurvature) * forward;
	                float segmentWidth = width * (1 - t);
                    
                    o.pos = UnityObjectToClipPos(pos + mul(transformationMatrix, float3(-segmentWidth, segmentForward, segmentHeight)));
                    o.uv = float2(0, t);
                    triStream.Append(o);
                
                    o.pos = UnityObjectToClipPos(pos + mul(transformationMatrix, float3(segmentWidth, segmentForward, segmentHeight)));
                    o.uv = float2(1, t);
                    triStream.Append(o);
                }

                o.pos = UnityObjectToClipPos(pos + mul(transformationMatrix, float3(0, forward, height)));
                o.uv = float2(0.5, 1);
                triStream.Append(o);

                // Restart strip
                triStream.RestartStrip();
            }

            // ---------------------------------------------------------------------------------------------------------------------- Fragment Phase ----
            fixed4 grassFrag (geomData i) : SV_Target
            {
                return lerp(_BottomColor, _TopColor, i.uv.y);
                //return float4(1, 1, 1, 1);
            }
            ENDCG
        }

        Pass
        {
            Tags
            {
                "LightMode" = "ShadowCaster"
            }

            Cull back

            CGPROGRAM
            #pragma vertex beforeTessVert

            #pragma hull hullProgram
            #pragma domain domainProgram

            #pragma geometry geo

            #pragma fragment shadowFrag

            #pragma target 5.0
            #pragma multi_compile_shadowcaster

            float4 shadowFrag (geomData i) : SV_Target
            {
                SHADOW_CASTER_FRAGMENT(i);
            }
            ENDCG
        }
    }
}
