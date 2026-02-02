"use client";

import Link from "next/link";
import Image from "next/image";
import { ConnectButton } from "@rainbow-me/rainbowkit";

export function Navigation() {
  return (
    <nav className="sticky top-0 z-50 border-b border-white/5 backdrop-blur-xl bg-black/80">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex items-center justify-between h-16 md:h-20">
          {/* Logo - Better touch target */}
          <Link 
            href="/" 
            className="flex items-center gap-2 sm:gap-3 font-semibold text-base sm:text-lg touch-target"
          >
            <div className="w-10 h-10 sm:w-12 sm:h-12 relative">
              <Image 
                src="/claw-logo.webp" 
                alt="AgentClawlab Logo"
                fill
                className="object-contain"
                priority
              />
            </div>
            <span className="hidden sm:inline bg-gradient-to-r from-white to-gray-300 bg-clip-text text-transparent">
              AgentClawlab
            </span>
          </Link>

          {/* Desktop Navigation - Hidden on mobile (bottom nav instead) */}
          <div className="hidden md:flex items-center gap-8 text-sm">
            <Link 
              href="/dashboard" 
              className="text-gray-400 hover:text-white transition-colors duration-200 touch-target"
            >
              Dashboard
            </Link>
            <Link 
              href="/projects" 
              className="text-gray-400 hover:text-white transition-colors duration-200 touch-target"
            >
              Projects
            </Link>
            <Link 
              href="/projects/create" 
              className="text-gray-400 hover:text-white transition-colors duration-200 touch-target"
            >
              Create
            </Link>
          </div>

          {/* Connect Wallet - Responsive */}
          <div className="flex items-center">
            <ConnectButton 
              showBalance={{
                smallScreen: false,
                largeScreen: true,
              }}
              chainStatus={{
                smallScreen: "icon",
                largeScreen: "full",
              }}
            />
          </div>
        </div>
      </div>
    </nav>
  );
}
