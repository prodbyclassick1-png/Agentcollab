"use client";

import { use } from "react";
import { useReadContract, useAccount } from "wagmi";
import { CONTRACTS, PROJECT_REGISTRY_ABI, TEAM_REGISTRY_ABI, TASK_MANAGER_ABI, ProjectState } from "@/lib/contracts";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/Card";
import { Button } from "@/components/ui/Button";
import Link from "next/link";
import { ArrowLeft, Users, DollarSign, Clock, CheckCircle, AlertCircle } from "lucide-react";
import { formatEther } from "viem";
import { ProjectActions } from "@/components/ProjectActions";
import { TaskList } from "@/components/TaskList";
import { TeamPanel } from "@/components/TeamPanel";

export default function ProjectDetailPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = use(params);
  const { address } = useAccount();
  const projectId = Number(id);

  const { data: project, isLoading } = useReadContract({
    address: CONTRACTS.ProjectRegistry,
    abi: PROJECT_REGISTRY_ABI,
    functionName: "getProject",
    args: [BigInt(projectId)],
  });

  const { data: teamMembers } = useReadContract({
    address: CONTRACTS.TeamRegistry,
    abi: TEAM_REGISTRY_ABI,
    functionName: "getTeamMembers",
    args: [BigInt(projectId)],
  });

  const { data: taskIds } = useReadContract({
    address: CONTRACTS.TaskManager,
    abi: TASK_MANAGER_ABI,
    functionName: "getProjectTasks",
    args: [BigInt(projectId)],
  });

  if (isLoading) {
    return (
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary mx-auto"></div>
          <p className="mt-4 text-text-secondary">Loading project...</p>
        </div>
      </div>
    );
  }

  if (!project) {
    return (
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
        <Card glass className="text-center py-12">
          <CardContent>
            <AlertCircle className="w-12 h-12 text-red-500 mx-auto mb-4" />
            <h3 className="text-xl font-bold mb-2">Project not found</h3>
            <p className="text-text-secondary mb-6">
              This project doesn't exist or has been removed
            </p>
            <Link href="/projects">
              <Button>Back to Projects</Button>
            </Link>
          </CardContent>
        </Card>
      </div>
    );
  }

  const isOwner = address && address.toLowerCase() === project.owner.toLowerCase();
  const isTeamMember = teamMembers?.some(
    (member) => address && member.toLowerCase() === address.toLowerCase()
  );

  const stateLabels: Record<number, string> = {
    [ProjectState.Draft]: "Draft",
    [ProjectState.Recruiting]: "Recruiting",
    [ProjectState.Active]: "Active",
    [ProjectState.Review]: "Review",
    [ProjectState.Complete]: "Complete",
    [ProjectState.Cancelled]: "Cancelled",
  };

  const stateColors: Record<number, string> = {
    [ProjectState.Draft]: "bg-gray-500/20 text-gray-500",
    [ProjectState.Recruiting]: "bg-blue-500/20 text-blue-500",
    [ProjectState.Active]: "bg-green-500/20 text-green-500",
    [ProjectState.Review]: "bg-yellow-500/20 text-yellow-500",
    [ProjectState.Complete]: "bg-purple-500/20 text-purple-500",
    [ProjectState.Cancelled]: "bg-red-500/20 text-red-500",
  };

  return (
    <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
      {/* Back Button */}
      <Link href="/projects" className="inline-flex items-center gap-2 text-text-secondary hover:text-text-primary mb-6">
        <ArrowLeft className="w-4 h-4" />
        Back to Projects
      </Link>

      {/* Project Header */}
      <div className="mb-8">
        <div className="flex items-start justify-between mb-4">
          <div>
            <div className="flex items-center gap-3 mb-2">
              <h1 className="text-4xl font-bold">{project.name}</h1>
              <span className={`px-3 py-1 rounded-full text-xs font-medium ${stateColors[project.state]}`}>
                {stateLabels[project.state]}
              </span>
            </div>
            <p className="text-text-secondary">{project.description}</p>
          </div>
          {isOwner && (
            <ProjectActions projectId={projectId} currentState={project.state} />
          )}
        </div>

        {/* Stats Grid */}
        <div className="grid md:grid-cols-4 gap-4">
          <Card glass>
            <CardHeader>
              <div className="flex items-center gap-2 text-text-secondary mb-1">
                <DollarSign className="w-4 h-4" />
                <CardDescription>Budget</CardDescription>
              </div>
              <CardTitle className="text-2xl">{formatEther(project.budget)} ETH</CardTitle>
            </CardHeader>
          </Card>
          <Card glass>
            <CardHeader>
              <div className="flex items-center gap-2 text-text-secondary mb-1">
                <Users className="w-4 h-4" />
                <CardDescription>Team Size</CardDescription>
              </div>
              <CardTitle className="text-2xl">
                {project.teamSize.toString()}/{project.maxTeamSize.toString()}
              </CardTitle>
            </CardHeader>
          </Card>
          <Card glass>
            <CardHeader>
              <div className="flex items-center gap-2 text-text-secondary mb-1">
                <CheckCircle className="w-4 h-4" />
                <CardDescription>Tasks</CardDescription>
              </div>
              <CardTitle className="text-2xl">{taskIds?.length || 0}</CardTitle>
            </CardHeader>
          </Card>
          <Card glass>
            <CardHeader>
              <div className="flex items-center gap-2 text-text-secondary mb-1">
                <Clock className="w-4 h-4" />
                <CardDescription>Created</CardDescription>
              </div>
              <CardTitle className="text-2xl">
                {new Date(Number(project.createdAt) * 1000).toLocaleDateString()}
              </CardTitle>
            </CardHeader>
          </Card>
        </div>
      </div>

      {/* Main Content Grid */}
      <div className="grid lg:grid-cols-3 gap-6">
        {/* Tasks Section */}
        <div className="lg:col-span-2">
          <TaskList 
            projectId={projectId} 
            taskIds={taskIds || []}
            isOwner={isOwner || false}
            isTeamMember={isTeamMember || false}
          />
        </div>

        {/* Team Panel */}
        <div>
          <TeamPanel 
            projectId={projectId}
            isOwner={isOwner || false}
            projectState={project.state}
          />
        </div>
      </div>
    </div>
  );
}
