"use client";

import { motion } from "framer-motion";
import { AreaChart, Area, ResponsiveContainer, Tooltip } from 'recharts';

const data = [
  { value: 420 },
  { value: 680 },
  { value: 520 },
  { value: 890 },
  { value: 720 },
  { value: 1100 },
  { value: 950 },
  { value: 1350 },
  { value: 1180 },
  { value: 1520 },
  { value: 1420 },
  { value: 1850 },
];

export function InteractiveGraph() {
  return (
    <motion.div
      initial={{ opacity: 0, scale: 0.95, rotateX: 10 }}
      animate={{ opacity: 1, scale: 1, rotateX: 0 }}
      transition={{ duration: 0.8, delay: 0.3 }}
      className="relative w-full h-full"
      style={{ transformStyle: "preserve-3d" }}
    >
      {/* 3D Glass Container */}
      <div className="relative glass-3d p-6 sm:p-8 rounded-3xl border border-blue-500/20 overflow-hidden">
        {/* Animated gradient background */}
        <div className="absolute inset-0 bg-gradient-to-br from-blue-500/10 via-cyan-500/10 to-purple-500/10 animate-gradient" />
        
        {/* Floating light effect */}
        <motion.div
          animate={{
            scale: [1, 1.2, 1],
            opacity: [0.3, 0.6, 0.3],
          }}
          transition={{
            duration: 4,
            repeat: Infinity,
            ease: "easeInOut"
          }}
          className="absolute top-0 right-0 w-40 h-40 bg-blue-500/30 rounded-full blur-3xl"
        />
        
        {/* Graph Header */}
        <div className="relative z-10 mb-6">
          <div className="flex items-center justify-between mb-2">
            <motion.h3 
              initial={{ opacity: 0, x: -20 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ delay: 0.5 }}
              className="text-sm font-medium text-gray-400"
            >
              Platform Growth
            </motion.h3>
            <motion.div
              initial={{ opacity: 0, scale: 0 }}
              animate={{ opacity: 1, scale: 1 }}
              transition={{ delay: 0.6 }}
              className="px-3 py-1 rounded-full bg-green-500/10 text-green-400 text-xs font-medium border border-green-500/20"
            >
              +247% ↗
            </motion.div>
          </div>
          <motion.div
            initial={{ opacity: 0, y: 10 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.7 }}
            className="text-3xl sm:text-4xl font-semibold"
          >
            $124,750
          </motion.div>
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ delay: 0.8 }}
            className="text-sm text-gray-400"
          >
            Total Volume
          </motion.div>
        </div>

        {/* Interactive Chart */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.9 }}
          className="relative z-10 h-40 sm:h-48"
        >
          <ResponsiveContainer width="100%" height="100%">
            <AreaChart data={data}>
              <defs>
                <linearGradient id="colorGradient" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%" stopColor="#0052FF" stopOpacity={0.4}/>
                  <stop offset="95%" stopColor="#00D4FF" stopOpacity={0}/>
                </linearGradient>
              </defs>
              <Tooltip
                contentStyle={{
                  backgroundColor: 'rgba(17, 17, 27, 0.95)',
                  border: '1px solid rgba(0, 82, 255, 0.3)',
                  borderRadius: '12px',
                  padding: '8px 12px',
                  backdropFilter: 'blur(20px)',
                }}
                labelStyle={{ display: 'none' }}
                formatter={(value: any) => [`$${value.toLocaleString()}`, '']}
              />
              <Area
                type="monotone"
                dataKey="value"
                stroke="url(#colorGradient)"
                strokeWidth={3}
                fill="url(#colorGradient)"
                animationDuration={1500}
                animationEasing="ease-out"
              />
            </AreaChart>
          </ResponsiveContainer>
        </motion.div>

        {/* Glowing bottom edge */}
        <div className="absolute bottom-0 left-0 right-0 h-px bg-gradient-to-r from-transparent via-blue-500/50 to-transparent" />
      </div>

      {/* 3D Shadow effect */}
      <div className="absolute inset-0 -z-10 blur-2xl opacity-50 bg-gradient-to-br from-blue-500/20 to-cyan-500/20 rounded-3xl transform translate-y-4" />
    </motion.div>
  );
}
