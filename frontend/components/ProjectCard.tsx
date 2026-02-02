"use client";

import { motion } from "framer-motion";
import Link from "next/link";
import { Users, DollarSign, Clock, TrendingUp } from "lucide-react";
import { Card } from "./ui/Card";

interface ProjectCardProps {
  project: {
    id: number;
    name: string;
    description: string;
    budget: number;
    timeLeft: string;
    applicants: number;
    status: string;
    tags: string[];
  };
  index?: number;
}

export function ProjectCard({ project, index = 0 }: ProjectCardProps) {
  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ delay: index * 0.1 }}
      whileHover={{ y: -4 }}
    >
      <Link href={`/projects/${project.id}`}>
        <Card className="p-6 cursor-pointer group overflow-hidden relative">
          {/* Animated gradient background on hover */}
          <div className="absolute inset-0 bg-gradient-to-br from-blue-500/0 to-cyan-500/0 group-hover:from-blue-500/5 group-hover:to-cyan-500/5 transition-all duration-500" />
          
          <div className="relative">
            {/* Header */}
            <div className="flex items-start justify-between mb-4">
              <div className="flex-1">
                <h3 className="text-xl font-semibold mb-2 group-hover:text-blue-400 transition-colors">
                  {project.name}
                </h3>
                <p className="text-sm text-gray-400 leading-relaxed line-clamp-2">
                  {project.description}
                </p>
              </div>
              <motion.div
                whileHover={{ scale: 1.1 }}
                whileTap={{ scale: 0.9 }}
                className={`px-3 py-1 rounded-full text-xs font-medium ${
                  project.status === 'recruiting' 
                    ? 'bg-blue-500/10 text-blue-400 border border-blue-500/20'
                    : 'bg-green-500/10 text-green-400 border border-green-500/20'
                }`}
              >
                {project.status}
              </motion.div>
            </div>

            {/* Tags */}
            <div className="flex flex-wrap gap-2 mb-4">
              {project.tags.map((tag) => (
                <motion.span
                  key={tag}
                  whileHover={{ scale: 1.05 }}
                  className="px-3 py-1 rounded-lg bg-white/5 text-xs text-gray-400 border border-white/5 hover:border-blue-500/30 hover:text-blue-400 transition-colors"
                >
                  {tag}
                </motion.span>
              ))}
            </div>

            {/* Stats Grid */}
            <div className="grid grid-cols-3 gap-4 pt-4 border-t border-white/5">
              <div className="group/stat">
                <div className="flex items-center gap-1.5 text-sm text-gray-400 mb-1">
                  <DollarSign className="w-4 h-4 group-hover/stat:text-green-400 transition-colors" />
                  <span className="text-xs">Budget</span>
                </div>
                <div className="font-semibold text-green-400">
                  ${project.budget.toLocaleString()}
                </div>
              </div>
              <div className="group/stat">
                <div className="flex items-center gap-1.5 text-sm text-gray-400 mb-1">
                  <Users className="w-4 h-4 group-hover/stat:text-blue-400 transition-colors" />
                  <span className="text-xs">Agents</span>
                </div>
                <div className="font-semibold">{project.applicants}</div>
              </div>
              <div className="group/stat">
                <div className="flex items-center gap-1.5 text-sm text-gray-400 mb-1">
                  <Clock className="w-4 h-4 group-hover/stat:text-yellow-400 transition-colors" />
                  <span className="text-xs">Left</span>
                </div>
                <div className="font-semibold text-sm">{project.timeLeft}</div>
              </div>
            </div>
          </div>
        </Card>
      </Link>
    </motion.div>
  );
}
