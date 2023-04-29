Shader "CustomShaders/CelShader"
{
    Properties
    {
        _SurfaceColor ("Surface Color", Color) = (1, 1, 1, 1)
        _Smoothness ("Smoothness Coefficient", Range(0.0, 1.0)) = 1.0
        _RimCoe ("Rim Coefficient", Range(0.0, 1.0)) = 1.0

        _DiffuseThreshold ("Diffuse Threshold",  Range(0.0, 1.0)) = 0.5
        _SpecularThreshold ("Specular Threshold",  Range(0.0, 1.0)) = 0.5
        _RimThreshold ("Rim Threshold",  Range(0.0, 1.0)) = 0.5
        _ShadowThreshold ("Shadow Threshold",  Range(0.0, 1.0)) = 0.5

        _ShadowBias("Shadow Bias",  Range(0.0, 1.0)) = 0.5
    }

    HLSLINCLUDE
    ENDHLSL

    SubShader
    {
        Tags { "RenderType"="Opaque" }

        // Cel shader
        Pass
        {
            Cull Back ZWrite On

            Tags
            {
                "LightMode" = "UniversalForward"
            }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
    
            struct a2v
            {
                float4 vertexOS : POSITION;
                float3 normalOS : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertexCS : SV_POSITION;
                float4 vertexWS : TEXCOORD0;
                float3 normalWS : TEXCOORD1;
                //SHADOW_COORDS(2)
            };

            float4 _SurfaceColor;
            float _Smoothness;
            float _RimCoe;

            float _DiffuseThreshold;
            float _SpecularThreshold;
            float _RimThreshold;
            float _ShadowThreshold;

            v2f vert (a2v v)
            {
                v2f o;
                o.vertexCS = mul(UNITY_MATRIX_MVP, v.vertexOS);
                o.vertexWS = mul(UNITY_MATRIX_M, v.vertexOS);
                o.normalWS = mul((float3x3)UNITY_MATRIX_M, v.normalOS);

                //#if UNITY_PASS_SHADOWCASTER
                //    o.vertexCS = UnityApplyLinearShadowBias(o.vertexCS);
                //#endif

                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                // Get light
                Light l = GetMainLight(TransformWorldToShadowCoord(i.vertexWS.xyz));

                // Calculate shadow
                float shadow = step(_ShadowThreshold, saturate(l.shadowAttenuation));

                // Calculate diffuse
                float diffuse = saturate(dot(i.normalWS, l.direction));
                diffuse *= shadow;
                diffuse = step(_DiffuseThreshold, diffuse);

                // Get view direction
                float3 viewDirWS = normalize(_WorldSpaceCameraPos.xyz - i.vertexWS.xyz);
                float3 h = normalize(l.direction + viewDirWS);
                // Calculate specular
                float specular = pow(saturate(dot(i.normalWS, h)), exp2(10 * _Smoothness + 1));
                specular *= diffuse * _Smoothness;
                specular = step(_SpecularThreshold, specular);

                // Calculate rim light
                float rim = 1 - dot(viewDirWS, i.normalWS);
                rim *= pow(diffuse, _RimCoe);
                rim = step(_RimThreshold, rim);

                // Get ambient
                //float3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
                float3 ambient = float3(unity_SHAr.w, unity_SHAg.w, unity_SHAb.w);

                float4 outColor = float4(l.color.rgb * (diffuse + max(specular, rim)) + ambient, 1) * _SurfaceColor;

                return outColor;
                return float4(shadow, shadow, shadow, 1);
            }

            ENDHLSL
        }

        //// Shadow
        //UsePass "VertexLit/SHADOWCASTER"

        Pass
        {
            Name "ShadowCaster"
            Tags{ "LightMode" = "ShadowCaster" }

            CGPROGRAM

            #pragma vertex vert_shadow
            #pragma fragment frag_shadow
            #pragma target 3.0

            float _ShadowBias;

            float4 vert_shadow(float4 vertex:POSITION, uint id : SV_VertexID, float3 normal : NORMAL) : SV_POSITION
            {
                vertex -= float4(normal * _ShadowBias, 0);
                vertex = UnityObjectToClipPos(vertex);
                return vertex;
            }

            float4 frag_shadow(void) : COLOR
            {
                return 0;
            }
            ENDCG
        }
    }
}
