using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

[CustomEditor(typeof(Test))]
public class EditorTest : Editor
{
    private SerializedProperty aArray;
    private bool showArray = false;

    private void OnEnable()
    {

        aArray = serializedObject.FindProperty("a");
    }
    public override void OnInspectorGUI()
    {
        base.DrawDefaultInspector(); // 绘制原有的属性
        serializedObject.Update();
        showArray = EditorGUILayout.BeginFoldoutHeaderGroup(showArray, "数组");
        if (showArray)
        {
            EditorGUI.indentLevel++; // 缩进加一
            aArray.arraySize = Mathf.Clamp(EditorGUILayout.IntField("数量", aArray.arraySize), 2, int.MaxValue);
            EditorGUI.indentLevel++;

            for (int i = 0; i < aArray.arraySize; i++)
            {
                EditorGUILayout.PropertyField(aArray.GetArrayElementAtIndex(i).FindPropertyRelative("Num"), new GUIContent("数字"));
                EditorGUILayout.PropertyField(aArray.GetArrayElementAtIndex(i).FindPropertyRelative("Str"), new GUIContent("字符串"));
            }
        }
        EditorGUILayout.EndFoldoutHeaderGroup();

        serializedObject.ApplyModifiedProperties();
    }

}
