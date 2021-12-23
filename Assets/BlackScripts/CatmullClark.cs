using System.Collections;
using System.Collections.Generic;
using UnityEngine;

/*
Created by BlackFJ
*/

///<summary>
///
///</summary>
public class CatmullClark : MonoBehaviour
{
    class VertexInfo
    {
        public Vector3 position;
        public List<int> edges;
        public List<int> quads;

        public VertexInfo(Vector3 pos)
        {
            position = pos;
            edges = new List<int>();
            quads = new List<int>();
        }

        public void addEdge(int edgeIdx)
        {
            edges.Add(edgeIdx);
        }

        public void addQuad(int quadIdx)
        {
            quads.Add(quadIdx);
        }
    }

    class EdgeInfo
    {
        public int firstVertex;
        public int secondVertex;
        public int faceCount;
        public List<int> quads;

        public EdgeInfo(int firstV,int secondV)
        {
            firstVertex = firstV;
            secondVertex = secondV;
            faceCount = 0;
            quads = new List<int>();
        }

        public void addQuad(int quadIdx)
        {
            faceCount += 1;
            quads.Add(quadIdx);
        }
    }

    class QuadInfo
    {
        public List<int> vertices;
        public List<int> edges;

        public QuadInfo()
        {
            vertices = new List<int>();
            edges = new List<int>();
        }

        public void addVertex(int vertexIdx)
        {
            vertices.Add(vertexIdx);
        }

        public void addEdge(int edgeIdx)
        {
            edges.Add(edgeIdx);
        }
    }

    class QuadMesh
    {
        private List<VertexInfo> vertices;
        private List<EdgeInfo> edges;
        private List<QuadInfo> quads;

        private Dictionary<Vector3, int> positionToVertex;
        private Dictionary<Vector2Int, int> vertexPairToEdge;

        private Vector2Int GetVertexPair(int firstIdx,int secondIdx)
        {
            Vector2Int tmp;
            if (firstIdx > secondIdx) tmp = new Vector2Int(secondIdx, firstIdx);
            else tmp = new Vector2Int(firstIdx, secondIdx);
            return tmp;
        }

        private int AddVertex(Vector3 vertex)
        {
            if (!positionToVertex.ContainsKey(vertex))
            {
                int idx = vertices.Count;
                positionToVertex.Add(vertex, idx);
                vertices.Add(new VertexInfo(vertex));
                return idx;
            }

            return positionToVertex[vertex];
        }

        private int AddEdge(int firstIdx,int secondIdx)
        {
            Vector2Int tmp = GetVertexPair(firstIdx, secondIdx);
            if (!vertexPairToEdge.ContainsKey(tmp))
            {
                int idx = edges.Count;
                vertexPairToEdge.Add(tmp, idx);
                edges.Add(new EdgeInfo(tmp.x, tmp.y));
                vertices[firstIdx].addEdge(idx);
                vertices[secondIdx].addEdge(idx);
                return idx;
            }
            return vertexPairToEdge[tmp];
        }

        private int AddQuad(int idx0,int idx1,int idx2,int idx3)
        {
            QuadInfo quad = new QuadInfo();
            quad.addVertex(idx0);
            quad.addVertex(idx1);
            quad.addVertex(idx2);
            quad.addVertex(idx3);
            Vector2Int e01 = GetVertexPair(idx0, idx1);
            Vector2Int e12 = GetVertexPair(idx1, idx2);
            Vector2Int e23 = GetVertexPair(idx2, idx3);
            Vector2Int e30 = GetVertexPair(idx3, idx0);
            int edgeIdx01 = vertexPairToEdge[e01];
            quad.addEdge(edgeIdx01);
            int edgeIdx12 = vertexPairToEdge[e12];
            quad.addEdge(edgeIdx12);
            int edgeIdx23 = vertexPairToEdge[e23];
            quad.addEdge(edgeIdx23);
            int edgeIdx30 = vertexPairToEdge[e30];
            quad.addEdge(edgeIdx30);

            int idx = quads.Count;
            quads.Add(quad);
            vertices[idx0].addQuad(idx);
            vertices[idx1].addQuad(idx);
            vertices[idx2].addQuad(idx);
            vertices[idx3].addQuad(idx);

            edges[edgeIdx01].addQuad(idx);
            edges[edgeIdx12].addQuad(idx);
            edges[edgeIdx23].addQuad(idx);
            edges[edgeIdx30].addQuad(idx);

            return idx;
        }

        public QuadMesh(Vector3[] triVertices,int[] triIndices)
        {
            vertices = new List<VertexInfo>();
            edges = new List<EdgeInfo>();
            quads = new List<QuadInfo>();
            positionToVertex = new Dictionary<Vector3, int>();
            vertexPairToEdge = new Dictionary<Vector2Int, int>();

            foreach(var triVertex in triVertices)
            {
                AddVertex(triVertex);
            }

            int size = triIndices.Length;
            
            for(int i = 0; i < size; i += 3)
            {
                Vector3 p0 = triVertices[triIndices[i]];
                Vector3 p1 = triVertices[triIndices[i + 1]];
                Vector3 p2 = triVertices[triIndices[i + 2]];

                int pi0 = positionToVertex[p0];
                int pi1 = positionToVertex[p1];
                int pi2 = positionToVertex[p2];

                float d01 = Vector3.Distance(p0, p1);
                float d12 = Vector3.Distance(p1, p2);
                float d20 = Vector3.Distance(p2, p0);
                float dMax = Mathf.Max(Mathf.Max(d01, d12), d20);
                Vector3 newPoint = Vector3.zero;

                if(dMax==d01)
                {
                    newPoint = (p0 + p1) / 2;
                    int pi3 = AddVertex(newPoint);
                    AddEdge(pi0, pi3);
                    AddEdge(pi3, pi1);
                    AddEdge(pi1, pi2);
                    AddEdge(pi2, pi0);
                    AddQuad(pi0, pi3, pi1, pi2);

                }
                else if (dMax == d12)
                {
                    newPoint = (p1 + p2) / 2;
                    int pi3 = AddVertex(newPoint);
                    AddEdge(pi0, pi1);
                    AddEdge(pi1, pi3);
                    AddEdge(pi3, pi2);
                    AddEdge(pi2, pi0);
                    AddQuad(pi0, pi1, pi3, pi2);
                }
                else
                {
                    newPoint = (p2 + p0) / 2;
                    int pi3 = AddVertex(newPoint);
                    AddEdge(pi0, pi1);
                    AddEdge(pi1, pi2);
                    AddEdge(pi2, pi3);
                    AddEdge(pi3, pi0);
                    AddQuad(pi0, pi1, pi2, pi3);
                }

            }
        }

        public void UpdateQuadMesh(Vector3[] quadVertices,int[] quadIndices)
        {
            vertices.Clear();
            edges.Clear();
            quads.Clear();
            positionToVertex.Clear();
            vertexPairToEdge.Clear();

            foreach(var vertex in quadVertices)
            {
                AddVertex(vertex);
            }

            for(int i = 0; i < quadIndices.Length; i += 4)
            {
                int idx0 = quadIndices[i];
                int idx1 = quadIndices[i + 1];
                int idx2 = quadIndices[i + 2];
                int idx3 = quadIndices[i + 3];

                AddEdge(idx0, idx1);
                AddEdge(idx1, idx2);
                AddEdge(idx2, idx3);
                AddEdge(idx3, idx0);
                AddQuad(idx0, idx1, idx2, idx3);
            }
        }

        public void CatmullClarkSubDivision(float alpha=1.0f,float beta=2.0f)
        {
            float rest = (4 - alpha - beta) / 4;
            alpha /= 4;
            beta /= 4;

            Vector3[] fp = new Vector3[quads.Count];
            Vector3[] ec = new Vector3[edges.Count];
            Vector3[] ep = new Vector3[edges.Count];
            Dictionary<Vector3, int> positionToVertexTmp = new Dictionary<Vector3, int>();
            List<Vector3> quadVertices = new List<Vector3>();
            List<int> quadIndices = new List<int>();

            //fp
            for(int i = 0; i < quads.Count; ++i)
            {
                Vector3 fpi = Vector3.zero;
                for(int j = 0; j < 4; ++j)
                {
                    fpi += vertices[quads[i].vertices[j]].position;
                }
                fp[i] = fpi / 4.0f;
            }

            //ec
            for(int i = 0; i < edges.Count; ++i)
            {
                int idx0 = edges[i].firstVertex;
                int idx1 = edges[i].secondVertex;
                ec[i] = (vertices[idx0].position + vertices[idx1].position) / 2.0f;
            }

            //fpc & ep
            for(int i = 0; i < edges.Count; ++i)
            {
                int idx0 = edges[i].quads[0];
                int idx1 = edges[i].quads[1];
                Vector3 fpci = (fp[idx0] + fp[idx1]) / 2.0f;
                ep[i] = (fpci + ec[i]) / 2.0f;
            }

            //avg_fp & avg_ec & update position
            for(int i = 0; i < vertices.Count; ++i)
            {
                int quadCount = vertices[i].quads.Count;
                Vector3 avg_fpi = Vector3.zero;
                foreach(var quadIdx in vertices[i].quads){
                    avg_fpi += fp[quadIdx];
                }
                avg_fpi /= quadCount;

                int edgeCount = vertices[i].edges.Count;
                Vector3 avg_eci = Vector3.zero;
                foreach(var edgeIdx in vertices[i].edges)
                {
                    avg_eci += ec[edgeIdx];
                }
                avg_eci/= edgeCount;

                Vector3 position = vertices[i].position * rest + avg_fpi * alpha + avg_eci * beta;
                positionToVertexTmp.Add(position, quadVertices.Count);
                quadVertices.Add(position);
                
            }

            //add point
            for(int i = 0; i < quads.Count; ++i)
            {
                
                int count = quadVertices.Count;
                Vector3 fpi = fp[i];
                int v0 = quads[i].vertices[0];
                int v1 = quads[i].vertices[1];
                int v2 = quads[i].vertices[2];
                int v3 = quads[i].vertices[3];

                int e01 = quads[i].edges[0];
                int e12 = quads[i].edges[1];
                int e23 = quads[i].edges[2];
                int e30 = quads[i].edges[3];

                Vector3 ep01 = ep[e01];
                Vector3 ep12 = ep[e12];
                Vector3 ep23 = ep[e23];
                Vector3 ep30 = ep[e30];

                int fpIdx, ep01Idx, ep12Idx, ep23Idx, ep30Idx;
                if (!positionToVertexTmp.ContainsKey(fpi))
                {
                    fpIdx = quadVertices.Count;
                    quadVertices.Add(fpi);
                    positionToVertexTmp.Add(fpi, fpIdx);
                }
                else
                {
                    fpIdx = positionToVertexTmp[fpi];
                }

                if (!positionToVertexTmp.ContainsKey(ep01))
                {
                    ep01Idx = quadVertices.Count;
                    quadVertices.Add(ep01);
                    positionToVertexTmp.Add(ep01, ep01Idx);
                }
                else
                {
                    ep01Idx = positionToVertexTmp[ep01];
                }

                if (!positionToVertexTmp.ContainsKey(ep12))
                {
                    ep12Idx = quadVertices.Count;
                    quadVertices.Add(ep12);
                    positionToVertexTmp.Add(ep12, ep12Idx);
                }
                else
                {
                    ep12Idx = positionToVertexTmp[ep12];
                }

                if (!positionToVertexTmp.ContainsKey(ep23))
                {
                    ep23Idx = quadVertices.Count;
                    quadVertices.Add(ep23);
                    positionToVertexTmp.Add(ep23, ep23Idx);
                }
                else
                {
                    ep23Idx = positionToVertexTmp[ep23];
                }

                if (!positionToVertexTmp.ContainsKey(ep30))
                {
                    ep30Idx = quadVertices.Count;
                    quadVertices.Add(ep30);
                    positionToVertexTmp.Add(ep30, ep30Idx);
                }
                else
                {
                    ep30Idx = positionToVertexTmp[ep30];
                }

                int[] quad0 = { v0, ep01Idx, fpIdx, ep30Idx };
                quadIndices.AddRange(quad0);

                int[] quad1 = { ep01Idx, v1, ep12Idx,fpIdx };
                quadIndices.AddRange(quad1);

                int[] quad2 = { ep30Idx, fpIdx, ep23Idx, v3 };
                quadIndices.AddRange(quad2);

                int[] quad3 = { fpIdx, ep12Idx, v2, ep23Idx };
                quadIndices.AddRange(quad3);

            }

            UpdateQuadMesh(quadVertices.ToArray(), quadIndices.ToArray());
        }

        static public void GetTriMesh(QuadMesh quadMesh,out Vector3[] triVertices,out int[] triIndices)
        {
            triVertices = new Vector3[quadMesh.vertices.Count];
            triIndices = new int[quadMesh.quads.Count * 6];
            for(int i = 0; i < quadMesh.vertices.Count; ++i)
            {
                triVertices[i] = quadMesh.vertices[i].position;
            }
            for(int i = 0; i < quadMesh.quads.Count; ++i)
            {
                triIndices[i * 6] = quadMesh.quads[i].vertices[0];
                triIndices[i * 6 + 1] = quadMesh.quads[i].vertices[1];
                triIndices[i * 6 + 2] = quadMesh.quads[i].vertices[2];

                triIndices[i * 6 + 3] = quadMesh.quads[i].vertices[0];
                triIndices[i * 6 + 4] = quadMesh.quads[i].vertices[2];
                triIndices[i * 6 + 5] = quadMesh.quads[i].vertices[3];
            }
        }

    }

    [SerializeField,Range(0, 3)] public int iterationTime = 0;

    private Vector3[] vertices_0;
    private int[] triangles_0;

    private Vector3[] vertices_1;
    private int[] triangles_1;
    private Vector3[] vertices_2;
    private int[] triangles_2;
    private Vector3[] vertices_3;
    private int[] triangles_3;

    private int lastIterationTime;

    private Mesh mesh;
    private void Start()
    {
        mesh = GetComponent<MeshFilter>().mesh;
        vertices_0 = mesh.vertices;
        triangles_0 = mesh.triangles;
        lastIterationTime = iterationTime;

        QuadMesh quadMesh = new QuadMesh(vertices_0, triangles_0);
        quadMesh.CatmullClarkSubDivision();
        QuadMesh.GetTriMesh(quadMesh,out vertices_1, out triangles_1);

        quadMesh.CatmullClarkSubDivision();
        QuadMesh.GetTriMesh(quadMesh, out vertices_2, out triangles_2);

        quadMesh.CatmullClarkSubDivision();
        QuadMesh.GetTriMesh(quadMesh, out vertices_3, out triangles_3);

    }


    private void Update()
    {
        if (iterationTime != lastIterationTime)
        {
            if (iterationTime == 0)
            {
                mesh.Clear();
                mesh.vertices = vertices_0;
                mesh.triangles = triangles_0;
            }
            else if (iterationTime == 1)
            {
                mesh.Clear();
                mesh.vertices = vertices_1;
                mesh.triangles = triangles_1;
            }
            else if (iterationTime == 2)
            {
                mesh.Clear();
                mesh.vertices = vertices_2;
                mesh.triangles = triangles_2;
            }
            else if (iterationTime == 3)
            {
                mesh.Clear();
                mesh.vertices = vertices_3;
                mesh.triangles = triangles_3;
            }
            lastIterationTime = iterationTime;
        }
    }

}
