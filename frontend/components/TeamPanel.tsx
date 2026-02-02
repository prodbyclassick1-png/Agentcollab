"use client";

import { useState } from "react";
import { useReadContract, useWriteContract, useWaitForTransactionReceipt, useAccount } from "wagmi";
import { CONTRACTS, TEAM_REGISTRY_ABI, ProjectState } from "@/lib/contracts";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/Card";
import { Button } from "@/components/ui/Button";
import { Users, UserPlus, CheckCircle, XCircle, Clock } from "lucide-react";

export function TeamPanel({ 
  projectId,
  isOwner,
  projectState
}: { 
  projectId: number;
  isOwner: boolean;
  projectState: number;
}) {
  const { address } = useAccount();
  const [showApplyForm, setShowApplyForm] = useState(false);

  const { data: teamMembers, refetch: refetchTeam } = useReadContract({
    address: CONTRACTS.TeamRegistry,
    abi: TEAM_REGISTRY_ABI,
    functionName: "getTeamMembers",
    args: [BigInt(projectId)],
  });

  const { data: pendingApplications, refetch: refetchApplications } = useReadContract({
    address: CONTRACTS.TeamRegistry,
    abi: TEAM_REGISTRY_ABI,
    functionName: "getPendingApplications",
    args: [BigInt(projectId)],
  });

  const isTeamMember = teamMembers?.some(
    (member) => address && member.toLowerCase() === address.toLowerCase()
  );

  const hasPendingApplication = pendingApplications?.some(
    (applicant) => address && applicant.toLowerCase() === address.toLowerCase()
  );

  const canApply = !isOwner && !isTeamMember && !hasPendingApplication && 
                   projectState === ProjectState.Recruiting;

  return (
    <div className="space-y-6">
      {/* Team Members */}
      <Card glass>
        <CardHeader>
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <Users className="w-5 h-5" />
              <CardTitle>Team Members</CardTitle>
            </div>
            <span className="text-2xl font-bold">{teamMembers?.length || 0}</span>
          </div>
        </CardHeader>
        <CardContent>
          {!teamMembers || teamMembers.length === 0 ? (
            <p className="text-sm text-text-secondary text-center py-4">
              No team members yet
            </p>
          ) : (
            <div className="space-y-2">
              {teamMembers.map((member, i) => (
                <div 
                  key={i}
                  className="flex items-center justify-between p-3 bg-background/50 rounded-lg"
                >
                  <div className="flex items-center gap-3">
                    <div className="w-8 h-8 rounded-full bg-gradient-primary flex items-center justify-center text-sm font-bold">
                      {member.slice(2, 4).toUpperCase()}
                    </div>
                    <div>
                      <div className="text-sm font-medium">
                        {member.slice(0, 6)}...{member.slice(-4)}
                      </div>
                    </div>
                  </div>
                  {isOwner && (
                    <CheckCircle className="w-4 h-4 text-green-500" />
                  )}
                </div>
              ))}
            </div>
          )}
        </CardContent>
      </Card>

      {/* Pending Applications (Owner View) */}
      {isOwner && pendingApplications && pendingApplications.length > 0 && (
        <Card glass>
          <CardHeader>
            <CardTitle>Pending Applications</CardTitle>
            <CardDescription>{pendingApplications.length} agent(s) waiting</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="space-y-2">
              {pendingApplications.map((applicant, i) => (
                <ApplicationCard 
                  key={i}
                  projectId={projectId}
                  applicant={applicant}
                  onUpdate={() => {
                    refetchApplications();
                    refetchTeam();
                  }}
                />
              ))}
            </div>
          </CardContent>
        </Card>
      )}

      {/* Apply Button */}
      {canApply && (
        <div>
          {!showApplyForm ? (
            <Button 
              onClick={() => setShowApplyForm(true)}
              className="w-full"
            >
              <UserPlus className="w-4 h-4 mr-2" />
              Apply to Join Team
            </Button>
          ) : (
            <ApplyForm 
              projectId={projectId}
              onSuccess={() => {
                setShowApplyForm(false);
                refetchApplications();
              }}
              onCancel={() => setShowApplyForm(false)}
            />
          )}
        </div>
      )}

      {hasPendingApplication && (
        <Card glass className="bg-blue-500/10 border-blue-500/30">
          <CardContent className="text-center py-6">
            <Clock className="w-8 h-8 text-blue-500 mx-auto mb-2" />
            <p className="text-sm text-blue-500 font-medium">
              Your application is pending review
            </p>
          </CardContent>
        </Card>
      )}
    </div>
  );
}

function ApplicationCard({ 
  projectId, 
  applicant,
  onUpdate
}: { 
  projectId: number;
  applicant: string;
  onUpdate: () => void;
}) {
  const { writeContract, data: hash, isPending } = useWriteContract();
  const { isSuccess } = useWaitForTransactionReceipt({ hash });

  const handleAccept = () => {
    writeContract({
      address: CONTRACTS.TeamRegistry,
      abi: TEAM_REGISTRY_ABI,
      functionName: "acceptApplication",
      args: [BigInt(projectId), applicant as `0x${string}`],
    });
  };

  if (isSuccess) {
    setTimeout(onUpdate, 1000);
  }

  return (
    <div className="flex items-center justify-between p-3 bg-background/50 rounded-lg">
      <div className="flex items-center gap-3">
        <div className="w-8 h-8 rounded-full bg-gradient-primary flex items-center justify-center text-sm font-bold">
          {applicant.slice(2, 4).toUpperCase()}
        </div>
        <div>
          <div className="text-sm font-medium">
            {applicant.slice(0, 6)}...{applicant.slice(-4)}
          </div>
        </div>
      </div>
      <div className="flex gap-2">
        <Button 
          size="sm" 
          onClick={handleAccept}
          disabled={isPending}
        >
          <CheckCircle className="w-4 h-4 mr-1" />
          Accept
        </Button>
      </div>
    </div>
  );
}

function ApplyForm({ 
  projectId,
  onSuccess,
  onCancel
}: { 
  projectId: number;
  onSuccess: () => void;
  onCancel: () => void;
}) {
  const [portfolio, setPortfolio] = useState("");
  const [skills, setSkills] = useState<string[]>([]);
  const [currentSkill, setCurrentSkill] = useState("");

  const { writeContract, data: hash, isPending } = useWriteContract();
  const { isSuccess } = useWaitForTransactionReceipt({ hash });

  const addSkill = () => {
    if (currentSkill && !skills.includes(currentSkill)) {
      setSkills([...skills, currentSkill]);
      setCurrentSkill("");
    }
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    
    writeContract({
      address: CONTRACTS.TeamRegistry,
      abi: TEAM_REGISTRY_ABI,
      functionName: "applyToProject",
      args: [
        BigInt(projectId),
        portfolio,
        skills,
        BigInt(0), // No ERC-8004 token for now
      ],
    });
  };

  if (isSuccess) {
    setTimeout(onSuccess, 1000);
  }

  return (
    <Card glass>
      <CardHeader>
        <CardTitle>Apply to Project</CardTitle>
        <CardDescription>Tell the owner why you're a good fit</CardDescription>
      </CardHeader>
      <CardContent>
        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="block text-sm font-medium mb-1">Portfolio URL</label>
            <input
              type="url"
              required
              value={portfolio}
              onChange={(e) => setPortfolio(e.target.value)}
              className="w-full px-3 py-2 bg-background/50 border border-border rounded-lg focus:outline-none focus:ring-2 focus:ring-primary text-sm"
              placeholder="https://..."
            />
          </div>
          <div>
            <label className="block text-sm font-medium mb-1">Skills</label>
            <div className="flex gap-2 mb-2">
              <input
                type="text"
                value={currentSkill}
                onChange={(e) => setCurrentSkill(e.target.value)}
                onKeyPress={(e) => e.key === "Enter" && (e.preventDefault(), addSkill())}
                className="flex-1 px-3 py-2 bg-background/50 border border-border rounded-lg focus:outline-none focus:ring-2 focus:ring-primary text-sm"
                placeholder="Add a skill..."
              />
              <Button type="button" onClick={addSkill} size="sm">
                Add
              </Button>
            </div>
            <div className="flex flex-wrap gap-2">
              {skills.map((skill) => (
                <span
                  key={skill}
                  className="inline-flex items-center px-2 py-1 bg-primary/20 text-primary rounded-full text-xs"
                >
                  {skill}
                </span>
              ))}
            </div>
          </div>
          <div className="flex gap-2">
            <Button type="submit" disabled={isPending} className="flex-1">
              {isPending ? "Applying..." : "Submit Application"}
            </Button>
            <Button type="button" onClick={onCancel} variant="outline">
              Cancel
            </Button>
          </div>
        </form>
      </CardContent>
    </Card>
  );
}
