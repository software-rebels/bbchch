package ca.mcgill.softwarerebels;

import java.io.File;
import java.io.IOException;
import java.nio.charset.Charset;
import java.util.*;

import org.apache.commons.io.FileUtils;

public class Main {
    /**
     * @param args
     */
    static List<String> projectList;
    static List<String> commitList;
    static File projectsfile;
    static File cgfile;

    public static void main(String[] args) {


        Graph g = new Graph();
        HashMap graphs = new HashMap();
        HashMap commits = new HashMap();

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
                graphs.put(projectID, new Graph());
            }
        }
        System.out.printf("project count %s\n", i);

        //First iteration
        for (String commitLine : commitList) {
            String[] commitData = commitLine.split(",");
            String buildID = trimQuotes(commitData[1]);
            String triggerCommit = trimQuotes(commitData[0]).substring(0, 8);
            String buildStatus = trimQuotes(commitData[3]);
            String projectName = trimQuotes(commitData[4]);

            if (graphs.containsKey(projectName)) {
                CommitNode dest = null;
                Graph commitGraph = (Graph) graphs.get(projectName);
                if (commits.containsKey(triggerCommit)) {
                    System.out.printf("Duplicate commit found %s!!%s\n", triggerCommit, buildID);
                } else {
                    dest = new CommitNode(triggerCommit, buildID, buildStatus);
                    commits.put(triggerCommit, dest);
                }
                if (!commitGraph.nodes.contains(dest)) {
                    commitGraph.addNode(dest);
                }
            } else {
                System.out.printf("1Project skipped.. %s\n", projectName);
            }

        }
        String[] fields = {"tr_build_id", "git_prev_built_commit", "git_trigger_commit", "tr_status", "gh_project_name"};

        //Second iteration
        int counter = 0;
        for (String commitLine : commitList) {
            System.out.println(counter++);
            String[] commitData = commitLine.split(",");
            String prevCommit = trimQuotes(commitData[2]);
            if (prevCommit.length() > 8) {
                prevCommit = prevCommit.substring(0, 8);
            }
            String triggerCommit = trimQuotes(commitData[0]).substring(0, 8);
            String projectName = trimQuotes(commitData[4]);
            System.out.println(commitLine);
            if (graphs.containsKey(projectName)) {
                Graph commitGraph = (Graph) graphs.get(projectName);
                CommitNode source = null;
                CommitNode dest = null;
                if (commits.containsKey(prevCommit)) {
                    source = (CommitNode) commits.get(prevCommit);
                } else {
                    System.out.printf("Source not found.. %s\n", prevCommit);
                    continue;
                }

                if (commits.containsKey(triggerCommit)) {
                    dest = (CommitNode) commits.get(triggerCommit);
                } else {
                    System.out.printf("Destination not found.. %s\n", triggerCommit);
                    continue;
                }
                if (!commitGraph.nodes.contains(source) || !commitGraph.nodes.contains(dest)) {
                    System.out.printf("Source or Destination not found.. %s %s\n", prevCommit, triggerCommit);
                    continue;
                }
                //if (!commitGraph.nodes.contains(dest)) {commitGraph.addNode(dest);}
                System.out.printf("gsize %s : %s -> %s\n", commitGraph.nodes.size(), source, dest);
                System.out.printf("%s -> %s\n", commitGraph.nodes.indexOf(source), commitGraph.nodes.indexOf(dest));
                commitGraph.connectNode(source, dest);


            } else {
                System.out.printf("2Project skipped.. %s\n", projectName);
            }
        }

        Iterator it = graphs.entrySet().iterator();
        while (it.hasNext()) {
            Map.Entry pair = (Map.Entry) it.next();
            System.out.println("\nProcessing: " + pair.getKey());
            Graph cgraph = (Graph) pair.getValue();
            for (Object cnode : cgraph.nodes) {
                CommitNode cn = (CommitNode) cnode;
                if (cn != null && cn.status != null && !cn.status.equals("passed")) {
                    cgraph.setRootNode(cn);
                    cgraph.bfs();
                }
            }
            it.remove();
        }

    }

    static String trimQuotes(String s) {
        if (s.startsWith("\"")) {
            s = s.substring(1, s.length() - 1);
        }
        return s;
    }


}