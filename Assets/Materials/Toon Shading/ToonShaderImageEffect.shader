Shader "Hidden/ToonShaderImageEffect"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _ToonIntensity ("Toon Intensity", Range(1.0, 256.0)) = 200.0
        _SaturationScaler ("Saturation Scaler", Range(0.0, 1.0)) = 1.0
        _BrightnessScaler ("Brightness Scaler", Range(0.0, 0.5)) = 0.0
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

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            sampler2D _MainTex;
            float _ToonIntensity;
            float _SaturationScaler;
            float _BrightnessScaler;

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);
                col = round(col * _ToonIntensity) / _ToonIntensity;
                float3 brightness = dot(col.rgb, float3(1, 1, 1)) / 3 * float3(1, 1, 1);
                col = float4((col.rgb - brightness) * _SaturationScaler + brightness, 1);
                col = float4(col.rgb * (1 - _BrightnessScaler) + float3(_BrightnessScaler, _BrightnessScaler, _BrightnessScaler), 1);
                return col;
            }
            ENDCG
        }
    }
}
