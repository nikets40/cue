import type { Metadata } from "next";
import { Manrope, Geist_Mono } from "next/font/google";
import "./globals.css";

const manrope = Manrope({
  variable: "--font-manrope",
  subsets: ["latin"],
});

const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  title: "Cue — an open-source iPhone remote for your Mac's media",
  description:
    "Cue turns your iPhone into a remote for whatever your Mac is playing: YouTube Music, Netflix, VLC, anything in the Now Playing pipeline. Two apps, your Wi-Fi, no cloud.",
  openGraph: {
    title: "Cue — an open-source iPhone remote for your Mac's media",
    description:
      "Control whatever your Mac is playing from your iPhone. Bonjour + WebSocket on your LAN, no accounts, no cloud. MIT licensed.",
    type: "website",
  },
};

export default function RootLayout({ children }: LayoutProps<"/">) {
  return (
    <html
      lang="en"
      className={`${manrope.variable} ${geistMono.variable} antialiased`}
    >
      <body>{children}</body>
    </html>
  );
}
