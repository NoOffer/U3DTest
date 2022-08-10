Shader "Nofer/CloudShader"
{
    Properties
    {
        _NoiseTex ("Texture", 3D) = "" {}

        _CloudStartH ("Cloud Center Height", float) = 50
        _CloudHeight ("Cloud Height", float) = 10
        _CloudCutOff ("Cloud Cut Off", Range(0, 1)) = 0.2
        _CloudSoftness ("Cloud Softness", Range(1, 5)) = 1
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
                "Queue"="Transparent"
                "RenderType"="TransparentCutout"
            }
            
            // ----------------------------------------------------------------------------------------------------------------------------- Render State
            Cull Off
            Blend SrcAlpha OneMinusSrcAlpha

            CGPROGRAM

	        // ----------------------------------------------------------------------------------------------------------------------------------- Pragma
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_instancing

	        // ---------------------------------------------------------------------------------------------------------------------------------- Include
            #include "UnityCG.cginc"

	        // ----------------------------------------------------------------------------------------------------------------------------------- Struct
            struct a2v
            {
                UNITY_VERTEX_INPUT_INSTANCE_ID
                float4 vertexOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                UNITY_VERTEX_INPUT_INSTANCE_ID
                float4 vertexCS : SV_POSITION;
                float4 vertexWS : TEXCOORD0;
                float2 uv : TEXCOORD1;
            };

	        // ---------------------------------------------------------------------------------------------------------------------- Redifine Properties
            sampler3D _NoiseTex;
            float4 _NoiseTex_ST;

            float _CloudStartH;
            float _CloudHeight;
            float _CloudCutOff;
            float _CloudSoftness;

	        // ---------------------------------------------------------------------------------------------------------------------------------- Kernels
            v2f vert (a2v v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v,o);
                o.vertexCS = UnityObjectToClipPos(v.vertexOS);
                o.vertexWS = mul(UNITY_MATRIX_M, v.vertexOS);
                o.uv = TRANSFORM_TEX(v.uv, _NoiseTex);
                return o;
            }

            float cutoff (float originalVal, float cutoffVal)
            {
                return max(originalVal - cutoffVal, 0) / (1 - cutoffVal);
            }

            fixed4 frag (v2f i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);
                // sample the texture
                //saturate((i.vertexWS.y - _CloudStartH) / _CloudHeight + 0.5)
                float col = tex3D(_NoiseTex, float3(i.uv, 0.5)).a;
                col = cutoff(col, _CloudCutOff);
                col = pow(col, _CloudSoftness);
                return float4(1, 1, 1, col);
            }
            ENDCG
        }
    }
}
