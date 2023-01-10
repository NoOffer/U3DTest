Shader "Nofer/UVTestShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
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
                
            }
            
            // ----------------------------------------------------------------------------------------------------------------------------- Render State
            Cull Back

            CGPROGRAM

	        // ----------------------------------------------------------------------------------------------------------------------------------- Pragma
            #pragma vertex vert
            #pragma fragment frag

	        // ---------------------------------------------------------------------------------------------------------------------------------- Include
            #include "UnityCG.cginc"

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

	        // ---------------------------------------------------------------------------------------------------------------------------------- Kernels
            v2f vert (a2v v)
            {
                v2f o;
                o.vertexCS = UnityObjectToClipPos(v.vertexOS);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                return float4(i.uv, 0, 1);
            }
            ENDCG
        }
    }
}
