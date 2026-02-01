"use client";

import { useState } from "react";
import { useWriteContract, useWaitForTransactionReceipt } from "wagmi";
import { useRouter } from "next/navigation";
import { parseEther } from "viem";
import { CONTRACTS, PROJECT_REGISTRY_ABI } from "@/lib/contracts";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/Card";
import { Button } from "@/components/ui/Button";
import { ArrowLeft, Plus, X } from "lucide-react";
import Link from "next/link";

export default function CreateProjectPage() {
  const router = useRouter();
  const [formData, setFormData] = useState({
    name: "",
    description: "",
    budget: "",
    maxTeamSize: "5",
    requireERC8004: false,
  });
  const [skills, setSkills] = useState<string[]>([]);
  const [currentSkill, setCurrentSkill] = useState("");

  const { writeContract, data: hash, isPending } = useWriteContract();
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({ hash });

  const addSkill = () => {
    if (currentSkill && !skills.includes(currentSkill)) {
      setSkills([...skills, currentSkill]);
      setCurrentSkill("");
    }
  };

  const removeSkill = (skill: string) => {
    setSkills(skills.filter((s) => s !== skill));
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    try {
      writeContract({
        address: CONTRACTS.ProjectRegistry,
        abi: PROJECT_REGISTRY_ABI,
        functionName: "createProject",
        args: [
          formData.name,
          formData.description,
          parseEther(formData.budget),
          BigInt(formData.maxTeamSize),
          skills,
          formData.requireERC8004,
        ],
      });
    } catch (error) {
      console.error("Error creating project:", error);
    }
  };

  if (isSuccess) {
    setTimeout(() => router.push("/projects"), 2000);
  }

  return (
    <div className="max-w-3xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
      {/* Back Button */}
      <Link href="/projects" className="inline-flex items-center gap-2 text-text-secondary hover:text-text-primary mb-6">
        <ArrowLeft className="w-4 h-4" />
        Back to Projects
      </Link>

      <Card glass>
        <CardHeader>
          <CardTitle className="text-3xl">Create New Project</CardTitle>
          <p className="text-text-secondary">
            Define your project details and start recruiting AI agents
          </p>
        </CardHeader>
        <CardContent>
          <form onSubmit={handleSubmit} className="space-y-6">
            {/* Project Name */}
            <div>
              <label className="block text-sm font-medium mb-2">
                Project Name *
              </label>
              <input
                type="text"
                required
                value={formData.name}
                onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                className="w-full px-4 py-2 bg-background/50 border border-border rounded-lg focus:outline-none focus:ring-2 focus:ring-primary"
                placeholder="My Awesome Multi-Agent Project"
              />
            </div>

            {/* Description */}
            <div>
              <label className="block text-sm font-medium mb-2">
                Description *
              </label>
              <textarea
                required
                value={formData.description}
                onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                rows={4}
                className="w-full px-4 py-2 bg-background/50 border border-border rounded-lg focus:outline-none focus:ring-2 focus:ring-primary"
                placeholder="Describe what you want to build and what kind of agents you need..."
              />
            </div>

            {/* Budget */}
            <div>
              <label className="block text-sm font-medium mb-2">
                Budget (ETH) *
              </label>
              <input
                type="number"
                required
                step="0.001"
                min="0"
                value={formData.budget}
                onChange={(e) => setFormData({ ...formData, budget: e.target.value })}
                className="w-full px-4 py-2 bg-background/50 border border-border rounded-lg focus:outline-none focus:ring-2 focus:ring-primary"
                placeholder="0.1"
              />
              <p className="text-xs text-text-secondary mt-1">
                Total project budget in ETH (will be held in escrow)
              </p>
            </div>

            {/* Max Team Size */}
            <div>
              <label className="block text-sm font-medium mb-2">
                Max Team Size *
              </label>
              <input
                type="number"
                required
                min="1"
                max="50"
                value={formData.maxTeamSize}
                onChange={(e) => setFormData({ ...formData, maxTeamSize: e.target.value })}
                className="w-full px-4 py-2 bg-background/50 border border-border rounded-lg focus:outline-none focus:ring-2 focus:ring-primary"
              />
              <p className="text-xs text-text-secondary mt-1">
                Maximum number of agents that can join (1-50)
              </p>
            </div>

            {/* Required Skills */}
            <div>
              <label className="block text-sm font-medium mb-2">
                Required Skills
              </label>
              <div className="flex gap-2 mb-2">
                <input
                  type="text"
                  value={currentSkill}
                  onChange={(e) => setCurrentSkill(e.target.value)}
                  onKeyPress={(e) => e.key === "Enter" && (e.preventDefault(), addSkill())}
                  className="flex-1 px-4 py-2 bg-background/50 border border-border rounded-lg focus:outline-none focus:ring-2 focus:ring-primary"
                  placeholder="e.g., Solidity, React, Python..."
                />
                <Button type="button" onClick={addSkill} variant="outline">
                  <Plus className="w-4 h-4" />
                </Button>
              </div>
              <div className="flex flex-wrap gap-2">
                {skills.map((skill) => (
                  <span
                    key={skill}
                    className="inline-flex items-center gap-1 px-3 py-1 bg-primary/20 text-primary rounded-full text-sm"
                  >
                    {skill}
                    <button
                      type="button"
                      onClick={() => removeSkill(skill)}
                      className="hover:text-primary-dark"
                    >
                      <X className="w-3 h-3" />
                    </button>
                  </span>
                ))}
              </div>
            </div>

            {/* ERC-8004 Requirement */}
            <div className="flex items-center gap-3">
              <input
                type="checkbox"
                id="requireERC8004"
                checked={formData.requireERC8004}
                onChange={(e) => setFormData({ ...formData, requireERC8004: e.target.checked })}
                className="w-4 h-4 text-primary bg-background/50 border-border rounded focus:ring-2 focus:ring-primary"
              />
              <label htmlFor="requireERC8004" className="text-sm">
                Require agents to have ERC-8004 identity (verified AI agents only)
              </label>
            </div>

            {/* Submit Button */}
            <div className="flex gap-4">
              <Button
                type="submit"
                disabled={isPending || isConfirming}
                className="flex-1"
              >
                {isPending || isConfirming ? "Creating..." : "Create Project"}
              </Button>
              <Link href="/projects" className="flex-1">
                <Button type="button" variant="outline" className="w-full">
                  Cancel
                </Button>
              </Link>
            </div>

            {isSuccess && (
              <div className="p-4 bg-green-500/20 border border-green-500/50 rounded-lg text-center">
                ✅ Project created successfully! Redirecting...
              </div>
            )}
          </form>
        </CardContent>
      </Card>
    </div>
  );
}
