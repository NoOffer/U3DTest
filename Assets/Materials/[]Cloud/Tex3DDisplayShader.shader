Shader "Nofer/Tex3DDisplayShader"
{
    Properties
    {
        _MainTex ("Texture", 3D) = "" {}
        _Z("Z", Range(0, 1)) = 0
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
            sampler3D _MainTex;
            float4 _MainTex_ST;
            float _Z;

	        // ---------------------------------------------------------------------------------------------------------------------------------- Kernels
            v2f vert (a2v v)
            {
                v2f o;
                o.vertexCS = UnityObjectToClipPos(v.vertexOS);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex3D(_MainTex, float3(i.uv, _Z));
                return col;
            }
            ENDCG
        }
    }
}
