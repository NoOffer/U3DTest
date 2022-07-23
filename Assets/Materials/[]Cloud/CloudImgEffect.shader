Shader "Nofer/CloudImgEffect"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "White" {}
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

            struct a2v
            {
                float4 vertexOS : POSITION;
                float2 uv : TEXCOORD0;
            };

	  // ----------------------------------------------------------------------------------------------------------------------------------- Struct
            struct v2f
            {
                float4 vertexCS : SV_POSITION;
                float4 vertexWS : TEXCOORD0;
                float2 uv : TEXCOORD1;
            };

	  // ---------------------------------------------------------------------------------------------------------------------- Redifine Properties
            sampler2D _MainTex;

	  // ---------------------------------------------------------------------------------------------------------------------------------- Kernels
            v2f vert (a2v v)
            {
                v2f o;
                o.vertexCS = UnityObjectToClipPos(v.vertexOS);
                o.vertexWS = mul(UNITY_MATRIX_M, v.vertexOS);
                o.uv = v.uv;
                return o;
            }

            float2 RayBoxDist (float3 boxMin, float3 boxMax, float3 rayOrigin, float3 rayDir)
            {
                float3 t0 = (boxMin - rayOrigin) / rayDir;
                float3 t1 = (boxMax - rayOrigin) / rayDir;
                float3 tmin = min(t0, t1);
                float3 tmax = max(t0, t1);
                float distToBox = max(0, max(max(tmin.x, tmin.y), tmin.z));
                float distInsideBox = max(0, min(min(tmax.x, tmax.y), tmax.z) - distToBox);

                return float2(distToBox, distInsideBox);
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 boundMin = float3(-1, -1, -1);
                float3 boundMax = float3(1, 1, 1);

                float2 boxDistInfo = RayBoxDist(boundMin, boundMax, _WorldSpaceCameraPos.xyz, -normalize(_WorldSpaceCameraPos.xyz - i.vertexWS.xyz));

                fixed4 col = tex2D(_MainTex, i.uv);
                if (boxDistInfo.y > 0){
                    col = 0;
                }
                return float4(i.vertexWS.xyz, 1);
            }
            ENDCG
        }
    }
}
