Shader "Nofer/DepthFogShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _FogColor ("Fog Color", Color) = (1, 1, 1, 1)
        _FogDensity ("Fog Density", Range(1, 100)) = 1
        _MaxFog ("Max Fog Transparency", Range(0.1, 1)) = 1
    }
    SubShader
    {
        // No culling or depth
        Cull Off ZWrite Off ZTest Always

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareOpaqueTexture.hlsl"

            struct a2v
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float4 screenPos : TEXCOORD0;
                float2 uv : TEXCOORD1;
            };

            v2f vert (a2v v)
            {
                v2f o;
                o.vertex = mul(UNITY_MATRIX_MVP, v.vertex);
                o.screenPos = ComputeScreenPos(o.vertex);
                o.uv = v.uv;
                return o;
            }

            sampler2D _MainTex;
            float4 _FogColor;
            float _FogDensity;
            float _MaxFog;

            float4 frag (v2f i) : SV_Target
            {
                float4 col = tex2D(_MainTex, i.uv);
                //float depth = _CameraDepthTexture.Sample (sampler_CameraDepthTexture, i.screenPos.xy / i.screenPos.w).x;
                float depth = LinearEyeDepth(SampleSceneDepth(i.screenPos.xyz / i.screenPos.w), _ZBufferParams) - i.screenPos.w;
                //float depth = Linear01Depth(SampleSceneDepth(i.screenPos.xyz / i.screenPos.w), _ZBufferParams);
                //return clamp(1 - pow(2, -depth * _FogDensity / 1000), 0, _MaxFog);
                return lerp(col, _FogColor, clamp(1 - pow(2, -depth * _FogDensity / 1000), 0, _MaxFog));
            }
            ENDHLSL
        }
    }
}
