Shader "Test/ToonShading"
{
    Properties
    {

    }
    SubShader
    {
        Tags 
        {
            "RenderType"="Opaque"
            "LightMode" = "UniversalForward" 
            "PassFlags" = "OnlyDirectional"
        } 

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
           	#pragma multi_compile_fwdbase
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS


            //#include "UnityCG.cginc"

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct a2v
            {
                float4 vertexOS : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 vertexCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float4 shadowCoord : TEXCOORD1;
            };


            v2f vert (a2v v)
            {
                v2f o;
                o.vertexCS = TransformObjectToHClip(v.vertexOS.xyz);
                o.uv = v.uv;
                float3 worldPos = GetVertexPositionInputs(v.vertexOS.xyz).positionWS; // world space position of this vertex
                o.shadowCoord = TransformWorldToShadowCoord(worldPos);
                return o;
            }


            float4 frag (v2f i) : SV_Target
            {
                /* Get lighting information */
                Light mainLight = GetMainLight(i.shadowCoord); // get main lighting info (including shadows)
                float shadow = mainLight.shadowAttenuation;

                return float4(shadow, shadow, shadow, 1);
            }
            ENDHLSL
        }

        UsePass "Legacy Shaders/VertexLit/SHADOWCASTER"

    }
}