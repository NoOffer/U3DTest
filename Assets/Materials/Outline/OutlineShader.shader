Shader "Nofer/OutlineImageEffect"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _NormalDiffMultiplier ("Normal Multiplier", float) = 1
        _DepthDiffMultiplier ("Depth Multiplier", float) = 100
        _OutlineColor ("Outline Color", Color) = (0, 0, 0, 1)
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

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float4 screenPos : TEXCOORD1;
            };

            sampler2D _MainTex;
            sampler2D _CameraNormalsTexture;
            float _NormalDiffMultiplier;
            float _DepthDiffMultiplier;
            float4 _OutlineColor;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = mul(UNITY_MATRIX_MVP, v.vertex);
                o.uv = v.uv;
                o.screenPos = ComputeScreenPos(o.vertex);
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                float4 bgCol = tex2D(_MainTex, i.uv);

                float2 normalDiffX =
                    tex2D(_CameraNormalsTexture, i.uv - float2(1, 1) / _ScreenParams.xy).xy -
                    tex2D(_CameraNormalsTexture, i.uv + float2(1, 1) / _ScreenParams.xy).xy;
                float2 normalDiffY =
                    tex2D(_CameraNormalsTexture, i.uv - float2(1, -1) / _ScreenParams.xy).xy -
                    tex2D(_CameraNormalsTexture, i.uv + float2(1, -1) / _ScreenParams.xy).xy;
                float depthDiffX =
                    Linear01Depth(SampleSceneDepth(i.uv - float2(1, 1) / _ScreenParams.xy), _ZBufferParams) - 
                    Linear01Depth(SampleSceneDepth(i.uv + float2(1, 1) / _ScreenParams.xy), _ZBufferParams);
                float depthDiffY =
                    Linear01Depth(SampleSceneDepth(i.uv - float2(1, 1) / _ScreenParams.xy), _ZBufferParams) - 
                    Linear01Depth(SampleSceneDepth(i.uv + float2(1, 1) / _ScreenParams.xy), _ZBufferParams);

                float outline = saturate(
                    length(normalDiffX) * length(normalDiffY) * _NormalDiffMultiplier +
                    abs(depthDiffX) * abs(depthDiffY) * _DepthDiffMultiplier
                    );

                return lerp(bgCol, _OutlineColor, outline);
            }
            ENDHLSL
        }
    }
}