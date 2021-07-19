using UnityEngine;
using UnityEditor;
using System;

internal class SVEGeneralShaderGUI : ShaderGUI
{
    private enum AlphaMode
    {
        Cutout,
        Blend
    }

    private enum BlendMode
    {
        Blend,
        Addition,
        Custom
    }
    private static class Styles
    {
        public static GUIContent uvSetLabel = EditorGUIUtility.TrTextContent("UV Set");

        public static GUIContent albedoText = EditorGUIUtility.TrTextContent("Albedo", "Albedo (RGB) and Transparency (A)");
        public static GUIContent alphaCutoffText = EditorGUIUtility.TrTextContent("Alpha Cutoff", "Threshold for alpha cutoff");


        public static string blendModeText = "Alpha Modes";
        public static string primaryMapsText = "Main Maps";
        public static string AlphaMode = "Alpha Mode";
        public static string BlendMode = "Blend Mode";
        public static readonly string[] alphaNames = Enum.GetNames(typeof(AlphaMode));
        public static readonly string[] blendNames = Enum.GetNames(typeof(BlendMode));
    }

    MaterialProperty alphaMode = null;
    MaterialProperty albedoMap = null;
    MaterialProperty albedoColor = null;
    MaterialProperty alphaCutoff = null;

    BlendMode blendMode;
    MaterialEditor m_MaterialEditor;

    bool m_FirstTimeApply = true;

    public void FindProperties(MaterialProperty[] props)
    {
        alphaMode = FindProperty("_Mode", props);
        albedoMap = FindProperty("_MainTex", props);
        albedoColor = FindProperty("_Color", props);
        alphaCutoff = FindProperty("_Cutoff", props);
    }

    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        FindProperties(properties);
        m_MaterialEditor = materialEditor;
        Material material = materialEditor.target as Material;

        // Make sure that needed setup (ie keywords/renderqueue) are set up if we're switching some existing
        // material to a standard shader.
        // Do this before any GUI code has been issued to prevent layout issues in subsequent GUILayout statements (case 780071)
        if (m_FirstTimeApply)
        {
            MaterialChanged(material, false);
            m_FirstTimeApply = false;
        }

        ShaderPropertiesGUI(material);
    }

    public void ShaderPropertiesGUI(Material material)
    {
        // Use default labelWidth
        EditorGUIUtility.labelWidth = 0f;

        bool blendModeChanged = false;

        // Detect any changes to the material
        EditorGUI.BeginChangeCheck();
        {
            GUILayout.Label(Styles.blendModeText, EditorStyles.boldLabel);
            blendModeChanged = BlendModePopup();
            DoBlendModeArea(material);

            EditorGUILayout.Space();

            // Primary properties
            GUILayout.Label(Styles.primaryMapsText, EditorStyles.boldLabel);
            DoAlbedoArea(material);
        }

        //m_MaterialEditor.EnableInstancingField();
        //m_MaterialEditor.DoubleSidedGIField();
    }

    static void MaterialChanged(Material material, bool overrideRenderQueue)
    {
        //SetupMaterialWithBlendMode(material, (BlendMode)material.GetFloat("_Mode"), overrideRenderQueue);

        //SetMaterialKeywords(material, workflowMode);
    }

    bool BlendModePopup()
    {
        EditorGUI.showMixedValue = alphaMode.hasMixedValue;
        var mode = (AlphaMode)alphaMode.floatValue;

        EditorGUI.BeginChangeCheck();
        mode = (AlphaMode)EditorGUILayout.Popup(Styles.AlphaMode, (int)mode, Styles.alphaNames);
        bool result = EditorGUI.EndChangeCheck();
        if (result)
        {
            m_MaterialEditor.RegisterPropertyChangeUndo("Rendering Mode");
            alphaMode.floatValue = (float)mode;
        }

        EditorGUI.showMixedValue = false;

        return result;
    }

    void DoBlendModeArea(Material material)
    {
        if (((AlphaMode)material.GetFloat("_Mode") == AlphaMode.Cutout))
        {
            m_MaterialEditor.ShaderProperty(alphaCutoff, Styles.alphaCutoffText.text, 0);
        }
        else if(((AlphaMode)material.GetFloat("_Mode") == AlphaMode.Blend))
        {
            //EditorGUI.showMixedValue = alphaMode.hasMixedValue;
            var mode = (BlendMode)blendMode;

            EditorGUI.BeginChangeCheck();
            mode = (BlendMode)EditorGUILayout.Popup(Styles.BlendMode, (int)mode, Styles.blendNames);
            bool result = EditorGUI.EndChangeCheck();
            if (result)
            {
                //m_MaterialEditor.RegisterPropertyChangeUndo("Rendering Mode");
                blendMode = mode;
            }

            //EditorGUI.showMixedValue = false;

            //return result;
        }
    }

    void DoAlbedoArea(Material material)
    {
        m_MaterialEditor.TexturePropertySingleLine(Styles.albedoText, albedoMap, albedoColor);
    }

}
