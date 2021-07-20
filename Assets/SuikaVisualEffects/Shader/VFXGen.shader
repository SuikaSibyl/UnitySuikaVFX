Shader "VFX/VFXGen"
{
    Properties
    {
        _Opacity("Opacity", range(0,1)) = 0.5
        
        // ==============================================
        // Alpha Mode
        // ----------------------------------------------
        // Alpha Cutout Mode Setting, threshold is needed
        _Cutoff("Alpha Cutoff", Range(0.0, 1.0)) = 0.5
        // Blending Mode Setting
        [Enum(UnityEngine.Rendering.BlendMode)]
        _BlendSrc("Blend Source", int) = 0
        [Enum(UnityEngine.Rendering.BlendMode)]
        _BlendDst("Blend Dst", int) = 0
        [Enum(UnityEngine.Rendering.BlendOp)]
        _BlendOp("Blend Op", int) = 0
        // End Alpha Mode Section
        // ==============================================

        // ==============================================
        // Texture Map
        // ----------------------------------------------
        // Main Tex & Multiply Color
        _MainTex ("Texture", 2D) = "white" {}
        _Color("Albedo Color", Color) = (1,1,1,1)
        // Mask Map
        _MaskTex ("Mask Texture", 2D) = "white"{}
        // ==============================================

        // ==============================================
        // Dissolve Effect
        // ----------------------------------------------
        // The Texture
        _DissolveTex ("Dissolve Texture", 2D) = "white" {}
        _DissolveIntensity("Intensity", range(0,1)) = 0.5
        _DissolveEdgeWidth("Edge Width", range(0,1)) = 0.1
        [HDR]_DissolveEdgeColor("Edge Color", Color) = (1,1,1,1)
        // ==============================================
        
        // ==============================================
        // Wrap Effect
        // ----------------------------------------------
        _WarpTex ("Warp Texture", 2D) = "gray"{}
        _WarpInt ("Warp Intensity", range(0,5)) = 0.5
        // ==============================================

        _NoiseTex ("Noise Texture", 2D) = "gray"{}
        _NoiseInt ("Noise Intensity", range(0,5)) = 0.5
        _FlowSpeed ("Flow Speed", Vector) = (0,0,0,0)
        
        _ScreenTex ("Screen Texture", 2D) = "white"{}

        // Blending state
        [HideInInspector] _Mode ("__mode", Float) = 0.0
        [HideInInspector] _BlendMode("__bmode", Float) = 0.0
        [HideInInspector] _ZWrite("__zw", Float) = 1.0
    }
    SubShader
    {
        Tags { 
            "Queue"="Transparent"
            "RenderType"="Transparent"
            "ForceNoShadowCasting"="True"
            "IgnoreProjector"="True"
        }
        LOD 100

        GrabPass
        {
            "_GrabTex"
        }

        Pass
        {
            Name "Forward"
            Tags {"LightMode"="ForwardBase"}
            
            BlendOp [_BlendOp]
            Blend [_BlendSrc] [_BlendDst]
            ZWrite[_ZWrite]

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog
            #pragma shader_feature REDIFY_ON
            #pragma multi_compile CUTOUT BLEND


            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float4 color : COLOR;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 color : TEXCOORD0;
                float2 uv0 : TEXCOORD1;
                float2 uv_mask : TEXCOORD2;
                float4 uv_screen : TEXCOORD3;
                float2 uv_attached : TEXCOORD4;
                float2 uv1 : TEXCOORD5;
                float4 vertex : SV_POSITION;
            };

            fixed4 _Color;
            float _Opacity;

            float  _NoiseInt;
            float2 _FlowSpeed;

            float  _WarpInt;
            // Blend Mode Only
        #if BLEND
            
        #endif 
            // Cutout Mode Only
        #if CUTOUT
            float _Cutoff;
        #endif

            // Dissolve
            fixed  _DissolveIntensity;
            fixed  _DissolveEdgeWidth;
            fixed4 _DissolveEdgeColor;

            // All Texture Samplers & STs
            sampler2D _MainTex;     float4 _MainTex_ST;
            sampler2D _MaskTex;     float4 _MaskTex_ST;
            sampler2D _NoiseTex;    float4 _NoiseTex_ST;
            sampler2D _WarpTex;     float4 _WarpTex_ST;
            sampler2D _ScreenTex;   float4 _ScreenTex_ST;
            sampler2D _DissolveTex;
            sampler2D _GrabTex;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.color = v.color;
                o.uv0 = TRANSFORM_TEX(v.uv, _MainTex);
                o.uv1 = TRANSFORM_TEX(v.uv, _NoiseTex);
                o.uv1 += frac(_Time.x * _FlowSpeed);
                o.uv_mask = TRANSFORM_TEX(v.uv, _MaskTex);
                o.uv_screen = ComputeScreenPos (o.vertex);
                
                // Get depth-scaled screen space uv
                float3 posVS = UnityObjectToViewPos(v.vertex).xyz;
                float originDist = UnityObjectToViewPos(float3(0,0,0)).z;
                o.uv_attached = posVS.xy / posVS.z;
                o.uv_attached *= originDist;
                o.uv_attached = o.uv_attached * _ScreenTex_ST.xy + frac(_ScreenTex_ST.zw);

                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // UV warping
                // ---------------------------------
                // warp the uv, using uv texture
                // sample the MainTex, get col
                fixed3 warp = tex2D(_WarpTex, i.uv1).rgb;
                fixed2 bias = (warp.rg - 0.5) * _WarpInt;

                // Main Color Determination
                // ---------------------------------
                // Get color from MainTex
                fixed  mask = tex2D(_MaskTex, i.uv_mask).r;
                fixed4 col = tex2D(_MainTex, i.uv0 + bias);
                       col *= _Color * i.
                           color;
                       col.a *= mask;
                // If use Cutout mode, do clip
                #if CUTOUT
                    clip(col.a - _Cutoff);
                    col.a = 1.0;
                #endif

                // Dissolve Effect Implementation
                // ---------------------------------
                fixed  dissolve = tex2D(_DissolveTex, i.uv0).r;
                       dissolve -= _DissolveIntensity;
                clip(dissolve);
                if(dissolve - 0.5*_DissolveEdgeWidth < 0)
                {
                    col.rgb = _DissolveEdgeColor;
                }

                // Multiply the alpha
                // ---------------------------------
                col.rgb *= col.a;

                i.uv_screen.xy /= i.uv_screen.w;
                fixed4 grab = tex2D(_GrabTex, i.uv_screen.xy + bias);

                // // 
                // fixed  noise = tex2D(_NoiseTex, i.uv1).r;
                //        noise = lerp(1.0, noise * 2.0, _NoiseInt);
                //        noise = max(0.0, noise);

                // fixed opacity = _Opacity * col.a * noise;

                // apply fog
                // UNITY_APPLY_FOG(i.fogCoord, col);

                return col;
            }
            ENDCG
        }
    }
    CustomEditor "SVEGeneralShaderGUI"
}
