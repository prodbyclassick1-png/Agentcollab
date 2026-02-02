"use client";

import { motion } from "framer-motion";
import Link from "next/link";
import { Users, DollarSign, Clock, TrendingUp, ArrowRight, Filter, Search } from "lucide-react";
import { Card } from "@/components/ui/Card";
import { Button } from "@/components/ui/Button";
import { ProjectCard } from "@/components/ProjectCard";
import { useState } from "react";

export default function ProjectsPage() {
  const [filter, setFilter] = useState("all");

  // Mock projects - will connect to contracts
  const projects = [
    {
      id: 1,
      name: "DeFi Dashboard",
      description: "Build a beautiful dashboard for tracking DeFi positions",
      budget: 2500,
      timeLeft: "5 days",
      applicants: 8,
      status: "recruiting",
      tags: ["Frontend", "React", "Web3"]
    },
    {
      id: 2,
      name: "NFT Marketplace Smart Contracts",
      description: "Audit and optimize NFT marketplace contracts on Base",
      budget: 4200,
      timeLeft: "2 days",
      applicants: 12,
      status: "recruiting",
      tags: ["Solidity", "Security", "Base"]
    },
    {
      id: 3,
      name: "AI Content Generator",
      description: "Create an AI-powered content generation tool",
      budget: 1800,
      timeLeft: "1 week",
      applicants: 5,
      status: "in-progress",
      tags: ["AI", "Python", "API"]
    },
  ];

  return (
    <main className="min-h-screen py-8 lg:py-12">
      <div className="container-tight px-6 sm:px-8 lg:px-12">
        {/* Header */}
        <div className="mb-10 lg:mb-12">
          <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 mb-6">
            <div>
              <h1 className="text-3xl font-semibold mb-2">Projects</h1>
              <p className="text-gray-400">Browse and apply to open projects</p>
            </div>
            <Link href="/projects/create">
              <Button className="btn-premium">
                Create Project
                <ArrowRight className="w-4 h-4 ml-2" />
              </Button>
            </Link>
          </div>

          {/* Filters & Search */}
          <div className="flex flex-col sm:flex-row gap-4">
            <div className="flex-1 relative">
              <Search className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
              <input
                type="text"
                placeholder="Search projects..."
                className="w-full pl-12 pr-4 py-3 bg-white/5 border border-white/10 rounded-xl focus:outline-none focus:border-blue-500/50 transition-colors"
              />
            </div>
            <div className="flex gap-2">
              {["all", "recruiting", "active", "completed"].map((f) => (
                <button
                  key={f}
                  onClick={() => setFilter(f)}
                  className={`px-4 py-3 rounded-xl text-sm font-medium transition-colors ${
                    filter === f
                      ? "bg-blue-500 text-white"
                      : "bg-white/5 text-gray-400 hover:bg-white/10"
                  }`}
                >
                  {f.charAt(0).toUpperCase() + f.slice(1)}
                </button>
              ))}
            </div>
          </div>
        </div>

        {/* Projects Grid */}
        <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
          {projects.map((project, i) => (
            <ProjectCard key={project.id} project={project} index={i} />
          ))}
        </div>

        {/* Empty State */}
        {projects.length === 0 && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            className="text-center py-20"
          >
            <div className="w-16 h-16 mx-auto mb-4 rounded-full bg-white/5 flex items-center justify-center">
              <Users className="w-8 h-8 text-gray-400" />
            </div>
            <h3 className="text-xl font-semibold mb-2">No projects found</h3>
            <p className="text-gray-400 mb-6">Be the first to create a project</p>
            <Link href="/projects/create">
              <Button className="btn-premium">Create Project</Button>
            </Link>
          </motion.div>
        )}
      </div>
    </main>
  );
}
