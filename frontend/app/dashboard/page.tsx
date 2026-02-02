"use client";

import { motion } from "framer-motion";
import Link from "next/link";
import { Users, TrendingUp, DollarSign, CheckCircle, Clock, ArrowRight } from "lucide-react";
import { Card } from "@/components/ui/Card";
import { LineChart, Line, AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts';
import { useAccount } from 'wagmi';
import { useUserProjects } from '@/hooks/useProjects';

export default function Dashboard() {
  const { address, isConnected } = useAccount();
  const { projects, isLoading } = useUserProjects(address);
  // Mock data - will connect to contracts later
  const stats = {
    totalEarnings: 1247.50,
    weeklyProfit: 186.25,
    weeklyGrowth: 12.5,
    activeProjects: 3,
    completedTasks: 12,
    reputation: 4.8
  };

  const weeklyData = [
    { day: 'Mon', earnings: 124 },
    { day: 'Tue', earnings: 215 },
    { day: 'Wed', earnings: 98 },
    { day: 'Thu', earnings: 167 },
    { day: 'Fri', earnings: 289 },
    { day: 'Sat', earnings: 142 },
    { day: 'Sun', earnings: 201 },
  ];

  const recentTransactions = [
    { id: 1, project: "AI Content Generator", amount: 125.00, date: "2 hours ago", status: "completed" },
    { id: 2, project: "Smart Contract Audit", amount: 350.00, date: "1 day ago", status: "completed" },
    { id: 3, project: "Frontend Development", amount: 89.50, date: "3 days ago", status: "pending" },
  ];

  const activeProjects = [
    { id: 1, name: "DeFi Dashboard", progress: 75, earnings: 450.00, deadline: "2 days" },
    { id: 2, name: "NFT Marketplace", progress: 40, earnings: 680.00, deadline: "1 week" },
    { id: 3, name: "DAO Tools", progress: 90, earnings: 320.00, deadline: "3 days" },
  ];

  return (
    <main className="min-h-screen py-8 lg:py-12">
      <div className="container-wide px-6 sm:px-8 lg:px-12">
        {/* Header */}
        <div className="mb-10 lg:mb-16">
          <div className="flex items-center justify-between">
            <div>
              <h1 className="text-3xl font-semibold mb-2">Dashboard</h1>
              <p className="text-gray-400">
                {isConnected ? 'Your earnings and projects' : 'Connect wallet to see your data'}
              </p>
            </div>
            {!isConnected && (
              <div className="px-4 py-2 rounded-xl bg-blue-500/10 border border-blue-500/20 text-sm text-blue-400">
                Demo Mode
              </div>
            )}
          </div>
        </div>

        {/* Balance Card */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="mb-8 lg:mb-10"
        >
          <Card className="p-6 bg-gradient-to-br from-blue-500/10 to-cyan-500/10 border-blue-500/20">
            <div className="flex items-center justify-between mb-4">
              <span className="text-sm text-gray-400">Total Earnings</span>
              <div className="px-3 py-1 rounded-full bg-green-500/10 text-green-400 text-xs font-medium">
                +{stats.weeklyGrowth}%
              </div>
            </div>
            <div className="mb-2">
              <div className="text-4xl font-semibold mb-1">
                ${stats.totalEarnings.toLocaleString()}
              </div>
              <div className="text-sm text-gray-400">
                Weekly: +${stats.weeklyProfit} <span className="text-green-400">↑</span>
              </div>
            </div>
          </Card>
        </motion.div>

        {/* Quick Stats */}
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-4 lg:gap-6 mb-10 lg:mb-12">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.1 }}
          >
            <Card className="p-4">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-xl bg-blue-500/10 flex items-center justify-center">
                  <Users className="w-5 h-5 text-blue-400" />
                </div>
                <div>
                  <div className="text-2xl font-semibold">{stats.activeProjects}</div>
                  <div className="text-xs text-gray-400">Active</div>
                </div>
              </div>
            </Card>
          </motion.div>

          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.2 }}
          >
            <Card className="p-4">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-xl bg-green-500/10 flex items-center justify-center">
                  <CheckCircle className="w-5 h-5 text-green-400" />
                </div>
                <div>
                  <div className="text-2xl font-semibold">{stats.completedTasks}</div>
                  <div className="text-xs text-gray-400">Completed</div>
                </div>
              </div>
            </Card>
          </motion.div>

          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.3 }}
          >
            <Card className="p-4">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-xl bg-yellow-500/10 flex items-center justify-center">
                  <TrendingUp className="w-5 h-5 text-yellow-400" />
                </div>
                <div>
                  <div className="text-2xl font-semibold">{stats.reputation}</div>
                  <div className="text-xs text-gray-400">Rating</div>
                </div>
              </div>
            </Card>
          </motion.div>

          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.4 }}
          >
            <Card className="p-4">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-xl bg-purple-500/10 flex items-center justify-center">
                  <DollarSign className="w-5 h-5 text-purple-400" />
                </div>
                <div>
                  <div className="text-2xl font-semibold">${stats.weeklyProfit}</div>
                  <div className="text-xs text-gray-400">This Week</div>
                </div>
              </div>
            </Card>
          </motion.div>
        </div>

        {/* Earnings Chart */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.5 }}
          className="mb-8"
        >
          <Card className="p-6">
            <div className="flex items-center justify-between mb-6">
              <div>
                <h2 className="text-lg font-semibold mb-1">Weekly Earnings</h2>
                <p className="text-sm text-gray-400">Last 7 days</p>
              </div>
              <div className="px-3 py-1.5 rounded-full bg-green-500/10 text-green-400 text-sm font-medium">
                +{stats.weeklyGrowth}%
              </div>
            </div>
            <ResponsiveContainer width="100%" height={200}>
              <AreaChart data={weeklyData}>
                <defs>
                  <linearGradient id="earningsGradient" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#0052FF" stopOpacity={0.3}/>
                    <stop offset="95%" stopColor="#0052FF" stopOpacity={0}/>
                  </linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.05)" />
                <XAxis 
                  dataKey="day" 
                  stroke="rgba(255,255,255,0.3)"
                  style={{ fontSize: '12px' }}
                />
                <YAxis 
                  stroke="rgba(255,255,255,0.3)"
                  style={{ fontSize: '12px' }}
                />
                <Tooltip 
                  contentStyle={{ 
                    backgroundColor: 'rgba(17, 17, 27, 0.9)', 
                    border: '1px solid rgba(255, 255, 255, 0.1)',
                    borderRadius: '12px',
                    padding: '8px 12px'
                  }}
                  labelStyle={{ color: '#fff' }}
                />
                <Area 
                  type="monotone" 
                  dataKey="earnings" 
                  stroke="#0052FF" 
                  strokeWidth={2}
                  fill="url(#earningsGradient)" 
                />
              </AreaChart>
            </ResponsiveContainer>
          </Card>
        </motion.div>

        {/* Two Column Layout */}
        <div className="grid lg:grid-cols-2 gap-6">
          {/* Active Projects */}
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.5 }}
          >
            <Card className="p-6">
              <div className="flex items-center justify-between mb-4">
                <h2 className="text-lg font-semibold">Active Projects</h2>
                <Link href="/projects" className="text-sm text-blue-400 hover:text-blue-300">
                  See All
                </Link>
              </div>
              <div className="space-y-4">
                {activeProjects.map((project) => (
                  <div key={project.id} className="flex items-center gap-3">
                    <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-blue-500/20 to-cyan-500/20 flex items-center justify-center flex-shrink-0">
                      <Users className="w-5 h-5 text-blue-400" />
                    </div>
                    <div className="flex-1 min-w-0">
                      <div className="font-medium text-sm mb-1">{project.name}</div>
                      <div className="flex items-center gap-2">
                        <div className="flex-1 h-1.5 bg-white/5 rounded-full overflow-hidden">
                          <div 
                            className="h-full bg-gradient-to-r from-blue-500 to-cyan-500 rounded-full transition-all"
                            style={{ width: `${project.progress}%` }}
                          />
                        </div>
                        <span className="text-xs text-gray-400">{project.progress}%</span>
                      </div>
                    </div>
                    <div className="text-right flex-shrink-0">
                      <div className="font-semibold text-sm">${project.earnings}</div>
                      <div className="text-xs text-gray-400">{project.deadline}</div>
                    </div>
                  </div>
                ))}
              </div>
            </Card>
          </motion.div>

          {/* Recent Transactions */}
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.6 }}
          >
            <Card className="p-6">
              <div className="flex items-center justify-between mb-4">
                <h2 className="text-lg font-semibold">Transactions</h2>
                <button className="text-sm text-gray-400 hover:text-white">
                  Filter
                </button>
              </div>
              <div className="space-y-3">
                {recentTransactions.map((tx) => (
                  <div key={tx.id} className="flex items-center gap-3 p-3 rounded-xl bg-white/[0.02] hover:bg-white/[0.04] transition-colors">
                    <div className={`w-10 h-10 rounded-xl flex items-center justify-center flex-shrink-0 ${
                      tx.status === 'completed' 
                        ? 'bg-green-500/10' 
                        : 'bg-yellow-500/10'
                    }`}>
                      {tx.status === 'completed' ? (
                        <CheckCircle className="w-5 h-5 text-green-400" />
                      ) : (
                        <Clock className="w-5 h-5 text-yellow-400" />
                      )}
                    </div>
                    <div className="flex-1 min-w-0">
                      <div className="font-medium text-sm mb-0.5">{tx.project}</div>
                      <div className="text-xs text-gray-400">{tx.date}</div>
                    </div>
                    <div className="text-right flex-shrink-0">
                      <div className="font-semibold text-green-400">
                        +${tx.amount}
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            </Card>
          </motion.div>
        </div>

        {/* CTA */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.7 }}
          className="mt-6"
        >
          <Link href="/projects">
            <Card className="p-6 hover:bg-white/[0.03] transition-colors cursor-pointer">
              <div className="flex items-center justify-between">
                <div>
                  <h3 className="font-semibold mb-1">Ready for more work?</h3>
                  <p className="text-sm text-gray-400">Browse available projects and start earning</p>
                </div>
                <ArrowRight className="w-6 h-6 text-blue-400" />
              </div>
            </Card>
          </Link>
        </motion.div>
      </div>
    </main>
  );
}
