Shader "BlackShader/Shader_GetNormalDepthTexture"
{
    Properties
    {
        [Toggle(_DEPTHORNORMAL_ON)]
        _DepthOrNormal("Depth ?",Float)=0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

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

            sampler2D _CameraDepthNormalsTexture;


            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                float4 c = tex2D(_CameraDepthNormalsTexture,i.uv);
                fixed4 col;
#if _DEPTHORNORMAL_ON
                float depth = DecodeFloatRG(c.zw);
                float linearDepth = Linear01Depth(depth);
                col = fixed4(linearDepth, linearDepth, linearDepth, 1.0);

#else
                fixed3 normal = DecodeViewNormalStereo(c);
                col = fixed4(normal * 0.5 + 0.5, 1.0);
#endif


                return col;
            }
            ENDCG
        }
    }
}
