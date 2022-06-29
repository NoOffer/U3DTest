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

        _OutlineScaler ("Outline Scaler",  Range(0.0, 1.0)) = 0.5
        _OutlineColor ("Outline Color", Color) = (0, 0, 0, 1)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        // Cel shader
        Pass
        {
            Cull Back

            Tags{"LightMode" = "UniversalForward"}

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
            //#include "AutoLight.cginc"

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

            v2f vert (a2v v)
            {
                v2f o;
                o.vertexCS = mul(UNITY_MATRIX_MVP, v.vertexOS);
                o.vertexWS = mul(UNITY_MATRIX_M, v.vertexOS);
                o.normalWS = mul((float3x3)UNITY_MATRIX_M, v.normalOS);
                //Light l = GetMainLight();
                //o.vertexCS = mul(UNITY_MATRIX_VP, ApplyShadowBias(o.vertexWS.xyz, o.normalWS.xyz, l.direction));

                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                //#if SHADOWS_SCREEN
                //    float4 shadowCoord = ComputeScreenPos(i.vertexCS);
                //#else
                //    float4 shadowCoord = TransformWorldToShadowCoord(i.vertexWS);
                //#endif

                // Get light
                Light l = GetMainLight(TransformWorldToShadowCoord(i.vertexWS));

                // Calculate shadow
                float shadow = step(0.5, saturate(l.shadowAttenuation));

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

                // Calculate outline
                //float outline = 1 - step(_OutlineThreshold, dot(normalize(i.normalWS), viewDirWS));

                //return float4(specular, specular, specular, 1);
                //return lerp(outColor, _OutlineColor, outline);
                return outColor;
            }
            ENDHLSL
        }

        // outline
        Pass
        {
            Cull Front

            Tags{"LightMode" = "SRPDefaultUnlit"}

            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            struct a2v 
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            }; 

            struct v2f 
            {
                float4 pos : SV_POSITION;
            };

            float _OutlineScaler;
            float4 _OutlineColor;

            v2f vert (a2v v) 
            {
                v2f o;

                float4 pos = mul(UNITY_MATRIX_MV, v.vertex); 
                float3 normal = mul((float3x3)UNITY_MATRIX_M, v.normal);  
                normal.z = -0.5;
                pos += float4(normalize(normal), 0) * _OutlineScaler;
                o.pos = mul(UNITY_MATRIX_P, pos);

                return o;
            }

            float4 frag(v2f i) : SV_Target 
            { 
                return float4(_OutlineColor.rgb, 1);               
            }
            ENDCG
        }
    }
}
