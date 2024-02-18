Shader "PeerPlay/RayMarchShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
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
            #pragma target 3.0

            #include "UnityCG.cginc"
            #include "DistanceFunctions.cginc"

            sampler2D _MainTex;
            uniform sampler2D _CameraDepthTexture;
            uniform float4x4 _CamFrustum, _CamToWorld;
            uniform float _maxDistance;
            uniform float4 _sphere1, _box1;
            uniform float3 _lightDir;
            uniform fixed4 _mainColor;

            
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 ray : TEXCOORD1;
            };

            v2f vert (appdata v)
            {
                v2f o;
                half index = v.vertex.z;
                v.vertex.z = 0;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;

                o.ray = _CamFrustum[(int)index].xyz;

                o.ray /= abs(o.ray.z);

                o.ray = mul(_CamToWorld, o.ray);
                return o;
            }


            float distanceField(float3 p) 
            {

                float modx = pMod1(p.x, 4);
                float mody = pMod1(p.y, 4);
                float modz = pMod1(p.z, 4);
                float Sphere1 = sdSphere(p - _sphere1.xyz, _sphere1.w);
                float Box1 = sdBox(p - _box1.xyz, _box1.www);
                
                return opS(Sphere1, Box1);
            }



            float3 getNormal(float3 p)
            {
                const float2 offset = float2(0.001, 0.0);
                float3 n = float3(
                    distanceField(p + offset.xyy) - distanceField(p - offset.xyy),
                    distanceField(p + offset.yxy) - distanceField(p - offset.yxy),
                    distanceField(p + offset.yyx) - distanceField(p - offset.yyx));
                return normalize(n);
            }

            // returns color
            fixed4 raymarching(float3 ro, float3 rd, float depth) 
            {
                fixed4 result = fixed4(1, 1, 1, 1);
                const int max_iteration = 164;
                float t = 0; // distance traveled along ray direction

                // move forward along the ray until you hit something
                for (int i = 0; i < max_iteration; i++) 
                {
                    if (t > _maxDistance || t >= depth)
                    {
                        result = fixed4(rd, 0);
                        break;
                    }

                    float3 p = ro + rd * t;
                    // check for hit in distance field
                    float d = distanceField(p);
                    // hit if statement
                    if (d < 0.01) 
                    {
                        // shading
                        float3 n = getNormal(p);
                        float light = dot(-_lightDir, n);
                        result = fixed4(_mainColor.rgb * light, 1);
                        break;
                    }

                    t += d;
                }

                return result;
            }
            

            fixed4 frag(v2f i) : SV_Target
            {
                float depth = LinearEyeDepth(tex2D(_CameraDepthTexture, i.uv).r);
                depth *= length(i.ray);
                fixed3 col = fixed3(0, 255, 0);

                float3 rayDirection = normalize(i.ray.xyz);
                float3 rayOrigin = _WorldSpaceCameraPos;
                fixed4 result = raymarching(rayOrigin, rayDirection, depth);
                return fixed4(col * (1.0 - result.w) + result.xyz * result.w, 1.0);
            }
            ENDCG
        }
    }
}
