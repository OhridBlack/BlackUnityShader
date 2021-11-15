Shader "BlackShader/Shader_NormalMapWorldSpace"
{
    Properties
    {
        _MainTex("Texture", 2D) = "white" {}
        _NormalTex("Normal Texture",2D) = ""{}
        _Gloss("Gloss",float) = 32.0
        _Color("Color",Color) = (1.0,1.0,1.0,1.0)
        _NormalScale("Normal Scale",Range(-10.0,10.0)) = 1.0
    }
        SubShader
        {
            Tags { "RenderType" = "Opaque" }

            Pass
            {
                CGPROGRAM
                #pragma vertex vert
                #pragma fragment frag

                #include "UnityCG.cginc"
                #include "Lighting.cginc"

                struct appdata
                {
                    float4 vertex : POSITION;
                    float2 uv : TEXCOORD0;
                    float3 normal : NORMAL;
                    float4 tangent : TANGENT;
                };

                struct v2f
                {
                    float4 uv : TEXCOORD0;
                    float4 vertex : SV_POSITION;
                    float4 TtoW0: TEXCOORD1;
                    float4 TtoW1: TEXCOORD2;
                    float4 TtoW2: TEXCOORD3;
                };

                sampler2D _MainTex;
                float4 _MainTex_ST;
                sampler2D _NormalTex;
                float4 _NormalTex_ST;
                fixed4 _Color;
                float _Gloss;
                float _NormalScale;

                v2f vert(appdata v)
                {
                    v2f o;
                    o.vertex = UnityObjectToClipPos(v.vertex);
                    o.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
                    o.uv.zw = TRANSFORM_TEX(v.uv, _NormalTex);

                    float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                    fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
                    fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
                    fixed3 worldBinormal = cross(worldNormal, worldTangent) * v.tangent.w;

                    //make float4 w to have worldPos,x worldTangent,y worldBinormal,z worldNormal
                    o.TtoW0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
                    o.TtoW1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
                    o.TtoW2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);
                    return o;
                }

                fixed4 frag(v2f i) : SV_Target
                {
                    float3 worldPos = float3(i.TtoW0.w,i.TtoW1.w,i.TtoW2.w);

                    fixed3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));
                    fixed3 viewDir = normalize(UnityWorldSpaceViewDir(worldPos));

                    fixed3 tangentNormal = UnpackNormal(tex2D(_NormalTex, i.uv.zw));
                    tangentNormal.xy *= _NormalScale;
                    tangentNormal.z = sqrt(1.0 - saturate(dot(tangentNormal.xy, tangentNormal.xy)));

                    fixed3 normalDir = normalize(half3(dot(i.TtoW0.xyz, tangentNormal), dot(i.TtoW1.xyz, tangentNormal), dot(i.TtoW2.xyz, tangentNormal)));

                    fixed3 albedo = tex2D(_MainTex, i.uv.xy).rgb * _Color.rgb;
                    fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;

                    fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(normalDir, lightDir));

                    fixed3 halfDir = normalize(lightDir + viewDir);
                    fixed3 specular = _LightColor0.rgb * pow(max(0, dot(normalDir, halfDir)), _Gloss);

                    return fixed4(ambient + diffuse + specular, 1.0);
                }
                ENDCG
            }
        }
}
