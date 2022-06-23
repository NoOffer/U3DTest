Shader "CustomShaders/ToonShader"
{
    Properties
    {
        _SurfaceColor ("Surface Color", Color) = (1, 1, 1, 1)
        _Smoothness ("Smoothness Coefficient", Range(0.0, 1.0)) = 1.0
        _RimCoe ("Rim Coefficient", Range(0.0, 1.0)) = 1.0

        _DiffuseThreshold ("Diffuse Threshold",  Range(0.0, 1.0)) = 0.5
        _SpecularThreshold ("Specular Threshold",  Range(0.0, 1.0)) = 0.5
        _RimThreshold ("Rim Threshold",  Range(0.0, 1.0)) = 0.5
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"

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
                SHADOW_COORDS(2)
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
                o.vertexCS = UnityObjectToClipPos(v.vertexOS);
                o.vertexWS = mul(unity_ObjectToWorld, v.vertexOS);
                o.normalWS = UnityObjectToWorldNormal(v.normalOS);

                TRANSFER_SHADOW(o);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // Calculate shadow
                float shadow = SHADOW_ATTENUATION(i);

                // Get light direction
                float3 lightDirWS = normalize(UnityWorldSpaceLightDir(i.vertexWS));
                //float3 lightDirWS = normalize(_WorldSpaceLightPos0.xyz);
                // Calculate diffuse
                float diffuse = saturate(dot(i.normalWS, lightDirWS));
                diffuse *= shadow;
                diffuse = step(_DiffuseThreshold, diffuse);

                // Get view direction
                float3 viewDirWS = normalize(UnityWorldSpaceViewDir(i.vertexWS));
                //float3 viewDirWS = normalize(_WorldSpaceCameraPos.xyz - i.vertexWS.xyz);
                float3 h = normalize(lightDirWS + viewDirWS);
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

                return float4(_LightColor0.rgb * (diffuse + max(specular, rim)) + ambient, 1);
                //return float4(ambient, 1);
            }
            ENDCG
        }
    }
}
