using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using ReadTiff3D;
/*
Created by BlackFJ
*/

///<summary>
///
///</summary>
public class MarchingCubesScript : MonoBehaviour
{
    const int threadGroupSize = 8;

    public ComputeShader marchingCubesComputeShader;

    private ComputeBuffer triangleBuffer;
    private ComputeBuffer pointsBuffer;
    private ComputeBuffer triangleCountBuffer;

    [Range(0.0f, 1.0f)]
    public float isosurfaceValue = 0.5f;

    [Range(2, 32)]
    public int numPointsPerAxis = 8;

    public ComputeShader generateOctreeComputeShader;

    public Texture3D texture3D;

    struct Triangle
    {
        public Vector3 a;
        public Vector3 b;
        public Vector3 c;

        public Vector3 this[int i]
        {
            get
            {
                switch (i)
                {
                    case 0:
                        return a;
                    case 1:
                        return b;
                    default:
                        return c;
                }
            }
        }
    }

    private void Start()
    {
        //TIFF tiff = new TIFF();
        //tiff.Decode("E:\\UnityHub\\Unity_tutorial\\BlackUnityShader\\Assets\\BlackResource\\Tiff3D\\1.tif", "asset3d", 128, 128, 128);
        
        int numVoxelsPerAxis = numPointsPerAxis - 1;
        int numThreadsPerAxis = Mathf.CeilToInt(numVoxelsPerAxis / (float)threadGroupSize);
        
        int numPoints = numPointsPerAxis * numPointsPerAxis * numPointsPerAxis;
        int numVoxels = numVoxelsPerAxis * numVoxelsPerAxis * numVoxelsPerAxis;
        int maxTriangleCount = numVoxels * 5;

        triangleBuffer = new ComputeBuffer(maxTriangleCount, sizeof(float) * 3 * 3, ComputeBufferType.Append);
        pointsBuffer = new ComputeBuffer(numPoints, sizeof(float) * 4);
        triangleCountBuffer = new ComputeBuffer(1, sizeof(int), ComputeBufferType.Raw);

        ReadTexture3DToPointsBuffer(numPointsPerAxis);
        
        var kernelId = marchingCubesComputeShader.FindKernel("MarchingCubes");
        marchingCubesComputeShader.SetBuffer(kernelId, "points", pointsBuffer);
        marchingCubesComputeShader.SetBuffer(kernelId, "triangles", triangleBuffer);
        marchingCubesComputeShader.SetInt("numPointsPerAxis", numPointsPerAxis);
        marchingCubesComputeShader.SetFloat("isosurfaceValue", isosurfaceValue);
        marchingCubesComputeShader.Dispatch(kernelId, numThreadsPerAxis, numThreadsPerAxis, numThreadsPerAxis);

        ComputeBuffer.CopyCount(triangleBuffer, triangleCountBuffer, 0);
        int[] triCountArray = { 0 };
        triangleCountBuffer.GetData(triCountArray);
        int triCount = triCountArray[0];

        Triangle[] triangles = new Triangle[triCount];
        triangleBuffer.GetData(triangles, 0, 0, triCount);

        if (triangleBuffer != null)
        {
            triangleBuffer.Release();
            pointsBuffer.Release();
            triangleCountBuffer.Release();
        }

        var vertices = new Vector3[triCount * 3];
        var meshTriangles = new int[triCount * 3];
        for(int i = 0; i < triCount; ++i)
        {
            for(int j = 0; j < 3; ++j)
            {
                meshTriangles[i * 3 + j] = i * 3 + j;
                vertices[i + 3 + j] = triangles[i][j];
            }
        }
        print(triCount);
        var mesh = new Mesh();
        mesh.vertices = vertices;
        mesh.triangles = meshTriangles;
        var meshFilter = gameObject.AddComponent<MeshFilter>();
        meshFilter.mesh = mesh;
        
    }


    void ReadTexture3DToPointsBuffer(int numPointsPerAxis)
    {
        Vector4[] dataArray = new Vector4[numPointsPerAxis * numPointsPerAxis * numPointsPerAxis];
        //int width = texture3D.width;
        //int height = texture3D.height;
        //int depth = texture3D.depth;
        //print("format:"+width.ToString() + " " + height.ToString() + " " + depth.ToString());
        //int wstep = width / numPointsPerAxis;
        //int ystep = height / numPointsPerAxis;
        //int zstep = depth / numPointsPerAxis;
        for(int z = 0; z < numPointsPerAxis; ++z)
        {
            float zf = 1.0f * z / (numPointsPerAxis-1);
            for(int y = 0; y < numPointsPerAxis; ++y)
            {
                float yf = 1.0f * y / (numPointsPerAxis-1);
                for(int x = 0; x < numPointsPerAxis; ++x)
                {
                    //Color c = texture3D.GetPixel(x * wstep, y * ystep, z * zstep);
                    //print(c);
                    float xf = 1.0f * x / (numPointsPerAxis-1);
                    float noiseValue = Mathf.PerlinNoise(xf*zf, yf*zf);
                    Vector4 d = new Vector4(xf, yf, zf, noiseValue);
                    dataArray[z * numPointsPerAxis * numPointsPerAxis + y * numPointsPerAxis + x] = d;
                }
            }
        }
        pointsBuffer.SetData(dataArray);
    }

}
