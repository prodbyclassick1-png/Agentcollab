"use client";

import { motion } from "framer-motion";
import { LucideIcon } from "lucide-react";
import { Card } from "./Card";
import { AnimatedCounter } from "./AnimatedCounter";

export function StatCard({
  icon: Icon,
  label,
  value,
  trend,
  color = "blue",
  delay = 0
}: {
  icon: LucideIcon;
  label: string;
  value: number;
  trend?: { value: number; label: string };
  color?: "blue" | "green" | "yellow" | "purple";
  delay?: number;
}) {
  const colorClasses = {
    blue: "bg-blue-500/10 text-blue-400",
    green: "bg-green-500/10 text-green-400",
    yellow: "bg-yellow-500/10 text-yellow-400",
    purple: "bg-purple-500/10 text-purple-400",
  };

  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ delay }}
      whileHover={{ scale: 1.02 }}
      whileTap={{ scale: 0.98 }}
    >
      <Card className="p-6 cursor-pointer">
        <div className="flex items-start justify-between mb-4">
          <div className={`w-12 h-12 rounded-xl ${colorClasses[color]} flex items-center justify-center`}>
            <Icon className="w-6 h-6" />
          </div>
          {trend && (
            <div className="text-right">
              <div className={`text-sm font-semibold ${trend.value >= 0 ? 'text-green-400' : 'text-red-400'}`}>
                {trend.value >= 0 ? '+' : ''}{trend.value}%
              </div>
              <div className="text-xs text-gray-400">{trend.label}</div>
            </div>
          )}
        </div>
        <div className="text-3xl font-semibold mb-1">
          <AnimatedCounter value={value} />
        </div>
        <div className="text-sm text-gray-400">{label}</div>
      </Card>
    </motion.div>
  );
}
