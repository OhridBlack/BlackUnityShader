Shader "BlackShader/Shader_OutlineNormal"
{
    Properties
    {
        _Color("Color", Color) = (1.0,1.0,1.0,1.0)
        _Gloss("Gloss",float) = 32.0
        _OutlineColor("Outline Color",Color) = (0.0,0.0,0.0,1.0)
        _ThresholdAngle("Threshold Angle",Range(0,1))=0.5
    }
        SubShader
    {
        Tags { "RenderType" = "Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Lighting.cginc"
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float4 normal : NORMAL;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 pos    : TEXCOORD0;
                float3 normal : TEXCOORD1;
            };

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.pos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.normal = normalize(mul(v.normal, (float3x3)unity_WorldToObject));
                return o;
            }
            fixed4 _Color;
            fixed _Gloss;
            fixed4 _OutlineColor;
            float _ThresholdAngle;

            fixed4 frag(v2f i) : SV_Target
            {
                fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.pos);
                if (dot(viewDir, i.normal) < _ThresholdAngle) {
                    return _OutlineColor;
                }
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
                fixed3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
                fixed3 diffuse = _Color.rgb * _LightColor0.rgb * saturate(dot(i.normal, lightDir));

                //blinn phong
                
                fixed3 halfDir = normalize(lightDir + viewDir);
                fixed3 specular = pow(saturate(dot(halfDir, i.normal)), _Gloss);

                return fixed4(diffuse + ambient + specular, 1.0);
            }
            ENDCG
        }
    }
}
