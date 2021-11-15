Shader "BlackShader/Shader_FresnelReflection"
{
    Properties
    {
        _Color("Color",Color) = (1,1,1,1)
        _FresnelScale("Fresnel Scale",Range(0,1))=0.5
        _Cubemap("Cubemap",Cube) = ""{}
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

            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"
            fixed4 _Color;
            float _FresnelScale;
            samplerCUBE _Cubemap;

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal:NORMAL;
            };

            struct v2f
            {
                float3 pos : TEXCOORD0;
                float3 normal:TEXCOORD1;
                float3 viewDir:TEXCOORD2;
                float3 reflDir:TEXCOORD3;
                float4 vertex : SV_POSITION;
            };


            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.pos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.viewDir = UnityWorldSpaceViewDir(o.pos);
                o.reflDir = reflect(-o.viewDir, o.normal);
                TRANSFER_SHADOW(o);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                fixed3 normal = normalize(i.normal);
                fixed3 lightDir = normalize(UnityWorldSpaceLightDir(i.pos));
                fixed3 viewDir = normalize(i.viewDir);

                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
                fixed3 diffuse = _LightColor0.rgb * _Color.rgb * max(0, dot(normal, lightDir));

                fixed3 reflection = texCUBE(_Cubemap, i.reflDir).rgb;

                fixed fresnel = _FresnelScale + (1 - _FresnelScale) * pow(1 - dot(viewDir, normal), 5);
                UNITY_LIGHT_ATTENUATION(atten, i, i.pos);
                fixed3 color = ambient + lerp(diffuse, reflection, saturate(fresnel)) * atten;

                return fixed4(color,1.0);
            }
            ENDCG
        }
    }
}
