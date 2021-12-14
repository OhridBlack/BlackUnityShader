using System.Collections;
using System.Collections.Generic;
using UnityEngine;

/*
Created by BlackFJ
*/

///<summary>
///
///</summary>
public class NoiseTerrian : MonoBehaviour
{
    private const int Dimension = 100;
    Vector3[] verts = new Vector3[Dimension * Dimension];
    protected MeshFilter meshFilter;
    protected Mesh mesh;
    public Material mat;

    private void Start()
    {
        mesh = new Mesh();
        MeshRenderer meshRender = GetComponent<MeshRenderer>();
        meshRender.material = mat;
        mesh.vertices = GetVerts();
        mesh.triangles = GetTriangles();
        mesh.RecalculateBounds();

        meshFilter = gameObject.AddComponent<MeshFilter>();
        meshFilter.mesh = mesh;
    }

    private Vector3[] GetVerts()
    {
        float[,] noiseMap = GetNoiseMap(Dimension, Dimension, Dimension/10);
        float highest = -10000000;
        float lowest = 10000000;
        for(int i = 0; i < Dimension; ++i)
        {
            for(int j = 0; j < Dimension; ++j)
            {
                verts[j * Dimension + i] = new Vector3(i / 10.0f, 5*noiseMap[i,j], j / 10.0f);
                highest = highest > 5*noiseMap[i, j] ? highest : 5*noiseMap[i, j];
                lowest = lowest < 5*noiseMap[i, j] ? lowest : 5*noiseMap[i, j];
            }
        }
        float step = (highest - lowest) / 3;
        mat.SetFloat("_HighestStep", step * 2 + lowest);
        mat.SetFloat("_LowestStep", step + lowest);
        return verts;
    }

    private int[] GetTriangles()
    {
        var tries = new int[mesh.vertices.Length * 6];
        for (int i = 0; i < Dimension - 1; i++)
        {
            for (int j = 0; j < Dimension - 1; j++)
            {
                int TriIdx = (j * (Dimension - 1) + i) * 6;
                int VerIdx = j * Dimension + i;
                tries[TriIdx] = VerIdx;
                tries[TriIdx + 1] = VerIdx + Dimension;
                tries[TriIdx + 2] = VerIdx + Dimension + 1;

                /*
                 1 ------  2/4
                 |             |
                 |             |
               0/3 ------- 5
                 
                 */

                tries[TriIdx + 3] = VerIdx;
                tries[TriIdx + 4] = VerIdx + Dimension + 1;
                tries[TriIdx + 5] = VerIdx + 1;
            }
        }
        return tries;
    }

    private float[,] GetNoiseMap(int width,int height,float scale)
    {
        float[,] noiseMap = new float[width, height];
        if (scale <= 0) scale = 0.0001f;
        for(int y = 0; y < height; ++y)
        {
            float sampley = y / scale;
            for(int x = 0; x < width; ++x)
            {
                float samplex = x / scale ;
                
                float value = Mathf.PerlinNoise(samplex, sampley);
                noiseMap[x, y] = value;
            }
        }
        return noiseMap;
    }

}
