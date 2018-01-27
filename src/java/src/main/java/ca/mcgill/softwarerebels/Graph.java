package ca.mcgill.softwarerebels;

import java.util.ArrayList;
import java.util.LinkedList;
import java.util.Queue;
import java.util.Stack;


public class Graph
{
    public CommitNode rootNode;
    public ArrayList nodes=new ArrayList();
    public int[][] adjMatrix;//Edges will be represented as adjacency Matrix
    int size;
    public void setRootNode(CommitNode n)
    {
        this.rootNode=n;
    }

    public CommitNode getRootNode()
    {
        return this.rootNode;
    }

    public void addNode(CommitNode n)
    {
        nodes.add(n);
    }

    //This method will be called to make connect two nodes
    public void connectNode(CommitNode start,CommitNode end)
    {
        if(adjMatrix==null)
        {
            size=nodes.size();
            adjMatrix=new int[size][size];
        }

        int startIndex=nodes.indexOf(start);
        int endIndex=nodes.indexOf(end);
        adjMatrix[startIndex][endIndex]=1;
        //adjMatrix[endIndex][startIndex]=1;
    }

    private CommitNode getUnvisitedChildNode(CommitNode n)
    {

        int index=nodes.indexOf(n);
        int j=0;
        while(j<size)
        {
            if(adjMatrix[index][j]==1 && ((CommitNode)nodes.get(j)).visited==false)
            {
                return (CommitNode)nodes.get(j);
            }
            j++;
        }
        return null;
    }

    private int getImmediateChildrenCount(CommitNode n)
    {
        int count = 0;
        int index=nodes.indexOf(n);
        int j=0;
        while(j<size)
        {
            if(adjMatrix[index][j]==1 && ((CommitNode)nodes.get(j)).visited==false)
            {
                count++;
            }
            j++;
        }
        return count;
    }

    //BFS traversal of a tree is performed by the bfs() function
    public void bfs()
    {

        //BFS uses Queue data structure
        Queue q=new LinkedList();
        q.add(this.rootNode);
        printNode(this.rootNode);
        rootNode.visited=true;
        int kidCount = getImmediateChildrenCount(rootNode);
        while(!q.isEmpty())
        {
            CommitNode n=(CommitNode)q.remove();
            CommitNode child=null;
            printParentalInfo(n, kidCount);
            while((child=getUnvisitedChildNode(n))!=null)
            {
                child.visited=true;
                child.distanceToSolution = n.distanceToSolution+1;
                printNode(child);
                if(child.status == "passed"){
                    System.out.printf("Found it! kidcount:%s distance:%s", kidCount, child.distanceToSolution);
                    clearNodes();
                    return;
                }
                q.add(child);
            }
        }
        //Clear visited property of nodes
        clearNodes();
    }

    //DFS traversal of a tree is performed by the dfs() function
    public void dfs()
    {
        //DFS uses Stack data structure
        Stack s=new Stack();
        s.push(this.rootNode);
        rootNode.visited=true;
        printNode(rootNode);
        while(!s.isEmpty())
        {
            CommitNode n=(CommitNode)s.peek();
            CommitNode child=getUnvisitedChildNode(n);
            if(child!=null)
            {
                child.visited=true;
                printNode(child);
                s.push(child);
            }
            else
            {
                s.pop();
            }
        }
        //Clear visited property of nodes
        clearNodes();
    }


    //Utility methods for clearing visited property of node
    private void clearNodes()
    {
        int i=0;
        while(i<size)
        {
            CommitNode n=(CommitNode)nodes.get(i);
            n.visited=false;
            n.distanceToSolution=0;
            i++;
        }
    }

    //Utility methods for printing the node's label
    private void printNode(CommitNode n)
    {
        System.out.print("\n"+ n.label+" depth:"+n.distanceToSolution);
    }

    private void printParentalInfo(CommitNode n, int c)
    {
        System.out.print("\n"+ n.label+" no .of kids:"+c);
    }





}

