"use client";

import { useWriteContract, useWaitForTransactionReceipt } from "wagmi";
import { CONTRACTS, PROJECT_REGISTRY_ABI, ProjectState } from "@/lib/contracts";
import { Button } from "@/components/ui/Button";
import { Play, CheckCircle, XCircle, Users } from "lucide-react";

export function ProjectActions({ 
  projectId, 
  currentState 
}: { 
  projectId: number;
  currentState: number;
}) {
  const { writeContract, data: hash, isPending } = useWriteContract();
  const { isLoading: isConfirming } = useWaitForTransactionReceipt({ hash });

  const handleStartRecruiting = () => {
    writeContract({
      address: CONTRACTS.ProjectRegistry,
      abi: PROJECT_REGISTRY_ABI,
      functionName: "startRecruiting",
      args: [BigInt(projectId)],
    });
  };

  const handleStartProject = () => {
    writeContract({
      address: CONTRACTS.ProjectRegistry,
      abi: PROJECT_REGISTRY_ABI,
      functionName: "startProject",
      args: [BigInt(projectId)],
    });
  };

  const handleCompleteProject = () => {
    writeContract({
      address: CONTRACTS.ProjectRegistry,
      abi: PROJECT_REGISTRY_ABI,
      functionName: "completeProject",
      args: [BigInt(projectId)],
    });
  };

  const handleCancelProject = () => {
    if (!confirm("Are you sure you want to cancel this project? This action cannot be undone.")) {
      return;
    }
    writeContract({
      address: CONTRACTS.ProjectRegistry,
      abi: PROJECT_REGISTRY_ABI,
      functionName: "cancelProject",
      args: [BigInt(projectId)],
    });
  };

  const isProcessing = isPending || isConfirming;

  return (
    <div className="flex flex-wrap gap-2">
      {currentState === ProjectState.Draft && (
        <Button 
          onClick={handleStartRecruiting}
          disabled={isProcessing}
          className="group"
        >
          <Users className="w-4 h-4 mr-2" />
          Start Recruiting
        </Button>
      )}

      {currentState === ProjectState.Recruiting && (
        <Button 
          onClick={handleStartProject}
          disabled={isProcessing}
          className="group"
        >
          <Play className="w-4 h-4 mr-2" />
          Start Project
        </Button>
      )}

      {currentState === ProjectState.Active && (
        <Button 
          onClick={handleCompleteProject}
          disabled={isProcessing}
          className="group"
        >
          <CheckCircle className="w-4 h-4 mr-2" />
          Complete Project
        </Button>
      )}

      {(currentState === ProjectState.Draft || 
        currentState === ProjectState.Recruiting) && (
        <Button 
          onClick={handleCancelProject}
          disabled={isProcessing}
          variant="outline"
          className="text-red-500 hover:text-red-600"
        >
          <XCircle className="w-4 h-4 mr-2" />
          Cancel Project
        </Button>
      )}
    </div>
  );
}
