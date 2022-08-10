Shader "Nofer/RefractionShader"
{
    Properties
    {
        _ScreenRT ("Screen Render Texture", 2D) = "" {}

        _IOR ("IOR", float) = 1
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
                "Queue" = "Transparent"
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
            sampler2D _ScreenRT;
            float4 _ScreenRT_ST;

            float _IOR;
            
	        SAMPLER(_CameraOpaqueTexture);

	        // ---------------------------------------------------------------------------------------------------------------------------------- Kernels
            v2f vert (a2v v)
            {
                v2f o;
                o.vertexCS = mul(UNITY_MATRIX_MVP, v.vertexOS);
                o.uv = TRANSFORM_TEX(v.uv, _ScreenRT);
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                //float4 col = tex2D(_MainTex, i.uv);

                //return float4(i.vertexCS.xy / _ScreenParams.xy, 0, 1);
                return tex2D(_ScreenRT, i.vertexCS.xy / _ScreenParams.xy);
            }
            ENDHLSL
        }
    }
}
