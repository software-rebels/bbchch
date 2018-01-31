package ca.mcgill.softwarerebels;

import java.util.Date;

public class CommitNode {

    public String label;
    public String buildID;
    public String status;
    public Date buildTime;
    public boolean visited=false;
    public int distanceToSolution = 0;
    public CommitNode(String l)
    {
        this.label=l;
    }

    public CommitNode(String l, String id, String status, Date buildTime)
    {
        this.label=l;
        this.buildID=id;
        this.status=status;
        this.buildTime=buildTime;
    }
    public CommitNode(String l, String status)
    {
        this.label=l;
        this.status=status;
    }

    @Override
    public String toString() {
        return label.toString();
    }
}



