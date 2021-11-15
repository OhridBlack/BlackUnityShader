﻿Shader "BlackShader/Shader_WaterSimulatingNormalMap"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _WaveMap("Wave Map",2D)=""{}
        _WaveXSpeed("Wave X Speed",Range(0.0,1.0))=0.5
        _WaveYSpeed("Wave Y Speed",Range(0.0,1.0))=0.5
        _Cubemap("CubeMap",Cube)=""{}
        _Color("Color",Color)=(1,1,1,1)

    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        GrabPass{
            "_RefractionTex"
        }
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
                    float4 scrPos:TEXCOORD4;

                };

                sampler2D _MainTex;
                float4 _MainTex_ST;
                sampler2D _WaveMap;
                float4 _WaveMap_ST;
                float _WaveXSpeed;
                float _WaveYSpeed;
                sampler2D _RefractionTex;
                half4 _RefractionTex_TexelSize;
                samplerCUBE _Cubemap;
                fixed4 _Color;

                v2f vert(appdata v)
                {
                    v2f o;
                    o.vertex = UnityObjectToClipPos(v.vertex);
                    o.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
                    o.uv.zw = TRANSFORM_TEX(v.uv, _WaveMap);

                    float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                    fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
                    fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
                    fixed3 worldBinormal = cross(worldNormal, worldTangent) * v.tangent.w;

                    //make float4 w to have worldPos,x worldTangent,y worldBinormal,z worldNormal
                    o.TtoW0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
                    o.TtoW1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
                    o.TtoW2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);
                    
                    o.scrPos = ComputeGrabScreenPos(o.vertex);
                    return o;
                }

                fixed4 frag(v2f i) : SV_Target
                {
                    float3 worldPos = float3(i.TtoW0.w,i.TtoW1.w,i.TtoW2.w);

                    fixed3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));
                    fixed3 viewDir = normalize(UnityWorldSpaceViewDir(worldPos));
                    float2 speed = _Time.y * float2(_WaveXSpeed, _WaveYSpeed);

                    fixed3 bump1 = UnpackNormal(tex2D(_WaveMap, i.uv.zw + speed)).rgb;
                    fixed3 bump2 = UnpackNormal(tex2D(_WaveMap, i.uv.zw - speed)).rgb;
                    fixed3 bump = normalize(bump1 + bump2);

                    float2 offset = bump.xy * _RefractionTex_TexelSize.xy;
                    i.scrPos.xy += offset * i.scrPos.z;
                    fixed3 refrCol = tex2D(_RefractionTex, i.scrPos.xy / i.scrPos.w).rgb;

                    bump = normalize(half3(dot(i.TtoW0.xyz, bump), dot(i.TtoW1.xyz, bump), dot(i.TtoW2.xyz, bump)));
                    fixed4 texColor = tex2D(_MainTex, i.uv.xy + speed);
                    fixed3 reflDir = reflect(-viewDir, bump);
                    fixed3 reflCol = texCUBE(_Cubemap, reflDir).rgb * texColor * _Color.rgb;

                    fixed fresnel = pow(1 - saturate(dot(viewDir, bump)), 4);
                    fixed3 finalColor = reflCol * fresnel + refrCol * (1 - fresnel);
                    return fixed4(finalColor, 1.0);
                }
                ENDCG
            }
    }
}
