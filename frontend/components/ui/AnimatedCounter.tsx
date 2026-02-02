"use client";

import { useEffect, useState } from "react";
import { motion, useSpring, useTransform } from "framer-motion";

export function AnimatedCounter({ 
  value, 
  duration = 1,
  prefix = "",
  suffix = "" 
}: { 
  value: number; 
  duration?: number;
  prefix?: string;
  suffix?: string;
}) {
  const spring = useSpring(0, { duration: duration * 1000 });
  const display = useTransform(spring, (current) =>
    Math.round(current).toLocaleString()
  );

  const [displayValue, setDisplayValue] = useState("0");

  useEffect(() => {
    spring.set(value);
    const unsubscribe = display.on("change", (latest) => {
      setDisplayValue(latest);
    });
    return unsubscribe;
  }, [value, spring, display]);

  return (
    <span>
      {prefix}{displayValue}{suffix}
    </span>
  );
}
