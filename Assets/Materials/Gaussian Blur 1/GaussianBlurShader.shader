Shader "Unlit/GaussianBlurShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Radius ("Blur Radius", Range(1, 8)) = 1
    }
    SubShader
    {
        Tags { "Queue"="Transparent" }

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

	        // ----------------------------------------------------------------------------------------------------------------------------------- Struct
            struct a2v
            {
                float4 vertexOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertexCS : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

	        // ---------------------------------------------------------------------------------------------------------------------- Redifine Properties
            sampler2D _MainTex;
            float4 _MainTex_ST;

	        SAMPLER(_CameraOpaqueTexture);

            float _Radius;

	        // ---------------------------------------------------------------------------------------------------------------------------------- Kernels
            v2f vert (a2v v)
            {
                v2f o;
                o.vertexCS = mul(UNITY_MATRIX_MVP, v.vertexOS);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            float GaussianFunc (float x, float y)
            {
                return 1 / 6.2831852 * exp((x * x + y * y) / 2);
            }

            float4 frag (v2f i) : SV_Target
            {
                float2 screenUV = i.vertexCS.xy / _ScreenParams.xy;
                float weight00 = GaussianFunc(0, 0);
                float weight10 = GaussianFunc(1, 0);
                float weight11 = GaussianFunc(1, 1);
                float s = weight00 + 4 * weight10 + 4 * weight11;
                weight00 /= s;
                weight10 /= s;
                weight11 /= s;
                // sample the texture
                float4 col = float4(0, 0, 0, 0);
                col += tex2D(_CameraOpaqueTexture, screenUV - float2(0, _Radius / 1000)) * weight10;
                col += tex2D(_CameraOpaqueTexture, screenUV - float2(_Radius / 1000, _Radius / 1000)) * weight11;
                col += tex2D(_CameraOpaqueTexture, screenUV - float2(_Radius / 1000, -_Radius / 1000)) * weight11;
                col += tex2D(_CameraOpaqueTexture, screenUV - float2(_Radius / 1000, 0)) * weight10;
                col += tex2D(_CameraOpaqueTexture, screenUV) * weight00;
                col += tex2D(_CameraOpaqueTexture, screenUV + float2(_Radius / 1000, 0)) * weight10;
                col += tex2D(_CameraOpaqueTexture, screenUV + float2(_Radius / 1000, -_Radius / 1000)) * weight11;
                col += tex2D(_CameraOpaqueTexture, screenUV + float2(_Radius / 1000, _Radius / 1000)) * weight11;
                col += tex2D(_CameraOpaqueTexture, screenUV + float2(0, _Radius / 1000)) * weight10;
                return float4(col.rgb, 1);
                return weight00 + weight10;
            }
            ENDHLSL
        }
    }
}
