package ca.mcgill.softwarerebels;

import java.io.File;
import java.io.IOException;
import java.nio.charset.Charset;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.*;
import java.util.concurrent.TimeUnit;

import com.c05mic.generictree.*;
import org.apache.commons.io.FileUtils;

public class Main {
    /**
     * @param args
     */
    static List<String> projectList;
    static List<String> commitList;
    static File projectsfile;
    static File cgfile;
    final static String timeformat = "yyyy-MM-dd HH:mm:ss";

    public static void main(String[] args) {
        SimpleDateFormat sdf = new SimpleDateFormat(timeformat);
        //HashMap graphs = new HashMap();
        Graph g = new Graph();
        HashMap<String, HashMap<String, Node>> commits = new HashMap<String, HashMap<String, Node>>();
        HashMap<String, Tree<CommitNode>> trees = new HashMap<String, Tree<CommitNode>>();

        ClassLoader classLoader = g.getClass().getClassLoader();
        projectsfile = new File(classLoader.getResource("projects_with_failed_builds.csv").getFile());
        cgfile = new File(classLoader.getResource("commit_graph.csv").getFile());
        try {
            projectList = FileUtils.readLines(projectsfile, Charset.defaultCharset());
            commitList = FileUtils.readLines(cgfile, Charset.defaultCharset());
        } catch (IOException e) {
            e.printStackTrace();
        }

        int i = 0;
        for (String line : projectList) {
            String projectID = trimQuotes(line.trim());
            if (projectID.length() > 1) {
                i++;
                System.out.printf("project name %s\n", projectID);
                //graphs.put(projectID, new Graph());
                commits.put(projectID,new HashMap());
                trees.put(projectID, new Tree(null));
            }
        }
        System.out.printf("project count %s\n", i);

        //First iteration
        for (String commitLine : commitList) {
            String[] commitData = commitLine.split(",");
            String buildID = trimQuotes(commitData[1]);
            String triggerCommit = trimQuotes(commitData[0]).substring(0, 8);
            String prevCommit = trimQuotes(commitData[2]);
            if (prevCommit.length() > 8) {
                prevCommit = prevCommit.substring(0, 8);
            }
            String buildStatus = trimQuotes(commitData[3]);
            String projectName = trimQuotes(commitData[4]);
            Date buildTime = null;
            try {
                buildTime = sdf.parse(trimQuotes(commitData[5]));
            } catch (ParseException e) {
                e.printStackTrace();
            }

            if (trees.containsKey(projectName)) {
                CommitNode destData = null;
                CommitNode srcData = null;
                Node dest = commits.get(projectName).get(triggerCommit);
                Node src =  commits.get(projectName).get(prevCommit);

                //Handling Trigger Commit
                if (dest==null) {
                    destData = new CommitNode(triggerCommit, buildID, buildStatus, buildTime);
                    dest = new Node(destData);
                    commits.get(projectName).put(triggerCommit, dest);

                } else if(((CommitNode)dest.getData()).status==null) {
                    dest.setData(new CommitNode(triggerCommit, buildID, buildStatus, buildTime));
                } else {
                    System.out.println("Trigger Commit should not be repeated.");
                }


                //Handling Src Commit
                if (src==null) {
                    srcData = new CommitNode(prevCommit);
                    src = new Node(srcData);
                    commits.get(projectName).put(prevCommit, src);

                }

                src.addChild(dest);
                trees.get(projectName).setRoot(src);

            } else {

            }

        }
        String[] fields = {"tr_build_id", "git_prev_built_commit", "git_trigger_commit", "tr_status", "gh_project_name"};

        //Second iteration


        Iterator it = trees.entrySet().iterator();
        while (it.hasNext()) {
            Map.Entry pair = (Map.Entry) it.next();
            String projectname =  (String)pair.getKey();
            System.out.println("\nProcessing: " +projectname);
            Tree ctree = (Tree) pair.getValue();
            HashMap<String, Node> hm = commits.get(projectname);
            ArrayList<Node> selectedNodes = findPotentialStartPoints(hm);

            for (Node n : selectedNodes) {
                ctree.setRoot(n);
                ArrayList<ArrayList> ps =  new ArrayList<ArrayList>();
                try {
                   ps = ctree.getPathsFromRootToAnyLeaf();
                } catch (java.lang.StackOverflowError e) {
                    e.printStackTrace();
                }


                trimPaths(ps);
                removeRedundantPaths(ps);

                for (ArrayList x : ps){
                    ArrayList nodes = x;
                    if (nodes.size()>1){
                        CommitNode start = (CommitNode) ((Node)nodes.get(0)).getData();
                        CommitNode end = (CommitNode) ((Node)nodes.get(nodes.size()-1)).getData();
                        int length = nodes.size();
                        long diff = 0;
                        if (end.status.equals("passed")) {
                            diff = end.buildTime.getTime() - start.buildTime.getTime();
                            length--;
                        }
                        long minutes = Math.abs(TimeUnit.MILLISECONDS.toSeconds(diff)/60);
                        for (Object a : nodes){
                            System.out.println(((CommitNode)((Node)a).getData()).buildID);
                        }
                        System.out.printf("%s,%s,%s,%s,%s,%s\n",start.label,projectname,String.valueOf(length),String.valueOf(minutes),start.buildID,end.buildID);
                    }
                }
            }

            it.remove();
        }

    }

    private static ArrayList<Node> findPotentialStartPoints(HashMap<String, Node> hm) {
        ArrayList<Node> selectedNodes = new ArrayList<Node>();
        Iterator it = hm.entrySet().iterator();
        while (it.hasNext()) {
            Map.Entry pair = (Map.Entry) it.next();
            Node n = (Node) pair.getValue();
            CommitNode nd = (CommitNode) n.getData();
            if (nd.status != null && nd.status.equals("passed")){
                for (Object x:n.getChildren()){
                    CommitNode cdata = (CommitNode)((Node) x).getData();
                    if (cdata.status != null && !cdata.status.equals("passed")){
                        selectedNodes.add((Node)x);
                    }
                }
            }
        }
        return selectedNodes;
    }

    private static void trimPaths(ArrayList paths) {
        for (Object x : paths){
            ArrayList nodes = (ArrayList) x;

            for (int i = 0; i < nodes.size(); i ++) {
                Node n = (Node)nodes.get(i);
                CommitNode cn = (CommitNode) n.getData();
                if (cn.status == null || cn.status.equals("passed")){
                    nodes.subList(i+1, nodes.size()).clear();
                }
            }
        }
    }

    static String trimQuotes(String s) {
        if (s.startsWith("\"")) {
            s = s.substring(1, s.length() - 1);
        }
        return s;
    }

    static void removeRedundantPaths(ArrayList paths) {
        int size = paths.size();

        // not using a method in the check also speeds up the execution
        // also i must be less that size-1 so that j doesn't
        // throw IndexOutOfBoundsException
        for (int i = 0; i < size - 1; i++) {
            // start from the next item after strings[i]
            // since the ones before are checked
            for (int j = i + 1; j < size; j++) {
                // no need for if ( i == j ) here
                if (!paths.get(j).equals(paths.get(i)))
                    continue;
                paths.remove(j);
                // decrease j because the array got re-indexed
                j--;
                // decrease the size of the array
                size--;
            } // for j
        }
    }


}