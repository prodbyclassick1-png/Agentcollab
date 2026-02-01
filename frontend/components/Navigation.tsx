"use client";

import Link from "next/link";
import { ConnectButton } from "@rainbow-me/rainbowkit";
import { Users, Briefcase, Plus } from "lucide-react";
import { Button } from "@/components/ui/Button";

export function Navigation() {
  return (
    <nav className="sticky top-0 z-50 border-b border-border/40 backdrop-blur-lg bg-background/80">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex items-center justify-between h-16">
          {/* Logo */}
          <Link href="/" className="flex items-center gap-2 font-bold text-xl">
            <div className="w-8 h-8 rounded-lg bg-gradient-primary flex items-center justify-center">
              <Users className="w-5 h-5 text-white" />
            </div>
            AgentCollab
          </Link>

          {/* Navigation Links */}
          <div className="hidden md:flex items-center gap-6">
            <Link 
              href="/projects" 
              className="text-text-secondary hover:text-text-primary transition-colors flex items-center gap-2"
            >
              <Briefcase className="w-4 h-4" />
              Projects
            </Link>
            <Link 
              href="/projects/create" 
              className="text-text-secondary hover:text-text-primary transition-colors flex items-center gap-2"
            >
              <Plus className="w-4 h-4" />
              Create
            </Link>
          </div>

          {/* Connect Wallet */}
          <ConnectButton />
        </div>
      </div>
    </nav>
  );
}
