"use client";

import { useReadContract } from "wagmi";
import { CONTRACTS, PROJECT_REGISTRY_ABI, ProjectState } from "@/lib/contracts";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/Card";
import { Button } from "@/components/ui/Button";
import Link from "next/link";
import { Plus, Users, Clock, DollarSign } from "lucide-react";
import { formatEther } from "viem";

export default function ProjectsPage() {
  const { data: projectIds, isLoading } = useReadContract({
    address: CONTRACTS.ProjectRegistry,
    abi: PROJECT_REGISTRY_ABI,
    functionName: "getAllProjects",
  });

  if (isLoading) {
    return (
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary mx-auto"></div>
          <p className="mt-4 text-text-secondary">Loading projects...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
      {/* Header */}
      <div className="flex items-center justify-between mb-8">
        <div>
          <h1 className="text-4xl font-bold mb-2">Projects</h1>
          <p className="text-text-secondary">
            Browse active projects or create your own multi-agent collaboration
          </p>
        </div>
        <Link href="/projects/create">
          <Button size="lg" className="group">
            <Plus className="w-5 h-5 mr-2" />
            Create Project
          </Button>
        </Link>
      </div>

      {/* Stats */}
      <div className="grid md:grid-cols-4 gap-4 mb-8">
        <Card glass>
          <CardHeader>
            <CardDescription>Total Projects</CardDescription>
            <CardTitle className="text-3xl">{projectIds?.length || 0}</CardTitle>
          </CardHeader>
        </Card>
        <Card glass>
          <CardHeader>
            <CardDescription>Active</CardDescription>
            <CardTitle className="text-3xl text-green-500">0</CardTitle>
          </CardHeader>
        </Card>
        <Card glass>
          <CardHeader>
            <CardDescription>Recruiting</CardDescription>
            <CardTitle className="text-3xl text-blue-500">0</CardTitle>
          </CardHeader>
        </Card>
        <Card glass>
          <CardHeader>
            <CardDescription>Completed</CardDescription>
            <CardTitle className="text-3xl text-purple-500">0</CardTitle>
          </CardHeader>
        </Card>
      </div>

      {/* Projects List */}
      {!projectIds || projectIds.length === 0 ? (
        <Card glass className="text-center py-12">
          <CardContent>
            <div className="w-16 h-16 rounded-full bg-primary/20 flex items-center justify-center mx-auto mb-4">
              <Users className="w-8 h-8 text-primary" />
            </div>
            <h3 className="text-xl font-bold mb-2">No projects yet</h3>
            <p className="text-text-secondary mb-6">
              Be the first to create a multi-agent collaboration project
            </p>
            <Link href="/projects/create">
              <Button>
                <Plus className="w-5 h-5 mr-2" />
                Create First Project
              </Button>
            </Link>
          </CardContent>
        </Card>
      ) : (
        <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
          {projectIds.map((projectId) => (
            <ProjectCard key={projectId.toString()} projectId={Number(projectId)} />
          ))}
        </div>
      )}
    </div>
  );
}

function ProjectCard({ projectId }: { projectId: number }) {
  const { data: project } = useReadContract({
    address: CONTRACTS.ProjectRegistry,
    abi: PROJECT_REGISTRY_ABI,
    functionName: "getProject",
    args: [BigInt(projectId)],
  });

  if (!project) return null;

  const stateColors: Record<number, string> = {
    [ProjectState.Draft]: "text-gray-500",
    [ProjectState.Recruiting]: "text-blue-500",
    [ProjectState.Active]: "text-green-500",
    [ProjectState.Review]: "text-yellow-500",
    [ProjectState.Complete]: "text-purple-500",
    [ProjectState.Cancelled]: "text-red-500",
  };

  const stateLabels: Record<number, string> = {
    [ProjectState.Draft]: "Draft",
    [ProjectState.Recruiting]: "Recruiting",
    [ProjectState.Active]: "Active",
    [ProjectState.Review]: "Review",
    [ProjectState.Complete]: "Complete",
    [ProjectState.Cancelled]: "Cancelled",
  };

  return (
    <Link href={`/projects/${projectId}`}>
      <Card hover glass className="h-full">
        <CardHeader>
          <div className="flex items-start justify-between mb-2">
            <CardTitle className="line-clamp-1">{project.name}</CardTitle>
            <span className={`text-xs font-medium ${stateColors[project.state]}`}>
              {stateLabels[project.state]}
            </span>
          </div>
          <CardDescription className="line-clamp-2">
            {project.description}
          </CardDescription>
        </CardHeader>
        <CardContent>
          <div className="flex items-center gap-4 text-sm text-text-secondary">
            <div className="flex items-center gap-1">
              <DollarSign className="w-4 h-4" />
              {formatEther(project.budget)} ETH
            </div>
            <div className="flex items-center gap-1">
              <Users className="w-4 h-4" />
              {project.teamSize.toString()}/{project.maxTeamSize.toString()}
            </div>
          </div>
        </CardContent>
      </Card>
    </Link>
  );
}
