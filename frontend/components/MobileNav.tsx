"use client";

import Link from "next/link";
import Image from "next/image";
import { usePathname } from "next/navigation";
import { Home, FolderKanban, PlusCircle, LayoutDashboard } from "lucide-react";
import { motion } from "framer-motion";

export function MobileNav() {
  const pathname = usePathname();

  const navItems = [
    { href: "/", icon: Home, label: "Home" },
    { href: "/projects", icon: FolderKanban, label: "Projects" },
    { href: "/projects/create", icon: PlusCircle, label: "Create" },
    { href: "/dashboard", icon: LayoutDashboard, label: "Dashboard" },
  ];

  const isActive = (href: string) => {
    if (href === "/") return pathname === "/";
    return pathname?.startsWith(href);
  };

  return (
    <nav className="md:hidden fixed bottom-0 left-0 right-0 z-50 safe-bottom">
      <div className="relative">
        {/* Premium Glass Background */}
        <div className="absolute inset-0 backdrop-blur-2xl bg-black/80 border-t border-white/10" />
        
        {/* Gradient Top Border */}
        <div className="absolute top-0 left-0 right-0 h-px bg-gradient-to-r from-transparent via-blue-500/50 to-transparent" />
        
        {/* Navigation Items */}
        <div className="relative grid grid-cols-4 gap-1 px-2 py-2">
          {navItems.map((item) => {
            const active = isActive(item.href);
            const Icon = item.icon;
            
            return (
              <Link
                key={item.href}
                href={item.href}
                className="relative flex flex-col items-center justify-center gap-1 py-2 px-3 rounded-xl touch-target transition-all duration-200"
              >
                {/* Active Background */}
                {active && (
                  <motion.div
                    layoutId="activeTab"
                    className="absolute inset-0 rounded-xl bg-gradient-to-br from-blue-500/20 to-cyan-500/10 border border-blue-500/30"
                    transition={{
                      type: "spring",
                      stiffness: 500,
                      damping: 40
                    }}
                  />
                )}
                
                {/* Icon */}
                <div className="relative">
                  <Icon 
                    className={`w-5 h-5 transition-colors duration-200 ${
                      active ? 'text-blue-400' : 'text-gray-400'
                    }`}
                  />
                  
                  {/* Active Indicator Dot */}
                  {active && (
                    <motion.div
                      initial={{ scale: 0 }}
                      animate={{ scale: 1 }}
                      className="absolute -top-1 -right-1 w-2 h-2 rounded-full bg-blue-400"
                    />
                  )}
                </div>
                
                {/* Label */}
                <span className={`text-xs font-medium transition-colors duration-200 ${
                  active ? 'text-white' : 'text-gray-400'
                }`}>
                  {item.label}
                </span>
              </Link>
            );
          })}
        </div>
      </div>
    </nav>
  );
}
