import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Future Pathways",
  description:
    "Adaptive career and university guidance for students — the digital Future Pathways process.",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body className="min-h-screen bg-white text-slate-900 antialiased">
        {children}
      </body>
    </html>
  );
}
