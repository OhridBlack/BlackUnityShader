Shader "BlackShader/Shader_Hatching"
{
    Properties
    {
        _ColorIntensity("ColorIntensity", Range(0,1)) = 1.0

        _Tex0("Texture0",2D)=""{}
        _Tex1("Texture1",2D) = ""{}
        _Tex2("Texture2",2D) = ""{}
        _Tex3("Texture3",2D) = ""{}
        _Tex4("Texture4",2D) = ""{}
        _Tex5("Texture5",2D) = ""{}
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
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 pos    : TEXCOORD0;
                float2 uv :TEXCOORD1;
                float3 hatchWeights0 :TEXCOORD2;
                float3 hatchWeights1:TEXCOORD3;
            };

            fixed _ColorIntensity;
            sampler2D _Tex0;
            sampler2D _Tex1;
            sampler2D _Tex2;
            sampler2D _Tex3;
            sampler2D _Tex4;
            sampler2D _Tex5;

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                float4 pos = mul(unity_ObjectToWorld, v.vertex);
                fixed3 lightDir = normalize(WorldSpaceLightDir(pos));
                fixed3 normal = normalize(mul(v.normal, (float3x3)unity_WorldToObject));
                o.uv = v.uv.xy * _ColorIntensity;
                o.hatchWeights0 = fixed3(0, 0, 0);
                o.hatchWeights1 = fixed3(0, 0, 0);
                float hatchFactor = max(0, dot(lightDir, normal))*7.0;
                if (hatchFactor > 6.0) {

                }
                else if (hatchFactor > 5.0) {
                    o.hatchWeights0.x = hatchFactor - 5.0;
                }
                else if (hatchFactor > 4.0) {
                    o.hatchWeights0.x = hatchFactor - 4.0;
                    o.hatchWeights0.y = 1.0 - o.hatchWeights0.x;
                }
                else if (hatchFactor > 3.0) {
                    o.hatchWeights0.y = hatchFactor - 3.0;
                    o.hatchWeights0.z = 1.0 - o.hatchWeights0.y;
                }
                else if (hatchFactor > 2.0) {
                    o.hatchWeights0.z = hatchFactor - 2.0;
                    o.hatchWeights1.x = 1.0 - o.hatchWeights0.z;
                }
                else if (hatchFactor > 1.0) {
                    o.hatchWeights1.x = hatchFactor - 1.0;
                    o.hatchWeights1.y = 1.0 - o.hatchWeights1.x;
                }
                else {
                    o.hatchWeights1.y = hatchFactor;
                    o.hatchWeights1.z = 1.0 - o.hatchWeights1.y;
                }
                o.pos = pos.xyz;
                return o;
            }
            

            fixed4 frag(v2f i) : SV_Target
            {
                fixed4 hatchTex0 = tex2D(_Tex0, i.uv) * i.hatchWeights0.x;
                fixed4 hatchTex1 = tex2D(_Tex1, i.uv) * i.hatchWeights0.y;
                fixed4 hatchTex2 = tex2D(_Tex2, i.uv) * i.hatchWeights0.z;
                fixed4 hatchTex3 = tex2D(_Tex3, i.uv) * i.hatchWeights1.x;
                fixed4 hatchTex4 = tex2D(_Tex4, i.uv) * i.hatchWeights1.y;
                fixed4 hatchTex5 = tex2D(_Tex5, i.uv) * i.hatchWeights1.z;
                fixed4 whiteColor = fixed4(1, 1, 1, 1) * (1 - i.hatchWeights0.x - i.hatchWeights0.y - i.hatchWeights0.z -
                            i.hatchWeights1.x - i.hatchWeights1.y - i.hatchWeights1.z);

                fixed4 hatchColor = hatchTex0 + hatchTex1 + hatchTex2 + hatchTex3 + hatchTex4 + hatchTex5 + whiteColor;

                return fixed4(hatchColor.rgb, 1.0);
            }
            ENDCG
        }
    }
}
