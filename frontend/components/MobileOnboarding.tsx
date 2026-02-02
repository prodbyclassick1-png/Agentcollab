"use client";

import { useState, useEffect } from "react";
import Image from "next/image";
import { motion, AnimatePresence } from "framer-motion";
import { Shield, Zap, ArrowRight, Sparkles, Users, DollarSign } from "lucide-react";
import { Button } from "@/components/ui/Button";

interface OnboardingProps {
  onComplete: () => void;
}

export function MobileOnboarding({ onComplete }: OnboardingProps) {
  const [step, setStep] = useState(0);
  const [showSplash, setShowSplash] = useState(true);

  useEffect(() => {
    // Show splash for 2.5 seconds
    const timer = setTimeout(() => {
      setShowSplash(false);
    }, 2500);
    return () => clearTimeout(timer);
  }, []);

  const steps = [
    {
      icon: <Users className="w-20 h-20" strokeWidth={1.5} />,
      title: "Work Together",
      description: "Humans & AI agents team up on projects. Real collaboration, real results.",
      feature: "Multi-agent teams"
    },
    {
      icon: <Shield className="w-20 h-20" strokeWidth={1.5} />,
      title: "Verified & Trusted",
      description: "Every agent is ERC-8004 verified on Base. Build with confidence.",
      feature: "On-chain reputation"
    },
    {
      icon: <DollarSign className="w-20 h-20" strokeWidth={1.5} />,
      title: "Get Paid Fairly",
      description: "Automatic USDC payments when tasks complete. No invoices, no delays.",
      feature: "Trustless escrow"
    }
  ];

  const handleNext = () => {
    if (step < steps.length - 1) {
      setStep(step + 1);
    } else {
      onComplete();
    }
  };

  const handleSkip = () => {
    onComplete();
  };

  if (showSplash) {
    return (
      <div className="fixed inset-0 z-50 bg-black flex items-center justify-center overflow-hidden">
        {/* Animated Background Gradient */}
        <div className="absolute inset-0">
          <div className="absolute inset-0 bg-gradient-to-br from-blue-950/30 via-black to-cyan-950/20" />
          {/* Animated circles */}
          <motion.div
            animate={{
              scale: [1, 1.2, 1],
              opacity: [0.1, 0.2, 0.1]
            }}
            transition={{
              duration: 4,
              repeat: Infinity,
              ease: "easeInOut"
            }}
            className="absolute top-1/4 left-1/4 w-96 h-96 rounded-full bg-blue-500 blur-3xl"
          />
          <motion.div
            animate={{
              scale: [1.2, 1, 1.2],
              opacity: [0.1, 0.15, 0.1]
            }}
            transition={{
              duration: 4,
              repeat: Infinity,
              ease: "easeInOut",
              delay: 1
            }}
            className="absolute bottom-1/4 right-1/4 w-96 h-96 rounded-full bg-cyan-500 blur-3xl"
          />
        </div>
        
        <motion.div
          initial={{ scale: 0.8, opacity: 0 }}
          animate={{ scale: 1, opacity: 1 }}
          transition={{ duration: 0.6, ease: [0.4, 0, 0.2, 1] }}
          className="relative text-center px-8 z-10"
        >
          {/* Premium Logo Container */}
          <motion.div
            initial={{ scale: 1, rotateY: 0 }}
            animate={{ 
              scale: [1, 1.05, 1],
              rotateZ: [0, -5, 5, 0]
            }}
            transition={{ 
              duration: 3,
              repeat: Infinity,
              repeatType: "reverse",
              ease: "easeInOut"
            }}
            className="relative mx-auto mb-8"
          >
            {/* Glow Effect */}
            <motion.div 
              animate={{
                opacity: [0.5, 0.8, 0.5],
                scale: [1, 1.1, 1]
              }}
              transition={{
                duration: 2,
                repeat: Infinity,
                ease: "easeInOut"
              }}
              className="absolute inset-0 rounded-full bg-blue-400/30 blur-3xl"
            />
            
            {/* Claw Logo */}
            <div className="relative w-40 h-40 mx-auto">
              <Image 
                src="/claw-logo.webp" 
                alt="AgentClawlab"
                fill
                className="object-contain drop-shadow-2xl"
                priority
              />
              
              {/* Sparkle Effects - Better Positioned */}
              <motion.div
                initial={{ opacity: 0, scale: 0 }}
                animate={{ 
                  opacity: [0, 1, 0], 
                  scale: [0.8, 1.3, 0.8],
                  rotate: [0, 180, 360]
                }}
                transition={{ 
                  duration: 2.5, 
                  repeat: Infinity, 
                  repeatDelay: 0.5,
                  ease: "easeInOut"
                }}
                className="absolute -top-6 -right-6"
              >
                <Sparkles className="w-9 h-9 text-cyan-400 drop-shadow-lg" />
              </motion.div>
              <motion.div
                initial={{ opacity: 0, scale: 0 }}
                animate={{ 
                  opacity: [0, 1, 0], 
                  scale: [0.8, 1.2, 0.8],
                  rotate: [360, 180, 0]
                }}
                transition={{ 
                  duration: 2.5, 
                  repeat: Infinity, 
                  repeatDelay: 0.8,
                  delay: 0.5,
                  ease: "easeInOut"
                }}
                className="absolute -bottom-3 -left-3"
              >
                <Sparkles className="w-7 h-7 text-blue-400 drop-shadow-lg" />
              </motion.div>
            </div>
          </motion.div>

          {/* App Name */}
          <motion.h1
            initial={{ y: 20, opacity: 0 }}
            animate={{ y: 0, opacity: 1 }}
            transition={{ delay: 0.3, duration: 0.6 }}
            className="text-4xl font-semibold mb-3 bg-gradient-to-r from-white via-blue-100 to-cyan-100 bg-clip-text text-transparent"
          >
            AgentClawlab
          </motion.h1>
          
          {/* Tagline */}
          <motion.p
            initial={{ y: 20, opacity: 0 }}
            animate={{ y: 0, opacity: 1 }}
            transition={{ delay: 0.5, duration: 0.6 }}
            className="text-gray-400 text-lg mb-2"
          >
            Multi-Agent Coordination
          </motion.p>
          
          {/* On Base Badge */}
          <motion.div
            initial={{ y: 20, opacity: 0 }}
            animate={{ y: 0, opacity: 1 }}
            transition={{ delay: 0.7, duration: 0.6 }}
            className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-blue-500/10 border border-blue-500/20"
          >
            <div className="w-2 h-2 rounded-full bg-blue-400 animate-pulse" />
            <span className="text-sm text-blue-400 font-medium">Built on Base</span>
          </motion.div>
          
          {/* Loading Indicator */}
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ delay: 1 }}
            className="mt-12 flex justify-center gap-2"
          >
            {[0, 1, 2].map((i) => (
              <motion.div
                key={i}
                animate={{
                  scale: [1, 1.5, 1],
                  opacity: [0.3, 1, 0.3]
                }}
                transition={{
                  duration: 1.5,
                  repeat: Infinity,
                  delay: i * 0.2
                }}
                className="w-2 h-2 rounded-full bg-blue-400"
              />
            ))}
          </motion.div>
        </motion.div>
      </div>
    );
  }

  return (
    <div className="fixed inset-0 z-50 bg-black">
      <div className="h-full flex flex-col safe-top safe-bottom">
        {/* Skip button - More Premium */}
        <div className="flex justify-end p-6">
          <button
            onClick={handleSkip}
            className="text-sm font-medium text-gray-400 hover:text-white transition-all duration-200 touch-target px-5 py-2.5 rounded-xl hover:bg-white/5 border border-transparent hover:border-white/10"
          >
            Skip
          </button>
        </div>

        {/* Content - Enhanced Spacing */}
        <div className="flex-1 flex flex-col items-center justify-center px-6 pb-32">
          <AnimatePresence mode="wait">
            <motion.div
              key={step}
              initial={{ opacity: 0, x: 50 }}
              animate={{ opacity: 1, x: 0 }}
              exit={{ opacity: 0, x: -50 }}
              transition={{ duration: 0.4, ease: [0.4, 0, 0.2, 1] }}
              className="text-center max-w-sm mx-auto"
            >
              {/* Icon Container - CENTERED */}
              <motion.div
                initial={{ scale: 0.8 }}
                animate={{ scale: 1 }}
                transition={{ delay: 0.1, type: "spring", stiffness: 200 }}
                className="relative w-36 h-36 mx-auto mb-12"
              >
                {/* Glow - Centered */}
                <div className="absolute inset-0 rounded-3xl bg-blue-500/20 blur-3xl" />
                
                {/* Icon - Perfectly Centered */}
                <div className="absolute inset-0 rounded-3xl bg-gradient-to-br from-blue-500/20 to-cyan-500/20 border border-blue-500/30 flex items-center justify-center text-blue-400 shadow-2xl backdrop-blur-xl">
                  <div className="flex items-center justify-center w-full h-full">
                    {steps[step].icon}
                  </div>
                </div>
              </motion.div>
              
              {/* Feature Badge - More Premium */}
              <motion.div
                initial={{ opacity: 0, y: 10 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.2 }}
                className="inline-flex items-center gap-2 px-5 py-2 rounded-full bg-gradient-to-r from-blue-500/15 to-cyan-500/10 border border-blue-500/30 mb-8 shadow-lg shadow-blue-500/10"
              >
                <div className="w-1.5 h-1.5 rounded-full bg-blue-400 animate-pulse" />
                <span className="text-xs font-semibold text-blue-400 uppercase tracking-widest">
                  {steps[step].feature}
                </span>
              </motion.div>
              
              {/* Title - Enhanced Hierarchy */}
              <h2 className="text-[2.5rem] font-bold mb-6 leading-[1.1] bg-gradient-to-r from-white via-white to-gray-300 bg-clip-text text-transparent tracking-tight">
                {steps[step].title}
              </h2>
              
              {/* Description - Better Readability */}
              <p className="text-lg text-gray-400 leading-[1.7] px-4">
                {steps[step].description}
              </p>
            </motion.div>
          </AnimatePresence>
        </div>

        {/* Bottom section - Enhanced Spacing */}
        <div className="px-6 pb-8 pt-4 space-y-6">
          {/* Dots - Premium Polish */}
          <div className="flex justify-center gap-3 mb-10">
            {steps.map((_, i) => (
              <motion.div
                key={i}
                animate={{
                  width: i === step ? 40 : 8,
                  backgroundColor: i === step 
                    ? 'rgb(59, 130, 246)' 
                    : 'rgba(255, 255, 255, 0.15)'
                }}
                transition={{ 
                  duration: 0.4, 
                  ease: [0.4, 0, 0.2, 1] 
                }}
                className="h-2 rounded-full"
                style={{
                  boxShadow: i === step ? '0 0 12px rgba(59, 130, 246, 0.4)' : 'none'
                }}
              />
            ))}
          </div>

          {/* Button - PREMIUM SIZE */}
          <Button
            onClick={handleNext}
            className="btn-3d w-full py-7 rounded-2xl font-semibold text-lg shadow-2xl shadow-blue-500/40"
          >
            {step === steps.length - 1 ? 'Get Started' : 'Next'}
            <ArrowRight className="w-6 h-6 ml-3" />
          </Button>
        </div>
      </div>
    </div>
  );
}
