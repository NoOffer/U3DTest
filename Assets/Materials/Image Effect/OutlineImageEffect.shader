Shader "Nofer/OutlineImageEffect"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _SampleOffset ("Outline Sample Offset (Outline Width)", Range(0, 0.01)) = 0.005
        _OutlineThreshold ("Threshold of Outline Sample Difference", Range(0.01, 0.9)) = 0.1
        _OutlineColor ("Outline Color", Color) = (0, 0, 0, 1)
    }
    SubShader
    {
        // No culling or depth
        Cull Off ZWrite Off ZTest Always

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float _SampleOffset;
            float _OutlineThreshold;
            float4 _OutlineColor;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 originalCol = tex2D(_MainTex, i.uv);
                fixed4 offsetCol = tex2D(_MainTex, i.uv + float2(_SampleOffset, _SampleOffset));
                float4 outCol = lerp(originalCol, _OutlineColor, step(_OutlineThreshold, length(originalCol.rgb - offsetCol.rgb)));

                offsetCol = tex2D(_MainTex, i.uv - float2(_SampleOffset, _SampleOffset));
                outCol = lerp(outCol, _OutlineColor, step(_OutlineThreshold, length(originalCol.rgb - offsetCol.rgb)));

                return outCol;
            }
            ENDCG
        }
    }
}
