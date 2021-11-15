Shader "BlackShader/Shader_ShaderReceiver"
{
    Properties
    {
        _Color("Color", Color) = (1.0,1.0,1.0,1.0)
        _Gloss("Gloss",float) = 32.0
    }
        SubShader
    {
        Tags { "RenderType" = "Opaque" }
        LOD 100

        Pass
        {
            Tags{"LightMode" = "ForwardBase"}
            CGPROGRAM
            #pragma multi_compile_fwdbase
            #pragma vertex vert
            #pragma fragment frag

            #include "Lighting.cginc"
            #include "UnityCG.cginc"
            #include "AutoLight.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float4 normal : NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 worldPos    : TEXCOORD0;
                float3 normal : TEXCOORD1;
                SHADOW_COORDS(2)
            };

            v2f vert(appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.normal = normalize(mul(v.normal, (float3x3)unity_WorldToObject));
                TRANSFER_SHADOW(o);
                return o;
            }
            fixed4 _Color;
            fixed _Gloss;

            fixed4 frag(v2f i) : SV_Target
            {
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
                fixed3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
                fixed3 diffuse = _Color.rgb * _LightColor0.rgb * saturate(dot(i.normal, lightDir));

                //blinn phong
                fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos);
                fixed3 halfDir = normalize(lightDir + viewDir);
                fixed3 specular = pow(saturate(dot(halfDir, i.normal)), _Gloss);

                fixed shadow = SHADOW_ATTENUATION(i);
                return fixed4(ambient + (diffuse + specular) * shadow, 1.0);
            }
            ENDCG
        }

        Pass{
                Tags {"LightMode" = "ForwardAdd"}
                Blend One One
                CGPROGRAM
                #pragma multi_compile_fwdadd
                #pragma vertex vert
                #pragma fragment frag

            #include "Lighting.cginc"
            #include "UnityCG.cginc"
            #include "AutoLight.cginc"

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

            fixed4 frag(v2f i) : SV_Target
            {
#ifdef USING_DIRECTIONAL_LIGHT
                //directional light worldspacelightpos0.xyz = world light dir
                fixed3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
#else
                //spot /point light worldspacelightpos0.xyz = world light pos
                fixed3 lightDir = normalize(_WorldSpaceLightPos0.xyz - i.pos.xyz);
#endif
                fixed3 diffuse = _Color.rgb * _LightColor0.rgb * saturate(dot(i.normal, lightDir));

                //blinn phong
                fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.pos);
                fixed3 halfDir = normalize(lightDir + viewDir);
                fixed3 specular = pow(saturate(dot(halfDir, i.normal)), _Gloss);
#ifdef USING_DIRECTIONAL_LIGHT
                fixed atten = 1.0;
#else
                //use _LightTexture0 map to calculate the attenuation instead of 
                float3 lightCoord = mul(unity_WorldToLight, float4(i.pos, 1.0)).xyz;
                fixed atten = tex2D(_LightTexture0, dot(lightCoord, lightCoord).rr).UNITY_ATTEN_CHANNEL;
#endif
                return fixed4((diffuse + specular) * atten, 1.0);
            }

                ENDCG
        }
    }
}
