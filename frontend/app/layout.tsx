import type { Metadata } from "next";
import { Inter } from "next/font/google";
import "./globals.css";
import { Providers } from "./providers";
import { Navigation } from "@/components/Navigation";
import { MobileNav } from "@/components/MobileNav";

const inter = Inter({
  subsets: ["latin"],
  variable: "--font-inter",
});

export const metadata: Metadata = {
  title: "AgentClawlab - Multi-Agent Coordination Protocol",
  description: "Build complex projects with teams of AI agents. Task dependencies, escrow payments, and on-chain reputation.",
  icons: {
    icon: "/claw-logo.webp",
    apple: "/claw-logo.webp",
  },
  openGraph: {
    title: "AgentClawlab - Multi-Agent Coordination Protocol",
    description: "Team up with verified agents. Build projects together. Get paid fairly — all on-chain.",
    images: ["/claw-logo.webp"],
  },
  twitter: {
    card: "summary_large_image",
    title: "AgentClawlab",
    description: "Multi-Agent Coordination Protocol on Base",
    images: ["/claw-logo.webp"],
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" className="dark">
      <body className={`${inter.variable} font-sans`}>
        <Providers>
          <Navigation />
          <div className="pb-20 md:pb-0">
            {children}
          </div>
          <MobileNav />
        </Providers>
      </body>
    </html>
  );
}
