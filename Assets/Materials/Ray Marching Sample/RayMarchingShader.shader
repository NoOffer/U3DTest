Shader "Hidden/RayMarchingShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        // No culling or depth
        Cull Off ZWrite Off ZTest Always

        Pass
        {
            CGPROGRAM

	  // ----------------------------------------------------------------------------------------------------------------------------------- Pragma
            #pragma vertex vert
            #pragma fragment frag

	  // ---------------------------------------------------------------------------------------------------------------------------------- Include
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

	  // ----------------------------------------------------------------------------------------------------------------------------------- Struct
            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

	  // ---------------------------------------------------------------------------------------------------------------------- Redifine Properties
            sampler2D _MainTex;

	  // ---------------------------------------------------------------------------------------------------------------------------------- Kernels
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);
                // just invert the colors
                col.rgb = 1 - col.rgb;
                return col;
            }
            ENDCG
        }
    }
}
