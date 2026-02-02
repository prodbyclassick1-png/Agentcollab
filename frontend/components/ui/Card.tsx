"use client";

import { HTMLAttributes, forwardRef } from "react";
import { motion, HTMLMotionProps } from "framer-motion";

interface CardProps extends Omit<HTMLMotionProps<"div">, "children"> {
  hover?: boolean;
  glass?: boolean;
  children: React.ReactNode;
}

export const Card = forwardRef<HTMLDivElement, CardProps>(
  ({ hover = false, glass = true, className = "", children, ...props }, ref) => {
    const baseClass = glass ? "glass" : "bg-surface border border-white/10";
    const hoverClass = hover ? "hover:-translate-y-1 hover:shadow-xl hover:shadow-primary/10" : "";

    return (
      <motion.div
        ref={ref}
        className={`${baseClass} rounded-xl p-6 transition-all duration-300 ${hoverClass} ${className}`}
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.3 }}
        {...props}
      >
        {children}
      </motion.div>
    );
  }
);

Card.displayName = "Card";

export const CardHeader = ({ className = "", children }: HTMLAttributes<HTMLDivElement>) => (
  <div className={`mb-4 ${className}`}>{children}</div>
);

export const CardTitle = ({ className = "", children }: HTMLAttributes<HTMLHeadingElement>) => (
  <h3 className={`text-xl font-bold ${className}`}>{children}</h3>
);

export const CardDescription = ({ className = "", children }: HTMLAttributes<HTMLParagraphElement>) => (
  <p className={`text-sm text-text-secondary ${className}`}>{children}</p>
);

export const CardContent = ({ className = "", children }: HTMLAttributes<HTMLDivElement>) => (
  <div className={className}>{children}</div>
);

export const CardFooter = ({ className = "", children }: HTMLAttributes<HTMLDivElement>) => (
  <div className={`mt-4 pt-4 border-t border-white/10 ${className}`}>{children}</div>
);
