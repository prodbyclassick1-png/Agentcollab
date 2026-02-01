"use client";

import { useState } from "react";
import { useReadContract, useWriteContract, useWaitForTransactionReceipt, useAccount } from "wagmi";
import { CONTRACTS, TASK_MANAGER_ABI, TaskState } from "@/lib/contracts";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/Card";
import { Button } from "@/components/ui/Button";
import { Plus, Clock, CheckCircle, XCircle, AlertCircle } from "lucide-react";
import { formatEther } from "viem";

export function TaskList({ 
  projectId, 
  taskIds,
  isOwner,
  isTeamMember
}: { 
  projectId: number;
  taskIds: readonly bigint[];
  isOwner: boolean;
  isTeamMember: boolean;
}) {
  const [showCreateForm, setShowCreateForm] = useState(false);

  return (
    <div>
      <div className="flex items-center justify-between mb-4">
        <h2 className="text-2xl font-bold">Tasks</h2>
        {isOwner && (
          <Button onClick={() => setShowCreateForm(!showCreateForm)}>
            <Plus className="w-4 h-4 mr-2" />
            {showCreateForm ? "Cancel" : "Create Task"}
          </Button>
        )}
      </div>

      {showCreateForm && (
        <CreateTaskForm projectId={projectId} onSuccess={() => setShowCreateForm(false)} />
      )}

      {taskIds.length === 0 ? (
        <Card glass className="text-center py-12">
          <CardContent>
            <AlertCircle className="w-12 h-12 text-yellow-500 mx-auto mb-4" />
            <h3 className="text-xl font-bold mb-2">No tasks yet</h3>
            <p className="text-text-secondary">
              {isOwner 
                ? "Create your first task to get started"
                : "The project owner hasn't created any tasks yet"}
            </p>
          </CardContent>
        </Card>
      ) : (
        <div className="space-y-4">
          {taskIds.map((taskId) => (
            <TaskCard 
              key={taskId.toString()} 
              taskId={Number(taskId)}
              isOwner={isOwner}
              isTeamMember={isTeamMember}
            />
          ))}
        </div>
      )}
    </div>
  );
}

function CreateTaskForm({ projectId, onSuccess }: { projectId: number; onSuccess: () => void }) {
  const [formData, setFormData] = useState({
    title: "",
    description: "",
    reward: "",
    deadline: "",
  });

  const { writeContract, data: hash, isPending } = useWriteContract();
  const { isSuccess } = useWaitForTransactionReceipt({ hash });

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    
    const deadlineTimestamp = Math.floor(new Date(formData.deadline).getTime() / 1000);
    
    writeContract({
      address: CONTRACTS.TaskManager,
      abi: TASK_MANAGER_ABI,
      functionName: "createTask",
      args: [
        BigInt(projectId),
        formData.title,
        formData.description,
        BigInt(Math.floor(parseFloat(formData.reward) * 1e18)),
        BigInt(deadlineTimestamp),
        [], // No dependencies for now
      ],
    });
  };

  if (isSuccess) {
    setTimeout(onSuccess, 1000);
  }

  return (
    <Card glass className="mb-6">
      <CardHeader>
        <CardTitle>Create New Task</CardTitle>
      </CardHeader>
      <CardContent>
        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="block text-sm font-medium mb-1">Title *</label>
            <input
              type="text"
              required
              value={formData.title}
              onChange={(e) => setFormData({ ...formData, title: e.target.value })}
              className="w-full px-3 py-2 bg-background/50 border border-border rounded-lg focus:outline-none focus:ring-2 focus:ring-primary"
              placeholder="Task title"
            />
          </div>
          <div>
            <label className="block text-sm font-medium mb-1">Description *</label>
            <textarea
              required
              value={formData.description}
              onChange={(e) => setFormData({ ...formData, description: e.target.value })}
              rows={3}
              className="w-full px-3 py-2 bg-background/50 border border-border rounded-lg focus:outline-none focus:ring-2 focus:ring-primary"
              placeholder="Task description and requirements"
            />
          </div>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium mb-1">Reward (ETH) *</label>
              <input
                type="number"
                required
                step="0.001"
                min="0"
                value={formData.reward}
                onChange={(e) => setFormData({ ...formData, reward: e.target.value })}
                className="w-full px-3 py-2 bg-background/50 border border-border rounded-lg focus:outline-none focus:ring-2 focus:ring-primary"
                placeholder="0.01"
              />
            </div>
            <div>
              <label className="block text-sm font-medium mb-1">Deadline *</label>
              <input
                type="datetime-local"
                required
                value={formData.deadline}
                onChange={(e) => setFormData({ ...formData, deadline: e.target.value })}
                className="w-full px-3 py-2 bg-background/50 border border-border rounded-lg focus:outline-none focus:ring-2 focus:ring-primary"
              />
            </div>
          </div>
          <Button type="submit" disabled={isPending}>
            {isPending ? "Creating..." : "Create Task"}
          </Button>
        </form>
      </CardContent>
    </Card>
  );
}

function TaskCard({ 
  taskId,
  isOwner,
  isTeamMember
}: { 
  taskId: number;
  isOwner: boolean;
  isTeamMember: boolean;
}) {
  const { address } = useAccount();
  const { data: task } = useReadContract({
    address: CONTRACTS.TaskManager,
    abi: TASK_MANAGER_ABI,
    functionName: "getTask",
    args: [BigInt(taskId)],
  });

  const { writeContract, isPending } = useWriteContract();

  if (!task) return null;

  const isAssignedToMe = address && task.assignee.toLowerCase() === address.toLowerCase();
  
  const stateColors: Record<number, string> = {
    [TaskState.Open]: "bg-blue-500/20 text-blue-500",
    [TaskState.Assigned]: "bg-yellow-500/20 text-yellow-500",
    [TaskState.Submitted]: "bg-purple-500/20 text-purple-500",
    [TaskState.Approved]: "bg-green-500/20 text-green-500",
    [TaskState.Rejected]: "bg-red-500/20 text-red-500",
    [TaskState.Failed]: "bg-gray-500/20 text-gray-500",
  };

  const stateLabels: Record<number, string> = {
    [TaskState.Open]: "Open",
    [TaskState.Assigned]: "Assigned",
    [TaskState.Submitted]: "Submitted",
    [TaskState.Approved]: "Approved",
    [TaskState.Rejected]: "Rejected",
    [TaskState.Failed]: "Failed",
  };

  const handleApprove = () => {
    writeContract({
      address: CONTRACTS.TaskManager,
      abi: TASK_MANAGER_ABI,
      functionName: "approveTask",
      args: [BigInt(taskId)],
    });
  };

  return (
    <Card glass hover>
      <CardHeader>
        <div className="flex items-start justify-between">
          <div className="flex-1">
            <div className="flex items-center gap-2 mb-1">
              <CardTitle className="text-lg">{task.title}</CardTitle>
              <span className={`px-2 py-0.5 rounded-full text-xs font-medium ${stateColors[task.state]}`}>
                {stateLabels[task.state]}
              </span>
            </div>
            <CardDescription>{task.description}</CardDescription>
          </div>
        </div>
      </CardHeader>
      <CardContent>
        <div className="flex items-center justify-between text-sm">
          <div className="flex items-center gap-4 text-text-secondary">
            <div className="flex items-center gap-1">
              <CheckCircle className="w-4 h-4" />
              {formatEther(task.reward)} ETH
            </div>
            <div className="flex items-center gap-1">
              <Clock className="w-4 h-4" />
              {new Date(Number(task.deadline) * 1000).toLocaleDateString()}
            </div>
          </div>
          
          {isOwner && task.state === TaskState.Submitted && (
            <Button size="sm" onClick={handleApprove} disabled={isPending}>
              <CheckCircle className="w-4 h-4 mr-1" />
              Approve
            </Button>
          )}
          
          {isAssignedToMe && task.state === TaskState.Assigned && (
            <Button size="sm" disabled={isPending}>
              Submit Work
            </Button>
          )}
        </div>
      </CardContent>
    </Card>
  );
}
