Shader "BlackShader/Shader_GlassRefraction"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _BumpMap("Normal",2D)=""{}
        _Cubemap("Cube map",Cube)=""{}
        _Distortion("Distortion",Range(0,100))=10
        _RefractAmount("Refract Amount",Range(0,1))=1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Transparent" }
        LOD 100
        GrabPass{"_RefractionTex"}
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal :NORMAL;
                float4 tangent :TANGENT;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 uv : TEXCOORD0;
                float4 TtoW0 : TEXCOORD1;
                float4 TtoW1 :TEXCOORD2;
                float4 TtoW2:TEXCOORD3;
                float4 scrPos: TEXCOORD4;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _BumpMap;
            float4 _BumpTex_ST;
            samplerCUBE _Cubemap;
            float _Distortion;
            fixed _RefractAmount;
            sampler2D _RefractionTex;
            float4 _RefractionTex_TexelSize;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
                o.uv.zw = TRANSFORM_TEX(v.uv, _BumpTex);
                o.scrPos = ComputeGrabScreenPos(o.vertex);

                float3 pos = mul(unity_ObjectToWorld, v.vertex).xyz;
                fixed3 normal = UnityObjectToWorldNormal(v.normal);
                fixed3 tangent = UnityObjectToWorldDir(v.tangent.xyz);
                fixed3 binormal = cross(normal, tangent) * v.tangent.w;

                o.TtoW0 = float4(tangent.x, binormal.x, normal.x, pos.x);
                o.TtoW1 = float4(tangent.y, binormal.y, normal.y, pos.y);
                o.TtoW2 = float4(tangent.z, binormal.z, normal.z, pos.z);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                float3 pos = float3(i.TtoW0.w,i.TtoW1.w,i.TtoW2.w);
                fixed3 viewDir = normalize(UnityWorldSpaceViewDir(pos));

                fixed3 bump = UnpackNormal(tex2D(_BumpMap, i.uv.zw));
                
                float2 offset = bump.xy * _Distortion * _RefractionTex_TexelSize.xy;
                i.scrPos.xy += offset;
                fixed3 refrCol = tex2D(_RefractionTex, i.scrPos.xy / i.scrPos.w).rgb;

                bump = normalize(half3(dot(i.TtoW0.xyz, bump), dot(i.TtoW1.xyz, bump), dot(i.TtoW2.xyz, bump)));
                fixed3 reflDir = reflect(-viewDir, bump);
                fixed4 texColor = tex2D(_MainTex, i.uv.xy);
                fixed3 reflCol = texCUBE(_Cubemap, reflDir).rgb * texColor;

                fixed3 col = reflCol * (1 - _RefractAmount) + refrCol * _RefractAmount;
                return fixed4(col,1.0);
            }
            ENDCG
        }
    }
}
